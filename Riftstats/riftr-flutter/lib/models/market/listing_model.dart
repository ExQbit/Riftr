import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/shipping_rates.dart';

enum CardCondition { MT, NM, EX, GD, LP, PL, PO }

extension CardConditionExt on CardCondition {
  String get label => switch (this) {
        CardCondition.MT => 'Mint',
        CardCondition.NM => 'Near Mint',
        CardCondition.EX => 'Excellent',
        CardCondition.GD => 'Good',
        CardCondition.LP => 'Lightly Played',
        CardCondition.PL => 'Played',
        CardCondition.PO => 'Poor',
      };

  String get short => name;
}

class MarketListing {
  final String id;
  final String cardId;
  final String cardName;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  final String? sellerCountry;
  final double sellerRating;
  final int sellerSales;
  /// Discogs-Modell (2026-05-01): Snapshot des Verkäufer-Status zur
  /// Listing-Erstellung. Treibt Badge-Anzeige + Reklamations-Hinweis-Dialog
  /// (Widerruf-Pfad bei `§ 14 BGB`-Verkäufern). Quelle: `populateListing
  /// SellerStats` Cloud Function aus `sellerProfile.isCommercialSeller`.
  final bool sellerIsCommercial;

  /// Firmierung des gewerblichen Verkäufers, snapshot zur Listing-Zeit.
  /// DSA Art. 30 / § 5 DDG Pflichtinfo. Nur für commercial sellers.
  final String? sellerLegalEntityName;

  /// USt-IdNr des gewerblichen Verkäufers, snapshot zur Listing-Zeit.
  /// DSA Art. 30 / § 5 DDG Pflichtinfo. Nur für commercial sellers.
  final String? sellerVatId;

  /// Stripe-Onboarding-Snapshot zur Listing-Zeit (2026-05-02). Buyer-Side-
  /// Listing-Query filtert `sellerStripeReady == false` raus damit Käufer
  /// keine Listings sieht die er nicht kaufen kann. Propagated vom
  /// `syncSellerProfileToPlayerMirror`-Trigger sobald der Seller Stripe
  /// fertig onboarded. Default true: legacy listings ohne dieses Feld
  /// werden NICHT versteckt (sonst verschwinden alle bestehenden Listings
  /// bei Deploy).
  final bool sellerStripeReady;

  /// DAC7-Volume-Suspended-Snapshot zur Listing-Zeit (2026-05-02 gap fix).
  /// Buyer-Side-Listing-Query filtert `sellerVolumeSuspended == true` raus.
  /// Propagated vom `syncSellerProfileToPlayerMirror`-Trigger bei jeder
  /// volumeSuspended-Transition. Default false: legacy listings ohne dieses
  /// Feld bleiben sichtbar.
  final bool sellerVolumeSuspended;
  final double price;
  final CardCondition condition;
  final int quantity;
  final int reservedQty;
  final bool insuredOnly;
  final String language; // 'EN', 'CN'
  final bool isFoil;
  final String status; // 'active', 'sold', 'cancelled', 'reserved'
  final DateTime listedAt;
  final String? preReleaseDate; // ISO date string, e.g. "2026-05-08"

  const MarketListing({
    required this.id,
    required this.cardId,
    required this.cardName,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.sellerCountry,
    this.sellerRating = 0,
    this.sellerSales = 0,
    this.sellerIsCommercial = false,
    this.sellerLegalEntityName,
    this.sellerVatId,
    this.sellerStripeReady = true,
    this.sellerVolumeSuspended = false,
    required this.price,
    required this.condition,
    this.quantity = 1,
    this.reservedQty = 0,
    this.insuredOnly = false,
    this.language = 'EN',
    this.isFoil = false,
    this.status = 'active',
    required this.listedAt,
    this.preReleaseDate,
  });

  int get availableQty => quantity - reservedQty;

  /// Create a minimal MarketListing from a CartItem (for CheckoutSheet compatibility).
  factory MarketListing.fromCartItem(dynamic cartItem) {
    return MarketListing(
      id: cartItem.listingId as String,
      cardId: cartItem.cardId as String,
      cardName: cartItem.cardName as String,
      imageUrl: cartItem.imageUrl as String?,
      sellerId: cartItem.sellerId as String,
      sellerName: cartItem.sellerName as String,
      sellerCountry: cartItem.sellerCountry as String?,
      sellerRating: (cartItem.sellerRating as double?) ?? 0,
      price: cartItem.pricePerCard as double,
      condition: CardCondition.values.firstWhere(
        (c) => c.name == (cartItem.condition as String),
        orElse: () => CardCondition.NM,
      ),
      quantity: cartItem.maxQuantity as int,
      language: (cartItem.language as String?) ?? 'EN',
      listedAt: DateTime.now(),
    );
  }

  /// Whether this listing is for a pre-release card that hasn't shipped yet.
  bool get isPreRelease {
    if (preReleaseDate == null) return false;
    final rd = DateTime.tryParse(preReleaseDate!);
    return rd != null && rd.isAfter(DateTime.now());
  }

  /// Shipping cost for a specific buyer country.
  ///
  /// [bundleCardCount] is the total number of card-copies that will ship
  /// together from this seller (NOT the deck size, NOT the unique-card
  /// count — the actual physical-card count for ONE shipment). Defaults to
  /// 1 for single-listing call-sites (listing tiles, single-listing
  /// checkout, listing detail). Bulk-cart and Smart Cart MUST pass the
  /// per-seller bundle size or shipping is silently underpriced.
  ///
  /// Returns `null` when the seller's origin offers no method that can
  /// carry the bundle (Iceland edge-case + insuredOnly listing, or
  /// gigantic bundles from origins without a parcel option). UI should
  /// surface that as "shipping unavailable, contact seller" — falling back
  /// to a guessed price hides the real problem from the buyer.
  double? shippingFor(String buyerCountry, {int bundleCardCount = 1}) {
    if (sellerCountry == null) return 2.00; // unknown country fallback
    final quote = ShippingRates.quoteForBundle(
      sellerCountry!,
      buyerCountry,
      cardCount: bundleCardCount,
      insuredOnly: insuredOnly,
      // Single-listing-context: Bundle-Wert = price × Anzahl. Bei
      // ≥ €300 erzwingt quoteForBundle Insured (Discogs-Modell).
      bundleValue: price * bundleCardCount,
    );
    return quote?.price;
  }

  /// Same as [shippingFor] but returns the full `ShippingQuote` so callers
  /// can render the chosen method label (Letter / Tracked / Insured) and
  /// the underlying carrier product name without a second lookup.
  ShippingQuote? shippingQuoteFor(String buyerCountry,
      {int bundleCardCount = 1}) {
    if (sellerCountry == null) return null;
    return ShippingRates.quoteForBundle(
      sellerCountry!,
      buyerCountry,
      cardCount: bundleCardCount,
      insuredOnly: insuredOnly,
      bundleValue: price * bundleCardCount,
    );
  }

  /// Total price (one copy + cheapest shipping) for a specific buyer.
  /// Single-listing semantics — for bundle math use Smart Cart's
  /// `BuyPlan.grandTotal` which feeds bundle sizes into shipping.
  ///
  /// When the route is unsupported (e.g. insured-only listing from Iceland),
  /// returns `null` — UI should hide the listing from cross-listing sorts
  /// or surface "shipping unavailable" rather than substitute a guess.
  double? totalPriceFor(String buyerCountry) {
    final s = shippingFor(buyerCountry);
    return s == null ? null : price + s;
  }

  factory MarketListing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MarketListing(
      id: doc.id,
      cardId: d['cardId'] as String? ?? '',
      cardName: d['cardName'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      sellerId: d['sellerId'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? 'Unknown',
      sellerCountry: d['sellerCountry'] as String?,
      sellerRating: (d['sellerRating'] as num?)?.toDouble() ?? 0,
      sellerSales: d['sellerSales'] as int? ?? 0,
      sellerIsCommercial: d['sellerIsCommercial'] as bool? ?? false,
      sellerLegalEntityName: d['sellerLegalEntityName'] as String?,
      sellerVatId: d['sellerVatId'] as String?,
      // Default true so legacy listings without this field stay visible.
      // The CF write happens at populateListingSellerStats — once that
      // has run for a listing, the field is explicitly set.
      sellerStripeReady: d['sellerStripeReady'] as bool? ?? true,
      // Default false (= not suspended) so legacy listings stay visible.
      sellerVolumeSuspended: d['sellerVolumeSuspended'] as bool? ?? false,
      price: (d['price'] as num?)?.toDouble() ?? 0,
      condition: CardCondition.values.firstWhere(
        (c) => c.name == d['condition'],
        orElse: () => CardCondition.NM,
      ),
      quantity: d['quantity'] as int? ?? 1,
      reservedQty: d['reservedQty'] as int? ?? 0,
      insuredOnly: d['insuredOnly'] as bool? ?? false,
      language: d['language'] as String? ?? 'EN',
      isFoil: d['isFoil'] as bool? ?? false,
      status: d['status'] as String? ?? 'active',
      listedAt: (d['listedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preReleaseDate: d['preReleaseDate'] as String?,
    );
  }
}
