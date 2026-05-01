import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/riftr_toast.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import '../services/notification_inbox_service.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/riftr_drag_handle.dart';
import '../theme/app_theme.dart';
import '../data/shipping_rates.dart';
import '../services/card_service.dart';
import '../services/market_service.dart';
import '../services/listing_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import '../services/demo_service.dart';
import '../services/seller_service.dart';
import '../services/firestore_collection_service.dart';
import '../models/market/card_price_data.dart';
import '../models/market/discover_filter.dart';
import '../models/market/listing_model.dart';
import '../models/market/price_point.dart';
import '../widgets/gold_header.dart';
import '../widgets/section_divider.dart';
import '../widgets/market/discover_filter_sheet.dart';
import '../widgets/market/portfolio_header.dart';
import '../widgets/market/portfolio_chart.dart';
import '../widgets/market/price_chart.dart';
import '../widgets/market/card_price_tile.dart';
import '../widgets/market/price_overview_card.dart';
import '../widgets/market/listing_tile.dart';
import '../widgets/market/time_range_selector.dart';
import '../widgets/riftr_search_bar.dart';
import '../widgets/market/gainers_losers_list.dart';
import '../widgets/market/sell_sheet.dart';
import '../widgets/market/seller_onboarding_sheet.dart';
import '../widgets/market/checkout_sheet.dart';
import '../widgets/market/order_tile.dart';
import '../models/market/order_model.dart';
import '../widgets/market/condition_badge.dart';
import '../services/order_service.dart';
import '../models/market/cost_basis_entry.dart';
import '../widgets/card_detail_sections.dart';
import '../widgets/card_image.dart';
import '../widgets/card_ribbon.dart';
import '../widgets/market/market_card_detail_view.dart';
import '../widgets/market/smart_cart_preferences_sheet.dart';
import '../widgets/market/smart_cart_review_sheet.dart';
import '../models/market/buy_plan.dart';
import '../services/market/missing_cards_optimizer.dart';
import 'dispute_detail_screen.dart';
import '../theme/app_components.dart';

/// Holdings metric display mode (Trade Republic-style)
enum HoldingsMetric {
  sincePurchaseRelative,  // Seit Kauf relativ (%)
  sincePurchaseAbsolute,  // Seit Kauf absolut (€)
  dayTrendRelative,       // Tagestrend relativ (%)
  dayTrendAbsolute,       // Tagestrend absolut (€)
}

class MarketScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  final void Function(String authorId, String authorName)? onNavigateToAuthor;
  const MarketScreen({super.key, this.onFullscreenChanged, this.onNavigateToAuthor});

  /// Sub-tab badge: unread order events (new order, status change, rating)
  static bool hasUnreadOrders = false;
  static bool hasUnreadSales = false;
  static bool hasUnreadPurchases = false;

  @override
  State<MarketScreen> createState() => MarketScreenState();
}

class MarketScreenState extends State<MarketScreen> {
  final _scrollController = ScrollController();

  // View state machine: 'portfolio' | 'discover' | 'cardDetail'
  String _view = 'portfolio';
  String _selectedRange = '1M';
  String _holdingsTab = 'holdings'; // 'holdings' | 'gainers' | 'losers'
  HoldingsMetric _holdingsMetric = HoldingsMetric.sincePurchaseRelative;
  int _holdingsDisplayCount = 50;
  CardPriceData? _selectedCard;
  bool _detailShowFoil = false; // Whether detail page focuses on foil variant

  // Search + Discover filters
  final _searchController = TextEditingController();
  List<CardPriceData> _searchResults = [];
  DiscoverFilter _discoverFilter = const DiscoverFilter();
  List<CardPriceData> _filteredResults = [];
  String? _activeQuickFilter;

  // Recently viewed cards (local, max 10). Per-user SharedPrefs key to
  // prevent cross-user leaks when multiple accounts use the same device.
  static String _recentlyViewedKey() {
    final uid = AuthService.instance.uid;
    return uid == null ? 'recently_viewed_cards' : 'recently_viewed_cards_$uid';
  }
  List<String> _recentlyViewedIds = [];

  // Missing cards filter (from Decks screen)
  Map<String, int>? _missingCardIds;

  String? _demoCountry; // Country selection stored locally in demo mode
  final List<MarketListing> _demoListings = []; // Local demo listings
  String _orderSubTab = 'purchases'; // 'purchases' | 'sales'

  bool get _isDemo => DemoService.instance.isActive;
  MarketService get _market => MarketService.instance;
  ListingService get _listings => ListingService.instance;

  void resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  /// Switch to Discover filtered to one seller's active listings.
  /// Called from ListingTile seller-name tap — leaves the card-detail view
  /// and shows all cards this seller has for sale. All other Discover filters
  /// (search, domain, rarity, etc.) remain active and stack on top.
  void _filterBySeller(String sellerId, String sellerName) {
    setState(() {
      _selectedCard = null;
      _view = 'discover';
      _searchController.clear();
      _activeQuickFilter = null;
      _missingCardIds = null;
      _discoverFilter = _discoverFilter.copyWith(
        sellerId: () => sellerId,
        sellerName: () => sellerName,
      );
    });
    // Leaving card-detail (fullscreen) → reveal nav bar.
    widget.onFullscreenChanged?.call(false);
    _refreshFilteredResults();
    resetScroll();
  }

  /// Smart Cart flow — 3-step wizard to optimize the purchase of all
  /// missing cards across sellers with shipping-aware consolidation.
  ///
  /// 1. Preferences sheet (condition/foil/language/country/art preferences)
  /// 2. Loading (compute optimized BuyPlan — typically <1s)
  /// 3. Review sheet (Pareto strip + seller groups + "Add all to cart")
  ///
  /// On Add-to-Cart: adds each listing to CartService. If any listing is
  /// no longer available (sold between plan and add), a toast is shown and
  /// the optimizer re-runs automatically with the updated listing pool.
  Future<void> startSmartCartFlow(
    Map<String, int> missingCards, {
    SmartCartFilters? prefilledFilters,
  }) async {
    final totalMissing = missingCards.values.fold(0, (s, q) => s + q);

    // Step 1 — Preferences. `prefilledFilters` is set by the
    // "Lower condition" round-trip from the review sheet so the user lands on
    // a sheet that already has all their previous choices + the new lowered
    // condition pre-selected.
    final filters = await showRiftrSheet<SmartCartFilters>(
      context: context,
      builder: (_) => SmartCartPreferencesSheet(
        missingCardCount: totalMissing,
        initialMinCondition: prefilledFilters?.minCondition,
        initialFoilPreference: prefilledFilters?.foilPreference,
        initialLanguage: prefilledFilters?.language,
        initialSellerCountry: prefilledFilters?.sellerCountry,
        initialAcceptCheaperArt: prefilledFilters?.acceptCheaperArt,
      ),
    );
    if (filters == null || !mounted) return;

    // Step 2 — Compute. Brief loading indicator while the algorithm runs.
    BuyPlan? plan;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Defer compute so the dialog actually paints before the ms-range work.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          plan = _computeSmartCartPlan(missingCards, filters);
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.amber500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Finding best deals…',
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (plan == null || !mounted) return;

    // Step 3 — Review
    await _showSmartCartReview(plan!, missingCards, totalMissing);
  }

  BuyPlan _computeSmartCartPlan(
    Map<String, int> missingCards,
    SmartCartFilters filters,
  ) {
    final buyerCountry = ProfileService.instance.ownProfile?.country ?? 'DE';
    return MissingCardsOptimizer.computeBestPlan(
      missingCards: missingCards,
      buyerCountry: buyerCountry,
      buyerUid: AuthService.instance.uid,
      filters: filters,
    );
  }

  /// Sentinel BuyPlan — used as a sheet.pop() value to signal "user tapped
  /// the art-toggle hint, please recompute". Compared via `identical()`.
  static final BuyPlan _artToggleSentinel = BuyPlan(
    sellerPlans: const {},
    unavailable: const [],
    baselineCost: 0,
    generatedAt: DateTime(0),
    appliedFilters: const SmartCartFilters(),
    buyerCountry: '',
  );

  /// Sentinel for the "Lower condition" CTA in the review sheet's
  /// unavailable banner. Carries the next-looser CardCondition embedded in
  /// `appliedFilters.minCondition` — parent reads it to re-open preferences
  /// with the new value pre-selected. Discriminator is `generatedAt`
  /// (DateTime(1)) so we don't clash with the art-toggle sentinel above.
  static BuyPlan _lowerConditionSentinel(CardCondition next) => BuyPlan(
        sellerPlans: const {},
        unavailable: const [],
        baselineCost: 0,
        generatedAt: DateTime(1),
        appliedFilters: SmartCartFilters(minCondition: next),
        buyerCountry: '',
      );

  static bool _isLowerConditionSentinel(BuyPlan p) =>
      p.generatedAt == DateTime(1) && p.sellerPlans.isEmpty;

  /// Show the review sheet. Handles the add-to-cart flow including
  /// expiry-prompt and stale-listing auto-retry.
  Future<void> _showSmartCartReview(
    BuyPlan plan,
    Map<String, int> missingCards,
    int totalMissing,
  ) async {
    // PageRouteBuilder + DragToDismiss pattern (mirrors DeckShoppingRoute /
    // CardPreviewRoute) so drag-from-anywhere dismissal works the same way
    // across the entire Smart Cart flow.
    final accepted = await Navigator.of(context).push<BuyPlan>(
      PageRouteBuilder<BuyPlan>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (sheetCtx, animation, secondaryAnimation) =>
            SmartCartReviewSheet(
          initialPlan: plan,
          totalMissingCopies: totalMissing,
          // Banner tap: pop current route with sentinel, parent re-runs below.
          onRequestArtToggle: () => Navigator.of(sheetCtx).pop(_artToggleSentinel),
          // "Lower condition" CTA in unavailable banner: pop with a sentinel
          // carrying the new condition; parent re-opens preferences sheet with
          // it pre-selected (and existing filters preserved).
          onRequestLowerCondition: (next) => Navigator.of(sheetCtx)
              .pop(_lowerConditionSentinel(next)),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
    );
    if (accepted == null || !mounted) return;

    // Art-toggle sentinel: user tapped the hint — recompute with flipped
    // acceptCheaperArt flag and re-show the review sheet.
    if (identical(accepted, _artToggleSentinel)) {
      final flippedFilters = plan.appliedFilters.copyWith(
        acceptCheaperArt: !plan.appliedFilters.acceptCheaperArt,
      );
      final fresh = _computeSmartCartPlan(missingCards, flippedFilters);
      if (!mounted) return;
      await _showSmartCartReview(fresh, missingCards, totalMissing);
      return;
    }

    // Lower-condition sentinel: user tapped "Lower condition to {next}" in
    // the unavailable banner. Restart the flow at the preferences sheet with
    // their previous filters preserved + the new condition pre-selected.
    if (_isLowerConditionSentinel(accepted)) {
      final newCondition = accepted.appliedFilters.minCondition;
      final preserved = plan.appliedFilters.copyWith(minCondition: newCondition);
      if (!mounted) return;
      await startSmartCartFlow(missingCards, prefilledFilters: preserved);
      return;
    }

    // Plan expiry: prompt user to refresh if >15 min old.
    if (accepted.isExpired) {
      final refresh = await _confirmRefreshStalePlan();
      if (refresh == null || !mounted) return;
      if (refresh) {
        final fresh = _computeSmartCartPlan(missingCards, accepted.appliedFilters);
        if (!mounted) return;
        await _showSmartCartReview(fresh, missingCards, totalMissing);
        return;
      }
    }

    // Attempt add-to-cart. On stale failures, recompute + re-show review.
    final result = await _addPlanToCart(accepted);
    if (!mounted) return;
    if (result.staleFailed > 0) {
      RiftrToast.info(
        context,
        '${result.staleFailed} of ${result.totalAttempted} cards no longer available — re-checking',
      );
      final fresh = _computeSmartCartPlan(missingCards, accepted.appliedFilters);
      if (!mounted) return;
      await _showSmartCartReview(fresh, missingCards, totalMissing);
      return;
    }
    if (result.successCount > 0) {
      // Toast says "cards" not "listings": the user thinks in terms of how
      // many cards from their missing-list got covered, not how many seller
      // listings (one listing can cover multiple copies of the same card).
      final n = result.successCardCopies;
      RiftrToast.cart(
        context,
        'Added $n card${n == 1 ? '' : 's'} to cart',
      );
      // Clear the missing-cards filter since user moved into cart flow.
      setState(() {
        _missingCardIds = null;
        _searchResults = [];
      });
    }
  }

  Future<bool?> _confirmRefreshStalePlan() async {
    return showRiftrSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Listings may have changed',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This plan is more than 15 minutes old. Refresh to see current availability.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(flex: 1, child: RiftrButton(
                  label: 'Cancel',
                  style: RiftrButtonStyle.secondary,
                  onPressed: () => Navigator.of(ctx).pop(null),
                )),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: RiftrButton(
                  label: 'Refresh',
                  onPressed: () => Navigator.of(ctx).pop(true),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<({int successCount, int successCardCopies, int staleFailed, int totalAttempted})>
      _addPlanToCart(BuyPlan plan) async {
    // Collect every (listing, qty) op to fire — both the optimizer's plan
    // picks and the user's opted-in alternative cards.
    //
    // Each addItem awaits two CF round-trips (reserveForCart + the
    // ListingService.refreshListing follow-up that prevents the Smart
    // Cart race condition). At ~350ms per item, a 22-item plan took 7-8s
    // sequentially. Fire them in parallel via Future.wait → total time
    // collapses to max(individual) ≈ 500ms.
    //
    // Safety: dedupe by listingId so two concurrent addItems for the same
    // listing can't race on the local cart's `_items.indexWhere`/`newQty`
    // logic. In practice plan picks have unique listingIds, but an
    // alternative card might point to a listing that's also in
    // sellerPlans — the merge keeps total qty correct in either order.
    final byListingId = <String, ({MarketListing listing, int qty})>{};
    for (final sellerPlan in plan.sellerPlans.values) {
      for (final purchase in sellerPlan.items) {
        final id = purchase.listing.id;
        final existing = byListingId[id];
        byListingId[id] = (
          listing: purchase.listing,
          qty: (existing?.qty ?? 0) + purchase.quantity,
        );
      }
    }
    for (final alt in plan.alternativeCards) {
      if (!plan.includedAlternativeGroupKeys.contains(alt.groupKey)) continue;
      final id = alt.cheapest.id;
      final existing = byListingId[id];
      byListingId[id] = (
        listing: alt.cheapest,
        qty: (existing?.qty ?? 0) + alt.neededQty,
      );
    }

    final ops = byListingId.values.toList();
    final results = await Future.wait(
      ops.map((op) => CartService.instance.addItem(
            CartItem.fromListing(op.listing, quantity: op.qty),
          )),
    );

    int success = 0;
    int successCopies = 0;
    int stale = 0;
    for (int i = 0; i < ops.length; i++) {
      if (results[i]) {
        success++;
        successCopies += ops[i].qty;
      } else {
        stale++;
      }
    }
    return (
      successCount: success,
      successCardCopies: successCopies,
      staleFailed: stale,
      totalAttempted: ops.length,
    );
  }

  /// Show missing cards from a deck in the Discover view
  void showMissingCards(Map<String, int> missing) {
    setState(() {
      _missingCardIds = missing;
      _view = 'discover';
      _searchController.clear();
      // Build filtered results from missing card IDs
      _searchResults = missing.keys
          .map((id) => _market.getPrice(id))
          .whereType<CardPriceData>()
          .toList()
        ..sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    });
    resetScroll();
  }

  @override
  void initState() {
    super.initState();
    _market.addListener(_refresh);
    _listings.addListener(_refresh);
    OrderService.instance.addListener(_refresh);
    NotificationInboxService.instance.addListener(_refresh);
    CartService.instance.addListener(_refresh);
    _loadRecentlyViewed();
  }

  Future<void> _loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_recentlyViewedKey()) ?? [];
    if (mounted) setState(() => _recentlyViewedIds = ids);
  }

  Future<void> _addRecentlyViewed(String cardId) async {
    _recentlyViewedIds.remove(cardId); // deduplicate
    _recentlyViewedIds.insert(0, cardId); // newest first
    if (_recentlyViewedIds.length > 10) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, 10);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentlyViewedKey(), _recentlyViewedIds);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _market.removeListener(_refresh);
    _listings.removeListener(_refresh);
    OrderService.instance.removeListener(_refresh);
    NotificationInboxService.instance.removeListener(_refresh);
    CartService.instance.removeListener(_refresh);
    super.dispose();
  }

  /// Navigate to a card by its ID (called from other tabs, e.g. Social)
  void navigateToCardById(String cardId) {
    // Try priced data first; fall back to zero-price CardPriceData for
    // unpriced cards (e.g. UNL pre-release). Ensures navigation works
    // from Cards/Collection tap even when no market price exists yet.
    final card = _market.getPrice(cardId) ?? _market.getFallbackPrice(cardId);
    if (card == null) return;
    _navigateToCard(card);
  }

  void _navigateToCard(CardPriceData card, {bool isFoil = false}) {
    _addRecentlyViewed(card.cardId);
    // History lazy-load + loading-state lives inside MarketCardDetailView
    // (it manages its own _loadingHistory + service listeners). Parent only
    // owns the navigation-level state (which card, foil-or-not initially).
    setState(() {
      _viewBeforeDetail = _view;
      _selectedCard = card;
      _selectedRange = '1M';
      _view = 'cardDetail';
      _detailShowFoil = isFoil;
    });
    widget.onFullscreenChanged?.call(true);
    resetScroll();
  }

  String _viewBeforeDetail = 'portfolio';

  void _goBack() {
    // 3-branch dismiss target by current _view:
    //   cardDetail              → restore _viewBeforeDetail (origin sub-tab)
    //   discover/listings/orders → portfolio (Market hero / main view)
    //   portfolio               → no-op (already at top of nav stack)
    //
    // Layer 1 (per-view ValueKey on each DragToDismiss) handles the
    // state-leak that previously caused a black screen on rapid view
    // switches; this 3-branch logic restores the legitimate "drag-back"
    // flow each sub-tab needs.
    if (_view == 'cardDetail') {
      setState(() {
        _selectedCard = null;
        _view = _viewBeforeDetail;
      });
      // Fullscreen parity: discover/listings/orders all run fullscreen,
      // only portfolio shows the navbar.
      final returnsFullscreen = _viewBeforeDetail != 'portfolio';
      widget.onFullscreenChanged?.call(returnsFullscreen);
      resetScroll();
      return;
    }
    if (_view == 'portfolio') return;
    // Sub-tab → Portfolio (Market hero with Market Value / Trend-Chart / Holdings).
    setState(() {
      _selectedCard = null;
      _view = 'portfolio';
    });
    widget.onFullscreenChanged?.call(false); // portfolio shows the navbar
    resetScroll();
  }

  Widget _cardPlaceholder(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: AppRadius.baseBR,
    ),
    child: Icon(Icons.style, size: 40, color: AppColors.textMuted),
  );

  /// Wraps a scrollable child with DragToDismiss for pull-to-dismiss.
  ///
  /// `ValueKey('dismiss-$_view')` forces Flutter to instantiate a fresh
  /// DragToDismiss-State whenever `_view` changes. Without this key, the
  /// internal `_offset` (which sits at `screenHeight + 50` after a successful
  /// dismiss animation) leaks across view transitions — Discover would
  /// render with its content translated off-screen, looking like a black
  /// scaffold. The key ties the State's lifetime to the active view.
  Widget _wrapWithDismiss(Widget child) {
    return DragToDismiss(
      key: ValueKey('dismiss-$_view'),
      onDismissed: _goBack,
      backgroundColor: AppColors.background,
      child: Column(children: [
        // Drag handle — md top + sm bottom matches CardPreviewOverlay
        // (Cards-Tab card detail) so handle-to-content distance is uniform
        // across the app.
        const Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
        ),
        Expanded(child: child),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_market.initialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.amber400, strokeWidth: 2),
            SizedBox(height: AppSpacing.md),
            Text('Loading market data...', style: AppTextStyles.caption),
          ],
        ),
      );
    }

    final content = switch (_view) {
      'discover' => _buildDiscover(),
      'cardDetail' => _buildCardDetail(),
      'listings' => _buildMyListings(),
      'orders' => _buildOrders(),
      _ => _buildPortfolio(),
    };

    // Wallet-FAB wurde in Phase 2 (2026-04-28) entfernt — Customer-Balance
    // ist nicht mehr aktiv (keine Top-Ups, keine Wallet-Buys). Verkaeufer-
    // Earnings laufen ueber Stripe Connect; eine eigene Earnings-View
    // entscheidet Phase 6/7 wenn das Konzept klar ist.
    //
    // Cart FAB nur in den Discover/Portfolio-Views (Listings + Orders + cardDetail
    // ausgeblendet — dort stoert er und ist nicht kontextrelevant: in „MY LISTINGS"
    // verkauft der User, in „ORDERS" prueft er bestehende Kaeufe, im Card-Detail
    // gibt's eigene Buy/Sell-Buttons).
    final showCartFab = !_isDemo &&
        _view != 'cardDetail' &&
        _view != 'listings' &&
        _view != 'orders' &&
        CartService.instance.totalItems > 0;

    debugPrint(
      '[MARKET-FAB] view=$_view demo=$_isDemo cartItems=${CartService.instance.totalItems} '
      'showCart=$showCartFab',
    );

    if (!showCartFab) return content;

    final viewPadding = MediaQuery.of(context).viewPadding;
    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        // FABs synced with NavBar slide — same Transform.translate
        ValueListenableBuilder<double>(
          valueListenable: AppShell.navSlideNotifier,
          builder: (context, navT, child) {
            return Transform.translate(
              offset: Offset(0, (1 - navT) * 80),
              child: child,
            );
          },
          child: Stack(children: [
        // Cart FAB (all Market views when cart has items)
        if (showCartFab)
          Positioned(
            right: AppSpacing.lg,
            bottom: 68 + viewPadding.bottom,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => CartScreen(
                    onViewAuthor: widget.onNavigateToAuthor != null
                        ? (id, name) {
                            Navigator.of(context).pop(); // Close cart
                            widget.onNavigateToAuthor!(id, name);
                          }
                        : null,
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: const Duration(milliseconds: 150),
                ),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                _CartFab(pulse: true),
                Positioned(right: -4, top: -4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Text('${CartService.instance.totalItems}',
                    style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textPrimary, letterSpacing: 0)),
                )),
              ]),
            ),
          ),
          ]), // FAB Stack (child of VLB)
        ), // ValueListenableBuilder
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ─── PORTFOLIO VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildPortfolio() {
    final portfolio = _market.portfolio;
    if (portfolio == null) return const SizedBox.shrink();

    // Get collection + cost basis for holdings
    final collectionService = FirestoreCollectionService.instance;
    final normalCards = _isDemo
        ? DemoService.instance.collection
        : collectionService.cards;
    final costBasisMap = _isDemo
        ? <String, CostBasisEntry>{}
        : collectionService.costBasis;

    final foilCards = _isDemo
        ? <String, int>{}
        : collectionService.foils;
    final allCardIds = {...normalCards.keys, ...foilCards.keys};

    // Build holdings list — separate entries for normal and foil
    final holdings = <_HoldingEntry>[];
    for (final cardId in allCardIds) {
      final price = _market.getPrice(cardId) ?? _market.getFallbackPrice(cardId);
      if (price == null) continue;

      final normalQty = normalCards[cardId] ?? 0;
      final foilQty = foilCards[cardId] ?? 0;
      final cb = costBasisMap[cardId];

      // Split cost basis by lot source so each entry gets its own cost
      CostBasisEntry? normalCb;
      CostBasisEntry? foilCb;
      if (cb != null && normalQty > 0 && foilQty > 0) {
        final normalLots = cb.lots.where((l) => !l.source.contains('foil')).toList();
        final foilLots = cb.lots.where((l) => l.source.contains('foil')).toList();
        if (normalLots.isNotEmpty) {
          final cost = normalLots.fold(0.0, (s, l) => s + l.price * l.qty);
          final qty = normalLots.fold(0, (s, l) => s + l.qty);
          normalCb = CostBasisEntry(totalCost: cost, totalQty: qty, lots: normalLots);
        }
        if (foilLots.isNotEmpty) {
          final cost = foilLots.fold(0.0, (s, l) => s + l.price * l.qty);
          final qty = foilLots.fold(0, (s, l) => s + l.qty);
          foilCb = CostBasisEntry(totalCost: cost, totalQty: qty, lots: foilLots);
        }
      } else {
        // Only one type present — use the full cost basis
        normalCb = normalQty > 0 ? cb : null;
        foilCb = foilQty > 0 ? cb : null;
      }

      if (normalQty > 0) {
        holdings.add(_HoldingEntry(
          data: price,
          quantity: normalQty,
          costBasis: normalCb,
        ));
      }
      if (foilQty > 0) {
        holdings.add(_HoldingEntry(
          data: price,
          quantity: foilQty,
          costBasis: foilCb,
          isFoil: true,
        ));
      }
    }

    // Metric value for the right-column number display AND for
    // Gainers/Losers sort. Holdings-tab sort is NOT metric-driven —
    // it's always by total market value (see below). Like Trade Republic:
    // portfolio is always sorted by position size; the dropdown only
    // switches which return number is shown next to each card.
    double metricVal(_HoldingEntry h) => switch (_holdingsMetric) {
      HoldingsMetric.sincePurchaseRelative => h.cbChangePct,
      HoldingsMetric.sincePurchaseAbsolute => h.cbChangeAbs,
      HoldingsMetric.dayTrendRelative => h.dayChangePct,
      HoldingsMetric.dayTrendAbsolute => h.dayChangeAbs,
    };

    // Alphabetical tiebreaker by card name — deterministic order when
    // primary sort values are equal.
    int byName(_HoldingEntry a, _HoldingEntry b) =>
        a.data.cardName.toLowerCase().compareTo(b.data.cardName.toLowerCase());

    // Holdings-tab sort: total market value desc (unitPrice × quantity),
    // name asc as tiebreaker. Never changes based on dropdown.
    int byTotalValueDesc(_HoldingEntry a, _HoldingEntry b) {
      final cmp = (b.unitPrice * b.quantity).compareTo(a.unitPrice * a.quantity);
      return cmp != 0 ? cmp : byName(a, b);
    }

    // Gainers/Losers: sort by selected metric, ties → alphabetical.
    int byMetricDesc(_HoldingEntry a, _HoldingEntry b) {
      final cmp = metricVal(b).compareTo(metricVal(a));
      return cmp != 0 ? cmp : byName(a, b);
    }

    int byMetricAsc(_HoldingEntry a, _HoldingEntry b) {
      final cmp = metricVal(a).compareTo(metricVal(b));
      return cmp != 0 ? cmp : byName(a, b);
    }

    // Meaningful-mover threshold: a holding qualifies for Gainers/Losers
    // only if its movement clears at least one of the two axes —
    // €0.10 absolute (per holding total) OR 5% relative. Both axes are
    // checked independently regardless of which metric the user has
    // active in the dropdown, so the filter behaves consistently when
    // the user toggles between Day-Trend and Since-Buy views.
    //
    // Without this, a 1-cent drop on a holding (e.g. Doran's Shield
    // SFD #33) would appear as Loser #2 — the global movers list in
    // MarketService._computeMovers had this threshold but the personal
    // Holdings filter was a separate code path that never got it.
    bool clearsThreshold(_HoldingEntry h) {
      final absMovement = switch (_holdingsMetric) {
        HoldingsMetric.sincePurchaseAbsolute ||
        HoldingsMetric.sincePurchaseRelative => h.cbChangeAbs.abs(),
        HoldingsMetric.dayTrendAbsolute ||
        HoldingsMetric.dayTrendRelative => h.dayChangeAbs.abs(),
      };
      final pctMovement = switch (_holdingsMetric) {
        HoldingsMetric.sincePurchaseAbsolute ||
        HoldingsMetric.sincePurchaseRelative => h.cbChangePct.abs(),
        HoldingsMetric.dayTrendAbsolute ||
        HoldingsMetric.dayTrendRelative => h.dayChangePct.abs(),
      };
      return absMovement >= 0.10 || pctMovement >= 5.0;
    }

    // Filter + sort per sub-tab.
    final displayList = switch (_holdingsTab) {
      'gainers' => holdings
          .where((h) => metricVal(h) > 0 && clearsThreshold(h))
          .toList()
        ..sort(byMetricDesc),
      'losers' => holdings
          .where((h) => metricVal(h) < 0 && clearsThreshold(h))
          .toList()
        ..sort(byMetricAsc),
      _ => [...holdings]..sort(byTotalValueDesc),
    };

    // Chart line = performance if available, value as legacy fallback
    final chartData = _filterByRange(
      portfolio.performanceHistory.isNotEmpty
          ? portfolio.performanceHistory
          : portfolio.valueHistory,
      _selectedRange,
    );

    // Performance = gains/losses from price movements only (NOT from adding cards)
    // Uses performanceHistory snapshots for time range calculation:
    //   rangePerf = perf(end) - perf(start) → correctly ignores buy/sell jumps
    final perfData = _filterByRange(portfolio.performanceHistory, _selectedRange);
    double perfAbs = portfolio.performance;
    double perfPct = portfolio.performancePercent;
    bool perfPositive = portfolio.performancePositive;
    if (perfData.length >= 2) {
      final startPerf = perfData.first.price;
      final endPerf = perfData.last.price;
      perfAbs = endPerf - startPerf;
      perfPct = portfolio.totalCostBasis > 0
          ? (perfAbs / portfolio.totalCostBasis * 100)
          : 0;
      perfPositive = perfAbs >= 0;
    }

    return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              const GoldOrnamentHeader(title: 'MARKET VALUE'),
          const SizedBox(height: AppSpacing.sm),

          // Portfolio header: value + performance (color based on PERFORMANCE)
          PortfolioHeader(
            snapshot: portfolio,
            changeAbs: perfAbs,
            changePercent: perfPct,
            isPositive: perfPositive,
          ),
          const SizedBox(height: AppSpacing.md),

          // Time range selector
          TimeRangeSelector(
            selected: _selectedRange,
            onChanged: (r) => setState(() => _selectedRange = r),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Portfolio chart (line = totalValue, color = performance)
          PortfolioChart(
            data: chartData,
            isPositive: perfPositive,
          ),
          const SizedBox(height: AppSpacing.base),

          // View toggle: Portfolio / Discover
          _buildViewToggle(),
          const SizedBox(height: AppSpacing.md),

          // Holdings section header — counts inlined in the trailing slot
          // (was a standalone "18 Cards · 42 Copies" row inside
          // PortfolioHeader; moved here to keep counts adjacent to the
          // list they describe and free up vertical space in the hero).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionDivider(
              icon: Icons.wallet,
              label: 'YOUR HOLDINGS',
              trailing: Text(
                '${portfolio.cardCount} cards · ${portfolio.totalCopies} copies',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.amber400,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Sub-tabs (Holdings/Gainers/Losers) + metric dropdown in one row.
          // Pills left, dropdown right — saves a full vertical line vs. stacking.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _holdingsTabPill('Holdings', 'holdings'),
                    const SizedBox(width: 6),
                    _holdingsTabPill('Gainers', 'gainers'),
                    const SizedBox(width: 6),
                    _holdingsTabPill('Losers', 'losers'),
                  ],
                ),
                _buildMetricDropdown(),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Holdings list
          if (displayList.isEmpty)
            RiftrEmptyState(
              icon: _holdingsTab == 'holdings' ? Icons.wallet : (_holdingsTab == 'gainers' ? Icons.trending_up : Icons.trending_down),
              title: _holdingsTab == 'holdings' ? 'No Holdings Yet' : 'No ${_holdingsTab[0].toUpperCase()}${_holdingsTab.substring(1)} Today',
              subtitle: _holdingsTab == 'holdings'
                  ? 'Add cards to your collection to track their value\nor browse the market'
                  : 'Price movements will show up here',
              buttonLabel: _holdingsTab == 'holdings' ? 'Browse Market' : null,
              buttonIcon: _holdingsTab == 'holdings' ? Icons.search : null,
              onButtonPressed: _holdingsTab == 'holdings' ? () {
                setState(() { _view = 'discover'; });
                widget.onFullscreenChanged?.call(true);
              } : null,
            )
          else
            ...displayList.take(_holdingsDisplayCount).map((h) {
              final changeText = _formatMetricValue(h);
              final isPositive = metricVal(h) >= 0;
              // TR-style split:
              //   LEFT: total position value (unitPrice × quantity)
              //   RIGHT: per-card unit price + change
              final totalValueLabel =
                  '€${(h.unitPrice * h.quantity).toStringAsFixed(2)}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                child: CardPriceTile(
                  data: h.data,
                  quantity: h.quantity,
                  onTap: () => _navigateToCard(h.data, isFoil: h.isFoil),
                  showFoilStar: h.isFoil,
                  // Foil-aware per-card price on the right.
                  priceOverride: h.unitPrice,
                  totalValueLabel: totalValueLabel,
                  changeText: changeText,
                  changePositive: isPositive,
                ),
              );
            }),

          // "Show more" button
          if (displayList.length > _holdingsDisplayCount)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _holdingsDisplayCount += 50),
                  child: SizedBox(
                    height: 44, // Apple HIG touch-target minimum
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: AppRadius.pillBR,
                      ),
                      child: Text(
                        'Show more (${displayList.length - _holdingsDisplayCount} remaining)',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.amber400),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── CART VIEW ───
  // ═══════════════════════════════════════════

  // ═══════════════════════════════════════════



  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _toggleButton('Listings', _view == 'listings', () {
            setState(() { _view = 'listings'; });
            widget.onFullscreenChanged?.call(true);
            resetScroll();
          }),
          const SizedBox(width: AppSpacing.sm),
          _toggleButton('Orders', _view == 'orders', () {
            setState(() { _view = 'orders'; });
            widget.onFullscreenChanged?.call(true);
            resetScroll();
          }, showDot: NotificationInboxService.instance.unseenOrderCount > 0),
          const SizedBox(width: AppSpacing.sm),
          _toggleButton('Discover', _view == 'discover', () {
            setState(() { _view = 'discover'; });
            widget.onFullscreenChanged?.call(true);
            resetScroll();
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap, {bool showDot = false}) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RiftrPill(label: label, isActive: active, onTap: onTap),
          if (showDot && !active)
            Positioned(
              top: -2, right: 4,
              child: Container(width: 8, height: 8, decoration: BoxDecoration(
                color: AppColors.amber400, shape: BoxShape.circle,
              )),
            ),
        ],
      ),
    );
  }

  // _buildHoldingsTabs() removed — pills are now inlined directly in the
  // Holdings section header so they share a Row with the metric dropdown.

  Widget _holdingsTabPill(String label, String value) {
    return RiftrPill(
      label: label,
      isActive: _holdingsTab == value,
      onTap: () {
        HapticFeedback.lightImpact();
        if (_holdingsTab == value) return;
        setState(() { _holdingsTab = value; _holdingsDisplayCount = 50; });
        // Scroll to top so content doesn't jump when list is shorter
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      },
    );
  }

  // ─── Holdings metric helpers ───

  String _metricLabel(HoldingsMetric m) => switch (m) {
    HoldingsMetric.sincePurchaseRelative => 'Since Buy',
    HoldingsMetric.sincePurchaseAbsolute => 'Since Buy €',
    HoldingsMetric.dayTrendRelative => 'Day Trend',
    HoldingsMetric.dayTrendAbsolute => 'Day Trend €',
  };

  String _metricSheetLabel(HoldingsMetric m) => switch (m) {
    HoldingsMetric.sincePurchaseRelative => 'Since Buy relative',
    HoldingsMetric.sincePurchaseAbsolute => 'Since Buy absolute',
    HoldingsMetric.dayTrendRelative => 'Day Trend relative',
    HoldingsMetric.dayTrendAbsolute => 'Day Trend absolute',
  };

  static String _sign(double val) => val >= 0 ? '+' : '';

  String _formatMetricValue(_HoldingEntry h) {
    return switch (_holdingsMetric) {
      HoldingsMetric.sincePurchaseRelative =>
        '${_sign(h.cbChangePct)}${h.cbChangePct.toStringAsFixed(1)}%',
      HoldingsMetric.sincePurchaseAbsolute =>
        '${_sign(h.cbChangeAbs)}€${h.cbChangeAbs.abs().toStringAsFixed(2)}',
      HoldingsMetric.dayTrendRelative =>
        '${_sign(h.dayChangePct)}${h.dayChangePct.toStringAsFixed(1)}%',
      HoldingsMetric.dayTrendAbsolute =>
        '${_sign(h.dayChangeAbs)}€${h.dayChangeAbs.abs().toStringAsFixed(2)}',
    };
  }

  Widget _buildMetricDropdown() {
    return GestureDetector(
      onTap: _showMetricSheet,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44, // Apple HIG touch-target minimum
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _metricLabel(_holdingsMetric),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showMetricSheet() {
    showRiftrSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Metric',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              ...HoldingsMetric.values.map((m) => _metricSheetRow(m)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricSheetRow(HoldingsMetric m) {
    final isSelected = _holdingsMetric == m;
    return GestureDetector(
      onTap: () {
        setState(() => _holdingsMetric = m);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _metricSheetLabel(m),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppColors.textPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── MY LISTINGS VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildMyListings() {
    final myListings = _isDemo ? _demoListings : _listings.myListings;

    // Card-Preview pattern (per RIFTR_DESIGN_SYSTEM 6.6.1): Stack with
    //   DragToDismiss wraps Column[handle, Expanded(scroll)]  — DRAG LAYER
    //   Positioned(bottom: 22) action buttons                  — STICKY LAYER
    // Drag returns to portfolio (Market hero) via _goBack.
    return Stack(
      fit: StackFit.expand,
      children: [
        DragToDismiss(
          key: const ValueKey('dismiss-listings'),
          onDismissed: _goBack,
          backgroundColor: AppColors.background,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // 120dp bottom-padding clears the pinned bulk-action pills.
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GoldOrnamentHeader(title: 'MY LISTINGS'),
          const SizedBox(height: AppSpacing.sm),
          _buildViewToggle(),
          const SizedBox(height: AppSpacing.base),

          // Strike / Suspension banner
          if (!_isDemo) ...[
            Builder(builder: (_) {
              final profile = SellerService.instance.profile;
              if (profile == null) return const SizedBox.shrink();
              if (profile.suspended) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lossMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.lossBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 14, color: AppColors.loss),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your seller account is suspended. You cannot create new listings.',
                            style: AppTextStyles.small.copyWith(color: AppColors.loss, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (profile.strikes > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.amberMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.amberBorderMuted),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amber500),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Strikes: ${profile.strikes}/3 — Ship orders on time to avoid suspension.',
                          style: AppTextStyles.small.copyWith(color: AppColors.amber500, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionDivider(
              icon: Icons.sell_outlined,
              label: 'MY LISTINGS (${myListings.length})',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (myListings.isEmpty)
            RiftrEmptyState(
              icon: Icons.sell_outlined,
              title: 'No Active Listings',
              subtitle: 'Select a card from your holdings to list it for sale',
              buttonLabel: 'Go to Holdings',
              buttonIcon: Icons.wallet,
              onButtonPressed: () {
                setState(() { _view = 'portfolio'; _holdingsTab = 'holdings'; });
              },
            )
          else
            ...myListings.map((l) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                  child: _myListingTile(l),
                )),

          const SizedBox(height: AppSpacing.legacyXl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          // Bulk actions pinned at bottom — Card-Preview pattern: Positioned
          // bottom: 22, Row of two 56dp pills (destructive LEFT, primary RIGHT
          // per V2 §7.3 dialog-pair convention).
          if (myListings.isNotEmpty)
            Positioned(
              left: AppSpacing.base,
              right: AppSpacing.base,
              bottom: 22,
              child: Row(
                children: [
                  Expanded(
                    child: RiftrButton(
                      label: 'Cancel all',
                      icon: Icons.delete_outline,
                      style: RiftrButtonStyle.danger,
                      height: 56,
                      radius: AppRadius.pill,
                      onPressed: () => _cancelAllListings(myListings),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: RiftrButton(
                      label: 'Adjust all prices',
                      style: RiftrButtonStyle.primary,
                      height: 56,
                      radius: AppRadius.pill,
                      onPressed: () => _showPriceAdjustmentSheet(myListings),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ─── ORDERS VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildOrders() {
    final orders = _orderSubTab == 'purchases'
        ? OrderService.instance.purchases
        : OrderService.instance.sales;
    final role = _orderSubTab == 'purchases' ? OrderRole.buyer : OrderRole.seller;

    return _wrapWithDismiss(SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldOrnamentHeader(title: 'ORDERS'),
          const SizedBox(height: AppSpacing.sm),
          _buildViewToggle(),
          const SizedBox(height: AppSpacing.md),

          // Purchases / Sales sub-tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _orderSubTabButton('Purchases', 'purchases'),
                const SizedBox(width: AppSpacing.sm),
                _orderSubTabButton('Sales', 'sales'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (orders.isEmpty)
            RiftrEmptyState(
              icon: _orderSubTab == 'purchases' ? Icons.shopping_bag_outlined : Icons.sell_outlined,
              title: _orderSubTab == 'purchases' ? 'No Purchases Yet' : 'No Sales Yet',
              subtitle: _orderSubTab == 'purchases'
                  ? 'Your purchased cards will appear here'
                  : 'Start selling cards to see your sales history',
              buttonLabel: 'Browse Market',
              buttonIcon: Icons.search,
              onButtonPressed: () {
                setState(() { _view = 'discover'; });
                widget.onFullscreenChanged?.call(true);
              },
            )
          else
            ...orders.map((order) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                  child: OrderTile(
                    order: order,
                    role: role,
                    onMarkShipped: (id, tracking) async {
                      final ok = await OrderService.instance.markShipped(id, tracking);
                      if (mounted) {
                        final qty = order.totalQuantity;
                        final label = qty == 1 ? 'Card' : 'Cards';
                        if (ok) {
                          RiftrToast.success(context, 'Shipped! $label removed from your collection.');
                        } else {
                          RiftrToast.error(context, 'Failed to mark shipped');
                        }
                      }
                    },
                    onConfirmDelivery: (id) async {
                      final ok = await OrderService.instance.confirmDelivery(id);
                      if (mounted) {
                        final qty = order.totalQuantity;
                        final label = qty == 1 ? 'Card' : 'Cards';
                        if (ok) {
                          RiftrToast.success(context, '$label added to your collection!');
                        } else {
                          RiftrToast.error(context, 'Failed to confirm');
                        }
                      }
                    },
                    onCancel: (id) async {
                      final confirmed = await showRiftrSheet<bool>(
                        context: context,
                        builder: (ctx) => Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('Cancel Order?', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: AppSpacing.md),
                            Text('Are you sure you want to cancel this order? This action cannot be undone.',
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                            const SizedBox(height: AppSpacing.lg),
                            Row(children: [
                              Expanded(child: RiftrButton(label: 'No, keep it', style: RiftrButtonStyle.secondary,
                                onPressed: () => Navigator.pop(ctx, false))),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: RiftrButton(label: 'Yes, cancel', style: RiftrButtonStyle.danger,
                                onPressed: () => Navigator.pop(ctx, true))),
                            ]),
                          ]),
                        ),
                      );
                      if (confirmed != true || !mounted) return;
                      final ok = await OrderService.instance.cancelOrder(id);
                      if (mounted) {
                        if (ok) {
                          RiftrToast.info(context, 'Order cancelled');
                        } else {
                          RiftrToast.error(context, 'Failed to cancel');
                        }
                      }
                    },
                    onOpenDispute: (
                      id,
                      reason,
                      description, {
                      String reasonCodeChoice = 'no_choice_required',
                      DateTime? widerrufHinweisShownAt,
                      DateTime? widerrufHinweisChosenAt,
                    }) async {
                      final ok = await OrderService.instance.openDispute(
                        id,
                        reason,
                        description: description,
                        reasonCodeChoice: reasonCodeChoice,
                        widerrufHinweisShownAt: widerrufHinweisShownAt,
                        widerrufHinweisChosenAt: widerrufHinweisChosenAt,
                      );
                      if (mounted) {
                        if (ok) {
                          RiftrToast.info(context, 'Dispute opened');
                        } else {
                          RiftrToast.error(context, 'Failed to open dispute');
                        }
                      }
                    },
                    onSubmitReview: (id, rating, comment, tags) async {
                      final ok = await OrderService.instance.submitReview(id, rating, comment, tags: tags);
                      if (mounted) {
                        if (ok) {
                          RiftrToast.success(context, 'Review submitted!');
                        } else {
                          RiftrToast.error(context, 'Failed to submit review');
                        }
                      }
                    },
                    onViewDispute: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DisputeDetailScreen(order: order),
                        ),
                      );
                    },
                    // Tap on Seller section-card inside Order Detail →
                    // close detail, jump to Market Discover filtered by seller.
                    onViewSellerListings: (sellerId, sellerName) =>
                        _filterBySeller(sellerId, sellerName),
                  ),
                )),
        ],
      ),
    ));
  }

  Widget _orderSubTabButton(String label, String value) {
    final active = _orderSubTab == value;
    final color = value == 'purchases' ? AppColors.win : AppColors.amber500;
    // Sub-tab dots: live check from Firestore inbox (role-based)
    final inbox = NotificationInboxService.instance;
    final expectedRole = value == 'sales' ? 'seller' : 'buyer';
    final showDot = inbox.unseen.any((n) => n.type == 'order' && n.role == expectedRole);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _orderSubTab = value);
          // Don't mark as seen here — dots persist until user opens the specific order card.
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 44, // Apple HIG touch-target minimum
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: active ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: active ? AppColors.background : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showDot)
              Positioned(
                top: -3, right: -3,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.amber400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── DISCOVER FILTER LOGIC ───
  // ═══════════════════════════════════════════

  static const _rarityOrder = {'Common': 0, 'Uncommon': 1, 'Rare': 2, 'Epic': 3, 'Showcase': 4, 'Ultimate': 5, 'Metal': 6};

  void _refreshFilteredResults() {
    final query = _searchController.text;
    if (query.isEmpty && _discoverFilter.isEmpty) {
      setState(() => _filteredResults = []);
      return;
    }
    setState(() => _filteredResults = _applyDiscoverFilter(_discoverFilter, query));
  }

  List<CardPriceData> _applyDiscoverFilter(DiscoverFilter filter, String query) {
    // Include all cards: priced + unpriced (e.g. UNL pre-release)
    var results = _market.allCardsWithFallback;

    // Text search (name, display name, card text, collector number, keywords)
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      final lookup = CardService.getLookup();
      results = results.where((p) {
        // Name match (from price data)
        if (p.cardName.toLowerCase().contains(lower)) return true;
        // Cross-reference with full card data for deeper search
        final card = lookup[p.cardId];
        if (card == null) return false;
        if (card.displayName.toLowerCase().contains(lower)) return true;
        if (card.textPlain?.toLowerCase().contains(lower) == true) return true;
        // Keyword match
        if (card.keywords.any((k) => k.toLowerCase().contains(lower))) return true;
        // Collector number match (e.g. "#186" or "SFD 32")
        final cn = lower.startsWith('#') ? lower.substring(1) : lower;
        final cnNum = cn.replaceAll(RegExp(r'[^0-9]'), '');
        final cnSuffix = cn.replaceAll(RegExp(r'[0-9]'), '');
        if (cnNum.isNotEmpty && card.collectorNumber != null &&
            card.collectorNumber!.startsWith(cnNum) &&
            (cnSuffix.isEmpty || card.collectorNumber!.endsWith(cnSuffix))) return true;
        return false;
      }).toList();
    }

    // Rarity
    if (filter.rarities.isNotEmpty) {
      results = results.where((p) => filter.rarities.contains(p.rarity)).toList();
    }

    // Price range
    if (filter.priceMin != null) {
      results = results.where((p) => p.currentPrice >= filter.priceMin!).toList();
    }
    if (filter.priceMax != null) {
      results = results.where((p) => p.currentPrice <= filter.priceMax!).toList();
    }

    // Set
    if (filter.setIds.isNotEmpty) {
      results = results.where((p) => filter.setIds.contains(p.setId?.toUpperCase())).toList();
    }

    // Domain (cross-reference with RiftCard)
    if (filter.domains.isNotEmpty) {
      final lookup = CardService.getLookup();
      results = results.where((p) {
        final card = lookup[p.cardId];
        if (card == null) return false;
        return card.domains.any((d) => filter.domains.contains(d));
      }).toList();
    }

    // Card type
    if (filter.cardType != null) {
      results = results.where((p) => p.cardType == filter.cardType).toList();
    }

    // Listing-level filters (condition, language, country, seller)
    if (filter.conditions.isNotEmpty || filter.languages.isNotEmpty ||
        filter.sellerCountry != null || filter.sellerId != null) {
      final listings = ListingService.instance.allActive;
      final listingsByCard = <String, List<MarketListing>>{};
      for (final l in listings) {
        (listingsByCard[l.cardId] ??= []).add(l);
      }
      results = results.where((p) {
        final cardListings = listingsByCard[p.cardId];
        if (cardListings == null || cardListings.isEmpty) return false;
        return cardListings.any((l) {
          if (filter.conditions.isNotEmpty && !filter.conditions.contains(l.condition)) return false;
          if (filter.languages.isNotEmpty && !filter.languages.contains(l.language)) return false;
          if (filter.sellerCountry != null && l.sellerCountry != filter.sellerCountry) return false;
          if (filter.sellerId != null && l.sellerId != filter.sellerId) return false;
          return true;
        });
      }).toList();
    }

    // Hide €0.00 cards in browse/filter mode, but KEEP them in search results
    if (query.isEmpty) {
      results = results.where((p) => p.currentPrice > 0).toList();
    }

    // Sort
    switch (filter.sort) {
      case DiscoverSort.priceAsc:
        results.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case DiscoverSort.priceDesc:
        results.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      case DiscoverSort.rarityAsc:
        results.sort((a, b) =>
            (_rarityOrder[a.rarity] ?? 0).compareTo(_rarityOrder[b.rarity] ?? 0));
      case DiscoverSort.newest:
        final listings = ListingService.instance.allActive;
        final latestByCard = <String, DateTime>{};
        for (final l in listings) {
          final existing = latestByCard[l.cardId];
          if (existing == null || l.listedAt.isAfter(existing)) {
            latestByCard[l.cardId] = l.listedAt;
          }
        }
        results.sort((a, b) {
          final aDate = latestByCard[a.cardId] ?? DateTime(2020);
          final bDate = latestByCard[b.cardId] ?? DateTime(2020);
          return bDate.compareTo(aDate);
        });
    }

    return results;
  }

  Future<void> _openFilterSheet() async {
    final result = await Navigator.push<DiscoverFilter>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => FilterFullScreen(initial: _discoverFilter),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _discoverFilter = result;
        _activeQuickFilter = null;
      });
      _refreshFilteredResults();
    }
  }

  // ═══════════════════════════════════════════
  // ─── DISCOVER VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildRecentlyViewedList() {
    final cards = _recentlyViewedIds
        .map((id) => _market.getPrice(id))
        .where((p) => p != null)
        .cast<CardPriceData>()
        .toList();
    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final riftCard = CardService.getLookup()[card.cardId];
          final isBattlefield = riftCard?.isBattlefield == true;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => _navigateToCard(card),
              child: SizedBox(
                width: 105,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card image (portrait slot 105×147). Battlefield art is
                    // landscape — RotatedBox(quarterTurns:1) lets it fill the
                    // portrait slot fully instead of cropping left/right.
                    // Same pattern as cart_screen._buildMoreCard,
                    // CardPriceTile, smart_cart_review_sheet.
                    SizedBox(
                      width: 105, height: 147,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        child: card.imageUrl != null
                            ? (isBattlefield
                                ? RotatedBox(
                                    quarterTurns: 1,
                                    child: CardImage(
                                      imageUrl: card.imageUrl,
                                      fallbackText: card.cardName,
                                      fit: BoxFit.cover,
                                      card: riftCard,
                                    ),
                                  )
                                : CardImage(
                                    imageUrl: card.imageUrl,
                                    fallbackText: card.cardName,
                                    width: 105,
                                    height: 147,
                                    fit: BoxFit.cover,
                                    card: riftCard,
                                  ))
                            : Container(
                                color: AppColors.surfaceLight,
                                child: Icon(Icons.style, color: AppColors.textMuted),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Name
                    Text(
                      card.cardName,
                      style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Price + daily change
                    if (card.currentPrice > 0)
                      Row(
                        children: [
                          Text(
                            '€${card.currentPrice.toStringAsFixed(2)}',
                            style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${card.dayChange >= 0 ? '+' : ''}${card.dayChange.toStringAsFixed(1)}%',
                            style: AppTextStyles.micro.copyWith(
                              color: card.dayChange > 0 ? AppColors.win : card.dayChange < 0 ? AppColors.loss : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text('—', style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscover() {
    final hasActiveFilter = !_discoverFilter.isEmpty || _searchController.text.isNotEmpty;

    return _wrapWithDismiss(SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const GoldOrnamentHeader(title: 'DISCOVER'),
          const SizedBox(height: AppSpacing.sm),

          // View toggle
          _buildViewToggle(),
          const SizedBox(height: AppSpacing.md),

          // Missing cards banner + Smart Cart CTA.
          // Visual hierarchy: status banner (quiet) → primary CTA (loud).
          // Previously both rendered as solid amber blocks of equal weight —
          // user couldn't tell what was info vs. action.
          if (_missingCardIds != null) ...[
            // Status banner — dezent surfaceLight bg, no competing color.
            // Uses RiftrCard (V2 §16) with override radius to match the
            // banner-family (rounded/8dp) used elsewhere in the app.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: RiftrCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.surfaceLight,
                borderColor: AppColors.surfaceLight, // borderless look
                radius: AppRadius.rounded,
                child: Row(children: [
                  Icon(Icons.style, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_missingCardIds!.values.fold(0, (s, q) => s + q)} missing cards',
                    style: AppTextStyles.captionBold,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() { _missingCardIds = null; _searchResults = []; }),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 44, height: 44, // Apple HIG touch-target minimum
                      child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Smart Cart CTA — single primary action on this screen. No
            // sparkle icon (app-wide consistency with Review-Sheet CTAs);
            // label shortened because "Smart cart" is already the feature
            // name in context.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: RiftrButton(
                label: 'Find best deals',
                onPressed: () => startSmartCartFlow(_missingCardIds!),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Search bar + filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(children: [
              Expanded(child: RiftrSearchBar(
                controller: _searchController,
                onChanged: (q) {
                  setState(() => _missingCardIds = null);
                  _refreshFilteredResults();
                },
                onSuggest: (q) => CardService.suggestCardNames(q),
                onSuggestionTap: (_) {
                  setState(() => _missingCardIds = null);
                  _refreshFilteredResults();
                },
              )),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterButton(),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quick-filter pills — hidden while a seller filter is active.
          // The quick-filters reset _discoverFilter on tap, which would
          // silently drop the seller context. Hiding them keeps the user's
          // "view this seller's listings" intent intact. When the user
          // clears the seller filter (via X on the chip), pills reappear.
          if (_discoverFilter.sellerId == null) ...[
            _buildQuickFilterPills(),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Active filter pills
          if (!_discoverFilter.isEmpty)
            _buildActiveFilterPills(),

          // Missing cards results
          if (_missingCardIds != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('${_searchResults.length} cards', style: AppTextStyles.small)),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._searchResults.map((card) {
              final needQty = _missingCardIds![card.cardId];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                child: CardPriceTile(data: card, quantity: needQty, onTap: () => _navigateToCard(card)),
              );
            }),
          ]
          // Filtered / search results
          else if (hasActiveFilter) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('${_filteredResults.length} results', style: AppTextStyles.small)),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._filteredResults.take(100).map((card) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
              child: CardPriceTile(data: card, onTap: () => _navigateToCard(card)),
            )),
            if (_filteredResults.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.legacyXl),
                child: RiftrEmptyState(
                  icon: Icons.search_off,
                  title: 'No results',
                  subtitle: 'Try adjusting your filters',
                ),
              ),
          ]
          // Browse mode: Recently Viewed + Gainers + Losers
          else ...[
            if (_recentlyViewedIds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SectionDivider(icon: Icons.history, label: 'RECENTLY VIEWED'),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildRecentlyViewedList(),
              const SizedBox(height: AppSpacing.base),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionDivider(icon: Icons.trending_up, label: 'TOP GAINERS'),
            ),
            const SizedBox(height: AppSpacing.xs),
            ..._market.topGainers.map((card) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
              child: CardPriceTile(data: card, onTap: () => _navigateToCard(card)),
            )),
            const SizedBox(height: AppSpacing.base),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SectionDivider(icon: Icons.trending_down, label: 'TOP LOSERS'),
            ),
            const SizedBox(height: AppSpacing.xs),
            ..._market.topLosers.map((card) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
              child: CardPriceTile(data: card, onTap: () => _navigateToCard(card)),
            )),
          ],
        ],
      ),
    ));
  }

  Widget _buildFilterButton() {
    final count = _discoverFilter.activeCount;
    return GestureDetector(
      onTap: _openFilterSheet,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: count > 0 ? AppColors.amber500 : AppColors.surfaceLight,
          borderRadius: AppRadius.baseBR,
        ),
        child: Stack(children: [
          Center(child: Icon(Icons.tune, size: 20,
              color: count > 0 ? AppColors.background : AppColors.textSecondary)),
          if (count > 0)
            Positioned(top: 4, right: 4,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(color: AppColors.loss, shape: BoxShape.circle),
                child: Center(child: Text('$count',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildQuickFilterPills() {
    Widget pill(String label, String key, IconData icon) {
      final isActive = _activeQuickFilter == key;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            if (isActive) {
              _activeQuickFilter = null;
              _discoverFilter = const DiscoverFilter();
            } else {
              _activeQuickFilter = key;
              _discoverFilter = switch (key) {
                'rareDeals' => DiscoverFilter.rareDeals(),
                'legends' => DiscoverFilter.legends(),
                'underOne' => DiscoverFilter.underOneEuro(),
                _ => const DiscoverFilter(),
              };
            }
          });
          _refreshFilteredResults();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.amber500 : AppColors.surfaceLight,
            borderRadius: AppRadius.pillBR,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: isActive ? AppColors.background : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.small.copyWith(
              color: isActive ? AppColors.background : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(children: [
        pill('Rare Deals', 'rareDeals', Icons.diamond_outlined),
        const SizedBox(width: AppSpacing.sm),
        pill('Legends', 'legends', Icons.shield_outlined),
        const SizedBox(width: AppSpacing.sm),
        pill('Under €1', 'underOne', Icons.euro_outlined),
      ]),
    );
  }

  Widget _buildActiveFilterPills() {
    final labels = _discoverFilter.activeLabels;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          ...labels.map((item) => Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _discoverFilter = _discoverFilter.removeByKey(item.key);
                  _activeQuickFilter = null;
                });
                _refreshFilteredResults();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.amber500,
                  borderRadius: AppRadius.pillBR,
                  border: Border.all(color: AppColors.amber500),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(item.label, style: AppTextStyles.small.copyWith(color: AppColors.background)),
                  const SizedBox(width: 4),
                  Icon(Icons.close, size: 12, color: AppColors.background),
                ]),
              ),
            ),
          )),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _discoverFilter = const DiscoverFilter();
                _activeQuickFilter = null;
              });
              _refreshFilteredResults();
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 44, // Apple HIG touch-target minimum
              child: Align(
                alignment: Alignment.center,
                child: Text('Clear all', style: AppTextStyles.small.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── CARD DETAIL VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildCardDetail() {
    final card = _selectedCard;
    if (card == null) return const SizedBox.shrink();
    // Single source of truth for the §7.2 card detail UI lives in
    // MarketCardDetailView. Both this in-tab path AND the modal sheet
    // (showMarketCardDetailSheet from DeckShoppingOverlay) render it.
    // ValueKey resets the widget's State when the user navigates to a
    // different card via _navigateToCard.
    //
    // _wrapWithDismiss adds the DragToDismiss + drag-handle wrapper so the
    // user can pull down anywhere on the detail to return to the previous
    // view. Modal sheet path doesn't need this — showRiftrSheet provides
    // its own drag handle.
    return _wrapWithDismiss(
      MarketCardDetailView(
        key: ValueKey(card.cardId),
        card: card,
        initialShowFoil: _detailShowFoil,
        onCheckout: _openCheckoutSheet,
        onAddToCart: _addToCart,
        onSell: () => _openSellSheet(card),
        onFilterSeller: _filterBySeller,
      ),
    );
  }


  /// Compute status badge label + type for a listing.
  /// Mirrors OrderTile's status-badge pattern so both tiles read similar.
  (String, RiftrBadgeType) _listingStatus(MarketListing listing) {
    if (listing.status == 'cancelled') {
      return ('Cancelled', RiftrBadgeType.error);
    }
    if (listing.availableQty <= 0) {
      return ('Sold', RiftrBadgeType.success);
    }
    final reserved = listing.quantity - listing.availableQty;
    if (reserved > 0) {
      return ('Reserved $reserved', RiftrBadgeType.warning);
    }
    return ('Active', RiftrBadgeType.gold);
  }

  /// Structural parity with OrderTile: RiftrCard(md, listItem) + 40×56
  /// thumbnail with scale 1.25, single-row info, small inline Cancel pill.
  Widget _myListingTile(MarketListing listing) {
    final card = CardService.getLookup()[listing.cardId];
    final marketPrice = _market.getPrice(listing.cardId);
    final mktPrice = marketPrice != null
        ? (listing.isFoil ? marketPrice.getPrice(true) : marketPrice.currentPrice)
        : null;

    final (statusLabel, statusType) = _listingStatus(listing);

    // Compose meta line: "SFD #123 · Mkt €1.20"
    final metaParts = <String>[];
    if (card != null) {
      final setCn = [
        if (card.setId != null) card.setId!,
        if (card.collectorNumber != null) '#${card.collectorNumber}',
      ].join(' ');
      if (setCn.isNotEmpty) metaParts.add(setCn);
    }
    if (mktPrice != null && mktPrice > 0) {
      metaParts.add('Mkt €${mktPrice.toStringAsFixed(2)}');
    }
    final metaLine = metaParts.join(' · ');

    return RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadius.listItem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail — identical to OrderTile (40×56 + scale 1.25)
          SizedBox(
            width: 40,
            height: 56,
            child: Transform.scale(
              scale: 1.25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.rounded),
                child: CardImage(
                  imageUrl: listing.imageUrl,
                  fallbackText: listing.cardName,
                  width: 40,
                  height: 56,
                  card: card,
                  ribbonSize: CardRibbonSize.compact,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Name + Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        listing.cardName,
                        // body (14sp) — matches OrderTile/CardPriceTile.
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    RiftrBadge(label: statusLabel, type: statusType),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 2: Condition + qty + foil + meta + price + edit
                Row(
                  children: [
                    ConditionBadge(condition: listing.condition),
                    if (listing.availableQty > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '×${listing.availableQty}',
                        style: AppTextStyles.tiny.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (listing.isFoil) ...[
                      const SizedBox(width: 6),
                      // App-wide Foil-Indicator standard '★' (V2 §15.17).
                      Text(
                        '★',
                        style: AppTextStyles.tiny.copyWith(color: AppColors.amber300),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        metaLine,
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Price (plain — adjust action moved to dedicated pill below)
                    Text(
                      '€${listing.price.toStringAsFixed(2)}',
                      // body (14sp) — matches OrderTile price size.
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),

                // Row 3: Inline action pills (only for active listings).
                // Layout matches OrderTile Sales-row (Cancel + Ship pair):
                //   LEFT  = Cancel (red, flex 1 — narrower)
                //   RIGHT = Adjust price (amber, flex 2 — wider primary action)
                // Adjust price = explicit pill (replaces previous pencil icon
                // next to the price — clearer affordance, easier to hit).
                if (listing.status == 'active') ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _smallActionPill(
                          label: 'Cancel',
                          color: AppColors.loss,
                          onTap: () => _cancelListing(listing),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: _smallActionPill(
                          label: 'Adjust price',
                          color: AppColors.amber500,
                          onTap: () => _showListingPriceEditor(listing),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small inline action pill — matches OrderTile's inline-action style.
  /// Used for Cancel in list tiles and for bulk-actions above the list.
  Widget _smallActionPill({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.pillBR,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.background),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented toggle button — visual parity with `_orderSubTabButton`
  /// (Purchases/Sales sub-tabs). Used inside the Adjust-all-prices sheet.
  /// 44dp height, AppRadius.md (8dp), solid amber active + border inactive.
  Widget _segmentedToggle({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.amber500 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: active ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.small.copyWith(
            color: active ? AppColors.background : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Tappable snap-point label below the percent slider.
  /// 44dp touch-target (Apple HIG) wraps the small text.
  Widget _percentSnapLabel({
    required String label,
    required int value,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: active ? AppColors.amber400 : AppColors.textMuted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showListingPriceEditor(MarketListing listing) {
    final controller = TextEditingController(text: listing.price.toStringAsFixed(2));
    showRiftrSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listing.cardName,
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '€ ',
                prefixStyle: AppTextStyles.titleMedium.copyWith(color: AppColors.amber400, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  borderSide: BorderSide(color: AppColors.amber400),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            RiftrButton(
              label: 'Confirm',
              style: RiftrButtonStyle.primary,
              onPressed: () async {
                final parsed = double.tryParse(controller.text);
                Navigator.pop(ctx);
                if (parsed == null || parsed < 0.01) return;

                if (_isDemo) {
                  final idx = _demoListings.indexWhere((l) => l.id == listing.id);
                  if (idx >= 0) {
                    setState(() {
                      _demoListings[idx] = MarketListing(
                        id: listing.id, cardId: listing.cardId, cardName: listing.cardName,
                        imageUrl: listing.imageUrl, sellerId: listing.sellerId,
                        sellerName: listing.sellerName, sellerCountry: listing.sellerCountry,
                        sellerRating: listing.sellerRating, sellerSales: listing.sellerSales,
                        price: parsed, condition: listing.condition, quantity: listing.quantity,
                        insuredOnly: listing.insuredOnly, isFoil: listing.isFoil,
                        status: listing.status, listedAt: listing.listedAt,
                      );
                    });
                  }
                  return;
                }

                final ok = await _listings.updateListingPrice(listing.id, parsed);
                if (!mounted) return;
                if (ok) {
                  RiftrToast.success(context, 'Price updated');
                } else {
                  RiftrToast.error(context, 'Failed to update price');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelListing(MarketListing listing) async {
    final confirm = await showRiftrSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CANCEL LISTING?', style: AppTextStyles.h2.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Remove ${listing.cardName} (€${listing.price.toStringAsFixed(2)}) from the marketplace?',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(child: RiftrButton(label: 'Keep',
                onPressed: () => Navigator.pop(ctx, false), style: RiftrButtonStyle.secondary)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: RiftrButton(label: 'Cancel Listing',
                onPressed: () => Navigator.pop(ctx, true), style: RiftrButtonStyle.danger)),
            ]),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    if (_isDemo) {
      setState(() => _demoListings.removeWhere((l) => l.id == listing.id));
      if (!mounted) return;
      RiftrToast.success(context, 'Listing cancelled (Demo Mode)');
      return;
    }

    final success = await _listings.cancelListing(listing.id);
    if (!mounted) return;
    if (success) {
      RiftrToast.success(context, 'Listing cancelled');
    } else {
      RiftrToast.error(context, 'Failed to cancel');
    }
  }

  Future<void> _cancelAllListings(List<MarketListing> listings) async {
    final confirm = await showRiftrSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CANCEL ALL LISTINGS?',
                style: AppTextStyles.h2.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Text('Cancel all ${listings.length} listing${listings.length > 1 ? 's' : ''}? This cannot be undone.',
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(child: RiftrButton(label: 'Keep',
                  onPressed: () => Navigator.pop(ctx, false), style: RiftrButtonStyle.secondary)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: RiftrButton(label: 'Cancel All',
                  onPressed: () => Navigator.pop(ctx, true), style: RiftrButtonStyle.danger)),
            ]),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    if (_isDemo) {
      setState(() => _demoListings.clear());
      if (mounted) RiftrToast.success(context, '${listings.length} listings cancelled (Demo)');
      return;
    }

    int cancelled = 0;
    for (final l in listings) {
      final ok = await _listings.cancelListing(l.id);
      if (ok) cancelled++;
    }

    if (!mounted) return;
    RiftrToast.success(context, '$cancelled listing${cancelled > 1 ? 's' : ''} cancelled');
  }

  void _showPriceAdjustmentSheet(List<MarketListing> listings) {
    int modifierPercent = 0;
    bool fromMarket = true; // true = market price, false = current listing price

    showRiftrSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Calculate preview prices
          final previews = listings.map((l) {
            final basePrice = fromMarket
                ? (_market.getPrice(l.cardId)?.currentPrice ?? l.price)
                : l.price;
            final newPrice = ((basePrice * (1.0 + modifierPercent / 100.0)) * 100).roundToDouble() / 100;
            return (listing: l, oldPrice: l.price, newPrice: newPrice.clamp(0.01, 9999.99));
          }).toList();

          final label = modifierPercent == 0
              ? '0%'
              : '${modifierPercent > 0 ? '+' : ''}$modifierPercent%';

          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── FIXED TOP: Header + Mode + Slider ──
                Text('Adjust all prices',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('${listings.length} listings will be updated',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.md),

                // Mode toggle — matches Purchases/Sales segmented pattern
                // (44dp, AppRadius.md, solid amber active + border inactive).
                Row(children: [
                  Expanded(
                    child: _segmentedToggle(
                      label: 'From market price',
                      active: fromMarket,
                      onTap: () => setSheetState(() => fromMarket = true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _segmentedToggle(
                      label: 'From current price',
                      active: !fromMarket,
                      onTap: () => setSheetState(() => fromMarket = false),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // Slider — form-group label + live value indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // FormSectionLabel-equivalent inline (sheet form-group label
                    // tokens: captionBold + textSecondary + letterSpacing 1.2).
                    Text('ADJUSTMENT', style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textSecondary, letterSpacing: 1.2)),
                    Text(label, style: AppTextStyles.titleMedium.copyWith(color: AppColors.amber400)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: AppColors.amber500,
                    inactiveTrackColor: AppColors.surfaceLight,
                    thumbColor: AppColors.amber500,
                    // Token instead of inline alpha (V2 Rule 2 — interactive el.)
                    overlayColor: AppColors.amberMuted,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: modifierPercent.toDouble(),
                    min: -10, max: 10, divisions: 20,
                    onChanged: (v) => setSheetState(() => modifierPercent = v.round()),
                  ),
                ),
                // Tappable snap-points — 44dp touch-target per Apple HIG.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final entry in const [
                      ('-10%', -10), ('-5%', -5), ('0%', 0), ('+5%', 5), ('+10%', 10),
                    ])
                      _percentSnapLabel(
                        label: entry.$1,
                        value: entry.$2,
                        active: modifierPercent == entry.$2,
                        onTap: () => setSheetState(() => modifierPercent = entry.$2),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── SCROLLABLE MIDDLE: Preview list ──
                // RiftrCard (V2 standard content container) instead of custom
                // surface+border+radius Container.
                Flexible(
                  child: RiftrCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // In-box label per V2 §15.4 (centered + amber + l-spacing 1.5)
                        // — same pattern as MARKET PRICE / YOUR COLLECTION boxes.
                        Text(
                          'PREVIEW',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.amber500,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: previews.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.surfaceLight),
                            itemBuilder: (_, i) {
                              final p = previews[i];
                              final changed = (p.oldPrice - p.newPrice).abs() >= 0.005;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(children: [
                                  Expanded(child: Text(
                                    '${p.listing.cardName}${p.listing.quantity > 1 ? ' ×${p.listing.quantity}' : ''}',
                                    style: AppTextStyles.bodySmallSecondary,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                  if (changed) ...[
                                    Text('€${p.oldPrice.toStringAsFixed(2)} ',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted,
                                          decoration: TextDecoration.lineThrough)),
                                  ],
                                  Text('€${p.newPrice.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary)),
                                ]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── FIXED BOTTOM: Buttons ──
                // Gap = md (12dp) per V2 §1 (button-pair gap rule).
                Row(children: [
                  Expanded(
                    child: RiftrButton(
                      label: 'Cancel',
                      style: RiftrButtonStyle.secondary,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: RiftrButton(
                      label: 'Apply to all',
                      style: RiftrButtonStyle.primary,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _applyPriceAdjustment(previews);
                      },
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _applyPriceAdjustment(
    List<({MarketListing listing, double oldPrice, double newPrice})> previews,
  ) async {
    if (_isDemo) {
      setState(() {
        for (final p in previews) {
          final idx = _demoListings.indexWhere((l) => l.id == p.listing.id);
          if (idx >= 0) {
            _demoListings[idx] = MarketListing(
              id: p.listing.id,
              cardId: p.listing.cardId,
              cardName: p.listing.cardName,
              imageUrl: p.listing.imageUrl,
              sellerId: p.listing.sellerId,
              sellerName: p.listing.sellerName,
              sellerCountry: p.listing.sellerCountry,
              sellerRating: p.listing.sellerRating,
              sellerSales: p.listing.sellerSales,
              price: p.newPrice,
              condition: p.listing.condition,
              quantity: p.listing.quantity,
              insuredOnly: p.listing.insuredOnly,
              isFoil: p.listing.isFoil,
              status: p.listing.status,
              listedAt: p.listing.listedAt,
            );
          }
        }
      });
      if (mounted) RiftrToast.success(context, '${previews.length} prices updated (Demo)');
      return;
    }

    int updated = 0;
    for (final p in previews) {
      if ((p.oldPrice - p.newPrice).abs() < 0.005) continue; // skip unchanged
      final ok = await _listings.updateListingPrice(p.listing.id, p.newPrice);
      if (ok) updated++;
    }

    if (!mounted) return;
    RiftrToast.success(context, '$updated prices updated');
  }

  Future<void> addToCart(MarketListing listing) => _addToCart(listing);
  Future<void> _addToCart(MarketListing listing) async {
    HapticFeedback.lightImpact();
    final ok = await CartService.instance.addItem(CartItem.fromListing(listing));
    if (!mounted) return;
    if (ok) {
      RiftrToast.cart(context, 'Added to cart');
    } else {
      RiftrToast.error(context, 'Not available');
    }
  }

  Future<void> openCheckoutSheet(MarketListing listing) =>
      _openCheckoutSheet(listing);
  Future<void> _openCheckoutSheet(MarketListing listing) async {
    // CheckoutSheet self-wraps in Scaffold + DragToDismiss + Stack now;
    // pushed via the Card-Preview pattern (Fade 200ms, opaque:false) so
    // the sheet feels identical to the Cards-Tab detail view.
    final result = await Navigator.push<dynamic>(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (ctx, anim, secondaryAnim) =>
            CheckoutSheet(listing: listing),
        transitionsBuilder: (ctx, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    if (!mounted) return;

    // Wallet purchase returns orderId string, demo returns 'demo-order'
    if (result is String) {
      RiftrToast.success(context, result == 'demo-order' ? 'Order placed (Demo Mode)' : 'Order placed!');
    }
  }

  /// Public entry point for the sell flow — can be called from Cards/Collection
  /// tab preview without switching to the Market tab. Looks up price data with
  /// fallback (UNL cards without a Firestore price still work) and delegates
  /// to [_openSellSheet].
  Future<void> openSellSheetById(String cardId) async {
    final card = _market.getPrice(cardId) ?? _market.getFallbackPrice(cardId);
    if (card == null) return;
    await _openSellSheet(card);
  }

  Future<void> _openSellSheet(CardPriceData card) async {
    // Gate: Suspended sellers cannot create listings
    if (!_isDemo) {
      final profile = SellerService.instance.profile;
      if (profile != null && profile.suspended) {
        if (mounted) {
          RiftrToast.error(context, 'Your seller account is suspended. You cannot create listings.');
        }
        return;
      }
    }

    // Gate: Seller must complete onboarding (name, email, address + verification)
    final needsOnboarding = _isDemo
        ? _demoCountry == null
        : !SellerService.instance.isReady;

    if (needsOnboarding) {
      final completed = await showRiftrSheet<bool>(
        context: context,
        builder: (_) => const SellerOnboardingSheet(),
      );
      if (completed != true || !mounted) return;
      // In demo mode, grab country from the onboarding sheet result
      if (_isDemo) {
        _demoCountry = 'DE'; // Default for demo after onboarding
      }
    }

    if (!mounted) return;
    final collectionQty = _isDemo
        ? 0
        : FirestoreCollectionService.instance.getTotalQuantity(card.cardId);

    final result = await showRiftrSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => SellSheet(
        cardName: card.cardName,
        imageUrl: card.imageUrl,
        suggestedPrice: card.currentPrice,
        collectionQty: collectionQty,
        setId: card.setId,
      ),
    );
    if (result == null || !mounted) return;

    final isNewCards = result['newCards'] as bool? ?? false;
    final quantity = result['quantity'] as int;

    if (_isDemo) {
      setState(() {
        _demoListings.add(MarketListing(
          id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
          cardId: card.cardId,
          cardName: card.cardName,
          imageUrl: card.imageUrl,
          sellerId: 'demo-user',
          sellerName: 'You (Demo)',
          sellerCountry: _demoCountry,
          sellerRating: 0.0,
          sellerSales: 0,
          price: result['price'] as double,
          condition: result['condition'] as CardCondition,
          quantity: quantity,
          insuredOnly: result['insuredOnly'] as bool? ?? false,
          isFoil: FirestoreCollectionService.isFoilVariant(card.setId, card.rarity),
          status: 'active',
          listedAt: DateTime.now(),
        ));
      });
      RiftrToast.sale(context, 'Listing created (Demo Mode)');
      return;
    }

    // Look up full card data for set/collector info
    final fullCard = CardService.getLookup()[card.cardId];

    final isFoil = FirestoreCollectionService.isFoilVariant(card.setId, card.rarity);

    final listingId = await _listings.createListing(
      cardId: card.cardId,
      cardName: card.cardName,
      imageUrl: card.imageUrl,
      condition: result['condition'] as CardCondition,
      price: result['price'] as double,
      quantity: quantity,
      insuredOnly: result['insuredOnly'] as bool? ?? false,
      isFoil: isFoil,
      language: result['language'] as String? ?? 'EN',
      setId: card.setId,
      setCode: fullCard?.setId ?? card.setId,
      collectorNumber: fullCard?.collectorNumber,
    );

    // Add new lots to collection if needed
    // Toggle AN: all cards are new → newLots = quantity
    // Toggle AUS: fill up collection if listing > owned → newLots = max(0, quantity - collectionQty)
    if (listingId != null) {
      final newLots = isNewCards ? quantity : (quantity - collectionQty).clamp(0, quantity);
      if (newLots > 0) {
        final collection = FirestoreCollectionService.instance;
        final costPrice = card.currentPrice;
        for (int i = 0; i < newLots; i++) {
          collection.increment(card.cardId, costPrice: costPrice, foil: isFoil, source: 'listing');
        }
      }
    }

    if (!mounted) return;
    final newLots = isNewCards ? quantity : (quantity - collectionQty).clamp(0, quantity);
    if (listingId != null) {
      final msg = newLots > 0
          ? newLots > 1
              ? 'Listed for sale! $newLots cards added to your collection.'
              : 'Listed for sale! Card added to your collection.'
          : 'Listed for sale!';
      RiftrToast.sale(context, msg);
    } else {
      RiftrToast.error(context, 'Failed to create listing');
    }
  }

  Future<String?> _showCountryPicker() async {
    return showRiftrSheet<String>(
      context: context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7 - 80,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Country',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Used to calculate shipping costs for buyers.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ShippingRates.countries.entries.map((entry) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.listItem),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            entry.key,
                            style: AppTextStyles.bodyBold.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            entry.value,
                            style: AppTextStyles.micro.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── HELPERS ───
  // ═══════════════════════════════════════════

  // Foil-variant chart helpers (`_getFoilOnlyChartData`,
  // `_getFoilChartData`, `_getStandardChartData`, `_getPremiumChartData`)
  // moved into MarketCardDetailView — only the card detail used them.

  List<PricePoint> _filterByRange(List<PricePoint> data, String range) {
    if (data.isEmpty) return data;
    final days = switch (range) {
      '1D' => 2, // min 2 points for a visible line (yesterday + today)
      '1W' => 7,
      '1M' => 30,
      '3M' => 90,
      '1Y' => 365,
      _ => data.length, // MAX
    };
    if (days >= data.length) return data;
    return data.sublist(data.length - days);
  }
}

class _HoldingEntry {
  final CardPriceData data;
  final int quantity;
  final CostBasisEntry? costBasis;
  final bool isFoil;
  const _HoldingEntry({required this.data, required this.quantity, this.costBasis, this.isFoil = false});

  /// The price used for this holding (foil uses foilPrice if available)
  double get unitPrice => isFoil
      ? (data.foilPrice > 0 ? data.foilPrice : data.currentPrice)
      : (data.nonFoilPrice > 0 ? data.nonFoilPrice : data.currentPrice);

  /// Cost basis change (current value vs purchase cost)
  double get cbChangeAbs {
    if (costBasis == null || costBasis!.totalQty <= 0) return 0;
    return unitPrice * quantity - costBasis!.totalCost;
  }

  double get cbChangePct {
    if (costBasis == null || costBasis!.totalCost <= 0) return 0;
    return cbChangeAbs / costBasis!.totalCost * 100;
  }

  /// Day trend (c24) — variant-specific. Previously used `data.dayChange`
  /// (the generic `c24`) and `data.dayChangeAbs` (derived from
  /// currentPrice/previousClose, which mirror the standard variant). For
  /// a foil holding of a Both-Variants Common/Uncommon card, that meant
  /// the price tile showed correct foil €-amount but a NON-foil %-delta
  /// underneath. Now uses variant-aware getDayChangeAbs / getDayChange so
  /// price and percentage agree with each other and with the chart.
  double get dayChangeAbs => data.getDayChangeAbs(isFoil) * quantity;
  double get dayChangePct => data.getDayChange(isFoil);
}

/// Pulsing Cart FAB — same style as Shop FAB in Deck Viewer but with cart icon.
/// Cart FAB using CartService.pulse (shared ValueNotifier) for synchronized animation.
class _CartFab extends StatelessWidget {
  final bool pulse;
  const _CartFab({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: CartService.pulse,
      builder: (context, t, child) {
        final scale = pulse ? 1.0 + 0.08 * t : 1.0; // 1.0 → 1.08
        final glowAlpha = pulse ? 0.4 + 0.4 * t : 0.4; // 0.4 → 0.8
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber500,
            ),
            // FAB icon stays pure white for max contrast on amber bg in both themes.
            child: Icon(Icons.shopping_cart, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }
}

// `_CheckoutFullScreen` was a manual wrapper providing DragToDismiss + drag
// handle around the old `CheckoutSheet` Column. CheckoutSheet now self-wraps
// in Scaffold + SafeArea + Stack + DragToDismiss + Positioned button (Card-
// Preview pattern), so this wrapper is no longer needed and was removed.


