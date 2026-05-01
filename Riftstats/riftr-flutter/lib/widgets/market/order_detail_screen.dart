import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/shipping_rates.dart';
import '../../models/market/order_model.dart';
import '../../screens/legal_screen.dart';
import '../../services/order_service.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import '../drag_to_dismiss.dart';
import '../riftr_drag_handle.dart';
import '../section_divider.dart';
import 'first_seller_modal.dart';
import 'order_item_tile.dart';
import 'order_price_summary.dart';
import 'order_tile.dart';
import 'order_timeline.dart';
import 'refund_path_choice_sheet.dart';
import 'seller_imprint_card.dart';
import 'seller_status_badge.dart';
import 'widerruf_modal.dart';
import '../../screens/seller_reviews_screen.dart';
import '../riftr_toast.dart';

/// Full-screen order detail with DragToDismiss.
///
/// Opened via Navigator.push from OrderTile.
/// Shows: Timeline → Items → Price → Shipping → Order Info.
/// Action buttons fixed at bottom.
class OrderDetailScreen extends StatefulWidget {
  final MarketOrder order;
  final OrderRole role;
  final Future<void> Function(String orderId, String tracking)? onMarkShipped;
  final Future<void> Function(String orderId)? onConfirmDelivery;
  final Future<void> Function(String orderId)? onCancel;
  /// Opens a dispute. Optional Audit-Felder (Discogs-Modell, 2026-05-01)
  /// für den Widerrufsrechts-Hinweis-Dialog. Siehe OrderTile-Doc.
  final Future<void> Function(
    String orderId,
    String reason,
    String description, {
    String reasonCodeChoice,
    DateTime? widerrufHinweisShownAt,
    DateTime? widerrufHinweisChosenAt,
  })? onOpenDispute;
  final Future<void> Function(
          String orderId, int rating, String comment, List<String> tags)?
      onSubmitReview;
  final VoidCallback? onViewDispute;
  /// Called when the user taps the Seller section-card (buyer view).
  /// The Order Detail screen will close itself, then invoke this callback
  /// so the host (MarketScreen) can switch to Discover with a seller filter.
  final void Function(String sellerId, String sellerName)? onViewSellerListings;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.role,
    this.onMarkShipped,
    this.onConfirmDelivery,
    this.onCancel,
    this.onOpenDispute,
    this.onSubmitReview,
    this.onViewDispute,
    this.onViewSellerListings,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _loadingAction;
  bool get _loading => _loadingAction != null;
  late MarketOrder _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;

    // Phase 7: First-Time-Seller-Modal — bei erstem paid-Sale onboarding
    // anzeigen. maybeShow prueft alle Conditions (Seller-Role, Status,
    // totalSales==0, Modal-not-shown-yet) und ist idempotent. Post-frame
    // damit Dialog nach Initial-Render aufgeht (vermeidet schwarzes Flicker).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPaidOrLater = _order.status == OrderStatus.paid ||
          _order.status == OrderStatus.shipped ||
          _order.status == OrderStatus.delivered ||
          _order.status == OrderStatus.autoCompleted;
      // effectiveDelayDays via toJson() lesen (Field optional in Model)
      int delayDays = 7;
      try {
        final raw = (_order.toJson()['effectiveDelayDays'] as num?)?.toInt();
        if (raw != null && raw > 0 && raw <= 30) delayDays = raw;
      } catch (_) {}
      FirstSellerModal.maybeShow(
        context,
        isSellerView: widget.role == OrderRole.seller,
        isPaidOrLater: isPaidOrLater,
        delayDays: delayDays,
      );
    });
  }

  MarketOrder get order => _order;
  OrderRole get role => widget.role;

  Future<void> _performAction(
      String actionLabel, Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loadingAction = actionLabel);
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stack pattern (mirrors card_preview.dart):
    //   Layer 1: DragToDismiss > scrollable content
    //   Layer 2: Gradient fade (surface → transparent), pointer-through
    //   Layer 3: Pinned action bar at bottom
    // Action bar lives OUTSIDE DragToDismiss so swipes don't move it,
    // and outside the scroll view so it stays pinned. SafeArea wraps
    // the whole stack — bottom of buttons sits above the home indicator.
    final content = DragToDismiss(
      onDismissed: () => Navigator.of(context).pop(),
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Drag handle — canonical fullscreen variant (40×5 textPrimary)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
          ),
          // Scrollable content. Bottom padding 120 = pinned-buttons-clearance.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0, AppSpacing.base, 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Status badge + order ID
                  _buildHeader(),
                  // Cancel request banner — V2 §2c: banner radius = rounded (8dp).
                  // Banner-Pair: amberMuted bg + amberBorderMuted border (canonical pair).
                  if (order.cancelRequested && role == OrderRole.seller) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.amberMuted,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        border: Border.all(color: AppColors.amberBorderMuted),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.amber500, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(
                            order.cancelReason != null
                                ? 'Cancel requested: ${order.cancelReason}'
                                : 'Buyer requested cancellation',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.amber500, fontWeight: FontWeight.w600))),
                        ]),
                        if (order.cancelNote != null && order.cancelNote!.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 4, left: 26),
                            child: Text('"${order.cancelNote}"',
                              style: AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),

                  // Timeline
                  OrderTimeline(order: order),
                  const SizedBox(height: AppSpacing.lg),

                  // Items
                  const SectionDivider(icon: Icons.style, label: 'Items'),
                  _buildItemsSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Price summary
                  const SectionDivider(icon: Icons.euro_symbol, label: 'Price'),
                  RiftrCard(
                    child: OrderPriceSummary(order: order, role: role),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Shipping / Address
                  _buildShippingSection(),

                  // Dispute info
                  if (order.status == OrderStatus.disputed &&
                      order.disputeReason != null)
                    _buildDisputeInfo(),

                  // Rating display
                  if (order.buyerRating != null) _buildRatingDisplay(),

                  // Order info
                  const SectionDivider(icon: Icons.receipt_long_outlined, label: 'Order Info'),
                  RiftrCard(
                    child: Column(
                      children: [
                        _infoRow('Order', order.id.substring(0, 8).toUpperCase()),
                        _infoRow(
                            'Ordered', _formatDateTime(order.createdAt)),
                        if (order.paidAt != null)
                          _infoRow('Paid', _formatDateTime(order.paidAt!)),
                        if (order.shippedAt != null)
                          _infoRow('Shipped', _formatDateTime(order.shippedAt!)),
                        if (order.deliveredAt != null)
                          _infoRow(
                              'Delivered', _formatDateTime(order.deliveredAt!)),
                      ],
                    ),
                  ),
                  // Widerrufsbelehrungs-Link — nur Buyer-View bei gewerblichem
                  // Verkäufer (Anhang 1 zur AGB, § 312g BGB). Pflicht-Hinweis
                  // unmittelbar in der Bestellbestätigung.
                  if (role == OrderRole.buyer && order.sellerIsCommercial) ...[
                    const SizedBox(height: AppSpacing.sm),
                    RiftrCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WiderrufsbelehrungScreen(),
                        ),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.gavel_outlined,
                              size: 20, color: AppColors.amber400),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Right of withdrawal',
                                  style: AppTextStyles.bodyBold.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '14-day right of withdrawal (§ 312g BGB) '
                                  '— commercial seller',
                                  style: AppTextStyles.tiny.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 20, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Counterparty info
                  _buildCounterpartySection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // GestureDetector(translucent) provides global tap-to-unfocus for
      // the dispute-reason / tracking / notes TextFields (this screen has
      // 5). Sits outside DragToDismiss so the drag-arena isn't disturbed.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: scrollable content with drag-to-dismiss.
            content,

            // Layer 2: gradient fade — content fades smoothly behind the
            // No gradient fade — reads as a shadow under the action bar.
            // Layer 3: pinned action bar — outside DragToDismiss so swipes
            // don't move it, outside the scroll view so it stays visible.
            // SafeArea-bottom is already applied by the outer SafeArea, so
            // `bottom: AppSpacing.base` sits 16dp above the home indicator.
            if (_hasActions)
              Positioned(
                left: AppSpacing.base,
                right: AppSpacing.base,
                bottom: AppSpacing.base,
                child: Row(children: _buildActionButtons()),
              ),
          ],
        ),
      ),
      ), // close GestureDetector
    );
  }

  // ── Header ──────────────────────────────────────────

  /// Counterparty id for profile navigation.
  /// Buyer view → sellerId, Seller view → buyerId.
  String? get _counterpartyId =>
      role == OrderRole.buyer ? order.sellerId : order.buyerId;

  /// Display name for the counterparty. Falls back to a generic role label.
  String get _counterpartyName => role == OrderRole.buyer
      ? (order.sellerName ?? 'Seller')
      : (order.buyerName ?? 'Buyer');

  /// Open the counterparty's reviews/profile screen.
  /// For a buyer tapping their seller: shows seller reviews as expected.
  /// For a seller tapping their buyer: reuses the same screen — empty if
  /// the buyer has never sold anything, otherwise their seller-side reviews.
  void _openCounterpartyProfile(BuildContext context, String id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerReviewsScreen(sellerId: id, sellerName: name),
      ),
    );
  }

  /// Tappable name with chevron — matches listing_tile.dart seller-name pattern.
  /// `style` applies to the text; chevron size tracks the font-size subtly.
  Widget _tappableName({
    required String name,
    required String? id,
    required TextStyle style,
    double chevronSize = 14,
  }) {
    final text = Text(
      name,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (id == null || id.isEmpty) return text;
    return GestureDetector(
      onTap: () => _openCounterpartyProfile(context, id, name),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: text),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right,
              size: chevronSize, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final roleLabel = role == OrderRole.buyer ? 'from' : 'to';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.items.length > 1
                    ? '${order.cardName} +${order.items.length - 1} more'
                    : order.cardName,
                // V2 §4: titleLarge (22sp) for "Card name in detail view".
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w900),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // "from/to {name}" — name is tappable → counterparty profile.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$roleLabel ',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  Flexible(
                    child: _tappableName(
                      name: _counterpartyName,
                      id: _counterpartyId,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      chevronSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _statusBadge(order.status),
      ],
    );
  }

  // ── Items ───────────────────────────────────────────

  Widget _buildItemsSection() {
    return RiftrCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (int i = 0; i < order.items.length; i++) ...[
            if (i > 0)
              Divider(color: AppColors.border, height: 1),
            OrderItemTile(item: order.items[i]),
          ],
        ],
      ),
    );
  }

  // ── Shipping ────────────────────────────────────────

  Widget _buildShippingSection() {
    if (role == OrderRole.seller && order.shippingAddress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionDivider(icon: Icons.local_shipping_outlined, label: 'Ship to'),
          RiftrCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipient name for shipping label — tappable → buyer profile.
                if (_recipientName != null) ...[
                  _tappableName(
                    name: _recipientName!,
                    id: order.buyerId,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    chevronSize: 16,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  _formatAddress(order.shippingAddress!),
                  style: AppTextStyles.body.copyWith(
                      height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                _infoRow('Method', order.shippingMethod.label),
                if (order.trackingNumber != null &&
                    order.trackingNumber!.isNotEmpty)
                  _trackingRow(order.trackingNumber!)
                else if (role == OrderRole.seller &&
                    order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.autoCompleted)
                  // 44dp touch-target (Apple HIG) wraps the visual icon+label.
                  GestureDetector(
                    onTap: () => _showEditTrackingDialog(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 14, color: AppColors.amber500),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Add tracking number',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.amber500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Auto-release countdown — V2 §2c banner: rounded (8dp).
                // Canonical pair: amberMuted bg + amberBorderMuted border.
                if (order.status == OrderStatus.shipped &&
                    order.autoReleaseAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.amberMuted,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        border: Border.all(color: AppColors.amberBorderMuted),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: AppColors.amber500),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Auto-confirmed in ${order.autoReleaseAt!.difference(DateTime.now()).inDays} days',
                              style: AppTextStyles.small
                                  .copyWith(color: AppColors.amber500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Pre-release countdown — same banner pattern as auto-release.
                if (order.isPreReleaseBlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.amberMuted,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        border: Border.all(color: AppColors.amberBorderMuted),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: AppColors.amber500),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: Builder(builder: (_) {
                            final rd = DateTime.parse(order.preReleaseDate!);
                            final days =
                                rd.difference(DateTime.now()).inDays;
                            return Text(
                              'Ships after ${order.preReleaseDate} ($days days)',
                              style: AppTextStyles.small
                                  .copyWith(color: AppColors.amber500),
                            );
                          })),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    // Buyer: show seller address + shipping method + tracking
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seller address (like Cardmarket "Adresse des Verkäufers")
        if (order.sellerAddress != null) ...[
          const SectionDivider(icon: Icons.location_on_outlined, label: 'Seller Address'),
          SizedBox(
            width: double.infinity,
            child: RiftrCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.sellerAddress!.name != null &&
                      order.sellerAddress!.name!.isNotEmpty)
                    _tappableName(
                      name: order.sellerAddress!.name!,
                      id: order.sellerId,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700),
                      chevronSize: 16,
                    ),
                  Text(
                    _formatAddress(order.sellerAddress!),
                    style: AppTextStyles.body
                        .copyWith(height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const SectionDivider(icon: Icons.local_shipping_outlined, label: 'Shipping'),
        RiftrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Method', order.shippingMethod.label),
              if (order.trackingNumber != null &&
                  order.trackingNumber!.isNotEmpty)
                _trackingRow(order.trackingNumber!),
              // Auto-release countdown for buyer
              if (order.status == OrderStatus.shipped &&
                  order.autoReleaseAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Auto-confirmed in ${order.autoReleaseAt!.difference(DateTime.now()).inDays} days',
                    style:
                        AppTextStyles.small.copyWith(color: AppColors.amber500),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _trackingRow(String tracking) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('Tracking',
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(tracking,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          // 44×44 touch-target wraps the visual 14sp copy icon (Apple HIG).
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: tracking));
              RiftrToast.info(context, 'Tracking number copied');
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.copy, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── Counterparty ────────────────────────────────────

  Widget _buildCounterpartySection() {
    if (role == OrderRole.buyer) {
      // Buyer sees seller username.
      // Tap → close OrderDetail, jump to Market Discover filtered by seller.
      // Intent differs from Header-subtitle tap (which goes to Reviews for
      // trust-check). Here the user wants "what else does this seller offer".
      final sellerName = order.sellerName ?? 'Seller';
      final canTap = order.sellerId.isNotEmpty
          && widget.onViewSellerListings != null;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionDivider(icon: Icons.storefront_outlined, label: 'Seller'),
            RiftrCard(
              onTap: canTap
                  ? () {
                      Navigator.of(context).pop();
                      widget.onViewSellerListings!(order.sellerId, sellerName);
                    }
                  : null,
              child: Row(
                children: [
                  Icon(Icons.storefront, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      sellerName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SellerStatusBadge(
                    isCommercial: order.sellerIsCommercial,
                    compact: true,
                  ),
                  if (canTap) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textMuted),
                  ],
                ],
              ),
            ),
            // DSA Art. 30 / § 5 DDG Pflicht-Imprint fuer gewerbliche
            // Verkaeufer. Bei privaten Verkaeufern rendert das Widget
            // SizedBox.shrink (keine Offenlegungspflicht).
            if (order.sellerIsCommercial) ...[
              const SizedBox(height: AppSpacing.sm),
              SellerImprintCard(
                isCommercial: order.sellerIsCommercial,
                legalEntityName: order.sellerLegalEntityName,
                vatId: order.sellerVatId,
                address: order.sellerAddress,
                email: order.sellerEmail,
              ),
            ],
          ],
        ),
      );
    }
    // Seller already sees buyer address in shipping section
    return const SizedBox.shrink();
  }

  // ── Dispute info ────────────────────────────────────

  Widget _buildDisputeInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        // V2 §2c banner: rounded (8dp). Canonical pair: amberMuted + amberBorderMuted.
        decoration: BoxDecoration(
          color: AppColors.amberMuted,
          borderRadius: BorderRadius.circular(AppRadius.rounded),
          border: Border.all(color: AppColors.amberBorderMuted),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.amber500),
                const SizedBox(width: 6),
                Text('Dispute',
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber500)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(order.disputeReason!,
                style: AppTextStyles.small
                    .copyWith(color: AppColors.textSecondary)),
            if (order.disputeDescription != null &&
                order.disputeDescription!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(order.disputeDescription!,
                  style: AppTextStyles.small
                      .copyWith(color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Rating ──────────────────────────────────────────

  Widget _buildRatingDisplay() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionDivider(icon: Icons.star_outline, label: 'Rating'),
          RiftrCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                        5,
                        (i) => Icon(
                              i < order.buyerRating!
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 18,
                              color: AppColors.amber500,
                            )),
                  ],
                ),
                if (order.buyerComment != null &&
                    order.buyerComment!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(order.buyerComment!,
                      style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Real name for shipping label: shippingAddress.name → buyerName → null.
  String? get _recipientName {
    final addrName = order.shippingAddress?.name;
    if (addrName != null && addrName.isNotEmpty) return addrName;
    final buyer = order.buyerName;
    if (buyer != null && buyer.isNotEmpty) return buyer;
    return null;
  }

  // ── Action Bar ──────────────────────────────────────

  bool get _hasActions =>
      order.status.isCancellable ||
      (role == OrderRole.seller && order.status == OrderStatus.paid) ||
      (role == OrderRole.buyer && order.status == OrderStatus.paid) ||
      (role == OrderRole.buyer && order.status == OrderStatus.shipped) ||
      (role == OrderRole.seller && order.cancelRequested) ||
      _hasDisputeAction ||
      _canRate;

  bool get _hasDisputeAction =>
      (order.status == OrderStatus.disputed ||
          order.status == OrderStatus.refunded) &&
      widget.onViewDispute != null;

  bool get _canRate =>
      role == OrderRole.buyer &&
      order.status.isCompleted &&
      order.buyerRating == null &&
      widget.onSubmitReview != null;

  // _buildActionBar() removed — replaced by inline `Positioned(Row(...))` in
  // the Stack body. The pinned-bar bg/border are no longer needed because the
  // gradient fade above the buttons handles the visual separation from
  // scroll content (see card_preview.dart pattern).

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];

    // Seller: paid + cancelRequested → Accept/Decline
    if (role == OrderRole.seller && order.status == OrderStatus.paid && order.cancelRequested) {
      buttons.add(Expanded(flex: 1, child: _actionButton('Decline', AppColors.textMuted, () async {
        HapticFeedback.lightImpact();
        final ok = await OrderService.instance.declineCancel(order.id);
        if (mounted) {
          if (ok) {
            RiftrToast.info(context, 'Cancel request declined');
          } else {
            RiftrToast.error(context, 'Failed');
          }
        }
      })));
      buttons.add(const SizedBox(width: AppSpacing.md));
      buttons.add(Expanded(flex: 2, child: _actionButton('Accept Cancel', AppColors.loss, () async {
        HapticFeedback.lightImpact();
        final ok = await OrderService.instance.acceptCancel(order.id);
        if (mounted) {
          if (ok) {
            RiftrToast.info(context, 'Order cancelled & refunded');
          } else {
            RiftrToast.error(context, 'Failed');
          }
        }
      })));
      return buttons;
    }

    // Seller: paid → Cancel + Ship
    if (role == OrderRole.seller && order.status == OrderStatus.paid) {
      if (widget.onCancel != null) {
        buttons.add(Expanded(flex: 1, child: _actionButton('Cancel', AppColors.loss, () async {
          HapticFeedback.lightImpact();
          final confirmed = await showRiftrSheet<bool>(
            context: context,
            builder: (ctx) => Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Sheet title — bodyLarge w500 textPrimary (canonical convention).
                Text('Cancel order?',
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
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
          if (confirmed == true) {
            _performAction('Cancel', () => widget.onCancel!(order.id));
          }
        })));
      }
      if (widget.onMarkShipped != null) {
        if (buttons.isNotEmpty) buttons.add(const SizedBox(width: AppSpacing.md));
        if (order.isPreReleaseBlocked) {
          buttons.add(Expanded(
            flex: 2,
            child: _actionButton('Ships ${order.preReleaseDate}', AppColors.textMuted,
                () {
              HapticFeedback.lightImpact();
              RiftrToast.info(context, 'Shipping unlocked on ${order.preReleaseDate}');
            }),
          ));
        } else {
          buttons.add(Expanded(
            flex: 2,
            child: _actionButton('Ship', AppColors.amber500, () {
              HapticFeedback.lightImpact();
              _showTrackingDialog();
            }),
          ));
        }
      }
    }

    // Buyer: paid → Request Cancel (or already requested)
    if (role == OrderRole.buyer && order.status == OrderStatus.paid) {
      if (order.cancelRequested) {
        buttons.add(Expanded(
          child: _actionButton('Cancel Requested', AppColors.textMuted, () {
            RiftrToast.info(context, 'Waiting for seller to respond');
          }),
        ));
      } else {
        buttons.add(Expanded(
          child: _actionButton('Request Cancel', AppColors.amber500, () {
            HapticFeedback.lightImpact();
            _showCancelReasonSheet();
          }),
        ));
      }
    }

    // Buyer: shipped → Problem + Received
    if (role == OrderRole.buyer && order.status == OrderStatus.shipped) {
      if (widget.onOpenDispute != null) {
        buttons.add(Expanded(flex: 1, child: _actionButton('Problem', AppColors.loss, () {
          HapticFeedback.lightImpact();
          _showDisputeDialog();
        })));
      }
      if (widget.onConfirmDelivery != null) {
        if (buttons.isNotEmpty) buttons.add(const SizedBox(width: AppSpacing.md));
        buttons.add(Expanded(
          flex: 2,
          child: _actionButton('Received', AppColors.win, () {
            HapticFeedback.lightImpact();
            _performAction(
                'Received', () => widget.onConfirmDelivery!(order.id));
          }),
        ));
      }
    }

    // Cancel only (pendingPayment)
    if (order.status == OrderStatus.pendingPayment && widget.onCancel != null) {
      buttons.add(Expanded(
        child: _actionButton('Cancel', AppColors.loss, () {
          HapticFeedback.lightImpact();
          _performAction('Cancel', () => widget.onCancel!(order.id));
        }),
      ));
    }

    // Dispute view
    if (_hasDisputeAction) {
      buttons.add(Expanded(
        child: _actionButton('View Dispute', AppColors.amber500, () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          widget.onViewDispute!();
        }),
      ));
    }

    // Rate
    if (_canRate) {
      buttons.add(Expanded(
        child: _actionButton('Rate Seller', AppColors.amber500, () {
          HapticFeedback.lightImpact();
          _showRatingDialog();
        }),
      ));
    }

    return buttons;
  }

  /// Maps legacy color-based action button to RiftrButton with pill radius.
  /// Color → Style mapping (single source of truth for this screen):
  ///   amber500       → primary
  ///   loss/error     → danger
  ///   win/success    → success (added to RiftrButtonStyle for this use case)
  ///   textMuted      → secondary (inert / less-prominent action)
  /// `radius: AppRadius.pill` keeps the pill look the screen already had.
  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    final isThisLoading = _loadingAction == label;
    final disabled = _loading && !isThisLoading;

    final style = color == AppColors.amber500
        ? RiftrButtonStyle.primary
        : (color == AppColors.loss || color == AppColors.error)
            ? RiftrButtonStyle.danger
            : (color == AppColors.win || color == AppColors.success)
                ? RiftrButtonStyle.success
                : RiftrButtonStyle.secondary;

    return RiftrButton(
      label: label,
      style: style,
      isLoading: isThisLoading,
      onPressed: disabled ? null : onTap,
      radius: AppRadius.pill,
    );
  }

  // ── Helpers ─────────────────────────────────────────

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          // bodySmall (12sp) — label readable at a glance for shipping method,
          // order info etc. Was tiny (11sp) — too dense for detail-screen info.
          SizedBox(
            width: 70,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatAddress(dynamic addr) {
    final parts = <String>[];
    if (addr.street != null && addr.street.toString().isNotEmpty) {
      parts.add(addr.street.toString());
    }
    final cityLine = [
      if (addr.zip != null && addr.zip.toString().isNotEmpty)
        addr.zip.toString(),
      if (addr.city != null && addr.city.toString().isNotEmpty)
        addr.city.toString(),
    ].join(' ');
    if (cityLine.isNotEmpty) parts.add(cityLine);
    if (addr.country != null && addr.country.toString().isNotEmpty) {
      final code = addr.country.toString();
      parts.add(_countryName(code));
    }
    return parts.join('\n');
  }

  static const _countryNames = <String, String>{
    'AT': 'Austria',
    'BE': 'Belgium',
    'BG': 'Bulgaria',
    'CH': 'Switzerland',
    'CY': 'Cyprus',
    'CZ': 'Czech Republic',
    'DE': 'Germany',
    'DK': 'Denmark',
    'EE': 'Estonia',
    'ES': 'Spain',
    'FI': 'Finland',
    'FR': 'France',
    'GB': 'United Kingdom',
    'GR': 'Greece',
    'HR': 'Croatia',
    'HU': 'Hungary',
    'IE': 'Ireland',
    'IS': 'Iceland',
    'IT': 'Italy',
    'LI': 'Liechtenstein',
    'LT': 'Lithuania',
    'LU': 'Luxembourg',
    'LV': 'Latvia',
    'MT': 'Malta',
    'NL': 'Netherlands',
    'NO': 'Norway',
    'PL': 'Poland',
    'PT': 'Portugal',
    'RO': 'Romania',
    'SE': 'Sweden',
    'SI': 'Slovenia',
    'SK': 'Slovakia',
  };

  String _countryName(String code) => _countryNames[code] ?? code;

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _statusBadge(OrderStatus status) {
    final type = switch (status) {
      OrderStatus.delivered || OrderStatus.autoCompleted =>
        RiftrBadgeType.success,
      OrderStatus.shipped => RiftrBadgeType.success,
      OrderStatus.paid => RiftrBadgeType.gold,
      OrderStatus.pendingPayment || OrderStatus.disputed =>
        RiftrBadgeType.warning,
      OrderStatus.refunded || OrderStatus.cancelled => RiftrBadgeType.error,
    };
    return RiftrBadge(label: status.label, type: type);
  }

  // ── Subdialogs ──────────────────────────────────────

  void _showTrackingDialog() {
    final controller = TextEditingController();
    showRiftrSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet title — bodyLarge w500 textPrimary (canonical sheet title
            // convention used in Adjust-all-prices sheet).
            Text('Mark as shipped',
                style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: controller,
              autofocus: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tracking number (optional)',
                hintStyle: TextStyle(
                    color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                // V2 input radius = rounded (8dp) — was legacy baseBR (12dp).
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                    borderSide: BorderSide(
                        color: AppColors.amber400,
                        width: 2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(flex: 1, child: _actionButton(
                  'Cancel', AppColors.loss, () => Navigator.pop(ctx))),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 2,
                  child: _actionButton('Ship', AppColors.amber500, () {
                Navigator.pop(ctx);
                _performAction(
                    'Ship',
                    () => widget.onMarkShipped!(
                        order.id, controller.text.trim()));
              })),
            ]),
          ],
        ),
      ),
    );
  }

  void _showEditTrackingDialog() {
    final controller =
        TextEditingController(text: order.trackingNumber ?? '');
    showRiftrSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet title — bodyLarge w500 textPrimary.
            Text('Tracking number',
                style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.base),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: controller,
              autofocus: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter tracking number',
                hintStyle: TextStyle(
                    color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                // V2 input radius = rounded (8dp) — was legacy baseBR (12dp).
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                    borderSide: BorderSide(
                        color: AppColors.amber400,
                        width: 2)),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(children: [
              Expanded(flex: 1, child: _actionButton(
                  'Cancel', AppColors.loss, () => Navigator.pop(ctx))),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 2,
                  child: _actionButton('Save', AppColors.win, () async {
                Navigator.pop(ctx);
                final tracking = controller.text.trim();
                final ok = await OrderService.instance
                    .updateTrackingNumber(order.id, tracking);
                if (context.mounted) {
                  if (ok) {
                    RiftrToast.success(context, 'Tracking number updated');
                  } else {
                    RiftrToast.error(context, 'Failed to update');
                  }
                }
              })),
            ]),
          ],
        ),
      ),
    );
  }

  static const _cancelReasons = [
    'Changed my mind',
    'Found it cheaper',
    'Ordered by mistake',
    'Other',
  ];

  void _showCancelReasonSheet() {
    String? selectedReason;
    final noteController = TextEditingController();

    showRiftrSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet title — bodyLarge w500 textPrimary (canonical convention).
              Text('Request cancellation',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              Text('The seller will be notified and can accept or decline.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              ..._cancelReasons.map((reason) {
                final isSelected = selectedReason == reason;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => setLocal(() => selectedReason = reason),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.amber500 : AppColors.background,
                        borderRadius: AppRadius.mdBR,
                        border: Border.all(color: isSelected ? AppColors.amber500 : AppColors.border),
                      ),
                      child: Row(children: [
                        Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 16, color: isSelected ? AppColors.background : AppColors.textMuted),
                        const SizedBox(width: AppSpacing.md),
                        Text(reason, style: AppTextStyles.body.copyWith(
                          color: isSelected ? AppColors.background : AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                controller: noteController,
                maxLength: 150,
                maxLines: 2,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Tell the seller why (optional)',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  // V2 input radius = rounded (8dp).
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide(color: AppColors.amber400, width: 1.5)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RiftrButton(
                label: 'Submit Request',
                onPressed: selectedReason != null ? () async {
                  Navigator.pop(ctx);
                  // Optimistic UI — update immediately
                  setState(() {
                    _order = _order.copyWith(
                      cancelRequested: true,
                      cancelRequestedAt: DateTime.now(),
                      cancelReason: selectedReason,
                      cancelNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );
                  });
                  final ok = await OrderService.instance.requestCancel(
                    order.id,
                    reason: selectedReason,
                    note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                  );
                  if (mounted) {
                    if (ok) {
                      RiftrToast.info(context, 'Cancel request sent to seller');
                    } else {
                      RiftrToast.error(context, 'Failed to send request');
                    }
                  }
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _disputeReasons = [
    'Not arrived',
    'Wrong condition (worse than listed)',
    'Wrong card received',
    'Damaged in shipping',
  ];

  void _showDisputeDialog() {
    String? selectedReason;
    final descController = TextEditingController();

    showRiftrSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet title — bodyLarge w500 textPrimary (canonical convention).
              Text('Report a problem',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.lg),
              ..._disputeReasons.map((reason) {
                final isSelected = selectedReason == reason;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => setLocal(() => selectedReason = reason),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amberMuted
                            : AppColors.background,
                        borderRadius: AppRadius.mdBR,
                        // amber500 (canonical primary) — was amber400, now
                        // matches the icon color inside this same row.
                        border: Border.all(
                          color: isSelected
                              ? AppColors.amber500
                              : AppColors.border,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 16,
                            color: isSelected
                                ? AppColors.amber500
                                : AppColors.textMuted),
                        const SizedBox(width: AppSpacing.sm),
                        Text(reason,
                            style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                );
              }),
              if (selectedReason != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Details (optional)',
                    style: AppTextStyles.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: descController,
                  maxLength: 300,
                  maxLines: 3,
                  minLines: 2,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Which card? What happened?',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    counterStyle: AppTextStyles.micro
                        .copyWith(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(
                            color:
                                AppColors.amber400)),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(children: [
                Expanded(flex: 1, child: _actionButton(
                    'Cancel', AppColors.loss, () => Navigator.pop(ctx))),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2,
                    child: _actionButton('Submit', AppColors.win, () async {
                  if (selectedReason == null) return;

                  // Discogs-Modell + AGB-Anhang 1 Abschnitt C (2026-05-01):
                  // Bei wrong_card / not_arrived UND gewerblichem Verkäufer
                  // muss der Käufer aktiv zwischen Widerruf und Reklamation
                  // wählen können.
                  final triggersHinweis = order.sellerIsCommercial &&
                      (selectedReason == 'Wrong card received' ||
                          selectedReason == 'Not arrived');

                  String reasonCodeChoice = 'no_choice_required';
                  DateTime? hinweisShownAt;
                  DateTime? hinweisChosenAt;

                  if (triggersHinweis) {
                    hinweisShownAt = DateTime.now();
                    Navigator.pop(ctx); // Reason-Sheet schließen
                    final choice =
                        await RefundPathChoiceSheet.show(context);
                    hinweisChosenAt = DateTime.now();
                    if (choice == null) {
                      // Käufer hat das Sheet abgebrochen — nichts tun.
                      return;
                    }
                    if (choice == RefundPathChoice.widerruf) {
                      // Reines Aufklaerungs-Modal — kein openDispute,
                      // kein Audit-Log. Tap ist keine Erklaerung iSd § 355 BGB.
                      if (context.mounted) {
                        await WiderrufModal.show(context, order);
                      }
                      return;
                    }
                    reasonCodeChoice = 'reklamation';
                  } else {
                    Navigator.pop(ctx);
                  }

                  _performAction(
                    'Problem',
                    () => widget.onOpenDispute!(
                      order.id,
                      selectedReason!,
                      descController.text.trim(),
                      reasonCodeChoice: reasonCodeChoice,
                      widerrufHinweisShownAt: hinweisShownAt,
                      widerrufHinweisChosenAt: hinweisChosenAt,
                    ),
                  );
                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  static const _reviewTags = [
    'Schneller Versand',
    'Wie beschrieben',
    'Gut verpackt',
    'Gute Kommunikation'
  ];

  void _showRatingDialog() {
    int selectedRating = 0;
    final commentController = TextEditingController();
    final selectedTags = <String>{};

    showRiftrSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet title — bodyLarge w500 textPrimary (canonical convention).
              Text('Rate this seller',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs),
                      child: Icon(
                          star <= selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: AppColors.amber500),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _reviewTags.map((tag) {
                  final isActive = selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => setLocal(() {
                      isActive
                          ? selectedTags.remove(tag)
                          : selectedTags.add(tag);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.amber500
                            : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive
                              ? AppColors.background
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.base),
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                controller: commentController,
                maxLength: 300,
                maxLines: 3,
                minLines: 1,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Any feedback? (optional)',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  counterStyle: AppTextStyles.micro
                      .copyWith(fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.mdBR,
                      borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBR,
                      borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(children: [
                Expanded(flex: 1, child: _actionButton(
                    'Cancel', AppColors.loss, () => Navigator.pop(ctx))),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2,
                    child: _actionButton('Submit', AppColors.win, () {
                  if (selectedRating <= 0) return;
                  Navigator.pop(ctx);
                  _performAction(
                      'Rate',
                      () => widget.onSubmitReview!(
                          order.id,
                          selectedRating,
                          commentController.text.trim(),
                          selectedTags.toList()));
                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }

}
