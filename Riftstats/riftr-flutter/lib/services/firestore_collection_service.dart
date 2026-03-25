import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/market/cost_basis_entry.dart';
import 'card_service.dart';
import 'firestore_service.dart';
import 'listing_service.dart';
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
    final wasReduction = qty < oldQty;

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

    if (wasReduction || qty <= 0) _syncListings(cardId);
  }

  void increment(String cardId, {double? costPrice, bool foil = false, String? source}) {
    if (foil) {
      _foils[cardId] = (_foils[cardId] ?? 0) + 1;
    } else {
      _cards[cardId] = (_cards[cardId] ?? 0) + 1;
    }

    // Track cost basis
    if (costPrice != null && costPrice > 0) {
      final lotSource = source ?? (foil ? 'manual_foil' : 'manual');
      final existing = _costBasis[cardId] ??
          const CostBasisEntry(totalCost: 0, totalQty: 0, lots: []);
      _costBasis[cardId] = CostBasisEntry(
        totalCost: existing.totalCost + costPrice,
        totalQty: existing.totalQty + 1,
        lots: [
          ...existing.lots,
          CostBasisLot(qty: 1, price: costPrice, date: DateTime.now(), source: lotSource),
        ],
      );
    }

    notifyListeners();
    _debounceSave();
  }

  /// Determines if a card should be tracked as foil based on rarity/set rules.
  static bool isFoilVariant(String? setId, String? rarity) {
    if (setId == 'OGS') return false;
    final r = rarity?.toLowerCase() ?? '';
    return r != 'common' && r != 'uncommon';
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
    _syncListings(cardId);
  }

  /// Check if collection can be reduced for this card.
  /// Returns null if OK, or a warning message if blocked by open orders.
  String? canReduce(String cardId, int newTotal) {
    final openOrders = ListingService.instance.openOrderQtyForCard(cardId);
    if (openOrders > 0 && newTotal < openOrders) {
      return 'You have $openOrders open order${openOrders > 1 ? 's' : ''} — ship first';
    }
    return null;
  }

  /// Check and sync active listings when collection qty decreases.
  /// Called from setQuantity and decrement after qty reduction.
  void _syncListings(String cardId) {
    final newTotal = getTotalQuantity(cardId);
    ListingService.instance.syncListingsForCard(cardId, newTotal).then((msg) {
      if (msg != null) {
        _lastListingSyncMessage = msg;
        notifyListeners();
      }
    });
  }

  /// Last listing sync message for toast display. Consumed once after read.
  String? _lastListingSyncMessage;
  String? consumeListingSyncMessage() {
    final msg = _lastListingSyncMessage;
    _lastListingSyncMessage = null;
    return msg;
  }

  /// ONE-TIME migration (2026-03-14): Fixed lots that used avg1 price instead of trend.
  /// DISABLED — was overwriting ALL lot prices with current market price on every
  /// app start, destroying historical cost basis data (the "0% bug").
  /// Cost basis prices are now immutable after creation.
  int repairCostBasis() {
    // Migration complete — no longer needed.
    return 0;
  }

  /// Synchronizes cost basis totalQty with actual collection quantity.
  /// Removes excess lots (FIFO) when cbQty > actualQty.
  /// Creates missing lots (at current market price) when cbQty < actualQty.
  /// Returns the number of cards corrected.
  int syncCostBasisWithCollection() {
    final market = MarketService.instance;
    int corrected = 0;

    // 1. cbQty > actualQty → remove excess lots
    // 2. cbQty < actualQty → add missing lots at current market price
    for (final cardId in {..._costBasis.keys, ..._cards.keys, ..._foils.keys}) {
      final actualQty = (_cards[cardId] ?? 0) + (_foils[cardId] ?? 0);
      final cb = _costBasis[cardId];
      final cbQty = cb?.totalQty ?? 0;

      if (actualQty == 0 && cb != null) {
        // Card no longer in collection — remove cost basis entirely
        _costBasis.remove(cardId);
        corrected++;
        debugPrint('CostBasis sync: $cardId removed (no longer in collection)');
        continue;
      }

      if (cbQty > actualQty && cb != null) {
        // Too many lots — trim excess (FIFO)
        final excess = cbQty - actualQty;
        final updated = cb.removeFIFO(excess);
        if (updated != null) {
          _costBasis[cardId] = updated;
        } else {
          _costBasis.remove(cardId);
        }
        corrected++;
        debugPrint('CostBasis sync: $cardId reduced $cbQty → $actualQty lots');
      } else if (cbQty < actualQty && actualQty > 0) {
        // Missing lots — create at current market price (break-even)
        final missing = actualQty - cbQty;
        final priceData = market.initialized ? market.getPrice(cardId) : null;
        final foilQty = _foils[cardId] ?? 0;
        final normalQty = _cards[cardId] ?? 0;

        // Use foil price if card is mostly foil, else normal price
        double fallbackPrice = 0;
        if (priceData != null) {
          if (foilQty >= normalQty) {
            fallbackPrice = priceData.foilPrice > 0 ? priceData.foilPrice : priceData.currentPrice;
          } else {
            fallbackPrice = priceData.nonFoilPrice > 0 ? priceData.nonFoilPrice : priceData.currentPrice;
          }
        }

        final existing = cb ?? const CostBasisEntry(totalCost: 0, totalQty: 0, lots: []);
        final source = foilQty >= normalQty ? 'manual_foil' : 'manual';
        _costBasis[cardId] = CostBasisEntry(
          totalCost: existing.totalCost + fallbackPrice * missing,
          totalQty: existing.totalQty + missing,
          lots: [
            ...existing.lots,
            CostBasisLot(qty: missing, price: fallbackPrice, date: DateTime.now(), source: source),
          ],
        );
        corrected++;
        debugPrint('CostBasis sync: $cardId added $missing missing lots @ €${fallbackPrice.toStringAsFixed(2)}');
      }
    }

    if (corrected > 0) {
      notifyListeners();
      _debounceSave();
      debugPrint('CostBasis sync: corrected $corrected cards');
    }

    return corrected;
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
