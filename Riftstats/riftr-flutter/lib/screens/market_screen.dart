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
import '../widgets/market/market_search_bar.dart';
import '../widgets/market/gainers_losers_list.dart';
import '../widgets/market/sell_sheet.dart';
import '../widgets/market/seller_onboarding_sheet.dart';
import '../widgets/market/checkout_sheet.dart';
import '../widgets/market/order_tile.dart';
import '../models/market/order_model.dart';
import '../widgets/market/condition_badge.dart';
import '../services/order_service.dart';
import '../models/market/cost_basis_entry.dart';
import '../widgets/card_image.dart';
import 'dispute_detail_screen.dart';
import 'wallet_screen.dart';
import '../services/wallet_service.dart';
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

  // Recently viewed cards (local, max 10)
  static const _recentlyViewedKey = 'recently_viewed_cards';
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
    final ids = prefs.getStringList(_recentlyViewedKey) ?? [];
    if (mounted) setState(() => _recentlyViewedIds = ids);
  }

  Future<void> _addRecentlyViewed(String cardId) async {
    _recentlyViewedIds.remove(cardId); // deduplicate
    _recentlyViewedIds.insert(0, cardId); // newest first
    if (_recentlyViewedIds.length > 10) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, 10);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentlyViewedKey, _recentlyViewedIds);
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

  bool _loadingHistory = false;

  /// Navigate to a card by its ID (called from other tabs, e.g. Social)
  void navigateToCardById(String cardId) {
    final card = _market.getPrice(cardId);
    if (card == null) return;
    _navigateToCard(card);
  }

  void _navigateToCard(CardPriceData card, {bool isFoil = false}) {
    _addRecentlyViewed(card.cardId);
    setState(() {
      _viewBeforeDetail = _view;
      _selectedCard = card;
      _selectedRange = '1M';
      _view = 'cardDetail';
      _detailShowFoil = isFoil;
      _loadingHistory = card.priceHistory.isEmpty;
    });
    widget.onFullscreenChanged?.call(true);
    resetScroll();

    // Lazy-load history from Firestore if not cached
    final hasCmId = _market.hasCmId(card.cardId);
    if (card.priceHistory.isEmpty && hasCmId) {
      debugPrint('MarketScreen: Loading history for ${card.cardName} (${card.cardId})');
      _market.loadHistory(card.cardId).then((_) {
        if (mounted && _selectedCard?.cardId == card.cardId) {
          final updated = _market.getPrice(card.cardId);
          debugPrint('MarketScreen: History loaded for ${card.cardName} — '
              'foil=${updated?.priceHistory.length ?? 0}, '
              'nf=${updated?.nonFoilHistory.length ?? 0}');
          setState(() {
            _selectedCard = updated ?? _selectedCard;
            _loadingHistory = false;
          });
        }
      });
    } else if (!hasCmId) {
      _loadingHistory = false;
    }
  }

  String _viewBeforeDetail = 'portfolio';

  void _goBack() {
    if (_view == 'cardDetail') {
      // Return to wherever we came from (discover, portfolio, etc.)
      setState(() {
        _selectedCard = null;
        _view = _viewBeforeDetail;
      });
      widget.onFullscreenChanged?.call(false);
    } else {
      // From any other view → back to portfolio
      setState(() {
        _selectedCard = null;
        _view = 'portfolio';
      });
      widget.onFullscreenChanged?.call(false);
    }
    resetScroll();
  }

  Widget _cardPlaceholder(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: AppRadius.baseBR,
    ),
    child: const Icon(Icons.style, size: 40, color: AppColors.textMuted),
  );

  /// Wraps a scrollable child with DragToDismiss for pull-to-dismiss.
  Widget _wrapWithDismiss(Widget child) {
    return DragToDismiss(
      onDismissed: _goBack,
      backgroundColor: AppColors.background,
      child: Column(children: [
        // Drag handle indicator
        Container(
          height: 36,
          color: AppColors.background,
          child: Center(child: Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 5,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
          )),
        ),
        Expanded(child: child),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_market.initialized) {
      return const Center(
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

    // Wallet FAB only on portfolio view
    final showWalletFab = !_isDemo &&
        _view != 'discover' &&
        _view != 'cardDetail' &&
        _view != 'listings' &&
        _view != 'orders';

    // Cart FAB on ALL Market views (except cardDetail)
    final showCartFab = !_isDemo &&
        _view != 'cardDetail' &&
        CartService.instance.totalItems > 0;

    if (!showWalletFab && !showCartFab) return content;

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
            bottom: (showWalletFab ? 133 : 68) + viewPadding.bottom,
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
                    borderRadius: BorderRadius.circular(AppRadius.iconButton),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Text('${CartService.instance.totalItems}',
                    style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textPrimary, letterSpacing: 0)),
                )),
              ]),
            ),
          ),
        if (showWalletFab)
          Positioned(
            right: AppSpacing.lg,
            bottom: 68 + viewPadding.bottom,
            child: _buildWalletFab(),
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

    // Sort by total value
    holdings.sort((a, b) => (b.unitPrice * b.quantity).compareTo(a.unitPrice * a.quantity));

    // Metric-aware sort value for gainers/losers
    double metricVal(_HoldingEntry h) => switch (_holdingsMetric) {
      HoldingsMetric.sincePurchaseRelative => h.cbChangePct,
      HoldingsMetric.sincePurchaseAbsolute => h.cbChangeAbs,
      HoldingsMetric.dayTrendRelative => h.dayChangePct,
      HoldingsMetric.dayTrendAbsolute => h.dayChangeAbs,
    };

    // Filter for sub-tabs
    final displayList = switch (_holdingsTab) {
      'gainers' => holdings.where((h) => metricVal(h) > 0).toList()
        ..sort((a, b) => metricVal(b).compareTo(metricVal(a))),
      'losers' => holdings.where((h) => metricVal(h) < 0).toList()
        ..sort((a, b) => metricVal(a).compareTo(metricVal(b))),
      _ => holdings,
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

          // Holdings section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionDivider(icon: Icons.wallet, label: 'YOUR HOLDINGS'),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Sub-tabs
          _buildHoldingsTabs(),
          const SizedBox(height: 6),

          // Metric selector (TR-style: right-aligned text link)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildMetricDropdown(),
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                child: CardPriceTile(
                  data: h.data,
                  quantity: h.quantity,
                  onTap: () => _navigateToCard(h.data, isFoil: h.isFoil),
                  showFoilStar: h.isFoil,

                  priceOverride: h.isFoil ? h.unitPrice : null,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
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

          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── CART VIEW ───
  // ═══════════════════════════════════════════

  // ═══════════════════════════════════════════


  Widget _buildWalletFab() {
    return ListenableBuilder(
      listenable: WalletService.instance,
      builder: (context, _) {
        final bal = WalletService.instance.balance;
        final label = '€${bal.availableEur.toStringAsFixed(2)}';

        return TweenAnimationBuilder<double>(
          key: const ValueKey('wallet-fab-anim'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.3 + value * 0.7,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black54,
                pageBuilder: (_, __, ___) => Material(
                  color: AppColors.background,
                  child: DragToDismiss(
                    onDismissed: () => Navigator.pop(context),
                    backgroundColor: AppColors.background,
                    child: SafeArea(
                      child: Column(children: [
                        Container(
                          height: 36,
                          color: AppColors.background,
                          child: Center(child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: 40, height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                        const Expanded(child: WalletScreen()),
                      ]),
                    ),
                  ),
                ),
                transitionsBuilder: (_, anim, __, child) =>
                    SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim), child: child),
              ),
            ),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.amber400,
                borderRadius: AppRadius.pillBR,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textPrimary, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(
                color: AppColors.amber400, shape: BoxShape.circle,
              )),
            ),
        ],
      ),
    );
  }

  Widget _buildHoldingsTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _holdingsTabPill('Holdings', 'holdings'),
          const SizedBox(width: 6),
          _holdingsTabPill('Gainers', 'gainers'),
          const SizedBox(width: 6),
          _holdingsTabPill('Losers', 'losers'),
        ],
      ),
    );
  }

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
          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
        ],
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
              const Icon(Icons.check, color: AppColors.textPrimary, size: 20),
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

    return _wrapWithDismiss(SingleChildScrollView(
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.loss.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.amber500.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amber500),
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

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ));
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
                    onOpenDispute: (id, reason, description) async {
                      final ok = await OrderService.instance.openDispute(id, reason, description: description);
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  decoration: const BoxDecoration(
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

    // Listing-level filters (condition, language, country)
    if (filter.conditions.isNotEmpty || filter.languages.isNotEmpty || filter.sellerCountry != null) {
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
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => _navigateToCard(card),
              child: SizedBox(
                width: 105,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card image (portrait ratio ~63:88)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: card.imageUrl != null
                          ? CardImage(
                              imageUrl: card.imageUrl,
                              fallbackText: card.cardName,
                              width: 105,
                              height: 147,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 105, height: 147,
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.style, color: AppColors.textMuted),
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

          // Missing cards banner
          if (_missingCardIds != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.amber400.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.iconButton),
                  border: Border.all(color: AppColors.amber400.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.style, size: 16, color: AppColors.amber400),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${_missingCardIds!.values.fold(0, (s, q) => s + q)} missing cards',
                    style: AppTextStyles.caption.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() { _missingCardIds = null; _searchResults = []; }),
                    child: const Icon(Icons.close, size: 16, color: AppColors.textMuted)),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Search bar + filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(children: [
              Expanded(child: MarketSearchBar(
                controller: _searchController,
                onChanged: (q) {
                  setState(() => _missingCardIds = null);
                  _refreshFilteredResults();
                },
              )),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterButton(),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quick-filter pills
          _buildQuickFilterPills(),
          const SizedBox(height: AppSpacing.sm),

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
                padding: EdgeInsets.only(top: AppSpacing.xl),
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
                decoration: const BoxDecoration(color: AppColors.loss, shape: BoxShape.circle),
                child: Center(child: Text('$count',
                    style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
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
                  color: AppColors.amber400.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillBR,
                  border: Border.all(color: AppColors.amber400.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(item.label, style: AppTextStyles.small.copyWith(color: AppColors.amber400)),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 12, color: AppColors.amber400),
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
            child: Text('Clear all', style: AppTextStyles.small.copyWith(
              color: AppColors.textMuted, fontWeight: FontWeight.w600)),
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

    final chartData = _filterByRange(
      card.isNonFoilOnly ? card.nonFoilHistory
          : card.isFoilOnly ? _getFoilOnlyChartData(card)
          : card.priceHistory,
      _selectedRange,
    );
    final liveListings = _listings.getListings(card.cardId);
    final listings = _isDemo
        ? ([...liveListings, ..._demoListings.where((l) => l.cardId == card.cardId)]
            ..sort((a, b) => a.price.compareTo(b.price)))
        : liveListings;

    // Buyable listings: exclude own, sort by total cost (price + shipping)
    final uid = AuthService.instance.uid;
    final buyerCountry = ProfileService.instance.ownProfile?.country;
    final buyableListings = listings
        .where((l) => l.sellerId != uid && l.availableQty > 0)
        .toList()
      ..sort((a, b) {
        final aCost = buyerCountry != null ? a.totalPriceFor(buyerCountry) : a.price;
        final bCost = buyerCountry != null ? b.totalPriceFor(buyerCountry) : b.price;
        final priceCmp = aCost.compareTo(bCost);
        if (priceCmp != 0) return priceCmp;
        // Same total price → prefer better condition
        return a.condition.index.compareTo(b.condition.index);
      });

    // Calculate change relative to selected range
    double rangeChangeAbs = card.dayChangeAbs;
    double rangeChangePct = card.dayChange;
    if (chartData.length >= 2) {
      final startPrice = chartData.first.price;
      final endPrice = chartData.last.price;
      rangeChangeAbs = endPrice - startPrice;
      rangeChangePct = startPrice > 0 ? (rangeChangeAbs / startPrice * 100) : 0;
    }
    final rangePositive = rangeChangeAbs >= 0;
    final changeColor = rangePositive ? AppColors.win : AppColors.loss;
    final changeSign = rangePositive ? '+' : '';

    final content = _wrapWithDismiss(SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 120, top: 36),
          child: Column(
            children: [
              // Card image (battlefields shown landscape via rotation)
              if (card.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Center(
                    child: ClipRRect(
                            borderRadius: AppRadius.baseBR,
                            child: CardImage(
                              imageUrl: card.imageUrl,
                              fallbackText: card.cardName,
                              width: card.isBattlefield ? 280 : 160,
                              height: card.isBattlefield ? 200 : 224,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // Name + set
              Text(
                card.cardName,
                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              if (card.setId != null || card.rarity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Builder(builder: (_) {
                    final riftCard = CardService.getLookup()[card.cardId];
                    final col = riftCard?.collectorNumber;
                    return Text(
                      [
                        if (card.setId != null) card.setId!.toUpperCase(),
                        if (col != null) col,
                        if (card.rarity != null) card.rarity!,
                      ].join(' · '),
                      style: AppTextStyles.small,
                    );
                  }),
                ),
              const SizedBox(height: AppSpacing.sm),

              // Price + change (relative to selected range)
              if (card.currentPrice == 0 && card.foilPrice == 0 && card.nonFoilPrice == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No price data available',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center),
                )
              else ...[
              // Show selected variant price (foil or non-foil)
              // Promo sets: always foil (standardPrice already returns foil via _isNonFoilStandard)
              Builder(builder: (_) {
                final showFoil = _detailShowFoil || card.isFoilOnly;
                final displayPrice = showFoil
                    ? (card.foilPrice > 0 ? card.foilPrice : card.currentPrice)
                    : (card.standardPrice > 0 ? card.standardPrice : card.currentPrice);
                return Text(
                  '€${displayPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.w900),
                );
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    rangePositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 18,
                    color: changeColor,
                  ),
                  Text(
                    '$changeSign€${rangeChangeAbs.abs().toStringAsFixed(2)} ($changeSign${rangeChangePct.toStringAsFixed(1)}%)',
                    style: AppTextStyles.captionBold.copyWith(
                      color: changeColor,
                    ),
                  ),
                ],
              ),

              // Variant price badges (foil + non-foil) — tappable
              // Toggle only for Common/Uncommon in base sets (both variants exist)
              if (card.showVariantToggle)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _detailShowFoil = false),
                        child: _variantBadge(
                          card.standardLabel,
                          card.standardPrice,
                          _detailShowFoil ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _detailShowFoil = true),
                        child: _variantBadge(
                          card.premiumLabel,
                          card.premiumPrice,
                          _detailShowFoil ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // Time range selector
              TimeRangeSelector(
                selected: _selectedRange,
                onChanged: (r) => setState(() => _selectedRange = r),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Price chart(s)
              if (_loadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.amber400,
                      ),
                    ),
                  ),
                )
              else ...[
                // Overlaid chart — active variant solid, inactive dimmed
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: PriceChart(
                    data: card.isNonFoilOnly
                        ? _filterByRange(card.nonFoilHistory, _selectedRange)
                        : card.isFoilOnly
                            ? _filterByRange(_getFoilOnlyChartData(card), _selectedRange)
                            : (_detailShowFoil
                                ? _getFoilChartData(card)
                                : _getStandardChartData(card)),
                    isPositive: rangePositive,
                    secondaryData: card.showVariantToggle
                        ? (_detailShowFoil
                            ? _getStandardChartData(card)
                            : _getPremiumChartData(card))
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.base),

              // Price overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: PriceOverviewCard(data: card, showFoil: _detailShowFoil || card.isFoilOnly),
              ),
              const SizedBox(height: AppSpacing.base),
              ], // end of price data section

              // Listings
              if (listings.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SectionDivider(icon: Icons.sell, label: 'LISTINGS (${listings.length})'),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...listings.map((l) {
                  final uid = AuthService.instance.uid;
                  final canBuy = l.sellerId != uid && l.availableQty > 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                    child: ListingTile(
                      listing: l,
                      onBuy: canBuy ? () => _openCheckoutSheet(l) : null,
                      onAddToCart: canBuy ? () => _addToCart(l) : null,
                    ),
                  );
                }),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: RiftrEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No Listings Yet',
                    subtitle: 'Be the first to list this card for sale',
                  ),
                ),
            ],
          ),
    ));

    final viewPadding = MediaQuery.of(context).viewPadding;

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        // Gradient fade behind buttons
        Positioned(
          left: 0, right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withValues(alpha: 0),
                    AppColors.surface,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Fixed Buy/Sell FABs
        Positioned(
          left: AppSpacing.base,
          right: AppSpacing.base,
          bottom: AppSpacing.base,
          child: Row(
            children: [
              Expanded(
                child: _buyButton(buyableListings.isNotEmpty ? buyableListings.first : null),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _sellButton(card),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _variantBadge(String label, double price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label  €${price.toStringAsFixed(2)}',
        style: AppTextStyles.tiny.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _myListingTile(MarketListing listing) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.baseBR,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Thumbnail
          SizedBox(
            width: 40,
            height: 56,
            child: Transform.scale(
              scale: 1.25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: CardImage(
                  imageUrl: listing.imageUrl,
                  fallbackText: listing.cardName,
                  width: 40,
                  height: 56,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.cardName,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ConditionBadge(condition: listing.condition),
                    if (listing.availableQty > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '×${listing.availableQty}',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '€${listing.price.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (listing.isPreRelease) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber400.withValues(alpha: 0.15),
                          borderRadius: AppRadius.pillBR,
                        ),
                        child: Text('PRE-ORDER',
                          style: AppTextStyles.micro.copyWith(
                            color: AppColors.amber400, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _cancelListing(listing),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.loss,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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

  Widget _sellButton(CardPriceData card) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openSellSheet(card);
      },
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.amber400,
          borderRadius: AppRadius.pillBR,
          boxShadow: [
            BoxShadow(
              color: AppColors.amber400.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sell_outlined, color: AppColors.background, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Sell',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buyButton(MarketListing? listing) {
    final canBuy = listing != null;
    final label = canBuy ? 'Buy €${listing.price.toStringAsFixed(2)}' : 'Buy';
    return GestureDetector(
      onTap: canBuy
          ? () {
              HapticFeedback.lightImpact();
              _openCheckoutSheet(listing);
            }
          : () {
              HapticFeedback.lightImpact();
              RiftrToast.info(context, 'No listings available');
            },
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: canBuy ? AppColors.win : AppColors.surfaceLight,
          borderRadius: AppRadius.pillBR,
          boxShadow: canBuy
              ? [
                  BoxShadow(
                    color: AppColors.win.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                color: canBuy ? AppColors.background : AppColors.textMuted,
                size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: canBuy ? AppColors.background : AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _openCheckoutSheet(MarketListing listing) async {
    final result = await Navigator.push<dynamic>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => _CheckoutFullScreen(listing: listing),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim), child: child),
      ),
    );

    if (!mounted) return;

    // Wallet purchase returns orderId string, demo returns 'demo-order'
    if (result is String) {
      RiftrToast.success(context, result == 'demo-order' ? 'Order placed (Demo Mode)' : 'Order placed!');
    }
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
          status: 'active',
          listedAt: DateTime.now(),
        ));
      });
      RiftrToast.sale(context, 'Listing created (Demo Mode)');
      return;
    }

    // Look up full card data for set/collector info
    final fullCard = CardService.getLookup()[card.cardId];

    final listingId = await _listings.createListing(
      cardId: card.cardId,
      cardName: card.cardName,
      imageUrl: card.imageUrl,
      condition: result['condition'] as CardCondition,
      price: result['price'] as double,
      quantity: quantity,
      insuredOnly: result['insuredOnly'] as bool? ?? false,
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
        final isFoil = FirestoreCollectionService.isFoilVariant(card.setId, card.rarity);
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
              const Text(
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
                        borderRadius: BorderRadius.circular(AppRadius.iconButton),
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

  Widget _comingSoonButton(String label, Color color) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: AppRadius.pillBR,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, color: color.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Coming Soon',
            style: AppTextStyles.bodyBold.copyWith(
              color: color.withValues(alpha: 0.4),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── HELPERS ───
  // ═══════════════════════════════════════════

  /// Best available history for foil-only cards: foil preferred, NF fallback
  /// (e.g. Nexus Night promos have NF-only history on Cardmarket)
  List<PricePoint> _getFoilOnlyChartData(CardPriceData card) {
    if (card.priceHistory.isNotEmpty) return card.priceHistory;
    return card.nonFoilHistory;
  }

  /// Standard variant chart data: nf history for Common/Uncommon, foil for Rare+
  List<PricePoint> _getStandardChartData(CardPriceData card) {
    // OGS: always non-foil history
    if (card.isNonFoilOnly) return _filterByRange(card.nonFoilHistory, _selectedRange);
    // Foil-only cards: foil history, NF fallback if foil empty
    if (card.isFoilOnly) return _filterByRange(_getFoilOnlyChartData(card), _selectedRange);
    final r = (card.rarity ?? '').toLowerCase();
    final isCommonUncommon = r == 'common' || r == 'uncommon';
    // Common/Uncommon standard = non-foil → use nonFoilHistory
    // Rare+ standard = foil → use priceHistory (foil)
    final data = isCommonUncommon && card.nonFoilHistory.isNotEmpty
        ? card.nonFoilHistory
        : card.priceHistory;
    return _filterByRange(data, _selectedRange);
  }

  /// Foil chart data (always uses foil/priceHistory)
  List<PricePoint> _getFoilChartData(CardPriceData card) {
    // priceHistory is the foil history; for Rare+ it's the standard
    // For Common/Uncommon, foil = priceHistory (premium)
    return _filterByRange(card.priceHistory, _selectedRange);
  }

  /// Premium variant chart data: foil for Common/Uncommon, nf for Rare+
  List<PricePoint> _getPremiumChartData(CardPriceData card) {
    final r = (card.rarity ?? '').toLowerCase();
    final isCommonUncommon = r == 'common' || r == 'uncommon';
    // Common/Uncommon premium = foil → use priceHistory (foil)
    // Rare+ premium = non-foil → use nonFoilHistory
    final data = isCommonUncommon
        ? card.priceHistory
        : card.nonFoilHistory;
    return _filterByRange(data, _selectedRange);
  }

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

  /// Day trend (c24)
  double get dayChangeAbs => data.dayChangeAbs * quantity;
  double get dayChangePct => data.dayChange;
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber400,
            ),
            child: const Icon(Icons.shopping_cart, color: AppColors.textPrimary, size: 24),
          ),
        );
      },
    );
  }
}

/// Full-screen checkout overlay with DragToDismiss.
class _CheckoutFullScreen extends StatelessWidget {
  final MarketListing listing;
  final List<CartCheckoutItem>? cartItems;

  const _CheckoutFullScreen({required this.listing, this.cartItems});

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: AppColors.background,
      child: DragToDismiss(
        onDismissed: () => Navigator.pop(context),
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: kb),
            child: Column(children: [
            Container(
              height: 36,
              color: AppColors.background,
              child: Center(child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
            Expanded(
              child: CheckoutSheet(
                listing: listing,
                cartItems: cartItems,
              ),
            ),
          ]),
          ),
        ),
      ),
    );
  }
}


