import 'package:flutter/material.dart';
import '../widgets/drag_to_dismiss.dart';
import '../theme/app_theme.dart';
import '../data/shipping_rates.dart';
import '../services/market_service.dart';
import '../services/listing_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import '../services/demo_service.dart';
import '../services/seller_service.dart';
import '../services/firestore_collection_service.dart';
import '../models/market/card_price_data.dart';
import '../models/market/listing_model.dart';
import '../models/market/price_point.dart';
import '../widgets/gold_header.dart';
import '../widgets/section_divider.dart';
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
import 'package:flutter_stripe/flutter_stripe.dart';
import '../widgets/market/condition_badge.dart';
import '../services/order_service.dart';
import '../models/market/cost_basis_entry.dart';
import '../widgets/card_image.dart';

/// Holdings metric display mode (Trade Republic-style)
enum HoldingsMetric {
  sincePurchaseRelative,  // Seit Kauf relativ (%)
  sincePurchaseAbsolute,  // Seit Kauf absolut (€)
  dayTrendRelative,       // Tagestrend relativ (%)
  dayTrendAbsolute,       // Tagestrend absolut (€)
}

class MarketScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  const MarketScreen({super.key, this.onFullscreenChanged});

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
  CardPriceData? _selectedCard;
  bool _detailShowFoil = false; // Whether detail page focuses on foil variant

  // Search
  final _searchController = TextEditingController();
  List<CardPriceData> _searchResults = [];

  String? _demoCountry; // Country selection stored locally in demo mode
  final List<MarketListing> _demoListings = []; // Local demo listings
  String _orderSubTab = 'purchases'; // 'purchases' | 'sales'

  // Cart: listingId → {listing, quantity}
  final Map<String, _CartEntry> _cart = {};
  int get _cartCount => _cart.values.fold(0, (sum, e) => sum + e.quantity);
  String? get _cartSellerId =>
      _cart.isNotEmpty ? _cart.values.first.listing.sellerId : null;

  bool get _isDemo => DemoService.instance.isActive;
  MarketService get _market => MarketService.instance;
  ListingService get _listings => ListingService.instance;

  void resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void initState() {
    super.initState();
    _market.addListener(_refresh);
    _listings.addListener(_refresh);
    OrderService.instance.addListener(_refresh);
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
    super.dispose();
  }

  bool _loadingHistory = false;

  void _navigateToCard(CardPriceData card, {bool isFoil = false}) {
    setState(() {
      _selectedCard = card;
      _selectedRange = '1M';
      _view = 'cardDetail';
      _detailShowFoil = isFoil;
      _loadingHistory = card.priceHistory.isEmpty;
    });
    widget.onFullscreenChanged?.call(true);
    resetScroll();

    // Lazy-load history from Firestore if not cached
    if (card.priceHistory.isEmpty) {
      _market.loadHistory(card.cardId).then((_) {
        if (mounted && _selectedCard?.cardId == card.cardId) {
          setState(() {
            _selectedCard = _market.getPrice(card.cardId);
            _loadingHistory = false;
          });
        }
      });
    }
  }

  void _goBack() {
    setState(() {
      _selectedCard = null;
      _view = 'portfolio';
    });
    widget.onFullscreenChanged?.call(false);
    resetScroll();
  }

  Widget _cardPlaceholder(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: 12),
            Text('Loading market data...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return switch (_view) {
      'discover' => _buildDiscover(),
      'cardDetail' => _buildCardDetail(),
      'listings' => _buildMyListings(),
      'orders' => _buildOrders(),
      'cart' => _buildCart(),
      _ => _buildPortfolio(),
    };
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
      final price = _market.getPrice(cardId);
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

    // Chart data filtered by range (plots totalValue over time)
    final chartData = _filterByRange(portfolio.valueHistory, _selectedRange);

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
          const SizedBox(height: 8),

          // Portfolio header: value + performance (color based on PERFORMANCE)
          PortfolioHeader(
            snapshot: portfolio,
            changeAbs: perfAbs,
            changePercent: perfPct,
            isPositive: perfPositive,
          ),
          const SizedBox(height: 12),

          // Time range selector
          TimeRangeSelector(
            selected: _selectedRange,
            onChanged: (r) => setState(() => _selectedRange = r),
          ),
          const SizedBox(height: 8),

          // Portfolio chart (line = totalValue, color = performance)
          PortfolioChart(
            data: chartData,
            isPositive: perfPositive,
          ),
          const SizedBox(height: 16),

          // View toggle: Portfolio / Discover
          _buildViewToggle(),
          const SizedBox(height: 12),

          // Holdings section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionDivider(icon: Icons.wallet, label: 'YOUR HOLDINGS'),
          ),
          const SizedBox(height: 4),

          // Sub-tabs
          _buildHoldingsTabs(),
          const SizedBox(height: 6),

          // Metric selector (TR-style: right-aligned text link)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildMetricDropdown(),
            ),
          ),
          const SizedBox(height: 6),

          // Holdings list
          if (displayList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _holdingsTab == 'holdings'
                    ? 'Add cards to your collection to see their value here.'
                    : 'No ${_holdingsTab} today.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...displayList.map((h) {
              final changeText = _formatMetricValue(h);
              final isPositive = metricVal(h) >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
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

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── CART VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildCart() {
    final entries = _cart.values.toList();
    final subtotal = entries.fold(0.0, (sum, e) => sum + e.listing.price * e.quantity);

    return _wrapWithDismiss(SingleChildScrollView(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldOrnamentHeader(title: 'CART'),
          const SizedBox(height: 8),
          _buildViewToggle(),
          const SizedBox(height: 16),

          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 32, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Cart is empty',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add cards from the listing page to your cart.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Seller info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'from ${entries.first.listing.sellerName}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),

            // Cart items
            ...entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.listing.cardName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ConditionBadge(condition: entry.listing.condition),
                              const SizedBox(width: 8),
                              Text(
                                '×${entry.quantity}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '€${(entry.listing.price * entry.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _cart.remove(entry.listing.id)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.loss.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.close, size: 12, color: AppColors.loss),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),

            // Subtotal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '€${subtotal.toStringAsFixed(2)} + shipping',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Checkout + Clear buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _cart.clear()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.loss.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.loss.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: AppColors.loss, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openCartCheckout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.win.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.win.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Checkout €${subtotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.win,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    ));
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _toggleButton('Listings', _view == 'listings', () {
            setState(() { _view = 'listings'; });
            widget.onFullscreenChanged?.call(true);
            resetScroll();
          }),
          const SizedBox(width: 8),
          _toggleButton('Orders', _view == 'orders', () {
            setState(() { _view = 'orders'; });
            widget.onFullscreenChanged?.call(true);
            resetScroll();
          }),
          const SizedBox(width: 8),
          _toggleButton('Discover', _view == 'discover', () {
            setState(() { _view = 'discover'; });
            widget.onFullscreenChanged?.call(true);
            resetScroll();
          }),
          if (_cart.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() { _view = 'cart'; });
                widget.onFullscreenChanged?.call(true);
                resetScroll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _view == 'cart' ? AppColors.amber600 : AppColors.amber500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _view == 'cart' ? AppColors.amber600 : AppColors.amber500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 12,
                      color: _view == 'cart' ? Colors.white : AppColors.amber500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_cartCount',
                      style: TextStyle(
                        color: _view == 'cart' ? Colors.white : AppColors.amber500,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.amber600 : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppColors.amber600 : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingsTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    final active = _holdingsTab == value;
    return GestureDetector(
      onTap: () => setState(() => _holdingsTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.amber600 : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.amber600 : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Metric',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _metricSheetLabel(m),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 20),
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
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldOrnamentHeader(title: 'MY LISTINGS'),
          const SizedBox(height: 8),
          _buildViewToggle(),
          const SizedBox(height: 16),

          // Strike / Suspension banner
          if (!_isDemo) ...[
            Builder(builder: (_) {
              final profile = SellerService.instance.profile;
              if (profile == null) return const SizedBox.shrink();
              if (profile.suspended) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.loss.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.block, size: 14, color: AppColors.loss),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your seller account is suspended. You cannot create new listings.',
                            style: TextStyle(color: AppColors.loss, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (profile.strikes > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amber500.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amber500),
                        const SizedBox(width: 8),
                        Text(
                          'Strikes: ${profile.strikes}/3 — Ship orders on time to avoid suspension.',
                          style: const TextStyle(color: AppColors.amber500, fontSize: 11, fontWeight: FontWeight.w600),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionDivider(
              icon: Icons.sell_outlined,
              label: 'MY LISTINGS (${myListings.length})',
            ),
          ),
          const SizedBox(height: 8),

          if (myListings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sell_outlined, size: 32, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No active listings',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Go to a card and tap "Sell" to create your first listing.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...myListings.map((l) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: _myListingTile(l),
                )),

          const SizedBox(height: 32),
        ],
      ),
    ));
  }

  // ═══════════════════════════════════════════
  // ─── BIDS VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildOrders() {
    final orders = _orderSubTab == 'purchases'
        ? OrderService.instance.purchases
        : OrderService.instance.sales;
    final role = _orderSubTab == 'purchases' ? OrderRole.buyer : OrderRole.seller;

    return _wrapWithDismiss(SingleChildScrollView(
      padding: const EdgeInsets.only(top: 36, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldOrnamentHeader(title: 'ORDERS'),
          const SizedBox(height: 8),
          _buildViewToggle(),
          const SizedBox(height: 12),

          // Purchases / Sales sub-tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _orderSubTabButton('Purchases', 'purchases'),
                const SizedBox(width: 8),
                _orderSubTabButton('Sales', 'sales'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      _orderSubTab == 'purchases'
                          ? Icons.shopping_bag_outlined
                          : Icons.sell_outlined,
                      size: 32,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _orderSubTab == 'purchases'
                          ? 'No purchases yet'
                          : 'No sales yet',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...orders.map((order) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: OrderTile(
                    order: order,
                    role: role,
                    onMarkShipped: (id, tracking) async {
                      final ok = await OrderService.instance.markShipped(id, tracking);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Marked as shipped' : 'Failed to mark shipped'),
                          backgroundColor: ok ? AppColors.win : AppColors.loss,
                        ));
                      }
                    },
                    onConfirmDelivery: (id) async {
                      final ok = await OrderService.instance.confirmDelivery(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Delivery confirmed!' : 'Failed to confirm'),
                          backgroundColor: ok ? AppColors.win : AppColors.loss,
                        ));
                      }
                    },
                    onCancel: (id) async {
                      final ok = await OrderService.instance.cancelOrder(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Order cancelled' : 'Failed to cancel'),
                          backgroundColor: ok ? AppColors.amber500 : AppColors.loss,
                        ));
                      }
                    },
                    onOpenDispute: (id, reason) async {
                      final ok = await OrderService.instance.openDispute(id, reason);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Dispute opened' : 'Failed to open dispute'),
                          backgroundColor: ok ? AppColors.amber500 : AppColors.loss,
                        ));
                      }
                    },
                  ),
                )),
        ],
      ),
    ));
  }

  Widget _orderSubTabButton(String label, String value) {
    final active = _orderSubTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _orderSubTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.win.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.win.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppColors.win : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── DISCOVER VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildDiscover() {
    return _wrapWithDismiss(SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100, top: 36),
      child: Column(
        children: [
          const GoldOrnamentHeader(title: 'DISCOVER'),
          const SizedBox(height: 8),

          // View toggle
          _buildViewToggle(),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MarketSearchBar(
              controller: _searchController,
              onChanged: (q) {
                setState(() {
                  _searchResults = _market.search(q);
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Search results or browse
          if (_searchController.text.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_searchResults.length} results',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._searchResults.take(50).map((card) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: CardPriceTile(
                    data: card,
                    onTap: () => _navigateToCard(card),
                  ),
                )),
          ] else ...[
            // Trending
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionDivider(icon: Icons.local_fire_department, label: 'TRENDING'),
            ),
            const SizedBox(height: 4),
            GainersLosersList(
              cards: _market.trending,
              isGainers: true,
              onCardTap: _navigateToCard,
            ),
            const SizedBox(height: 16),

            // Top Gainers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionDivider(icon: Icons.trending_up, label: 'TOP GAINERS'),
            ),
            const SizedBox(height: 4),
            ..._market.topGainers.map((card) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: CardPriceTile(
                    data: card,
                    onTap: () => _navigateToCard(card),
                  ),
                )),
            const SizedBox(height: 16),

            // Top Losers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionDivider(icon: Icons.trending_down, label: 'TOP LOSERS'),
            ),
            const SizedBox(height: 4),
            ..._market.topLosers.map((card) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: CardPriceTile(
                    data: card,
                    onTap: () => _navigateToCard(card),
                  ),
                )),
          ],
        ],
      ),
    ));
  }

  // ═══════════════════════════════════════════
  // ─── CARD DETAIL VIEW ───
  // ═══════════════════════════════════════════

  Widget _buildCardDetail() {
    final card = _selectedCard;
    if (card == null) return const SizedBox.shrink();

    final chartData = _filterByRange(card.priceHistory, _selectedRange);
    final liveListings = _listings.getListings(card.cardId);
    final listings = _isDemo
        ? [...liveListings, ..._demoListings.where((l) => l.cardId == card.cardId)]
        : liveListings;

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

    return _wrapWithDismiss(SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, top: 36),
          child: Column(
            children: [
              // Card image (battlefields shown landscape via rotation)
              if (card.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 12),

              // Name + set
              Text(
                card.cardName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              if (card.setId != null || card.rarity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [if (card.setId != null) card.setId!.toUpperCase(), if (card.rarity != null) card.rarity!]
                        .join(' · '),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 8),

              // Price + change (relative to selected range)
              // Show selected variant price (foil or non-foil)
              Builder(builder: (_) {
                final displayPrice = _detailShowFoil
                    ? (card.foilPrice > 0 ? card.foilPrice : card.currentPrice)
                    : (card.standardPrice > 0 ? card.standardPrice : card.currentPrice);
                return Text(
                  '€${displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
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
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              // Variant price badges (foil + non-foil) — tappable
              if (card.hasBothVariants)
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
                          _detailShowFoil ? AppColors.textMuted : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _detailShowFoil = true),
                        child: _variantBadge(
                          card.premiumLabel,
                          card.premiumPrice,
                          _detailShowFoil ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Time range selector
              TimeRangeSelector(
                selected: _selectedRange,
                onChanged: (r) => setState(() => _selectedRange = r),
              ),
              const SizedBox(height: 8),

              // Price chart(s)
              if (_loadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PriceChart(
                    data: _detailShowFoil
                        ? _getFoilChartData(card)
                        : _getStandardChartData(card),
                    isPositive: rangePositive,
                    secondaryData: card.hasBothVariants
                        ? (_detailShowFoil
                            ? _getStandardChartData(card)
                            : _getPremiumChartData(card))
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Price overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PriceOverviewCard(data: card, showFoil: _detailShowFoil),
              ),
              const SizedBox(height: 16),

              // Listings
              if (listings.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionDivider(icon: Icons.sell, label: 'LISTINGS (${listings.length})'),
                ),
                const SizedBox(height: 4),
                ...listings.map((l) {
                  final uid = AuthService.instance.uid;
                  final canBuy = l.sellerId != uid && l.availableQty > 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    child: ListingTile(
                      listing: l,
                      onBuy: canBuy ? () => _openCheckoutSheet(l) : null,
                      onAddToCart: canBuy ? () => _addToCart(l) : null,
                    ),
                  );
                }),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.storefront_outlined, size: 28, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No listings yet',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Buy/Sell buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: listings.isNotEmpty
                          ? _buyButton(listings.first)
                          : _comingSoonButton('Buy', AppColors.win),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sellButton(card),
                    ),
                  ],
                ),
              ),
            ],
          ),
    ));
  }

  Widget _variantBadge(String label, double price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label  €${price.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _myListingTile(MarketListing listing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.cardName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ConditionBadge(condition: listing.condition),
                    if (listing.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '×${listing.quantity}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '€${listing.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _cancelListing(listing),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.loss,
                  fontSize: 11,
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Listing?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Remove ${listing.cardName} (€${listing.price.toStringAsFixed(2)}) from the marketplace?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Listing', style: TextStyle(color: AppColors.loss)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (_isDemo) {
      setState(() => _demoListings.removeWhere((l) => l.id == listing.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing cancelled (Demo Mode)'),
          backgroundColor: AppColors.win,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await _listings.cancelListing(listing.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Listing cancelled' : 'Failed to cancel'),
        backgroundColor: success ? AppColors.win : AppColors.loss,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _sellButton(CardPriceData card) {
    return GestureDetector(
      onTap: () => _openSellSheet(card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.amber500.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber500.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Sell',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.amber400,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buyButton(MarketListing listing) {
    final uid = AuthService.instance.uid;
    final canBuy = listing.sellerId != uid && listing.availableQty > 0;
    return GestureDetector(
      onTap: canBuy ? () => _openCheckoutSheet(listing) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: canBuy
              ? AppColors.win.withValues(alpha: 0.15)
              : AppColors.textMuted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canBuy
                ? AppColors.win.withValues(alpha: 0.3)
                : AppColors.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          'Buy €${listing.price.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: canBuy ? AppColors.win : AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _addToCart(MarketListing listing) {
    // All cart items must be from the same seller
    if (_cart.isNotEmpty && _cartSellerId != listing.sellerId) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart cleared — different seller.'),
          backgroundColor: AppColors.amber500,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      final existing = _cart[listing.id];
      if (existing != null) {
        if (existing.quantity < listing.availableQty) {
          existing.quantity++;
        }
      } else {
        _cart[listing.id] = _CartEntry(listing: listing);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart ($_cartCount items)'),
        backgroundColor: AppColors.win,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openCartCheckout() async {
    if (_cart.isEmpty) return;

    // Use first listing for the checkout sheet (seller info stays the same)
    final entries = _cart.values.toList();
    final firstListing = entries.first.listing;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutSheet(
        listing: firstListing,
        cartItems: entries.map((e) => CartCheckoutItem(
          listing: e.listing,
          quantity: e.quantity,
        )).toList(),
      ),
    );

    if (!mounted) return;

    if (result is String) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed (Demo Mode)'),
          backgroundColor: AppColors.win,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (result is CheckoutResult) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: result.clientSecret,
            merchantDisplayName: 'Riftr',
            style: ThemeMode.dark,
            returnURL: 'riftr://stripe-redirect',
          ),
        );

        await Stripe.instance.presentPaymentSheet();
        if (!mounted) return;

        // Confirm payment with backend (updates order to "paid")
        await OrderService.instance.confirmPayment(result.orderId);

        if (!mounted) return;
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Order placed.'),
            backgroundColor: AppColors.win,
            duration: Duration(seconds: 3),
          ),
        );
      } on StripeException catch (e) {
        await OrderService.instance.cancelOrder(result.orderId);
        if (!mounted) return;
        if (e.error.code == FailureCode.Canceled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: AppColors.textMuted,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${e.error.localizedMessage}'),
              backgroundColor: AppColors.loss,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _openCheckoutSheet(MarketListing listing) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutSheet(listing: listing),
    );

    if (!mounted) return;

    // Demo mode returns a string
    if (result is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed (Demo Mode)'),
          backgroundColor: AppColors.win,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Real mode: CheckoutSheet returns CheckoutResult with clientSecret.
    // Init + present PaymentSheet both from this parent context.
    if (result is CheckoutResult) {
      try {
        // Wait for bottom sheet dismiss animation to fully complete
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        debugPrint('Stripe: initPaymentSheet from parent...');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: result.clientSecret,
            merchantDisplayName: 'Riftr',
            style: ThemeMode.dark,
            returnURL: 'riftr://stripe-redirect',
          ),
        );
        debugPrint('Stripe: initPaymentSheet DONE, presenting...');

        await Stripe.instance.presentPaymentSheet();
        debugPrint('Stripe: presentPaymentSheet DONE — payment success');
        if (!mounted) return;

        // Confirm payment with backend (updates order to "paid")
        await OrderService.instance.confirmPayment(result.orderId);
        debugPrint('Stripe: confirmPayment DONE — order marked as paid');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Order placed.'),
            backgroundColor: AppColors.win,
            duration: Duration(seconds: 3),
          ),
        );
      } on StripeException catch (e) {
        debugPrint('Stripe PaymentSheet error: ${e.error.localizedMessage}');
        // Release reservation on cancel/failure
        await OrderService.instance.cancelOrder(result.orderId);
        debugPrint('Order ${result.orderId} cancelled — reservation released');
        if (!mounted) return;
        // User cancelled is not an error
        if (e.error.code == FailureCode.Canceled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: AppColors.textMuted,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${e.error.localizedMessage}'),
              backgroundColor: AppColors.loss,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('PaymentSheet unexpected error: $e');
        // Release reservation on unexpected failure
        await OrderService.instance.cancelOrder(result.orderId);
        debugPrint('Order ${result.orderId} cancelled — reservation released');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: AppColors.loss,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openSellSheet(CardPriceData card) async {
    // Gate: Suspended sellers cannot create listings
    if (!_isDemo) {
      final profile = SellerService.instance.profile;
      if (profile != null && profile.suspended) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Your seller account is suspended. You cannot create listings.'),
            backgroundColor: AppColors.loss,
          ));
        }
        return;
      }
    }

    // Gate: Seller must complete onboarding (name, email, address + verification)
    final needsOnboarding = _isDemo
        ? _demoCountry == null
        : !SellerService.instance.isReady;

    if (needsOnboarding) {
      final completed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SellerOnboardingSheet(),
      );
      if (completed != true || !mounted) return;
      // In demo mode, grab country from the onboarding sheet result
      if (_isDemo) {
        _demoCountry = 'DE'; // Default for demo after onboarding
      }
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellSheet(
        cardName: card.cardName,
        imageUrl: card.imageUrl,
        suggestedPrice: card.currentPrice,
      ),
    );
    if (result == null || !mounted) return;

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
          quantity: result['quantity'] as int,
          insuredOnly: result['insuredOnly'] as bool? ?? false,
          status: 'active',
          listedAt: DateTime.now(),
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing created (Demo Mode)'),
          backgroundColor: AppColors.win,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final listingId = await _listings.createListing(
      cardId: card.cardId,
      cardName: card.cardName,
      imageUrl: card.imageUrl,
      condition: result['condition'] as CardCondition,
      price: result['price'] as double,
      quantity: result['quantity'] as int,
      insuredOnly: result['insuredOnly'] as bool? ?? false,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          listingId != null ? 'Listed for sale!' : 'Failed to create listing',
        ),
        backgroundColor: listingId != null ? AppColors.win : AppColors.loss,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _showCountryPicker() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Your Country',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Used to calculate shipping costs for buyers.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ShippingRates.countries.entries.map((entry) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comingSoonButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Coming Soon',
            style: TextStyle(
              color: color.withValues(alpha: 0.25),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ─── HELPERS ───
  // ═══════════════════════════════════════════

  /// Standard variant chart data: nf history for Common/Uncommon, foil for Rare+
  List<PricePoint> _getStandardChartData(CardPriceData card) {
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

class _CartEntry {
  final MarketListing listing;
  int quantity;
  _CartEntry({required this.listing, this.quantity = 1});
}
