import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/market/order_model.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_components.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/market/order_tile.dart';
import '../widgets/market/seller_status_badge.dart';
import '../widgets/riftr_drag_handle.dart';
import '../widgets/riftr_toast.dart';

class DisputeDetailScreen extends StatefulWidget {
  final MarketOrder order;

  const DisputeDetailScreen({super.key, required this.order});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  late MarketOrder order;
  bool _loading = false;
  double _sliderValue = 50;

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  String get _uid => AuthService.instance.uid ?? '';
  bool get _isBuyer => _uid == order.buyerId;
  bool get _isSeller => _uid == order.sellerId;
  OrderRole get _role => _isBuyer ? OrderRole.buyer : OrderRole.seller;

  String get _disputeStatusLabel {
    return switch (order.disputeStatus) {
      'sellerProposed' => 'Refund Proposed',
      'resolved' => 'Resolved',
      'cancelled' => 'Cancelled',
      _ => 'Open',
    };
  }

  Color get _bannerColor {
    return switch (order.disputeStatus) {
      'sellerProposed' => AppColors.accent,
      'resolved' => AppColors.win,
      'cancelled' => AppColors.textMuted,
      _ => AppColors.amber500,
    };
  }

  Color get _bannerBg {
    return switch (order.disputeStatus) {
      'sellerProposed' => AppColors.accentMuted,
      'resolved' => AppColors.winMuted,
      'cancelled' => AppColors.surfaceLight,
      _ => AppColors.amberMuted,
    };
  }

  Color get _bannerBorderColor {
    return switch (order.disputeStatus) {
      'sellerProposed' => AppColors.accentBorder,
      'resolved' => AppColors.winBorder,
      'cancelled' => AppColors.border,
      _ => AppColors.amberBorderMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = order.status == OrderStatus.disputed;
    final isProposed = order.disputeStatus == 'sellerProposed';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: DragToDismiss(
          onDismissed: () => Navigator.of(context).pop(),
          backgroundColor: AppColors.background,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: RiftrDragHandle(
                    style: RiftrDragHandleStyle.fullscreen),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base),
                child: Row(
                  children: [
                    Text(
                      'Dispute Details',
                      style: AppTextStyles.h3
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.amber500),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        children: [
                          // Status banner
                          _statusBanner(),
                          const SizedBox(height: AppSpacing.md),

                          // Order summary
                          _orderSummaryCard(),
                          const SizedBox(height: AppSpacing.md),

                          // Dispute info
                          _disputeInfoCard(),
                          const SizedBox(height: AppSpacing.md),

                          // Proposal card (if proposed)
                          if (isProposed) ...[
                            _proposalCard(),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Timeline
                          _timelineCard(),
                          const SizedBox(height: AppSpacing.md),

                          // Buyer-Eskalations-Card (Discogs-Modell,
                          // 2026-04-30): Erscheint NUR fuer den Kaeufer und
                          // nur wenn der Dispute mehr als 14 Tage offen
                          // ist. Verweist auf die externen Wege
                          // (Stripe-Chargeback, Schlichtung, Zivilrechtsweg)
                          // — Riftr ist kein Schiedsgericht (siehe BACKLOG
                          // Pre-Launch Legal Track / Riftr_ZAG_Gutachten.md).
                          if (_shouldShowEscalation()) ...[
                            _buyerEscalationCard(),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Actions
                          if (isOpen && !isProposed) _openActions(),
                          if (isOpen && isProposed) _proposedActions(),

                          // Contact support (always)
                          const SizedBox(height: AppSpacing.sm),
                          _contactSupportButton(),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Status Banner ───

  Widget _statusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: _bannerBg,
        // V2 banner radius (8dp) — consistent with login + wallet banners.
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: _bannerBorderColor),
      ),
      child: Row(
        children: [
          Icon(
            order.status == OrderStatus.refunded
                ? Icons.receipt_long_rounded
                : order.disputeStatus == 'resolved'
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
            size: 18,
            color: _bannerColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            order.status == OrderStatus.refunded
                ? 'Refunded'
                : _disputeStatusLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: _bannerColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (order.proposedRefundPercent != null &&
              order.disputeStatus == 'sellerProposed') ...[
            const Spacer(),
            Text(
              '${order.proposedRefundPercent}% — €${(order.proposedRefundAmount ?? 0).toStringAsFixed(2)}',
              style: AppTextStyles.caption.copyWith(
                color: _bannerColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Order Summary ───

  Widget _orderSummaryCard() {
    return _card(
      'Order Summary',
      Column(
        children: [
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cardName}${item.quantity > 1 ? ' ×${item.quantity}' : ''}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '€${item.lineTotal.toStringAsFixed(2)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              )),
          Divider(color: AppColors.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '€${order.totalPaid.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _isBuyer
                            ? 'from ${order.sellerName ?? "Seller"}'
                            : 'to ${order.buyerName ?? "Buyer"}',
                        style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isBuyer) ...[
                      const SizedBox(width: AppSpacing.xs),
                      SellerStatusBadge(
                        isCommercial: order.sellerIsCommercial,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                'Order ${order.id.substring(0, 8).toUpperCase()}',
                style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dispute Info ───

  Widget _disputeInfoCard() {
    return _card(
      'Dispute',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined,
                  size: 14, color: AppColors.amber500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.disputeReason ?? 'Unknown reason',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (order.disputeDescription != null &&
              order.disputeDescription!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.disputeDescription!,
              style: AppTextStyles.small.copyWith(height: 1.4),
            ),
          ],
          if (order.disputedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Opened ${_timeAgo(order.disputedAt!)}',
              style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Proposal Card ───

  Widget _proposalCard() {
    final amount = order.proposedRefundAmount ?? 0;
    final percent = order.proposedRefundPercent ?? 0;

    return RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      color: AppColors.accentMuted,
      borderColor: AppColors.accentBorder,
      radius: AppRadius.listItem,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Refund Proposal',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'Seller proposes $percent% refund',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '€${amount.toStringAsFixed(2)} of €${order.totalPaid.toStringAsFixed(2)}',
            style: AppTextStyles.caption,
          ),
          if (order.proposedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Proposed ${_timeAgo(order.proposedAt!)}',
              style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Timeline ───

  Widget _timelineCard() {
    final events = <_TimelineEvent>[
      _TimelineEvent('Ordered', order.createdAt, AppColors.textSecondary),
      if (order.paidAt != null)
        _TimelineEvent('Paid', order.paidAt!, AppColors.order),
      if (order.shippedAt != null)
        _TimelineEvent('Shipped', order.shippedAt!, AppColors.mind,
            subtitle: order.trackingNumber),
      if (order.disputedAt != null)
        _TimelineEvent('Dispute opened', order.disputedAt!, AppColors.amber500),
      if (order.proposedAt != null &&
          order.disputeStatus == 'sellerProposed')
        _TimelineEvent(
          'Refund proposed (${order.proposedRefundPercent}%)',
          order.proposedAt!,
          AppColors.accent,
        ),
      if (order.resolvedAt != null)
        _TimelineEvent('Resolved', order.resolvedAt!, AppColors.win),
    ];

    return _card(
      'Timeline',
      Column(
        children: events.asMap().entries.map((entry) {
          final e = entry.value;
          final isLast = entry.key == events.length - 1;
          return _timelineRow(e, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _timelineRow(_TimelineEvent event, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.label,
                    style: AppTextStyles.small.copyWith(
                      color: event.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(event.date),
                    style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              if (event.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  event.subtitle!,
                  style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
                ),
              ],
              if (!isLast) const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Actions: Open dispute ───

  Widget _openActions() {
    if (_isSeller) return _sellerProposeSection();
    if (_isBuyer) return _buyerCancelSection();
    return const SizedBox.shrink();
  }

  Widget _sellerProposeSection() {
    final refundAmount = order.totalPaid * _sliderValue / 100;

    return _card(
      'Propose Refund',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_sliderValue.round()}% — €${refundAmount.toStringAsFixed(2)}',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _sliderValue,
              min: 10,
              max: 100,
              divisions: 18,
              label: '${_sliderValue.round()}%',
              onChanged: (v) => setState(() => _sliderValue = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10%',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted)),
              Text('100%',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RiftrButton(
            label: 'Propose ${_sliderValue.round()}% Refund (€${refundAmount.toStringAsFixed(2)})',
            style: RiftrButtonStyle.primary,
            onPressed: () => _confirmProposeRefund(_sliderValue.round()),
          ),
        ],
      ),
    );
  }

  Widget _buyerCancelSection() {
    return _card(
      'Actions',
      RiftrButton(
        label: 'Cancel Dispute',
        style: RiftrButtonStyle.secondary,
        onPressed: _confirmCancelDispute,
      ),
    );
  }

  // ─── Actions: Proposed ───

  Widget _proposedActions() {
    if (_isBuyer) {
      final amount = order.proposedRefundAmount ?? 0;
      return _card(
        'Respond to Proposal',
        Column(
          children: [
            RiftrButton(
              label: 'Accept Refund (€${amount.toStringAsFixed(2)})',
              style: RiftrButtonStyle.primary,
              onPressed: _confirmAcceptRefund,
            ),
            const SizedBox(height: AppSpacing.sm),
            RiftrButton(
              label: 'Reject — Ask for Different Amount',
              style: RiftrButtonStyle.danger,
              onPressed: _confirmRejectRefund,
            ),
          ],
        ),
      );
    }

    if (_isSeller) {
      return _card(
        'Waiting',
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Waiting for buyer response...',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Contact Support ───

  Widget _contactSupportButton() {
    return RiftrButton(
      label: 'Contact Support',
      onPressed: () {
        final uri = Uri(
          scheme: 'mailto',
          path: 'support@riftr.app',
          queryParameters: {
            'subject': 'Dispute ${order.id.substring(0, 8).toUpperCase()}',
          },
        );
        launchUrl(uri);
      },
      style: RiftrButtonStyle.secondary,
      icon: Icons.support_agent,
    );
  }

  // ─── Confirm dialogs & actions ───

  Future<void> _confirmProposeRefund(int percent) async {
    final amount = order.totalPaid * percent / 100;
    final confirmed = await _showConfirmDialog(
      'Propose $percent% Refund?',
      'You are offering to refund €${amount.toStringAsFixed(2)} to the buyer. They will need to accept this proposal.',
      'Propose Refund',
      AppColors.accent,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final ok = await OrderService.instance.proposeRefund(order.id, percent);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      RiftrToast.success(context, 'Refund proposal sent');
      Navigator.pop(context);
    } else {
      RiftrToast.error(context, 'Failed to propose refund');
    }
  }

  Future<void> _confirmAcceptRefund() async {
    final amount = order.proposedRefundAmount ?? 0;
    final confirmed = await _showConfirmDialog(
      'Accept Refund?',
      'You will receive €${amount.toStringAsFixed(2)} back. This action cannot be undone.',
      'Accept',
      AppColors.win,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final ok =
        await OrderService.instance.respondToRefund(order.id, accept: true);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      RiftrToast.success(context, 'Refund accepted');
      Navigator.pop(context);
    } else {
      RiftrToast.error(context, 'Failed to accept refund');
    }
  }

  Future<void> _confirmRejectRefund() async {
    final confirmed = await _showConfirmDialog(
      'Reject Proposal?',
      'The seller will be asked to propose a different refund amount.',
      'Reject',
      AppColors.loss,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final ok =
        await OrderService.instance.respondToRefund(order.id, accept: false);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      RiftrToast.info(context, 'Proposal rejected');
      Navigator.pop(context);
    } else {
      RiftrToast.error(context, 'Failed to reject proposal');
    }
  }

  Future<void> _confirmCancelDispute() async {
    final confirmed = await _showConfirmDialog(
      'Cancel Dispute?',
      'The order will return to shipped status and the auto-release timer will restart.',
      'Cancel Dispute',
      AppColors.textMuted,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final ok = await OrderService.instance.cancelDispute(order.id);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      RiftrToast.info(context, 'Dispute cancelled');
      Navigator.pop(context);
    } else {
      RiftrToast.error(context, 'Failed to cancel dispute');
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String message,
    String confirmLabel,
    Color confirmColor,
  ) async {
    final isDanger = confirmColor == AppColors.error || confirmColor == AppColors.loss;
    return await showRiftrSheet<bool>(
          context: context,
          builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTextStyles.h2.copyWith(
                  color: isDanger ? AppColors.error : AppColors.amber400, fontWeight: FontWeight.w900)),
                const SizedBox(height: AppSpacing.sm),
                Text(message, style: AppTextStyles.bodySecondary),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(child: RiftrButton(label: 'Cancel',
                    onPressed: () => Navigator.pop(ctx, false), style: RiftrButtonStyle.secondary)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: RiftrButton(label: confirmLabel,
                    onPressed: () => Navigator.pop(ctx, true),
                    style: isDanger ? RiftrButtonStyle.danger : RiftrButtonStyle.primary)),
                ]),
              ],
            ),
          ),
        ) ??
        false;
  }

  // ─── Helpers ───

  Widget _card(String title, Widget child) {
    return RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }

  // ─── Buyer-Eskalation (Discogs-Modell) ───

  /// Zeigt die Eskalations-Card an wenn:
  ///   - aktueller User ist Kaeufer (Verkaeufer braucht das nicht)
  ///   - Order ist im Status `disputed` (nicht resolved/cancelled/refunded)
  ///   - mehr als 14 Tage seit Dispute-Oeffnung vergangen
  /// Vor 14 Tagen sollten die normalen Riftr-Mechanismen greifen
  /// (proposeRefund vom Verkaeufer, autoResolveSellerSilence-Cron).
  bool _shouldShowEscalation() {
    if (!_isBuyer) return false;
    if (order.status != OrderStatus.disputed) return false;
    if (order.disputeStatus == 'resolved' ||
        order.disputeStatus == 'cancelled') {
      return false;
    }
    final disputedAt = order.disputedAt;
    if (disputedAt == null) return false;
    final daysSince = DateTime.now().difference(disputedAt).inDays;
    return daysSince >= 14;
  }

  Widget _buyerEscalationCard() {
    final disputedAt = order.disputedAt;
    final daysSince = disputedAt != null
        ? DateTime.now().difference(disputedAt).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.amberBorderMuted, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.escalator_warning,
                  size: 20, color: AppColors.amber500),
              const SizedBox(width: AppSpacing.sm),
              Text('Externe Eskalation',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.amber500,
                    fontWeight: FontWeight.w800,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amberMuted,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text('${daysSince}d offen',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.amber500,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Riftr ist ein Marktplatz, kein Schiedsgericht — wir koennen bei '
            'widersprechenden Aussagen ohne objektive Beweise nicht entscheiden, '
            'wer recht hat. Nach 14 Tagen ohne Einigung empfehlen wir die '
            'folgenden externen Wege:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Pfad 1: Stripe-Chargeback
          _escalationPathCard(
            icon: Icons.credit_card_outlined,
            title: 'Stripe-Chargeback bei deiner Bank',
            subtitle: 'Empfohlen — schnellster Weg, hoeherer Erfolg bei Karten-/SEPA-Zahlungen',
            description:
                'Kontaktiere deine Bank (oder Kreditkarten-Anbieter) und beantrage '
                'einen Chargeback fuer diese Transaktion. Die Bank prueft den Fall '
                'und holt das Geld direkt von Stripe zurueck. Du brauchst dafuer '
                'die unten kopierbaren Order-Daten.',
            buttonLabel: 'Order-Daten kopieren',
            buttonIcon: Icons.content_copy,
            buttonStyle: RiftrButtonStyle.primary,
            onAction: _copyOrderDataForBank,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Pfad 2: Verbraucherschlichtung (nur bei gewerblichen Verkaeufern relevant)
          _escalationPathCard(
            icon: Icons.gavel_outlined,
            title: 'Verbraucherschlichtungsstelle',
            subtitle: 'Bei gewerblichen Verkaeufern — kostenfrei',
            description:
                'Bei einem gewerblichen Verkaeufer kannst du dich an die '
                'Allgemeine Verbraucherschlichtungsstelle wenden. Riftr selbst '
                'nimmt nicht an Verbraucherschlichtung teil (§ 36 VSBG), aber '
                'der gewerbliche Verkaeufer ist ggf. dazu verpflichtet.',
            buttonLabel: 'Schlichtungsstelle oeffnen',
            buttonIcon: Icons.open_in_new,
            buttonStyle: RiftrButtonStyle.secondary,
            onAction: () => _openExternal(
              'https://www.verbraucher-schlichter.de/',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Pfad 3: Zivilrechtsweg
          _escalationPathCard(
            icon: Icons.account_balance_outlined,
            title: 'Zivilrechtsweg',
            subtitle: 'Bei groesseren Betraegen oder Betrugsverdacht',
            description:
                'Du kannst zivilrechtlich gegen den Verkaeufer vorgehen oder '
                'bei Betrugsverdacht Strafanzeige bei der Polizei stellen. '
                'Die Verkaeufer-Identitaet ist durch Stripe-KYC verifiziert — '
                'gib bei der Polizei die kopierten Order-Daten an, sie koennen '
                'die Klarnamens-Auskunft via Stripe einholen.',
            buttonLabel: 'Order-Daten fuer Anzeige',
            buttonIcon: Icons.content_copy,
            buttonStyle: RiftrButtonStyle.secondary,
            onAction: _copyOrderDataForLegal,
          ),
        ],
      ),
    );
  }

  Widget _escalationPathCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required String buttonLabel,
    required IconData buttonIcon,
    required RiftrButtonStyle buttonStyle,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(subtitle,
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                )),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(description,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              )),
          const SizedBox(height: AppSpacing.sm),
          RiftrButton(
            label: buttonLabel,
            icon: buttonIcon,
            style: buttonStyle,
            fullWidth: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }

  /// Order-Daten fuer Bank-Chargeback-Anfrage in die Zwischenablage.
  /// Format ist auf Bank-Mitarbeiter zugeschnitten — sie brauchen
  /// idealerweise Stripe-PI-ID, Datum, Betrag, Empfaenger.
  Future<void> _copyOrderDataForBank() async {
    final lines = <String>[
      '=== Riftr Bestellung — Chargeback-Anfrage ===',
      'Bestell-ID: ${order.id}',
      if (order.stripePaymentIntentId != null)
        'Stripe Payment-Intent: ${order.stripePaymentIntentId}',
      if (order.paidAt != null) 'Bezahlt am: ${_formatDate(order.paidAt!)}',
      'Betrag: €${order.totalPaid.toStringAsFixed(2)}',
      if (order.sellerName != null) 'Verkaeufer (Riftr-Profil): ${order.sellerName}',
      'Plattform: Riftr (getriftr.app)',
      'Zahlungsdienstleister: Stripe Payments Europe Ltd. (Dublin, Irland)',
      'Streit-Grund: ${order.disputeReason ?? "Item nicht erhalten / nicht wie beschrieben"}',
      if (order.disputedAt != null)
        'Streit-Eroeffnung: ${_formatDate(order.disputedAt!)}',
      '',
      'Hinweis: Stripe-Chargeback geht ueber deine Bank-/Karten-Anbieter.',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    RiftrToast.success(context, 'Order-Daten kopiert');
  }

  /// Order-Daten fuer Polizei-/Anwalts-Anfrage. Wie Bank-Variante,
  /// aber mit zusaetzlichem Hinweis auf Stripe-KYC-Auskunft.
  Future<void> _copyOrderDataForLegal() async {
    final lines = <String>[
      '=== Riftr Bestellung — Beweismittel fuer Strafanzeige / Klage ===',
      'Bestell-ID: ${order.id}',
      if (order.stripePaymentIntentId != null)
        'Stripe Payment-Intent: ${order.stripePaymentIntentId}',
      if (order.paidAt != null) 'Bezahlt am: ${_formatDate(order.paidAt!)}',
      'Betrag: €${order.totalPaid.toStringAsFixed(2)}',
      if (order.sellerName != null) 'Verkaeufer (Riftr-Profil): ${order.sellerName}',
      'Verkaeufer-UID: ${order.sellerId}',
      'Plattform: Riftr UG (i.G.) — getriftr.app',
      'Zahlungsdienstleister: Stripe Payments Europe Ltd. (Dublin, Irland)',
      'Streit-Grund: ${order.disputeReason ?? "Item nicht erhalten / nicht wie beschrieben"}',
      if (order.disputeDescription != null)
        'Streit-Beschreibung: ${order.disputeDescription}',
      if (order.disputedAt != null)
        'Streit-Eroeffnung: ${_formatDate(order.disputedAt!)}',
      '',
      'Hinweis fuer Ermittlungsbehoerde / Anwalt:',
      'Die Verkaeufer-Identitaet ist durch Stripe-KYC verifiziert. Klarname '
      'und Adresse koennen ueber eine Auskunft an Stripe Payments Europe Ltd. '
      'eingeholt werden (referenz: oben Stripe Payment-Intent).',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    RiftrToast.success(context, 'Beweismittel-Daten kopiert');
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      RiftrToast.error(context, 'Konnte $url nicht oeffnen');
    }
  }
}

class _TimelineEvent {
  final String label;
  final DateTime date;
  final Color color;
  final String? subtitle;

  const _TimelineEvent(this.label, this.date, this.color, {this.subtitle});
}
