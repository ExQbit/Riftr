import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/market/listing_model.dart';
import '../models/market/order_model.dart';
import 'card_service.dart';
import 'firestore_service.dart';
import 'auth_service.dart';
import 'order_service.dart';
import 'profile_service.dart';
import 'seller_service.dart';

class ListingService extends ChangeNotifier {
  ListingService._();
  static final ListingService instance = ListingService._();

  StreamSubscription? _sub;
  List<MarketListing> _listings = [];

  /// Recently server-fetched listings with expiry time.
  /// The snapshot stream won't overwrite these until the protection expires.
  final Map<String, ({MarketListing listing, DateTime expiresAt})> _fresh = {};

  /// Buyer-side visibility: listing must be active AND its seller's
  /// Stripe-Connect-Onboarding fertig AND the seller is not DAC7-volume-
  /// suspended. Sonst kann/darf der Buyer nicht kaufen → wir verstecken
  /// das Listing komplett (Cardmarket-Pattern). `myListings` (owner-side)
  /// bypassed diesen Filter — Seller sieht die eigenen Listings auch im
  /// "Setting-up-payouts" oder "DAC7-suspended"-Zustand.
  bool _visibleToBuyers(MarketListing l) =>
      l.status == 'active' &&
      l.sellerStripeReady &&
      !l.sellerVolumeSuspended;

  List<MarketListing> get allActive =>
      _listings.where(_visibleToBuyers).toList();

  List<MarketListing> getListings(String cardId) =>
      _listings.where((l) => l.cardId == cardId && _visibleToBuyers(l)).toList()
        ..sort((a, b) => a.price.compareTo(b.price));

  /// Active listings for the given card AND all game-equivalent reprints
  /// across base sets (OGN / SFD / UNL). Sorted by price ascending.
  ///
  /// [acceptCheaperArt]: if true, Regular and Showcase variants are
  /// considered equivalent (Smart Cart opt-in for budget-minded buyers
  /// who don't care about alt-art). Default false = strict same-rarity.
  ///
  /// For non-base-set cards (promo/OGS), behaves identically to [getListings]
  /// because equivalentCardIds returns only the input id for those.
  List<MarketListing> getListingsForGameplayCard(
    String cardId, {
    bool acceptCheaperArt = false,
  }) {
    final equivalents = CardService.equivalentCardIds(
      cardId,
      acceptCheaperArt: acceptCheaperArt,
    ).toSet();
    return _listings
        .where((l) => equivalents.contains(l.cardId) && _visibleToBuyers(l))
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  int getListingCount(String cardId) =>
      _listings.where((l) => l.cardId == cardId && _visibleToBuyers(l)).length;

  /// Active listing count across equivalent cards (cross-set).
  int getListingCountForGameplayCard(
    String cardId, {
    bool acceptCheaperArt = false,
  }) {
    final equivalents = CardService.equivalentCardIds(
      cardId,
      acceptCheaperArt: acceptCheaperArt,
    ).toSet();
    return _listings
        .where((l) => equivalents.contains(l.cardId) && _visibleToBuyers(l))
        .length;
  }

  /// Lookup a listing by id in the local cache. Returns null if not cached.
  /// Used by CartService.syncWithFirestore to rehydrate cart items from
  /// server-side reservations on app start.
  MarketListing? byId(String listingId) {
    for (final l in _listings) {
      if (l.id == listingId) return l;
    }
    return null;
  }

  /// All active listings by the current user.
  List<MarketListing> get myListings {
    final uid = AuthService.instance.uid;
    if (uid == null) return [];
    return _listings
        .where((l) => l.sellerId == uid && l.status == 'active')
        .toList()
      ..sort((a, b) => b.listedAt.compareTo(a.listedAt));
  }

  /// Re-fetch a single listing from the Firestore **server** (bypassing cache)
  /// and patch it into the local list so the UI reflects the latest reservedQty
  /// immediately — without waiting for the snapshot stream to catch up.
  Future<void> refreshListing(String listingId) async {
    try {
      final doc = await FirestoreService.instance
          .globalCollection('listings')
          .doc(listingId)
          .get(const GetOptions(source: Source.server));
      if (!doc.exists) return;
      final updated = MarketListing.fromFirestore(doc);

      // Protect this value from being overwritten by stale stream snapshots.
      _fresh[listingId] = (
        listing: updated,
        expiresAt: DateTime.now().add(const Duration(seconds: 5)),
      );

      // Patch directly into _listings.
      final idx = _listings.indexWhere((l) => l.id == listingId);
      if (idx >= 0) {
        _listings[idx] = updated;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ListingService.refreshListing ERROR: $e');
    }
  }

  /// Re-apply fresh server data on top of stream-delivered listings.
  void _applyFreshEntries() {
    final now = DateTime.now();
    _fresh.removeWhere((_, v) => v.expiresAt.isBefore(now));
    for (final entry in _fresh.entries) {
      final idx = _listings.indexWhere((l) => l.id == entry.key);
      if (idx >= 0) {
        _listings[idx] = entry.value.listing;
      }
    }
  }

  void listen() {
    _sub?.cancel();
    try {
      _sub = FirestoreService.instance
          .globalCollection('listings')
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen(
        (snap) {
          final fromCache = snap.metadata.isFromCache;
          _listings = snap.docs
              .map((doc) {
                try {
                  return MarketListing.fromFirestore(doc);
                } catch (e) {
                  debugPrint('ListingService: Failed to parse listing ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<MarketListing>()
              .toList();

          // Re-apply any recently server-fetched listings so stale stream
          // data doesn't overwrite them.
          _applyFreshEntries();

          debugPrint('ListingService: ${_listings.length} listings '
              '(cache=$fromCache, fresh=${_fresh.length})');
          notifyListeners();
        },
        onError: (e) {
          debugPrint('ListingService: Stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('ListingService: Error starting listener: $e');
    }
  }

  /// Create a new listing in the global listings collection.
  Future<String?> createListing({
    required String cardId,
    required String cardName,
    String? imageUrl,
    required CardCondition condition,
    required double price,
    int quantity = 1,
    bool insuredOnly = false,
    bool isFoil = false,
    String language = 'EN',
    String? setId,
    String? setCode,
    String? collectorNumber,
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return null;

    // Source seller info — public profile name (NOT real name from seller onboarding)
    final seller = SellerService.instance.profile;
    final userProfile = ProfileService.instance.ownProfile;
    final sellerName = userProfile?.displayName ??
        AuthService.instance.currentUser?.displayName ??
        seller?.displayName ??
        'Unknown';
    final sellerCountry = seller?.country ?? userProfile?.country;

    // Security-Audit Round 4 (2026-04-29): sellerRating + sellerSales
    // duerfen NICHT mehr client-side gesetzt werden — Self-Stats-Fraud-
    // Vektor. Firestore-Rules rejecten neue Listings wenn diese Werte
    // != 0 sind. Server-side Trigger `populateListingSellerStats` (CF)
    // populiert sie aus sellerProfile (trusted) bei onCreate.
    // → Bis der Trigger gelaufen ist (~1-2s) zeigt die Listing-Tile
    //   "0 Sales / 0 Rating" — UI sollte das als "New seller" rendern.

    final data = {
      'cardId': cardId,
      'cardName': cardName,
      'imageUrl': imageUrl,
      'sellerId': uid,
      'sellerName': sellerName,
      'sellerCountry': sellerCountry,
      'sellerRating': 0.0,
      'sellerSales': 0,
      'price': price,
      'condition': condition.name,
      'quantity': quantity,
      'insuredOnly': insuredOnly,
      'language': language,
      'isFoil': isFoil,
      if (setCode != null) 'setCode': setCode,
      if (collectorNumber != null) 'collectorNumber': collectorNumber,
      'status': 'active',
      'listedAt': FieldValue.serverTimestamp(),
    };

    // Pre-release: store release date so orders know when shipping unlocks
    final releaseDate = CardService.getReleaseDate(setId);
    if (releaseDate != null && releaseDate.isAfter(DateTime.now())) {
      data['preReleaseDate'] = releaseDate.toIso8601String().substring(0, 10);
    }

    try {
      final doc = await FirestoreService.instance
          .globalCollection('listings')
          .add(data);
      return doc.id;
    } catch (e) {
      debugPrint('ListingService: Failed to create listing: $e');
      return null;
    }
  }

  /// Update listing quantity. Only the seller can update.
  Future<bool> updateListingQuantity(String listingId, int newQty) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return false;

    final listing = _listings.where((l) => l.id == listingId).firstOrNull;
    if (listing == null || listing.sellerId != uid) return false;

    try {
      await FirestoreService.instance
          .globalCollection('listings')
          .doc(listingId)
          .update({'quantity': newQty});
      return true;
    } catch (e) {
      debugPrint('ListingService: Failed to update listing qty: $e');
      return false;
    }
  }

  /// Update the price of a listing. Only the seller can update.
  Future<bool> updateListingPrice(String listingId, double newPrice) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return false;

    final listing = _listings.where((l) => l.id == listingId).firstOrNull;
    if (listing == null || listing.sellerId != uid) return false;

    try {
      await FirestoreService.instance
          .globalCollection('listings')
          .doc(listingId)
          .update({'price': newPrice});
      return true;
    } catch (e) {
      debugPrint('ListingService: Failed to update listing price: $e');
      return false;
    }
  }

  /// Count open (unshipped) order qty for a card from seller's sales.
  /// Open = pendingPayment, paid (not yet shipped, not cancelled/delivered).
  int openOrderQtyForCard(String cardId) {
    final sales = OrderService.instance.sales;
    var qty = 0;
    for (final order in sales) {
      if (!order.status.isActive) continue; // skip delivered/cancelled/etc
      if (order.status == OrderStatus.shipped) continue; // already shipped, collection already decremented
      for (final item in order.items) {
        if (item.cardId == cardId) qty += item.quantity;
      }
    }
    return qty;
  }

  /// Sync listings when collection quantity decreases.
  /// Respects open orders — collection cannot go below open order qty.
  /// Returns a description of what changed for toast display.
  Future<String?> syncListingsForCard(String cardId, int newCollectionQty) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return null;

    // Check open orders first — these are the hard minimum
    final openOrderQty = openOrderQtyForCard(cardId);
    if (openOrderQty > 0 && newCollectionQty < openOrderQty) {
      return 'You have $openOrderQty open order${openOrderQty > 1 ? 's' : ''} — ship first';
    }

    // Include both active and reserved listings
    final myListings = _listings
        .where((l) => l.cardId == cardId && l.sellerId == uid
            && (l.status == 'active' || l.status == 'reserved'))
        .toList()
      ..sort((a, b) => a.listedAt.compareTo(b.listedAt)); // oldest first

    if (myListings.isEmpty) return null;

    final totalListed = myListings.fold<int>(0, (t, l) => t + l.quantity);
    if (totalListed <= newCollectionQty) return null;

    // Need to reduce listings to fit within newCollectionQty
    var remaining = newCollectionQty - openOrderQty; // available for listings beyond orders
    if (remaining < 0) remaining = 0;
    final cancelled = <String>[];
    final reduced = <String, int>{}; // listingId → newQty

    for (final listing in myListings) {
      final minQty = listing.reservedQty; // can never go below reserved

      if (remaining <= 0) {
        if (minQty > 0) {
          // Has reservations — can't cancel
          continue;
        }
        await cancelListing(listing.id);
        cancelled.add(listing.cardName);
      } else if (listing.quantity > remaining) {
        final newQty = remaining.clamp(minQty, listing.quantity);
        if (newQty < listing.quantity) {
          await updateListingQuantity(listing.id, newQty);
          reduced[listing.id] = newQty;
        }
        remaining = 0;
      } else {
        remaining -= listing.quantity;
      }
    }

    // Build toast message
    final parts = <String>[];
    if (reduced.isNotEmpty) {
      final newQty = reduced.values.first;
      parts.add('Listing reduced to $newQty');
    }
    if (cancelled.isNotEmpty) {
      parts.add(cancelled.length == 1
          ? 'Listing cancelled'
          : '${cancelled.length} listings cancelled');
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Cancel (soft-delete) a listing. Only the seller can cancel.
  Future<bool> cancelListing(String listingId) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return false;

    // Verify ownership
    final listing = _listings.where((l) => l.id == listingId).firstOrNull;
    if (listing == null || listing.sellerId != uid) return false;

    try {
      await FirestoreService.instance
          .globalCollection('listings')
          .doc(listingId)
          .update({'status': 'cancelled'});
      return true;
    } catch (e) {
      debugPrint('ListingService: Failed to cancel listing: $e');
      return false;
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _listings = [];
  }
}
