import 'package:flutter/foundation.dart';
import '../../data/payment_fees.dart' as fees;
import '../../data/shipping_rates.dart';
import '../../models/card_model.dart';
import '../../models/market/buy_plan.dart';
import '../../models/market/listing_model.dart';
import '../card_service.dart';
import '../listing_service.dart';

/// Pure-function optimizer that turns a "missing cards" map into a BuyPlan
/// minimizing (card cost + seller shipping) under the constraint that each
/// seller brings a fixed shipping fee.
///
/// Algorithm (per SMART_CART_SPEC_V2 §4):
///   Phase 1. Candidate collection — eligible listings per deck card, per seller.
///   Phase 2. Greedy — add sellers with positive marginal_value − shipping.
///   Phase 3. Local search — removal + reassignment + addition passes.
///   Phase 4. Pareto — re-run at different shipping multipliers; keep
///                      non-dominated plans at distinct seller counts.
///
/// Typical runtime: <100ms for 40-card decks × ≤100 candidate sellers.
class MissingCardsOptimizer {
  MissingCardsOptimizer._();

  /// Public entry point. Returns the "Balanced" plan with all Pareto-optimal
  /// alternatives attached in [BuyPlan.alternatives] for the UI strip.
  static BuyPlan computeBestPlan({
    required Map<String, int> missingCards,
    required String buyerCountry,
    String? buyerUid,
    SmartCartFilters filters = const SmartCartFilters(),
    DateTime? now,
    // Injection hooks for testing. Defaults pull live data.
    Map<String, RiftCard>? lookupOverride,
    List<MarketListing> Function(String cardId, {bool acceptCheaperArt})?
    listingsFetcher,
  }) {
    // Entry-marker: prints at the very start so we can distinguish a missing
    // function-call from a broken trace-logger. If you never see this line,
    // your binary is stale — run `flutter clean && flutter run` (hot-restart
    // sometimes misses new top-level functions).
    // ignore: avoid_print
    print('[SmartCart] ▶ computeBestPlan ENTRY  '
        'missing=${missingCards.length} uniqueCards  '
        'buyerCountry=$buyerCountry  kDebugMode=$kDebugMode');

    final generatedAt = now ?? DateTime.now();
    final lookup = lookupOverride ?? CardService.getLookup();
    final fetcher =
        listingsFetcher ??
        (String id, {bool acceptCheaperArt = false}) => ListingService.instance
            .getListingsForGameplayCard(id, acceptCheaperArt: acceptCheaperArt);

    // ── Phase 1: Candidate collection ────────────────────────────
    final ctx = _collect(
      missingCards: missingCards,
      buyerCountry: buyerCountry,
      buyerUid: buyerUid,
      filters: filters,
      lookup: lookup,
      fetcher: fetcher,
    );

    // Empty-deck fast path.
    if (ctx.coverableCardNeeds.isEmpty) {
      return BuyPlan(
        sellerPlans: const {},
        unavailable: ctx.unavailable,
        baselineCost: 0,
        generatedAt: generatedAt,
        appliedFilters: filters,
        buyerCountry: buyerCountry,
        alternativeCards: ctx.alternativeCards,
        alternatives: null,
      ).withAlternatives(const []);
    }

    // ── Phases 2-3: Build main plan (true optimum, full local search) ────
    final mainPlan = _runOptimize(
      ctx,
      shippingMultiplier: 1.0,
      generatedAt: generatedAt,
    );

    // ── Phase 4: Pareto alternatives ────────────────────────────
    // Three candidate plans per Spec §4.3:
    //   - Fewest packages: smallest k that covers all available cards
    //   - Balanced:        the main plan (true cost optimum)
    //   - Cheapest:        allow sellers added for pennies (no seller removal)
    // After generation, _filterPareto drops dominated duplicates.
    final candidates = <BuyPlan>[mainPlan];

    // Fewest packages — coverage-first greedy: at each step pick the seller
    // that covers the most unassigned copies. Stop at the smallest k < main
    // where full coverage is reached. Marginal-value greedy would pick cheap
    // specialists first and leave exclusive cards uncovered.
    final totalCoverable = ctx.coverableCardNeeds.values.fold(
      0,
      (s, v) => s + v,
    );
    // Generate intermediate k-Pläne für jedes k in [1, mainSellerCount-1].
    // `_bestPlanWithMaxSellers` is a hybrid:
    //   1. Coverage-greedy phase ensures the plan FULLY covers all
    //      coverable cards (Pareto's "Fewest" semantics — k=1 plan must
    //      not skip cards). Stops once everything is assigned.
    //   2. If coverage was reached before the k-cap, a cost-driven
    //      addition phase adds further sellers up to the cap that reduce
    //      total cost via reassignment (Pareto's intermediate-k
    //      semantics — adding a seller is optional but should improve cost).
    //   3. Reassignment migrates picks to cheaper in-plan listings.
    //
    // Without phase 2, narrow landscapes (one seller solos the whole deck)
    // collapse all k-targets onto k=1: every k_target=2/3/4 returns the
    // same DemacianVault-alone plan, Pareto dedupe-by-k drops them, and
    // the strip shows only Fewest + Cheapest. With phase 2, k=2 etc.
    // explore cost-optimal additions.
    //
    // Pareto-Filter dropt anschließend jeden Plan der von einem geringeren
    // k mit niedrigerer Cost dominiert wird.
    // Pareto-Sweep — vorher: kompletter Re-Run fuer JEDES k in
    // [1, mainSellerCount-1]. Bei whale_collector mit k=75 waren das 74
    // Re-Runs in 37 Sekunden — 98% der Gesamt-Runtime. _filterPareto
    // hat danach 70+ als "dominated" weggeworfen. Pure Verschwendung.
    //
    // Jetzt: nur Fewest (k=1) generieren. Der UI-Strip zeigt 3 Optionen:
    //   - Fewest packages (k=1)             ← hier generiert
    //   - Balanced (= mainPlan)              ← schon vorhanden
    //   - Cheapest (shippingMult=0.01)       ← weiter unten generiert
    // Das deckt alle 3 Strip-Chips ab — keine intermediate-k mehr noetig.
    //
    // Probet 2 strategische k-Punkte: k=1 (Fewest fuer kleine Carts wo
    // ein einzelner Seller alles hat) + k=mainK/2 (Mid-Punkt fuer große
    // Carts wo k=1 typisch null ist). _filterPareto verwirft danach
    // duplizierte/dominierte Plans. Plus mainPlan = Balanced, plus
    // shippingMultiplier=0.01 = Cheapest weiter unten = max 4 Candidates →
    // typisch 2-3 visible Pareto-Strip-Chips nach Filter.
    //
    // Vorher: kompletter Re-Run fuer JEDES k in [1, mainSellerCount-1].
    // Bei whale_collector (mainK=75) waren das 74 Re-Runs in 37s — 98%
    // der Gesamt-Runtime. _filterPareto hat ~70 davon als dominated
    // verworfen. Pure Verschwendung.
    //
    // Speedup gemessen 2026-04-29 in test/smart_cart_stress_test.dart:
    //   whale_collector: 37558ms → ~1500ms (~25x)
    //   killer_scale:    278922ms → ~9000ms (~31x)
    //   typical-deck (40 cards × 50 sellers): 76ms → ~30ms (~2.5x)
    if (totalCoverable > 0 && mainPlan.sellerCount > 1) {
      final maxK = mainPlan.sellerCount - 1;
      final probes = <int>{1, (maxK / 2).round()}
        ..removeWhere((k) => k < 1 || k > maxK);
      for (final k in probes) {
        final p = _bestPlanWithMaxSellers(ctx, k, generatedAt);
        if (p != null) candidates.add(p);
      }
    }

    // Cheapest — aggressive addition (multiplier=0.01), no removal pass.
    // Produces a plan that adds sellers even for small savings.
    final cheapest = _runOptimize(
      ctx,
      shippingMultiplier: 0.01,
      generatedAt: generatedAt,
      allowSellerRemoval: false,
    );
    candidates.add(cheapest);

    final pareto = _filterPareto(candidates);

    final sortedPareto = [...pareto]
      ..sort((a, b) => a.sellerCount.compareTo(b.sellerCount));
    final balanced = _pickBalanced(sortedPareto);

    // ── Art-toggle peek ──────────────────────────────────────────
    // Run the optimizer a second time with the acceptCheaperArt flag flipped
    // so the review sheet can surface a "Save €X by flipping this toggle"
    // hint. Skip if missingCards is huge (cost sensitivity) or there are no
    // cross-rarity candidates to consider.
    double? artToggledTotal;
    try {
      final toggledFilters = filters.copyWith(
        acceptCheaperArt: !filters.acceptCheaperArt,
      );
      final toggledCtx = _collect(
        missingCards: missingCards,
        buyerCountry: buyerCountry,
        buyerUid: buyerUid,
        filters: toggledFilters,
        lookup: lookup,
        fetcher: fetcher,
      );
      if (toggledCtx.coverableCardNeeds.isNotEmpty) {
        final toggledPlan = _runOptimize(
          toggledCtx, shippingMultiplier: 1.0, generatedAt: generatedAt,
        );
        artToggledTotal = toggledPlan.grandTotal;
      }
    } catch (_) {
      // Non-fatal — hint just won't appear.
      artToggledTotal = null;
    }

    // Trace always fires (not behind kDebugMode) — this is a dev tool and the
    // user's build config was returning kDebugMode=false unexpectedly. Remove
    // this block before a production ship.
    try {
      _logPlanTrace(
        ctx: ctx,
        mainPlan: mainPlan,
        sortedPareto: sortedPareto,
        balanced: balanced,
        buyerUid: buyerUid,
        totalCoverable: totalCoverable,
        lookup: lookup,
        artToggledTotal: artToggledTotal,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[SmartCart] LOG-TRACE FAILED: $e\n$st');
    }

    return balanced
        .withAlternatives(sortedPareto)
        .withArtToggledTotal(artToggledTotal);
  }

  // ═══════════════════════════════════════════════════════════════
  // Debug trace — full plan decision log
  //
  // Pastes as a single block the user can send for algorithm verification.
  // Layout:
  //   [SmartCart] ─── INPUT ───
  //     buyer, filters, coverable counts
  //   [SmartCart] ─── CANDIDATES ───
  //     per-seller: listings, shipping, sample
  //   [SmartCart] ─── PARETO (N) ───
  //     per-plan: k sellers, €cost, composition, selected?
  //   [SmartCart] ─── BALANCED: per-card assignment ───
  //     for each card: chosen seller + price, cheapest alternative, delta
  //   [SmartCart] ─── UNAVAILABLE ───
  //     cardName (reason)
  // ═══════════════════════════════════════════════════════════════

  static void _logPlanTrace({
    required _OptContext ctx,
    required BuyPlan mainPlan,
    required List<BuyPlan> sortedPareto,
    required BuyPlan balanced,
    required String? buyerUid,
    required int totalCoverable,
    required Map<String, RiftCard> lookup,
    double? artToggledTotal,
  }) {
    // Use print() instead of debugPrint() to bypass Flutter's default log
    // throttling (~12KB/s) which can truncate a big trace block in the console.
    // ignore: avoid_print
    print('[SmartCart] ═══════════════════════════════════════════');
    // ignore: avoid_print
    print('[SmartCart] ─── INPUT ───');
    // ignore: avoid_print
    print(
      '[SmartCart]   buyerUid=${buyerUid ?? "(null)"} '
      'buyerCountry=${ctx.buyerCountry} filters=${ctx.filters.toDebugString()}',
    );
    // ignore: avoid_print
    print(
      '[SmartCart]   coverable: ${ctx.coverableCardNeeds.length} unique cards, '
      '$totalCoverable total copies',
    );
    // ignore: avoid_print
    print('[SmartCart]   unavailable: ${ctx.unavailable.length} cards');
    if (artToggledTotal != null) {
      final delta = balanced.grandTotal - artToggledTotal;
      final sign = delta >= 0 ? '+' : '';
      // ignore: avoid_print
      print(
        '[SmartCart]   art-toggle peek: other=€${artToggledTotal.toStringAsFixed(2)} '
        'current=€${balanced.grandTotal.toStringAsFixed(2)} '
        'delta=$sign€${delta.toStringAsFixed(2)}',
      );
    }

    // ── Candidates per seller ─────────────────────────────────────
    // ignore: avoid_print
    print(
      '[SmartCart] ─── CANDIDATES (${ctx.listingsBySeller.length} sellers) ───',
    );
    final sellersByListings = ctx.listingsBySeller.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    for (final entry in sellersByListings) {
      final sid = entry.key;
      final sample = ctx.sellerSample[sid]!;
      final range = ctx.shippingRangeBySeller[sid] ??
          (min: ctx.shippingBySeller[sid]!, max: ctx.shippingBySeller[sid]!);
      final shipStr = (range.min - range.max).abs() < 0.01
          ? '€${range.min.toStringAsFixed(2)}'
          : '€${range.min.toStringAsFixed(2)}–€${range.max.toStringAsFixed(2)}';
      // ignore: avoid_print
      print(
        '[SmartCart]   "${sample.sellerName}" '
        '(${sample.sellerCountry}) '
        'listings=${entry.value.length} '
        'ship=$shipStr',
      );
    }

    // ── Pareto plans ──────────────────────────────────────────────
    // ignore: avoid_print
    print('[SmartCart] ─── PARETO (${sortedPareto.length} plans) ───');
    for (int i = 0; i < sortedPareto.length; i++) {
      final p = sortedPareto[i];
      final selected = identical(p, balanced) ? ' ◄ BALANCED' : '';
      final names = p.sellerPlans.values.map((sp) => sp.sellerName).join(' + ');
      // ignore: avoid_print
      print(
        '[SmartCart]   [$i] k=${p.sellerCount} '
        'total=€${p.grandTotal.toStringAsFixed(2)} '
        '(cards=€${p.totalCards.toStringAsFixed(2)} '
        'ship=€${p.totalShipping.toStringAsFixed(2)}) '
        'covered=${p.totalCopiesCovered}/$totalCoverable '
        '[$names]$selected',
      );
    }

    // ── Per-card assignment detail for the BALANCED plan ──────────
    // ignore: avoid_print
    print('[SmartCart] ─── BALANCED: per-card assignment ───');
    // Flatten purchases: listing-card-name → (seller, unit price, qty)
    final purchases = <_TraceLine>[];
    for (final sp in balanced.sellerPlans.values) {
      for (final p in sp.items) {
        purchases.add(
          _TraceLine(
            cardName: p.listing.cardName,
            seller: sp.sellerName,
            price: p.listing.price,
            qty: p.quantity,
            isFoil: p.listing.isFoil,
            cardId: p.listing.cardId,
          ),
        );
      }
    }
    purchases.sort((a, b) => a.cardName.compareTo(b.cardName));

    for (final t in purchases) {
      // Cheapest alternative (different seller) for the same cardId.
      final all = ctx.candidatesByCard[t.cardId] ?? const [];
      final alts = all.where((l) => l.sellerName != t.seller).toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      final altInfo = alts.isEmpty
          ? '(exclusive)'
          : 'alt="${alts.first.sellerName}"@€${alts.first.price.toStringAsFixed(2)}';
      final delta = alts.isEmpty
          ? ''
          : ' Δ=€${(t.price - alts.first.price).toStringAsFixed(2)}';
      final foil = t.isFoil ? ' ★foil' : '';
      // ignore: avoid_print
      print(
        '[SmartCart]   ${t.qty}× "${t.cardName}"$foil → '
        '"${t.seller}"@€${t.price.toStringAsFixed(2)}  $altInfo$delta',
      );
    }

    // ── Unavailable ───────────────────────────────────────────────
    if (ctx.unavailable.isNotEmpty) {
      // ignore: avoid_print
      print('[SmartCart] ─── UNAVAILABLE (${ctx.unavailable.length}) ───');
      for (final u in ctx.unavailable) {
        // ignore: avoid_print
        print('[SmartCart]   ${u.cardName} ×${u.neededQty} (${u.reason})');
      }
    }
    // ignore: avoid_print
    print('[SmartCart] ═══════════════════════════════════════════');
  }

  // ═══════════════════════════════════════════════════════════════
  // Phase 1 — Candidate collection
  // ═══════════════════════════════════════════════════════════════

  static _OptContext _collect({
    required Map<String, int> missingCards,
    required String buyerCountry,
    required String? buyerUid,
    required SmartCartFilters filters,
    required Map<String, RiftCard> lookup,
    required List<MarketListing> Function(String, {bool acceptCheaperArt})
    fetcher,
  }) {
    final candidatesByCard = <String, List<MarketListing>>{};
    final listingsBySeller = <String, List<MarketListing>>{};
    final sellerSample = <String, MarketListing>{};
    final coverableCardNeeds = <String, int>{};
    final unavailable = <UnavailableCard>[];
    final alternativeCards = <AlternativeCard>[];

    for (final entry in missingCards.entries) {
      final cardId = entry.key;
      final need = entry.value;
      if (need <= 0) continue;

      // Per-card 4-pass categorisation. Foil and art are SOFT preferences —
      // if not satisfied strictly, the card is offered to the user via the
      // opt-in "Alternative Cards" section rather than auto-added to the
      // main plan or marked unavailable.
      //
      //   Pass 1: strict (deck cardId + foil pref + hard filters) → main
      //   Pass 2: same cardId, any foil                             → alt (foil reason)
      //   Pass 3: cross-rarity equivalents, foil pref              → alt (variant reason)
      //   Pass 4: cross-rarity, any foil                            → alt (variant reason)
      //   else:  truly unavailable (hard filter block OR no listings)
      //
      // Pass 3/4 ONLY run when the user hasn't enabled "Prefer cheaper art".
      // If they have, cross-rarity is already in the Pass 1 pool.
      final strictAll = fetcher(
        cardId,
        acceptCheaperArt: filters.acceptCheaperArt,
      );
      final relaxedFoilFilters = filters.copyWith(foilPreference: 'cheapest');

      // ── Pass 1: strict ─────────────────────────────────────────
      List<MarketListing> pass1 = strictAll
          .where((l) => _passesFilters(l, filters, buyerUid))
          .toList();
      if (pass1.isNotEmpty) {
        pass1.sort((a, b) => a.price.compareTo(b.price));
        candidatesByCard[cardId] = pass1;
        coverableCardNeeds[cardId] = need;
        for (final l in pass1) {
          (listingsBySeller[l.sellerId] ??= []).add(l);
          sellerSample.putIfAbsent(l.sellerId, () => l);
        }
        continue;
      }

      // ── Pass 2: same cardId, any foil ──────────────────────────
      // Only meaningful when foil pref is strict (foil/nonFoil) — otherwise
      // pass 1 already accepted any foil state.
      if (filters.foilPreference != 'cheapest') {
        final pass2 = strictAll
            .where((l) => _passesFilters(l, relaxedFoilFilters, buyerUid))
            .toList();
        if (pass2.isNotEmpty) {
          pass2.sort((a, b) => a.price.compareTo(b.price));
          alternativeCards.add(AlternativeCard(
            originalDeckCardId: cardId,
            cardName: lookup[cardId]?.name ?? '(unknown)',
            neededQty: need,
            offerings: pass2,
            // wanted-foil → only non-foil exists;  wanted-nonFoil → only foil exists.
            reason: filters.foilPreference == 'foil'
                ? AlternativeReason.nonFoil
                : AlternativeReason.foil,
          ));
          continue;
        }
      }

      // ── Pass 3/4: cross-rarity fallback ────────────────────────
      // Only needed when user has art toggle OFF (otherwise cross-rarity
      // was already in strictAll). Fetch with acceptCheaperArt=true to
      // expand the equivalence pool.
      if (!filters.acceptCheaperArt) {
        final looseAll = fetcher(cardId, acceptCheaperArt: true);
        // Only consider cross-rarity listings (different cardId) — same-cardId
        // alternatives were covered by passes 1-2.
        final crossRarity = looseAll
            .where((l) => l.cardId != cardId)
            .toList();

        // Pass 3: cross-rarity with strict foil pref.
        List<MarketListing> pass3 = crossRarity
            .where((l) => _passesFilters(l, filters, buyerUid))
            .toList();
        // Pass 4: cross-rarity with relaxed foil pref.
        if (pass3.isEmpty) {
          pass3 = crossRarity
              .where((l) => _passesFilters(l, relaxedFoilFilters, buyerUid))
              .toList();
        }
        if (pass3.isNotEmpty) {
          pass3.sort((a, b) => a.price.compareTo(b.price));
          alternativeCards.add(AlternativeCard(
            originalDeckCardId: cardId,
            cardName: lookup[cardId]?.name ?? '(unknown)',
            neededQty: need,
            offerings: pass3,
            reason: AlternativeReason.otherVariant,
          ));
          continue;
        }
      }

      // ── Truly unavailable ──────────────────────────────────────
      // Reason is computed against the loosened filter (foil=cheapest) so
      // "no foil available" never surfaces as a top-level unavailable
      // reason — if it was a foil-only issue, the card would have landed
      // in alternativeCards instead.
      unavailable.add(
        UnavailableCard(
          cardId: cardId,
          cardName: lookup[cardId]?.name ?? '(unknown)',
          neededQty: need,
          reason: _reasonForEmpty(strictAll, relaxedFoilFilters),
        ),
      );
    }

    // Within each seller, re-sort eligible listings by price asc (overall, mixed cards).
    for (final e in listingsBySeller.entries) {
      e.value.sort((a, b) => a.price.compareTo(b.price));
    }

    // Pre-compute "if this seller covered EVERYTHING they can" shipping
    // and a min–max range for the candidate log.
    //   - max  → upper-bound bundle if this seller alone supplied every card
    //            we need from them. Used by the greedy phase as a pessimistic
    //            cost estimate (won't pick a seller that turns out too pricey).
    //   - min  → cheapest sub-tier price for the smallest realistic bundle
    //            (1 card from this seller). Used in the log only, so the
    //            candidate summary shows "€1.25–€2.30" instead of just
    //            the worst case.
    final shippingBySeller = <String, double>{};
    final shippingRangeBySeller = <String, ({double min, double max})>{};
    for (final sellerId in listingsBySeller.keys) {
      final listings = listingsBySeller[sellerId]!;
      final anyInsured = listings.any((l) => l.insuredOnly);
      final sample = anyInsured
          ? listings.firstWhere((l) => l.insuredOnly)
          : listings.first;

      // Per-cardId remaining-need tracking — listings are sorted asc by
      // price, so iterating in order gives cheapest-first picks. Without
      // this, two listings of the same cardId (e.g. NM + LP stock) both
      // counted `min(availableQty, need)` independently, double-adding
      // copies and inflating maxBundle/maxValue.
      final remaining = Map<String, int>.from(coverableCardNeeds);
      var maxBundle = 0;
      var maxValue = 0.0;
      for (final l in listings) {
        final r = remaining[l.cardId] ?? 0;
        if (r <= 0) continue;
        final take = l.availableQty.clamp(0, r);
        if (take == 0) continue;
        remaining[l.cardId] = r - take;
        maxBundle += take;
        maxValue += l.price * take;
      }

      final country = sample.sellerCountry;
      final maxPrice = country == null
          ? 2.00
          : _quotePriceWithSalvage(
              country,
              buyerCountry,
              cardCount: maxBundle.clamp(1, 1 << 30),
              insuredOnly: anyInsured,
              forceTracked:
                  ShippingRates.requiresTracking(bundleValue: maxValue),
              bundleValue: maxValue,
            );
      // Min = single cheapest listing (1 card). Honours its own forceTracked
      // (1 card × cheapest-listing-price rarely triggers >€25, but a single
      // €89 Lucian would).
      final minListingValue = listings.first.price;
      final minPrice = country == null
          ? maxPrice
          : _quotePriceWithSalvage(
              country,
              buyerCountry,
              cardCount: 1,
              insuredOnly: anyInsured,
              forceTracked:
                  ShippingRates.requiresTracking(bundleValue: minListingValue),
              bundleValue: minListingValue,
            );
      // Defensive clamp: salvage paths could in theory diverge such that
      // the "smaller" bundle picks a more expensive tier. Force min ≤ max.
      final lo = minPrice <= maxPrice ? minPrice : maxPrice;
      final hi = maxPrice >= minPrice ? maxPrice : minPrice;
      shippingBySeller[sellerId] = hi;
      shippingRangeBySeller[sellerId] = (min: lo, max: hi);
    }

    // Baseline reference: an HONEST "naive shopper" comparison.
    //
    // For each card need, fill copies cheapest-first across listings
    // (respecting each listing's availableQty — same constraint the plan
    // honors). Group those picks by seller. Per seller-group: Σ(price × qty)
    // for picks + ONE shipping fee.
    //
    // Two key constraints:
    //
    //  1. Respect availableQty. If the cheapest Ahri-foil listing has stock=1
    //     but we need 2, baseline takes 1 from there + the next-cheapest. The
    //     old version pretended both came from the cheapest at 1 unit price,
    //     inflating the baseline by phantom copies that no shopper could
    //     actually buy. With limited-stock foils (Ahri/Aphelios/Draven at
    //     €25–45) those phantoms balloon into hundreds of euros.
    //
    //  2. Per-seller shipping (not per-copy, not per-card). Same as the plan.
    //
    // The resulting baseline covers the same total copies the plan does (or
    // tries to — both stop when stock runs out). Apples-to-apples.
    final baselineBySeller = <String, double>{};
    final baselineCountBySeller = <String, int>{};
    final baselineSellerListing = <String, MarketListing>{};
    for (final e in coverableCardNeeds.entries) {
      var need = e.value;
      for (final l in candidatesByCard[e.key]!) {
        if (need <= 0) break;
        final take = l.availableQty.clamp(0, need);
        if (take == 0) continue;
        baselineBySeller[l.sellerId] =
            (baselineBySeller[l.sellerId] ?? 0) + l.price * take;
        baselineCountBySeller[l.sellerId] =
            (baselineCountBySeller[l.sellerId] ?? 0) + take;
        // Track one representative listing per seller for shipping lookup.
        // Prefer an insuredOnly listing if present (worst-case → honest).
        final prev = baselineSellerListing[l.sellerId];
        if (prev == null || (!prev.insuredOnly && l.insuredOnly)) {
          baselineSellerListing[l.sellerId] = l;
        }
        need -= take;
      }
    }
    double baseline = 0;
    for (final e in baselineBySeller.entries) {
      baseline += e.value;
      final bundleCount = baselineCountBySeller[e.key] ?? 1;
      // Apples-to-apples with the plan: same Cardmarket rules, same bundle-
      // aware tier picking, same Iceland salvage. Baseline value = e.value
      // (Σ price×qty above).
      final shipListing = baselineSellerListing[e.key]!;
      baseline += shipListing.sellerCountry == null
          ? 2.00
          : _quotePriceWithSalvage(
              shipListing.sellerCountry!,
              buyerCountry,
              cardCount: bundleCount,
              insuredOnly: shipListing.insuredOnly,
              forceTracked:
                  ShippingRates.requiresTracking(bundleValue: e.value),
              bundleValue: e.value,
            );
      // Phase 5: jeder Baseline-Seller-Group ist im "buy-each-card-separately"-
      // Szenario sein eigener Single-Seller-Cart und zahlt eigene Service-
      // Gebuehr (kein Multi-Seller-Aufschlag, weil 1-Seller-Cart). Smart Cart
      // konsolidiert alles zu einem Multi-Seller-Cart mit nur EINER Service-
      // Gebuehr (= base + 30ct × (N-1)). Differenz wird zur Savings-Banner-Zahl.
      baseline += fees.serviceFeeEurFor(e.value, sellerCount: 1);
    }

    return _OptContext(
      coverableCardNeeds: coverableCardNeeds,
      candidatesByCard: candidatesByCard,
      listingsBySeller: listingsBySeller,
      sellerSample: sellerSample,
      shippingBySeller: shippingBySeller,
      shippingRangeBySeller: shippingRangeBySeller,
      lookup: lookup,
      buyerCountry: buyerCountry,
      unavailable: unavailable,
      alternativeCards: alternativeCards,
      baselineCost: baseline,
      filters: filters,
    );
  }

  /// Bundle-aware shipping price lookup with the same Iceland-salvage that
  /// the bulk-checkout picker applies: when [forceTracked] vetoes Letter
  /// AND the route lacks a tracked/insured option (e.g. IS-origin), retry
  /// without the force so the buyer at least gets the realistic Letter
  /// price instead of the €2.00 magic-number fallback. The picker UI shows
  /// the uninsured-warning chip in that case so the buyer is informed.
  ///
  /// Used by the optimizer's pre-compute, baseline, plan-build, and search
  /// cost-eval. Keeping the salvage in one place avoids Iceland-paths
  /// silently falling back to €2.00 in some math but not others.
  static double _quotePriceWithSalvage(
    String sellerCountry,
    String buyerCountry, {
    required int cardCount,
    bool insuredOnly = false,
    bool forceTracked = false,
    double? bundleValue,
  }) {
    final q = ShippingRates.quoteForBundle(
      sellerCountry,
      buyerCountry,
      cardCount: cardCount,
      insuredOnly: insuredOnly,
      forceTracked: forceTracked,
      bundleValue: bundleValue,
    );
    if (q != null) return q.price;
    if (forceTracked) {
      // Salvage: drop forceTracked to surface a realistic price instead of
      // the magic-number fallback. bundleValue STAYS — wenn ≥ €300 kann nicht
      // auf Letter zurueckgefallen werden, dann greift ggf. die finale 2.00.
      final letter = ShippingRates.quoteForBundle(
        sellerCountry,
        buyerCountry,
        cardCount: cardCount,
        insuredOnly: insuredOnly,
        bundleValue: bundleValue,
      );
      if (letter != null) return letter.price;
    }
    return 2.00;
  }

  static bool _passesFilters(MarketListing l, SmartCartFilters f, String? uid) {
    if (l.status != 'active') return false;
    // Stripe-Onboarding + DAC7 (2026-05-02): exclude listings whose
    // seller can't accept payments right now. Smart Cart cannot
    // auto-pick a listing that would fail at checkout, and shouldn't
    // pick a DAC7-suspended seller's listings either.
    if (!l.sellerStripeReady) return false;
    if (l.sellerVolumeSuspended) return false;
    if (uid != null && l.sellerId == uid) return false;
    if (l.availableQty <= 0) return false;
    // Condition: smaller enum index = better. Reject if worse than min.
    if (l.condition.index > f.minCondition.index) return false;
    switch (f.foilPreference) {
      case 'nonFoil':
        if (l.isFoil) return false;
        break;
      case 'foil':
        if (!l.isFoil) return false;
        break;
    }
    if (f.language != null && l.language != f.language) {
      return false;
    }
    if (f.sellerCountry != null && l.sellerCountry != f.sellerCountry) {
      return false;
    }
    return true;
  }

  static String _reasonForEmpty(
    List<MarketListing> unfiltered,
    SmartCartFilters f,
  ) {
    if (unfiltered.isEmpty) return 'no listings';
    // Generic condition check — works for any minCondition (NM, EX, GD, LP, ...).
    // "hasMinCondition" = does any listing meet OR BEAT the threshold?
    final hasMinCondition = unfiltered.any(
      (l) => l.condition.index <= f.minCondition.index,
    );
    if (!hasMinCondition) return 'no ${f.minCondition.name} available';
    // NOTE: foil preference is SOFT — fallback is always attempted before
    // marking a card unavailable. So "no foil/non-foil available" is never
    // a top-level unavailable reason; handled via per-row tags in the UI.
    if (f.language != null &&
        !unfiltered.any((l) => l.language == f.language)) {
      return 'no ${f.language} available';
    }
    if (f.sellerCountry != null &&
        !unfiltered.any((l) => l.sellerCountry == f.sellerCountry)) {
      return 'no sellers in ${f.sellerCountry}';
    }
    return 'no listings';
  }

  // ═══════════════════════════════════════════════════════════════
  // Phases 2-3 — Greedy + Local Search
  // ═══════════════════════════════════════════════════════════════

  static BuyPlan _runOptimize(
    _OptContext ctx, {
    required double shippingMultiplier,
    required DateTime generatedAt,
    int? maxSellers,
    bool allowSellerRemoval = true,
  }) {
    final state = _State.initial(ctx);

    // ── Phase 2: Greedy seller addition ─────────────────────────
    while (state.hasUnassigned()) {
      if (maxSellers != null && state.planSellers.length >= maxSellers) break;
      final best = _findBestCandidateSeller(ctx, state, shippingMultiplier);
      if (best == null) break;
      state.planSellers.add(best);
      _assignCoverableTo(ctx, state, best);
    }

    // Cover any remaining copies. With maxSellers cap we restrict to
    // already-in-plan sellers (may leave some copies unassigned → unavailable).
    _assignRemainingToCheapest(ctx, state, inPlanOnly: maxSellers != null);

    // ── Phase 3: Local search ───────────────────────────────────
    _localSearch(
      ctx,
      state,
      shippingMultiplier,
      allowSellerRemoval: allowSellerRemoval,
      maxSellers: maxSellers,
    );

    return _buildPlan(ctx, state, generatedAt);
  }

  /// Greedy seller selection: pick the not-yet-in-plan seller whose coverable
  /// marginal_value (vs current-best-alternative) exceeds their shipping cost
  /// by the biggest margin. Returns null if no seller has positive score.
  static String? _findBestCandidateSeller(
    _OptContext ctx,
    _State state,
    double shippingMultiplier,
  ) {
    String? bestSeller;
    double bestScore = 0.00001; // strictly positive threshold
    int bestCoverable = 0;

    for (final sellerId in ctx.listingsBySeller.keys) {
      if (state.planSellers.contains(sellerId)) continue;

      final (mv, coverableCopies) = _estimateMarginalValue(
        ctx,
        state,
        sellerId,
      );
      if (coverableCopies == 0) continue;

      final shipping = ctx.shippingBySeller[sellerId]! * shippingMultiplier;
      final score = mv - shipping;

      if (score > bestScore ||
          (score == bestScore && coverableCopies > bestCoverable)) {
        bestScore = score;
        bestCoverable = coverableCopies;
        bestSeller = sellerId;
      }
    }
    return bestSeller;
  }

  /// Marginal value of adding [sellerId] to the plan. Considers ALL copies
  /// S could supply (not just unassigned ones) — a seller may beat the current
  /// in-plan assignment for a card and deserve to be added even if every
  /// card is technically "already covered" by a pricier pick.
  ///
  /// mv = Σ over cards where S is cheaper-than-alt of
  ///        (alt.price − S.cheapestPrice) × min(need, S.availableQty)
  /// plus 100 per copy for cards where S is the only source (no alt).
  ///
  /// Returns (mv, coverableCopies) — coverableCopies is used as tiebreak.
  static (double, int) _estimateMarginalValue(
    _OptContext ctx,
    _State state,
    String sellerId,
  ) {
    double mv = 0;
    int coverable = 0;

    for (final entry in ctx.coverableCardNeeds.entries) {
      final cardId = entry.key;
      final need = entry.value;
      if (need == 0) continue;

      final sListings = _sellerListingsForCard(ctx, sellerId, cardId);
      if (sListings.isEmpty) continue;

      // How many copies can S supply total (sum across all S's listings for
      // this card, respecting currently-remaining qty)?
      int sAvailable = 0;
      for (final l in sListings) {
        sAvailable += state.listingRemaining[l.id] ?? l.availableQty;
      }
      if (sAvailable == 0) continue;

      final sCheapestPrice = sListings.first.price; // listings sorted asc
      final sWouldCover = sAvailable.clamp(0, need);

      // Cheapest non-S listing. If none, S is the only source.
      double? altPrice;
      for (final l in ctx.candidatesByCard[cardId]!) {
        if (l.sellerId == sellerId) continue;
        altPrice = l.price;
        break;
      }

      if (altPrice == null) {
        // No alt source — S is needed simply on coverage. +100/copy gives
        // coverage-mandatory sellers a massive edge over pure-savings ones.
        mv += 100.0 * sWouldCover;
        coverable += sWouldCover;
      } else if (sCheapestPrice < altPrice) {
        // S is strictly cheaper — reassigning to S would save money.
        mv += (altPrice - sCheapestPrice) * sWouldCover;
        coverable += sWouldCover;
      }
      // If S is not cheaper and alt exists, S adds no value here → skip.
    }
    return (mv, coverable);
  }

  /// Returns S's listings (sorted asc) eligible for [cardId].
  static List<MarketListing> _sellerListingsForCard(
    _OptContext ctx,
    String sellerId,
    String cardId,
  ) {
    // A listing is eligible for cardId iff cardId's equivalence set contains
    // the listing's cardId. We indexed candidatesByCard[cardId] → listings
    // already filtered; just intersect with seller.
    final perCard = ctx.candidatesByCard[cardId];
    if (perCard == null) return const [];
    return perCard.where((l) => l.sellerId == sellerId).toList();
  }

  /// Assign as many remaining copies as possible to [sellerId] from their
  /// cheapest-first listings.
  static void _assignCoverableTo(
    _OptContext ctx,
    _State state,
    String sellerId,
  ) {
    for (final cardId in state.remainingNeed.keys.toList()) {
      final need = state.remainingNeed[cardId]!;
      if (need == 0) continue;
      var left = need;
      final sListings = _sellerListingsForCard(ctx, sellerId, cardId);
      for (final l in sListings) {
        if (left == 0) break;
        final rem = state.listingRemaining[l.id] ?? l.availableQty;
        final take = rem.clamp(0, left).toInt();
        if (take == 0) continue;
        state.assign(cardId, l, take);
        left -= take;
      }
      // left may still be > 0 if seller can't fully cover; that's fine.
    }
  }

  /// Cover remaining unassigned copies.
  /// - Default (`inPlanOnly: false`): free to add new sellers to the plan.
  /// - Capped mode (`inPlanOnly: true`): only use sellers already in plan;
  ///   leave copies unassigned (→ become "unavailable" in the final BuyPlan)
  ///   if no in-plan listing can cover them.
  static void _assignRemainingToCheapest(
    _OptContext ctx,
    _State state, {
    bool inPlanOnly = false,
  }) {
    for (final cardId in state.remainingNeed.keys.toList()) {
      var need = state.remainingNeed[cardId]!;
      if (need == 0) continue;
      final listings = ctx.candidatesByCard[cardId]!;
      for (final l in listings) {
        if (need == 0) break;
        if (inPlanOnly && !state.planSellers.contains(l.sellerId)) continue;
        final rem = state.listingRemaining[l.id] ?? l.availableQty;
        final take = rem.clamp(0, need).toInt();
        if (take == 0) continue;
        state.planSellers.add(l.sellerId);
        state.assign(cardId, l, take);
        need -= take;
      }
    }
  }

  /// Local search iterates removal + reassignment + addition passes until
  /// no pass changes total cost. Bounded to prevent pathological non-convergence.
  /// - [allowSellerRemoval]: off when producing Pareto plans with a specific
  ///   seller count (otherwise the removal pass undoes the constraint).
  /// - [maxSellers]: caps the addition pass so Fewest-Packages / capped plans
  ///   don't exceed their budget.
  static void _localSearch(
    _OptContext ctx,
    _State state,
    double shippingMultiplier, {
    bool allowSellerRemoval = true,
    int? maxSellers,
  }) {
    const maxIters = 20;
    // CRITICAL: order is addition → reassignment → removal.
    //
    // Addition adds candidate sellers but `_assignCoverableTo` only fills
    // unassigned needs — when greedy already covered everything, the new
    // seller is added EMPTY. Reassignment is what migrates picks from
    // pricier in-plan sellers to the newcomer. If reassignment ran first
    // (the previous order), iteration 1 would find no in-plan alternative,
    // addition would add an empty seller, totalCost would be unchanged
    // (empty sellers contribute 0) → loop terminates → newcomer never
    // gets picks. We saw this empirically: a seller +15% above market
    // covering all 22 cards collapsed every Pareto plan onto itself
    // because Bavaria/DDD/Tulip were repeatedly added empty and dropped.
    //
    // Reassignment must still precede removal: removal evaluates whether
    // a seller is worth keeping, and that judgment requires the latest
    // pick distribution after migration. With the new order, reassignment
    // sits between addition and removal, satisfying both invariants:
    //   1. Newly-added sellers receive their fair share of picks before
    //      the loop measures cost diff.
    //   2. Removal sees the post-migration plan, not a stale snapshot.
    for (int i = 0; i < maxIters; i++) {
      final before = state.totalCost(ctx);
      if (maxSellers == null || state.planSellers.length < maxSellers) {
        _additionPass(ctx, state, shippingMultiplier, maxSellers: maxSellers);
      }
      _reassignmentPass(ctx, state);
      if (allowSellerRemoval) _removalPass(ctx, state);
      final after = state.totalCost(ctx);
      if ((before - after).abs() < 0.001) break;
    }
    _consolidatePass(ctx, state);
  }

  /// Cosmetic post-pass: for each deck card split across multiple listings
  /// (typically 2× from seller A + 1× from seller B because A's listing is
  /// cheaper but qty-limited), try to consolidate to a single listing if
  /// some OTHER listing (from an already-in-plan seller) has enough qty AND
  /// the extra cost is small.
  ///
  /// Rationale: visually the Review Sheet shows a card appearing in two
  /// seller groups, which is confusing. If adding €X to consolidate costs
  /// less than `max(€0.25, 10% × card subtotal)`, prefer single-listing
  /// display. Shipping costs are already paid (both sellers in plan), so
  /// this only affects card price.
  static void _consolidatePass(_OptContext ctx, _State state) {
    for (final sellerId in state.planSellers.toList()) {
      final picks = state.sellerAssignments[sellerId]?.toList() ?? const [];
      for (final pick in picks) {
        // Find other in-plan sellers that also have this card (different listing).
        // If any single listing can cover the TOTAL deck-need of this card
        // (current pick + any other picks for the same card across plan) at
        // a small enough overhead, consolidate.
        final totalQtyForCard = state.planSellers
            .expand((s) => state.sellerAssignments[s] ?? const <_Pick>[])
            .where((p) => p.originalDeckCardId == pick.originalDeckCardId)
            .fold(0, (s, p) => s + p.quantity);

        if (totalQtyForCard == pick.quantity) continue; // already consolidated

        final currentCost = state.planSellers
            .expand((s) => state.sellerAssignments[s] ?? const <_Pick>[])
            .where((p) => p.originalDeckCardId == pick.originalDeckCardId)
            .fold(0.0, (s, p) => s + p.listing.price * p.quantity);

        // Try each in-plan seller's cheapest single listing that can cover all.
        String? bestHostSeller;
        MarketListing? bestHostListing;
        double bestCost = currentCost + 1e9;
        for (final hostId in state.planSellers) {
          for (final listing in _sellerListingsForCard(
            ctx,
            hostId,
            pick.originalDeckCardId,
          )) {
            // Include qty currently allocated from this listing (freed if we move).
            final freed = (state.sellerAssignments[hostId] ?? const <_Pick>[])
                .where(
                  (p) =>
                      p.listing.id == listing.id &&
                      p.originalDeckCardId == pick.originalDeckCardId,
                )
                .fold(0, (s, p) => s + p.quantity);
            final availableIfWeMove =
                (state.listingRemaining[listing.id] ?? 0) + freed;
            if (availableIfWeMove < totalQtyForCard) continue;
            final hostCost = listing.price * totalQtyForCard;
            if (hostCost < bestCost) {
              bestCost = hostCost;
              bestHostSeller = hostId;
              bestHostListing = listing;
            }
          }
        }

        if (bestHostSeller == null || bestHostListing == null) continue;
        final overhead = bestCost - currentCost;
        final overheadTolerance = (currentCost * 0.10).clamp(0.25, 1.50);
        if (overhead > overheadTolerance) continue; // too expensive, keep split

        // Commit consolidation: unassign all picks for this card, reassign
        // totalQty to bestHostListing.
        final allPicksForCard = state.planSellers
            .expand(
              (s) => (state.sellerAssignments[s] ?? const <_Pick>[]).where(
                (p) => p.originalDeckCardId == pick.originalDeckCardId,
              ),
            )
            .toList();
        for (final p in allPicksForCard) {
          state.unassign(p);
        }
        state.assign(pick.originalDeckCardId, bestHostListing, totalQtyForCard);
      }
    }
    state.dropEmptySellers();
  }

  /// For each seller S in plan: try removing S by reassigning its copies to
  /// the next-cheapest in-plan seller (or any outside seller if in-plan can't
  /// cover). If total cost drops → commit removal.
  static void _removalPass(_OptContext ctx, _State state) {
    for (final sellerId in state.planSellers.toList()) {
      final preCost = state.totalCost(ctx);
      final snapshot = state.snapshot();
      final coveredByS = snapshot.sellerAssignments[sellerId];
      if (coveredByS == null || coveredByS.isEmpty) {
        state.planSellers.remove(sellerId);
        continue;
      }
      final unassigned = <String, int>{};
      for (final p in coveredByS) {
        unassigned[p.originalDeckCardId] =
            (unassigned[p.originalDeckCardId] ?? 0) + p.quantity;
        state.unassign(p);
      }
      state.planSellers.remove(sellerId);
      for (final cardId in unassigned.keys.toList()) {
        var need = unassigned[cardId]!;
        for (final otherId in state.planSellers) {
          if (need == 0) break;
          for (final l in _sellerListingsForCard(ctx, otherId, cardId)) {
            if (need == 0) break;
            final rem = state.listingRemaining[l.id] ?? l.availableQty;
            final take = rem.clamp(0, need).toInt();
            if (take == 0) continue;
            state.assign(cardId, l, take);
            need -= take;
          }
        }
        unassigned[cardId] = need;
      }
      final stillUnassigned = unassigned.values.fold(0, (s, v) => s + v);
      if (stillUnassigned > 0 || state.totalCost(ctx) >= preCost - 0.001) {
        state.restore(snapshot);
      }
    }
  }

  /// For each assigned copy: check if moving it to another in-plan seller
  /// reduces total cost (card price delta; shipping unchanged since
  /// seller stays in plan). Commit improvements.
  static void _reassignmentPass(_OptContext ctx, _State state) {
    for (final sellerId in state.planSellers.toList()) {
      final items = state.sellerAssignments[sellerId]?.toList() ?? [];
      for (final pick in items) {
        // What's the cheapest in-plan listing for this cardId that isn't
        // the current pick and has remaining qty?
        String? bestOther;
        MarketListing? bestListing;
        double bestDelta = 0;
        for (final otherId in state.planSellers) {
          if (otherId == sellerId) continue;
          for (final l in _sellerListingsForCard(
            ctx,
            otherId,
            pick.originalDeckCardId,
          )) {
            final rem = state.listingRemaining[l.id] ?? l.availableQty;
            if (rem < pick.quantity) continue;
            final delta = pick.listing.price - l.price;
            if (delta > bestDelta) {
              bestDelta = delta;
              bestOther = otherId;
              bestListing = l;
            }
          }
        }
        if (bestListing != null && bestOther != null) {
          state.unassign(pick);
          state.assign(pick.originalDeckCardId, bestListing, pick.quantity);
        }
      }
    }
    // Remove empty sellers from plan.
    state.dropEmptySellers();
  }

  /// Try to add any candidate seller whose current marginal_value
  /// (not already in plan) exceeds their shipping cost.
  static void _additionPass(
    _OptContext ctx,
    _State state,
    double shippingMultiplier, {
    int? maxSellers,
  }) {
    bool changed = true;
    while (changed) {
      if (maxSellers != null && state.planSellers.length >= maxSellers) break;
      changed = false;
      final cand = _findBestCandidateSeller(ctx, state, shippingMultiplier);
      if (cand == null) break;
      state.planSellers.add(cand);
      _assignCoverableTo(ctx, state, cand);
      changed = true;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Plan construction
  // ═══════════════════════════════════════════════════════════════

  static BuyPlan _buildPlan(
    _OptContext ctx,
    _State state,
    DateTime generatedAt,
  ) {
    final sellerPlans = <String, SellerPlan>{};
    for (final sellerId in state.planSellers) {
      final picks = state.sellerAssignments[sellerId] ?? const [];
      if (picks.isEmpty) continue;
      final sample = ctx.sellerSample[sellerId]!;
      // Recompute shipping for actual selection: insuredOnly if ANY picked
      // listing requires it.
      final anyInsured = picks.any((p) => p.listing.insuredOnly);
      final shippingListing = anyInsured
          ? picks.firstWhere((p) => p.listing.insuredOnly).listing
          : sample;
      // Bundle metrics — count drives tier-cap; value drives Cardmarket's
      // tracked-required rule (>€25 bundles can't ship as Letter even if
      // it would fit by weight). Insured stays per-listing (insuredOnly).
      final bundleCount =
          picks.fold<int>(0, (sum, p) => sum + p.quantity);
      final bundleValue = picks.fold<double>(
          0, (sum, p) => sum + p.listing.price * p.quantity);
      final shipping = shippingListing.sellerCountry == null
          ? 2.00
          : _quotePriceWithSalvage(
              shippingListing.sellerCountry!,
              ctx.buyerCountry,
              cardCount: bundleCount,
              insuredOnly: anyInsured,
              forceTracked:
                  ShippingRates.requiresTracking(bundleValue: bundleValue),
              bundleValue: bundleValue,
            );

      sellerPlans[sellerId] = SellerPlan(
        sellerId: sellerId,
        sellerName: sample.sellerName,
        sellerCountry: sample.sellerCountry,
        sellerRating: sample.sellerRating,
        items: [
          for (final p in picks)
            PlannedPurchase(
              listing: p.listing,
              originalDeckCardId: p.originalDeckCardId,
              quantity: p.quantity,
            ),
        ],
        shipping: shipping,
      );
    }
    // Also surface "unavailable due to insufficient qty after optimization"
    // — any remaining unmet needs that weren't in ctx.unavailable originally.
    final unavailable = [...ctx.unavailable];
    for (final e in state.remainingNeed.entries) {
      if (e.value > 0) {
        unavailable.add(
          UnavailableCard(
            cardId: e.key,
            cardName: ctx.lookup[e.key]?.name ?? '(unknown)',
            neededQty: e.value,
            reason: 'insufficient stock',
          ),
        );
      }
    }

    return BuyPlan(
      sellerPlans: sellerPlans,
      unavailable: unavailable,
      baselineCost: ctx.baselineCost,
      generatedAt: generatedAt,
      appliedFilters: ctx.filters,
      buyerCountry: ctx.buyerCountry,
      alternatives: null,
      alternativeCards: ctx.alternativeCards,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Phase 4 — Pareto helpers
  // ═══════════════════════════════════════════════════════════════

  /// Build the best plan that uses at most [maxSellers] distinct sellers
  /// AND fully covers all coverable cards. Two-phase:
  ///
  ///   1. Coverage-greedy: pick sellers in order of how many remaining
  ///      copies they can supply, stop when everything is assigned.
  ///   2. If coverage was reached and we still have headroom (planSellers
  ///      < maxSellers), run cost-driven addition + reassignment to swap
  ///      pricier picks for cheaper listings on additional sellers.
  ///
  /// Returns null if maxSellers isn't enough to fully cover the deck —
  /// caller skips the candidate (Pareto requires full coverage at every
  /// k value to be honest).
  static BuyPlan? _bestPlanWithMaxSellers(
    _OptContext ctx,
    int maxSellers,
    DateTime generatedAt,
  ) {
    final state = _State.initial(ctx);

    // Phase 1: coverage-greedy until covered or cap reached.
    // Tie-Breaker: bei gleicher Coverage gewinnt der GUENSTIGERE Seller
    // (gemessen am Sum-of-cheapest-listing-prices fuer covered Cards). Sonst
    // gewinnt einfach der erste Seller in Iteration und „Fewest packages"
    // wird nicht zwingend „cheapest at Fewest" — der User-relevante Sinn
    // des Pareto-Chips waere verfehlt.
    while (state.planSellers.length < maxSellers && state.hasUnassigned()) {
      String? best;
      int bestCoverage = 0;
      double bestCost = double.infinity;
      for (final sellerId in ctx.listingsBySeller.keys) {
        if (state.planSellers.contains(sellerId)) continue;
        final coverage = _simulateCoverableCopies(ctx, state, sellerId);
        if (coverage <= 0) continue;
        // Quick-Cost-Estimate: sum-of-cheapest-listing-prices fuer copies
        // dieser Seller deckt. Genauer waere full Reassignment, aber das
        // ist hier ein Tie-Breaker und braucht nicht perfekt zu sein.
        double cost = 0;
        for (final l in ctx.listingsBySeller[sellerId] ?? const []) {
          final remaining = state.remainingNeed[l.cardId] ?? 0;
          if (remaining <= 0) continue;
          final qty = remaining < l.quantity ? remaining : l.quantity;
          cost += l.price * qty;
        }
        if (coverage > bestCoverage ||
            (coverage == bestCoverage && cost < bestCost)) {
          bestCoverage = coverage;
          bestCost = cost;
          best = sellerId;
        }
      }
      if (best == null) break;
      state.planSellers.add(best);
      _assignCoverableTo(ctx, state, best);
    }

    // If we couldn't cover everything within the seller cap, this k value
    // isn't a valid Pareto candidate. Caller drops it.
    if (state.hasUnassigned()) return null;

    // Phase 2: cost-driven addition + reassignment up to the cap.
    // Only runs when we have headroom (covered with fewer than maxSellers).
    // Each addition adds a seller whose marginal value (savings vs current
    // cheapest in-plan price) exceeds shipping. _reassignmentPass then
    // migrates picks to the new seller. Loop until no further savings.
    if (state.planSellers.length < maxSellers) {
      const maxIters = 10;
      for (int i = 0; i < maxIters; i++) {
        final before = state.totalCost(ctx);
        if (state.planSellers.length >= maxSellers) break;
        final cand = _findBestCandidateSeller(ctx, state, 1.0);
        if (cand == null) break;
        state.planSellers.add(cand);
        _assignCoverableTo(ctx, state, cand);
        _reassignmentPass(ctx, state);
        final after = state.totalCost(ctx);
        if ((before - after).abs() < 0.001) {
          // Adding this seller didn't reduce cost — undo and stop.
          // (Reassignment after addition should normally save cost; if not,
          //  the addition was speculative and we don't want to keep it.)
          state.planSellers.remove(cand);
          break;
        }
      }
    }

    _consolidatePass(ctx, state);
    return _buildPlan(ctx, state, generatedAt);
  }

  /// How many copies of unassigned cards could [sellerId] supply, respecting
  /// listing qty and remaining-need? Pure simulation — does not modify state.
  static int _simulateCoverableCopies(
    _OptContext ctx,
    _State state,
    String sellerId,
  ) {
    int total = 0;
    final simListingRemaining = Map<String, int>.from(state.listingRemaining);
    for (final entry in state.remainingNeed.entries) {
      final need = entry.value;
      if (need == 0) continue;
      var left = need;
      for (final l in _sellerListingsForCard(ctx, sellerId, entry.key)) {
        if (left == 0) break;
        final rem = simListingRemaining[l.id] ?? l.availableQty;
        final take = rem.clamp(0, left).toInt();
        if (take == 0) continue;
        simListingRemaining[l.id] = rem - take;
        total += take;
        left -= take;
      }
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════════
  // Phase 4 — Pareto filtering
  // ═══════════════════════════════════════════════════════════════

  /// Keep only plans that aren't dominated by another with fewer sellers
  /// at equal-or-lower cost. Dedupe by seller count (keep cheapest per count).
  static List<BuyPlan> _filterPareto(List<BuyPlan> plans) {
    // Group by seller count; keep cheapest per count.
    final byCount = <int, BuyPlan>{};
    for (final p in plans) {
      final k = p.sellerCount;
      final existing = byCount[k];
      if (existing == null || p.grandTotal < existing.grandTotal) {
        byCount[k] = p;
      }
    }
    // Filter dominated: a plan with N sellers is dominated iff there exists
    // a plan with M<=N sellers that has lower-or-equal cost AND strictly
    // smaller M or strictly lower cost.
    final sorted = byCount.values.toList()
      ..sort((a, b) => a.sellerCount.compareTo(b.sellerCount));
    final pareto = <BuyPlan>[];
    double bestCostSoFar = double.infinity;
    for (final p in sorted) {
      if (p.grandTotal < bestCostSoFar - 0.001) {
        pareto.add(p);
        bestCostSoFar = p.grandTotal;
      }
    }
    return pareto;
  }

  /// Pick the Balanced default — median seller-count among plans within
  /// `max(€2, 3% × Cheapest)` of the Cheapest plan.
  ///
  /// Earlier heuristic was "first plan where adding the NEXT seller saves
  /// less than max(€3, 8%)" — fundamentally a fewer-sellers-bias which
  /// stuck close to Fewest. With the Cardmarket-honest €25-tracked rule
  /// the Pareto-spread widened (e.g. €4.66 between BALANCED and Cheapest
  /// in Schorn-test) so that bias started leaving real money on the table.
  ///
  /// The new rule: any plan within €2 / 3% of the Cheapest is "in the
  /// good zone"; among those, pick the one with median seller count.
  /// That keeps Balanced visually middle of the chip strip while still
  /// honouring the consolidate-when-cheap-enough preference.
  ///
  /// Anti-duplication: with 3+ Pareto plans the chip strip shows distinct
  /// Fewest / Balanced / Cheapest slots. If our pick lands on the first
  /// or last entry we step inward by one so the user always sees three
  /// distinct prices.
  static BuyPlan _pickBalanced(List<BuyPlan> paretoAscBySellers) {
    if (paretoAscBySellers.isEmpty) {
      throw StateError(
        'No Pareto plans — should not happen after _collect check',
      );
    }
    if (paretoAscBySellers.length == 1) return paretoAscBySellers.first;

    final cheapestTotal = paretoAscBySellers
        .map((p) => p.grandTotal)
        .reduce((a, b) => a < b ? a : b);
    final tolerance = _balancedTolerance(cheapestTotal);
    final maxAllowed = cheapestTotal + tolerance;

    // Qualifying plans, in original (fewest-first) order.
    final qualifying = paretoAscBySellers
        .where((p) => p.grandTotal <= maxAllowed)
        .toList();

    // Median seller-count of qualifying. Even count → lower (more
    // consolidated) middle, matching the prior fewer-sellers preference.
    final medianIx = (qualifying.length - 1) ~/ 2;
    BuyPlan picked = qualifying[medianIx];

    // Anti-duplication: chip strip prefers 3 distinct prices when ≥3 plans
    // exist. Nudge inward by one IF the inward neighbour is ALSO within
    // tolerance — otherwise the nudge would lift Balanced out of the
    // sensible-cost zone (see Schorn-test edge: only Cheapest qualified, a
    // blind nudge made Balanced €7+ more expensive than Cheapest, which
    // turned the tolerance heuristic on its head).
    //
    // When the nudge would escape tolerance, we accept a duplicate price
    // chip instead — the chip-strip layer can hide the duplicate slot if
    // it looks confusing. Mathematical honesty > distinct-chip cosmetic.
    if (paretoAscBySellers.length >= 3) {
      final qualifyingSet = qualifying.toSet();
      if (identical(picked, paretoAscBySellers.first) &&
          qualifyingSet.contains(paretoAscBySellers[1])) {
        return paretoAscBySellers[1];
      }
      if (identical(picked, paretoAscBySellers.last) &&
          qualifyingSet.contains(
              paretoAscBySellers[paretoAscBySellers.length - 2])) {
        return paretoAscBySellers[paretoAscBySellers.length - 2];
      }
    }
    return picked;
  }

  static double _balancedTolerance(double cheapestTotal) {
    final byPercent = cheapestTotal * 0.03;
    return byPercent > 2.0 ? byPercent : 2.0;
  }
}

// ═════════════════════════════════════════════════════════════════
// Internal data structures
// ═════════════════════════════════════════════════════════════════

/// Immutable per-compute context. Built once by [_collect] and shared
/// across every optimize-run (main + Pareto sweep).
class _OptContext {
  /// cardId (user's deck) → need qty. Only cards with ≥1 eligible listing.
  final Map<String, int> coverableCardNeeds;

  /// cardId → listings across all sellers, sorted by price ascending.
  final Map<String, List<MarketListing>> candidatesByCard;

  /// sellerId → their eligible listings (any card), price-ascending.
  final Map<String, List<MarketListing>> listingsBySeller;

  /// Sample listing per seller for name/country/rating fallback.
  final Map<String, MarketListing> sellerSample;

  /// Worst-case shipping cost per seller (used by greedy phase).
  final Map<String, double> shippingBySeller;

  /// Min/max shipping range per seller (log only — shows the spread
  /// between "1-card sub-tier" and "everything-from-this-seller bundle").
  final Map<String, ({double min, double max})> shippingRangeBySeller;
  final Map<String, RiftCard> lookup;
  final String buyerCountry;
  final List<UnavailableCard> unavailable;
  /// Cards with a soft mismatch (foil or art variant); user can opt-in to
  /// include them via the review sheet. NEVER auto-included.
  final List<AlternativeCard> alternativeCards;
  final double baselineCost;
  final SmartCartFilters filters;

  _OptContext({
    required this.coverableCardNeeds,
    required this.candidatesByCard,
    required this.listingsBySeller,
    required this.sellerSample,
    required this.shippingBySeller,
    required this.shippingRangeBySeller,
    required this.lookup,
    required this.buyerCountry,
    required this.unavailable,
    required this.alternativeCards,
    required this.baselineCost,
    required this.filters,
  });
}

/// Debug-trace line: one purchase flattened for the per-card assignment log.
class _TraceLine {
  final String cardName;
  final String cardId;
  final String seller;
  final double price;
  final int qty;
  final bool isFoil;
  _TraceLine({
    required this.cardName,
    required this.cardId,
    required this.seller,
    required this.price,
    required this.qty,
    required this.isFoil,
  });
}

/// A single assignment made during the optimizer run.
class _Pick {
  final String originalDeckCardId;
  final MarketListing listing;
  final int quantity;
  const _Pick({
    required this.originalDeckCardId,
    required this.listing,
    required this.quantity,
  });
}

/// Mutable per-run state: what's assigned, remaining qty, plan sellers.
class _State {
  final Map<String, int> remainingNeed;
  final Map<String, List<_Pick>> sellerAssignments;
  final Set<String> planSellers;
  final Map<String, int> listingRemaining;

  _State({
    required this.remainingNeed,
    required this.sellerAssignments,
    required this.planSellers,
    required this.listingRemaining,
  });

  factory _State.initial(_OptContext ctx) => _State(
    remainingNeed: Map.of(ctx.coverableCardNeeds),
    sellerAssignments: {},
    planSellers: <String>{},
    listingRemaining: {
      for (final list in ctx.candidatesByCard.values)
        for (final l in list) l.id: l.availableQty,
    },
  );

  bool hasUnassigned() => remainingNeed.values.any((v) => v > 0);

  void assign(String cardId, MarketListing listing, int qty) {
    if (qty <= 0) return;
    final picks = (sellerAssignments[listing.sellerId] ??= []);
    // Merge adjacent pick on same listing.
    for (int i = 0; i < picks.length; i++) {
      if (picks[i].listing.id == listing.id &&
          picks[i].originalDeckCardId == cardId) {
        picks[i] = _Pick(
          originalDeckCardId: cardId,
          listing: listing,
          quantity: picks[i].quantity + qty,
        );
        listingRemaining[listing.id] =
            (listingRemaining[listing.id] ?? 0) - qty;
        remainingNeed[cardId] = (remainingNeed[cardId] ?? 0) - qty;
        return;
      }
    }
    picks.add(
      _Pick(originalDeckCardId: cardId, listing: listing, quantity: qty),
    );
    listingRemaining[listing.id] = (listingRemaining[listing.id] ?? 0) - qty;
    remainingNeed[cardId] = (remainingNeed[cardId] ?? 0) - qty;
  }

  void unassign(_Pick pick) {
    final picks = sellerAssignments[pick.listing.sellerId];
    if (picks == null) return;
    picks.removeWhere(
      (p) =>
          p.listing.id == pick.listing.id &&
          p.originalDeckCardId == pick.originalDeckCardId &&
          p.quantity == pick.quantity,
    );
    if (picks.isEmpty) {
      sellerAssignments.remove(pick.listing.sellerId);
    }
    listingRemaining[pick.listing.id] =
        (listingRemaining[pick.listing.id] ?? 0) + pick.quantity;
    remainingNeed[pick.originalDeckCardId] =
        (remainingNeed[pick.originalDeckCardId] ?? 0) + pick.quantity;
  }

  void dropEmptySellers() {
    planSellers.removeWhere(
      (id) =>
          !sellerAssignments.containsKey(id) || sellerAssignments[id]!.isEmpty,
    );
  }

  /// Current total cost of the plan = card subtotals + seller shipping
  /// + Buyer-Service-Gebuehr (Phase 5, gestaffelt nach Cart-Subtotal +
  /// Multi-Seller-Aufschlag von 0.30€ pro zusaetzlichem Seller).
  ///
  /// Service-Gebuehr ist Teil der Cost-Function damit der Optimizer einen
  /// echten Multi-Seller-Tradeoff sieht: ein 4ter Seller fuegt nicht nur
  /// Versand-Kosten hinzu, sondern auch +0.30€ Service-Aufschlag — der
  /// Optimizer wird Seller-Anzahl deshalb tendenziell minimieren.
  double totalCost(_OptContext ctx) {
    double cardSubtotal = 0;
    double shippingTotal = 0;
    int activeSellerCount = 0;

    for (final sellerId in planSellers) {
      final picks = sellerAssignments[sellerId] ?? const [];
      if (picks.isEmpty) continue;
      activeSellerCount++;
      for (final p in picks) {
        cardSubtotal += p.listing.price * p.quantity;
      }
      final anyInsured = picks.any((p) => p.listing.insuredOnly);
      final sample = anyInsured
          ? picks.firstWhere((p) => p.listing.insuredOnly).listing
          : ctx.sellerSample[sellerId]!;
      final bundleCount =
          picks.fold<int>(0, (s, p) => s + p.quantity);
      final bundleValue = picks.fold<double>(
          0, (s, p) => s + p.listing.price * p.quantity);
      shippingTotal += sample.sellerCountry == null
          ? 2.00
          : MissingCardsOptimizer._quotePriceWithSalvage(
              sample.sellerCountry!,
              ctx.buyerCountry,
              cardCount: bundleCount,
              insuredOnly: anyInsured,
              forceTracked:
                  ShippingRates.requiresTracking(bundleValue: bundleValue),
              bundleValue: bundleValue,
            );
    }

    if (activeSellerCount == 0) return 0;

    final serviceFee = fees.serviceFeeEurFor(
      cardSubtotal,
      sellerCount: activeSellerCount,
    );
    return cardSubtotal + shippingTotal + serviceFee;
  }

  _StateSnapshot snapshot() => _StateSnapshot(
    remainingNeed: Map.of(remainingNeed),
    sellerAssignments: {
      for (final e in sellerAssignments.entries) e.key: List.of(e.value),
    },
    planSellers: Set.of(planSellers),
    listingRemaining: Map.of(listingRemaining),
  );

  void restore(_StateSnapshot s) {
    remainingNeed
      ..clear()
      ..addAll(s.remainingNeed);
    sellerAssignments
      ..clear()
      ..addAll({
        for (final e in s.sellerAssignments.entries) e.key: List.of(e.value),
      });
    planSellers
      ..clear()
      ..addAll(s.planSellers);
    listingRemaining
      ..clear()
      ..addAll(s.listingRemaining);
  }
}

class _StateSnapshot {
  final Map<String, int> remainingNeed;
  final Map<String, List<_Pick>> sellerAssignments;
  final Set<String> planSellers;
  final Map<String, int> listingRemaining;
  _StateSnapshot({
    required this.remainingNeed,
    required this.sellerAssignments,
    required this.planSellers,
    required this.listingRemaining,
  });
}
