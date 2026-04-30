import 'listing_model.dart';

/// User-selected preferences that constrain which listings are eligible
/// for the Smart Cart plan.
class SmartCartFilters {
  /// Minimum acceptable card condition. Listings with worse condition
  /// (higher enum index) are rejected.
  final CardCondition minCondition;

  /// Foil handling:
  ///   'cheapest' — any foil state acceptable, pick lowest price
  ///   'nonFoil'  — reject foil listings
  ///   'foil'     — reject non-foil listings
  final String foilPreference;

  /// Language code filter (e.g. 'EN', 'CN'). Null = any language.
  final String? language;

  /// Seller country filter (ISO code). Null = any country.
  final String? sellerCountry;

  /// When true, Regular and Showcase variants are considered interchangeable
  /// (cross-rarity listings eligible). Routes through CardService.equivalentCardIds.
  final bool acceptCheaperArt;

  const SmartCartFilters({
    this.minCondition = CardCondition.NM,
    this.foilPreference = 'cheapest',
    this.language,
    this.sellerCountry,
    this.acceptCheaperArt = false,
  });

  SmartCartFilters copyWith({
    CardCondition? minCondition,
    String? foilPreference,
    String? language,
    String? sellerCountry,
    bool? acceptCheaperArt,
  }) =>
      SmartCartFilters(
        minCondition: minCondition ?? this.minCondition,
        foilPreference: foilPreference ?? this.foilPreference,
        language: language,
        sellerCountry: sellerCountry,
        acceptCheaperArt: acceptCheaperArt ?? this.acceptCheaperArt,
      );

  /// Compact one-liner for debug log output.
  String toDebugString() =>
      'cond≥${minCondition.name} foil=$foilPreference '
      'lang=${language ?? "any"} country=${sellerCountry ?? "any"} '
      'art=${acceptCheaperArt ? "cheaper-ok" : "strict"}';
}

/// One item in a SellerPlan — a specific listing assigned a quantity of copies.
class PlannedPurchase {
  final MarketListing listing;
  /// The cardId from the user's deck that this purchase fulfills. May differ
  /// from [listing.cardId] when the listing is a cross-set equivalent reprint
  /// or (with acceptCheaperArt) a cross-rarity alt-art.
  final String originalDeckCardId;
  final int quantity;

  const PlannedPurchase({
    required this.listing,
    required this.originalDeckCardId,
    required this.quantity,
  });

  double get lineTotal => listing.price * quantity;

  /// True when the chosen listing is a different physical card than the
  /// deck originally specified (different set or different rarity via
  /// acceptCheaperArt). Used by the Review Sheet to show a Regular/Showcase
  /// tag so the user is never surprised by the substitution.
  bool get isSubstituted => listing.cardId != originalDeckCardId;
}

class SellerPlan {
  final String sellerId;
  final String sellerName;
  final String? sellerCountry;
  final double? sellerRating;
  final List<PlannedPurchase> items;
  final double shipping;

  const SellerPlan({
    required this.sellerId,
    required this.sellerName,
    this.sellerCountry,
    this.sellerRating,
    required this.items,
    required this.shipping,
  });

  double get cardsSubtotal =>
      items.fold(0.0, (s, p) => s + p.lineTotal);
  double get subtotal => cardsSubtotal + shipping;
  int get totalCopies => items.fold(0, (s, p) => s + p.quantity);
}

/// A card the user needs that the algorithm couldn't cover under the
/// active filters (no listings / no matching condition / no foil / etc.).
class UnavailableCard {
  final String cardId;
  final String cardName;
  final int neededQty;
  /// Short reason label ("no listings", "no NM available", "no foil available").
  final String reason;

  const UnavailableCard({
    required this.cardId,
    required this.cardName,
    required this.neededQty,
    required this.reason,
  });
}

/// Why a card wasn't fulfilled by its strictly-preferred listing. Drives the
/// grouping in the Opt-in Alternatives section of the review sheet.
enum AlternativeReason {
  /// User wanted foil, only non-foil listings exist for this cardId.
  nonFoil,
  /// User wanted non-foil, only foil listings exist for this cardId.
  foil,
  /// Deck's preferred art (cardId) isn't listed, but an equivalent cross-
  /// rarity variant (same name+type, different cardId, e.g. Showcase↔Rare) is.
  otherVariant,
}

/// A card that couldn't be strictly fulfilled but has a soft-mismatch option
/// available. Shown in the review sheet's opt-in section; user includes
/// (or doesn't) via a per-group button. NEVER auto-added to the main plan.
class AlternativeCard {
  /// The deck card's own id — what the user originally asked for.
  final String originalDeckCardId;
  /// Name of the offered listing's card (may differ from deck card name only
  /// in the [otherVariant] case where [listing.cardId] is a different CN).
  final String cardName;
  /// How many copies remain needed.
  final int neededQty;
  /// Candidate listings for the relaxed match, sorted cheapest-first.
  /// All listings share the same classification per [reason].
  final List<MarketListing> offerings;
  final AlternativeReason reason;

  const AlternativeCard({
    required this.originalDeckCardId,
    required this.cardName,
    required this.neededQty,
    required this.offerings,
    required this.reason,
  });

  MarketListing get cheapest => offerings.first;
  bool get isFoil => cheapest.isFoil;
  double get totalPrice => cheapest.price * neededQty;

  /// Stable grouping key for UI merging and opt-in state tracking.
  /// - Foil fallbacks collapse globally to one group per reason.
  /// - Variant fallbacks group per listing cardId (each CN its own group).
  String get groupKey => switch (reason) {
    AlternativeReason.nonFoil => 'foil:nonFoil',
    AlternativeReason.foil => 'foil:foil',
    AlternativeReason.otherVariant => 'variant:${cheapest.cardId}',
  };
}

/// The outcome of a Smart Cart computation. Contains the chosen plan plus
/// optional Pareto-alternatives at different seller counts for the UI strip.
class BuyPlan {
  /// sellerId → plan. Deterministic iteration order preserved (LinkedHashMap).
  final Map<String, SellerPlan> sellerPlans;
  final List<UnavailableCard> unavailable;

  /// "Buying each card separately" reference cost: sum of each copy's
  /// cheapest listing + that listing's seller shipping (treating each
  /// copy as its own one-card order). Drives the savings banner.
  final double baselineCost;

  final DateTime generatedAt;
  final SmartCartFilters appliedFilters;

  /// Other Pareto-optimal plans at different seller counts (including
  /// this one). Null on individual sub-plans to avoid recursion.
  final List<BuyPlan>? alternatives;

  /// Hypothetical grandTotal if the user flipped [appliedFilters.acceptCheaperArt].
  /// Null = no meaningful alternate (either the toggle changes nothing, or the
  /// computation was skipped). Drives the "Save €X with Accept cheaper art" hint
  /// in the review sheet.
  final double? grandTotalIfArtToggled;

  /// Cards where the user's foil/art preference wasn't fulfilled but a
  /// soft-mismatch option exists. Presented in the review sheet's opt-in
  /// section — user decides per group whether to include.
  final List<AlternativeCard> alternativeCards;

  /// Buyer's ISO country code — needed by the review sheet to compute
  /// shipping cost when a user opts in an alternative from a new seller.
  final String buyerCountry;

  /// Set of [AlternativeCard.groupKey] values the user has elected to
  /// include at checkout. Populated by the review sheet on "Add all to
  /// cart"; consumed by market_screen when materializing the cart.
  /// Empty on freshly computed plans.
  final Set<String> includedAlternativeGroupKeys;

  const BuyPlan({
    required this.sellerPlans,
    required this.unavailable,
    required this.baselineCost,
    required this.generatedAt,
    required this.appliedFilters,
    required this.buyerCountry,
    this.alternatives,
    this.grandTotalIfArtToggled,
    this.alternativeCards = const [],
    this.includedAlternativeGroupKeys = const {},
  });

  double get totalCards =>
      sellerPlans.values.fold(0.0, (s, sp) => s + sp.cardsSubtotal);
  double get totalShipping =>
      sellerPlans.values.fold(0.0, (s, sp) => s + sp.shipping);

  /// Phase-1 Buyer-Service-Gebuehr (Cart-Subtotal-Staffel + 0.30€ × (N-1)
  /// Multi-Seller-Aufschlag). Source-of-Truth: `lib/data/payment_fees.dart`.
  ///
  /// Empty-Plan-Edge-Case (2026-04-30): bei sellerPlans.isEmpty zurueck 0.
  /// Vorher gab es 0.49 zurueck (Min-Tier service-fee bei totalCards=0),
  /// was den `Empty missing list — empty plan` Test in
  /// smart_cart_optimizer_test.dart brach.
  double get serviceFee {
    if (sellerPlans.isEmpty) return 0;
    final cents = (totalCards * 100).round();
    final base = _serviceFeeBaseFor(cents);
    final multiSellerSurcharge = 30 * (sellerCount - 1).clamp(0, 99);
    return (base + multiSellerSurcharge) / 100;
  }

  /// Inline mirror of `lib/data/payment_fees.dart::baseServiceFeeCents` —
  /// kept here to avoid circular dep when payment_fees is imported into
  /// optimizer code that also constructs BuyPlans. MUSS sync mit Backend.
  static int _serviceFeeBaseFor(int cartSubtotalCents) {
    if (cartSubtotalCents < 1500) return 49;
    if (cartSubtotalCents <= 5000) return 79;
    if (cartSubtotalCents <= 20000) return 129;
    return 199;
  }

  double get grandTotal => totalCards + totalShipping + serviceFee;
  double get savingsVsSeparate => (baselineCost - grandTotal).clamp(0, double.infinity);
  int get sellerCount => sellerPlans.length;
  int get totalCopiesCovered =>
      sellerPlans.values.fold(0, (s, sp) => s + sp.totalCopies);
  int get totalCopiesUnavailable =>
      unavailable.fold(0, (s, u) => s + u.neededQty);

  /// Plans are considered stale after 15 minutes — listings may have changed.
  DateTime get expiresAt => generatedAt.add(const Duration(minutes: 15));
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  BuyPlan _copyWith({
    List<BuyPlan>? alternatives,
    double? grandTotalIfArtToggled,
    List<AlternativeCard>? alternativeCards,
    Set<String>? includedAlternativeGroupKeys,
  }) => BuyPlan(
        sellerPlans: sellerPlans,
        unavailable: unavailable,
        baselineCost: baselineCost,
        generatedAt: generatedAt,
        appliedFilters: appliedFilters,
        buyerCountry: buyerCountry,
        alternatives: alternatives ?? this.alternatives,
        grandTotalIfArtToggled: grandTotalIfArtToggled ?? this.grandTotalIfArtToggled,
        alternativeCards: alternativeCards ?? this.alternativeCards,
        includedAlternativeGroupKeys:
            includedAlternativeGroupKeys ?? this.includedAlternativeGroupKeys,
      );

  BuyPlan withAlternatives(List<BuyPlan> alts) =>
      _copyWith(alternatives: alts);

  BuyPlan withArtToggledTotal(double? total) =>
      _copyWith(grandTotalIfArtToggled: total);

  /// Replace the opt-in alternatives list (used after collect to attach them).
  BuyPlan withAlternativeCards(List<AlternativeCard> alts) =>
      _copyWith(alternativeCards: alts);

  /// Stamp the user's opt-in selections before returning the plan from the
  /// review sheet. Read by market_screen when staging the cart.
  BuyPlan withIncludedAlternativeGroups(Set<String> keys) =>
      _copyWith(includedAlternativeGroupKeys: keys);

  /// Difference vs. the alternate plan with art-toggle flipped. Positive ⇒
  /// current plan is MORE EXPENSIVE and flipping would save money.
  double? get artToggleSavings {
    final alt = grandTotalIfArtToggled;
    if (alt == null) return null;
    return grandTotal - alt;
  }

}
