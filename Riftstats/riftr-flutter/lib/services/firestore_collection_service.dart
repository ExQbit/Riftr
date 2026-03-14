import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/market/cost_basis_entry.dart';
import 'card_service.dart';
import 'firestore_service.dart';
import 'market_service.dart';

/// Firestore-backed collection service with real-time sync + cost basis tracking.
/// Collection path: artifacts/riftr-v1/users/{uid}/data/collection
/// Cost basis path: artifacts/riftr-v1/users/{uid}/data/cost_basis
class FirestoreCollectionService extends ChangeNotifier {
  FirestoreCollectionService._();
  static final FirestoreCollectionService instance = FirestoreCollectionService._();

  Map<String, int> _cards = {};
  Map<String, int> _foils = {};
  Map<String, CostBasisEntry> _costBasis = {};
  StreamSubscription? _sub;
  StreamSubscription? _cbSub;
  Timer? _debounce;

  Map<String, int> get cards => Map.unmodifiable(_cards);
  Map<String, int> get foils => Map.unmodifiable(_foils);
  Map<String, CostBasisEntry> get costBasis => Map.unmodifiable(_costBasis);
  int get uniqueOwned {
    final allIds = {..._cards.keys, ..._foils.keys};
    return allIds.where((id) => (_cards[id] ?? 0) + (_foils[id] ?? 0) > 0).length;
  }
  int get totalCopies => _cards.values.fold(0, (t, q) => t + q) + _foils.values.fold(0, (t, q) => t + q);

  void listen() {
    _sub?.cancel();
    _cbSub?.cancel();

    // Collection listener
    try {
      _sub = FirestoreService.instance
          .userDoc('data', 'collection')
          .snapshots()
          .listen((snap) {
        final data = snap.data();
        if (data != null && data['cards'] is Map) {
          _cards = {};
          _foils = {};
          (data['cards'] as Map).forEach((k, v) {
            final id = k.toString();
            if (v is Map) {
              _cards[id] = (v['qty'] as num?)?.toInt() ?? 0;
              final foilQty = (v['foil_qty'] as num?)?.toInt() ?? 0;
              if (foilQty > 0) _foils[id] = foilQty;
            } else if (v is num) {
              // Legacy format: plain int
              _cards[id] = v.toInt();
            }
          });
        } else {
          _cards = {};
          _foils = {};
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('FirestoreCollectionService.listen error: $e');
    }

    // Cost basis listener
    try {
      _cbSub = FirestoreService.instance
          .userDoc('data', 'cost_basis')
          .snapshots()
          .listen((snap) {
        final data = snap.data();
        if (data != null && data['entries'] is Map) {
          _costBasis = {};
          (data['entries'] as Map).forEach((k, v) {
            if (v is Map<String, dynamic>) {
              _costBasis[k.toString()] = CostBasisEntry.fromMap(v);
            }
          });
        } else {
          _costBasis = {};
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('CostBasis listen error: $e');
    }
  }

  void stopListening() {
    _sub?.cancel();
    _cbSub?.cancel();
    _sub = null;
    _cbSub = null;
    _debounce?.cancel();
    _cards = {};
    _foils = {};
    _costBasis = {};
  }

  int getQuantity(String cardId) => _cards[cardId] ?? 0;
  int getFoilQuantity(String cardId) => _foils[cardId] ?? 0;
  int getTotalQuantity(String cardId) => getQuantity(cardId) + getFoilQuantity(cardId);

  void setQuantity(String cardId, int qty, {double? costPrice, bool foil = false}) {
    final map = foil ? _foils : _cards;
    final oldQty = map[cardId] ?? 0;

    if (qty <= 0) {
      map.remove(cardId);
      if (getTotalQuantity(cardId) == 0) _costBasis.remove(cardId);
    } else if (qty > oldQty) {
      map[cardId] = qty;
      final addCount = qty - oldQty;
      final price = costPrice ?? 0;
      if (price > 0) {
        final existing = _costBasis[cardId] ??
            const CostBasisEntry(totalCost: 0, totalQty: 0, lots: []);
        _costBasis[cardId] = CostBasisEntry(
          totalCost: existing.totalCost + price * addCount,
          totalQty: existing.totalQty + addCount,
          lots: [
            ...existing.lots,
            CostBasisLot(qty: addCount, price: price, date: DateTime.now(), source: foil ? 'manual_foil' : 'manual'),
          ],
        );
      }
    } else if (qty < oldQty) {
      map[cardId] = qty;
      final removeCount = oldQty - qty;
      final cb = _costBasis[cardId];
      if (cb != null) {
        final updated = cb.removeFIFO(removeCount);
        if (updated != null) {
          _costBasis[cardId] = updated;
        } else {
          _costBasis.remove(cardId);
        }
      }
    }

    notifyListeners();
    _debounceSave();
  }

  void increment(String cardId, {double? costPrice, bool foil = false}) {
    if (foil) {
      _foils[cardId] = (_foils[cardId] ?? 0) + 1;
    } else {
      _cards[cardId] = (_cards[cardId] ?? 0) + 1;
    }

    // Track cost basis
    if (costPrice != null && costPrice > 0) {
      final existing = _costBasis[cardId] ??
          const CostBasisEntry(totalCost: 0, totalQty: 0, lots: []);
      _costBasis[cardId] = CostBasisEntry(
        totalCost: existing.totalCost + costPrice,
        totalQty: existing.totalQty + 1,
        lots: [
          ...existing.lots,
          CostBasisLot(qty: 1, price: costPrice, date: DateTime.now(), source: foil ? 'manual_foil' : 'manual'),
        ],
      );
    }

    notifyListeners();
    _debounceSave();
  }

  void decrement(String cardId, {bool foil = false}) {
    if (foil) {
      final current = _foils[cardId] ?? 0;
      if (current <= 1) {
        _foils.remove(cardId);
      } else {
        _foils[cardId] = current - 1;
      }
    } else {
      final current = _cards[cardId] ?? 0;
      if (current <= 1) {
        _cards.remove(cardId);
      } else {
        _cards[cardId] = current - 1;
      }
    }

    // Remove cost basis only if both normal and foil are 0
    if (getTotalQuantity(cardId) == 0) {
      _costBasis.remove(cardId);
    } else {
      final cb = _costBasis[cardId];
      if (cb != null) {
        // Source-aware FIFO: remove lots matching the type being decremented first
        final sourceMatch = foil ? 'foil' : 'manual';
        final updated = cb.removeFIFOBySource(1, preferSource: sourceMatch, isFoil: foil);
        if (updated != null) {
          _costBasis[cardId] = updated;
        } else {
          _costBasis.remove(cardId);
        }
      }
    }

    notifyListeners();
    _debounceSave();
  }

  /// Repairs all existing cost basis lots with correct foilPrice / nonFoilPrice.
  /// Lots recorded before the fix used currentPrice for all variants.
  /// After repair, each lot.price reflects the correct variant price.
  /// Returns the number of cards whose cost basis was repaired.
  int repairCostBasis() {
    final market = MarketService.instance;
    if (!market.initialized) return 0;

    int repairedCards = 0;

    final updatedCostBasis = <String, CostBasisEntry>{};

    for (final entry in _costBasis.entries) {
      final cardId = entry.key;
      final cb = entry.value;
      final priceData = market.getPrice(cardId);
      if (priceData == null) {
        updatedCostBasis[cardId] = cb;
        continue;
      }

      // Determine correct prices (same logic as _increment)
      final correctFoilPrice = priceData.foilPrice > 0
          ? priceData.foilPrice
          : priceData.currentPrice;
      final correctNormalPrice = priceData.nonFoilPrice > 0
          ? priceData.nonFoilPrice
          : priceData.currentPrice;

      bool changed = false;
      final newLots = <CostBasisLot>[];
      double newTotalCost = 0;

      for (final lot in cb.lots) {
        final isFoilLot = lot.source.contains('foil');
        final correctPrice = isFoilLot ? correctFoilPrice : correctNormalPrice;

        if ((lot.price - correctPrice).abs() > 0.001) {
          // Price was wrong — fix it
          newLots.add(CostBasisLot(
            qty: lot.qty,
            price: correctPrice,
            date: lot.date,
            source: lot.source,
          ));
          newTotalCost += correctPrice * lot.qty;
          changed = true;
        } else {
          newLots.add(lot);
          newTotalCost += lot.price * lot.qty;
        }
      }

      if (changed) {
        updatedCostBasis[cardId] = CostBasisEntry(
          totalCost: newTotalCost,
          totalQty: cb.totalQty,
          lots: newLots,
        );
        repairedCards++;
      } else {
        updatedCostBasis[cardId] = cb;
      }
    }

    if (repairedCards > 0) {
      _costBasis = updatedCostBasis;
      notifyListeners();
      _debounceSave();
      debugPrint('CostBasis: Repaired $repairedCards cards');
    }

    return repairedCards;
  }

  /// Migrates non-foil entries for foil-only cards (promos, rare+) into foil map.
  /// Fixes stuck entries where cards were added as non-foil before variant rules.
  /// Returns the number of cards migrated.
  int migrateVariantEntries() {
    final lookup = CardService.getLookup();
    if (lookup.isEmpty) return 0;

    int migrated = 0;

    for (final cardId in _cards.keys.toList()) {
      final card = lookup[cardId];
      if (card == null) continue;

      final isOGS = card.setId == 'OGS';
      final foilOnly = !isOGS &&
          (card.isPromo ||
              (card.rarity != 'Common' && card.rarity != 'Uncommon'));
      if (!foilOnly) continue;

      final nfQty = _cards[cardId] ?? 0;
      if (nfQty <= 0) continue;

      // Move non-foil quantity to foil
      _foils[cardId] = (_foils[cardId] ?? 0) + nfQty;
      _cards.remove(cardId);

      // Update cost basis lots: change 'manual' source → 'manual_foil'
      final cb = _costBasis[cardId];
      if (cb != null) {
        final newLots = cb.lots.map((lot) {
          if (!lot.source.contains('foil')) {
            return CostBasisLot(
              qty: lot.qty,
              price: lot.price,
              date: lot.date,
              source: 'manual_foil',
            );
          }
          return lot;
        }).toList();
        _costBasis[cardId] = CostBasisEntry(
          totalCost: cb.totalCost,
          totalQty: cb.totalQty,
          lots: newLots,
        );
      }

      migrated++;
    }

    if (migrated > 0) {
      notifyListeners();
      _debounceSave();
      debugPrint('Variant migration: moved $migrated cards from non-foil to foil');
    }

    return migrated;
  }

  void _debounceSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    try {
      // Save collection (A1 format: { cardId: { qty, foil_qty } })
      final allIds = {..._cards.keys, ..._foils.keys};
      final cardsMap = <String, Map<String, int>>{};
      for (final id in allIds) {
        final qty = _cards[id] ?? 0;
        final foilQty = _foils[id] ?? 0;
        if (qty > 0 || foilQty > 0) {
          cardsMap[id] = {'qty': qty, 'foil_qty': foilQty};
        }
      }
      await FirestoreService.instance
          .userDoc('data', 'collection')
          .set({
        'cards': cardsMap,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Save cost basis
      final cbMap = <String, dynamic>{};
      _costBasis.forEach((k, v) => cbMap[k] = v.toMap());
      await FirestoreService.instance
          .userDoc('data', 'cost_basis')
          .set({
        'entries': cbMap,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Collection save error: $e');
    }
  }
}
