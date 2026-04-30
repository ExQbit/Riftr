import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_components.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_header.dart';
import '../widgets/riftr_toast.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/riftr_drag_handle.dart';

/// Admin-only Mediation-Tool fuer festgefahrene Disputes.
///
/// **Discogs-Modell-Refactor (2026-04-30, ZAG-Compliance):**
/// Plattform-Refunds wurden komplett entfernt — `adminResolveDispute` macht
/// nur noch den Verkaeufer-Win-Pfad (Order zurueck auf shipped, KEIN Geld).
/// Fuer Buyer-Win gibt's keinen Plattform-Pfad mehr — Buyer wird ueber den
/// Eskalations-Screen auf 1) Stripe-Chargeback bei seiner Bank,
/// 2) Verbraucherschlichtung, 3) Zivilrechtsweg verwiesen.
///
/// Admin-Aktionen aus diesem Screen:
///   - **Reject (Seller Win)** → `adminResolveDispute` mit refundPercent: 0
///     (kein Geld bewegt sich, Order zurueck auf shipped)
///   - **Listings pausieren (30 Tage)** → `adminAccountSanction`
///     (Hausrecht-Sanktion gegen Verkaeufer ohne Geldbewegung)
///   - **Account sperren** → `adminAccountSanction` (dauerhaft)
///
/// Zugang: nur fuer User mit `admin: true` Custom-Claim. Triggert Backend-
/// Authentifizierung — wenn Frontend-Klick durchkommt aber CF-Aufruf scheitert,
/// liegt's am Token-Refresh (siehe README zu Custom-Claims).
class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  static final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _disputes = [];

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _functions
          .httpsCallable('adminListDisputes')
          .call<Map<String, dynamic>>({});
      final list = (result.data['disputes'] as List?) ?? [];
      setState(() {
        _disputes = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      String msg = 'Failed to load disputes';
      if (e is FirebaseFunctionsException) {
        msg = e.message ?? msg;
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  /// Reject-Refund (Verkaeufer-Win) via `adminResolveDispute`.
  /// Keine Geldbewegung — Order zurueck auf shipped, neuer 7-Tage-Auto-Release.
  Future<void> _rejectRefund(Map<String, dynamic> dispute) async {
    final orderId = dispute['orderId'] as String;
    final reason = await _promptReason(_PromptKind.rejectRefund);
    if (reason == null || reason.length < 5) return;

    setState(() => _loading = true);
    try {
      final result = await _functions
          .httpsCallable('adminResolveDispute')
          .call<Map<String, dynamic>>({
        'orderId': orderId,
        'refundPercent': 0,
        'reason': reason,
      });
      if (mounted) {
        final outcome = result.data['outcome'] as String? ?? 'done';
        RiftrToast.success(context, 'Dispute resolved: $outcome');
      }
      await _loadDisputes();
    } catch (e) {
      String msg = 'Resolve failed';
      if (e is FirebaseFunctionsException) msg = e.message ?? msg;
      if (mounted) {
        RiftrToast.error(context, msg);
        setState(() => _loading = false);
      }
    }
  }

  /// Account-Sanktion via `adminAccountSanction`.
  /// Reines Hausrecht — keine Geldbewegung. Listings werden pausiert oder
  /// Account gebannt. Dispute-State wird durch diese Aktion nicht veraendert
  /// (separate Eskalation: Buyer geht via Stripe-Chargeback / Schlichtung
  /// vor, oder Admin schliesst Dispute zusaetzlich via Reject Refund).
  Future<void> _sanctionSeller(
    Map<String, dynamic> dispute, {
    required String actionType, // "pauseListings" | "ban"
  }) async {
    final sellerUid = dispute['sellerId'] as String?;
    if (sellerUid == null) {
      RiftrToast.error(context, 'No sellerId in dispute');
      return;
    }
    final reason = await _promptReason(
      actionType == 'ban' ? _PromptKind.banSeller : _PromptKind.pauseListings,
    );
    if (reason == null || reason.length < 5) return;

    setState(() => _loading = true);
    try {
      final result = await _functions
          .httpsCallable('adminAccountSanction')
          .call<Map<String, dynamic>>({
        'targetUid': sellerUid,
        'actionType': actionType,
        'reason': reason,
        if (actionType == 'pauseListings') 'durationDays': 30,
      });
      if (mounted) {
        final affected = result.data['listingsAffected'] as int? ?? 0;
        RiftrToast.success(
          context,
          actionType == 'ban'
              ? 'Account banned · $affected listings paused'
              : 'Listings paused 30d · $affected affected',
        );
      }
      await _loadDisputes();
    } catch (e) {
      String msg = 'Sanction failed';
      if (e is FirebaseFunctionsException) msg = e.message ?? msg;
      if (mounted) {
        RiftrToast.error(context, msg);
        setState(() => _loading = false);
      }
    }
  }

  Future<String?> _promptReason(_PromptKind kind) async {
    final controller = TextEditingController();
    final title = switch (kind) {
      _PromptKind.rejectRefund => 'Reject refund (seller wins)',
      _PromptKind.pauseListings => 'Pause seller listings (30 days)',
      _PromptKind.banSeller => 'Ban seller account',
    };
    return showRiftrSheet<String?>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reason for audit log (≥5 chars). Both parties get notified.',
              style: AppTextStyles.bodySmallSecondary,
            ),
            const SizedBox(height: AppSpacing.base),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'e.g. Buyer provided photo proof of damaged card.',
                hintStyle:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: RiftrButton(
                  label: 'Cancel',
                  style: RiftrButtonStyle.secondary,
                  onPressed: () => Navigator.pop(ctx, null),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RiftrButton(
                  label: 'Confirm',
                  style: kind == _PromptKind.banSeller
                      ? RiftrButtonStyle.danger
                      : kind == _PromptKind.pauseListings
                          ? RiftrButtonStyle.secondary
                          : RiftrButtonStyle.primary,
                  onPressed: () {
                    final t = controller.text.trim();
                    if (t.length < 5) return;
                    Navigator.pop(ctx, t);
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.only(
                    top: AppSpacing.md, bottom: AppSpacing.sm),
                child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
              ),
              const GoldOrnamentHeader(title: 'ADMIN — DISPUTES'),
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                  child: Row(children: [
                    Text('${_disputes.length} open',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _loadDisputes();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Row(children: [
                          Icon(Icons.refresh, size: 16, color: AppColors.amber400),
                          const SizedBox(width: 4),
                          Text('Refresh',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.amber400, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: AppColors.loss, size: 40),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(_error!,
                                      style: AppTextStyles.body.copyWith(color: AppColors.loss),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: AppSpacing.base),
                                  RiftrButton(
                                    label: 'Retry',
                                    style: RiftrButtonStyle.secondary,
                                    onPressed: _loadDisputes,
                                    fullWidth: false,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _disputes.isEmpty
                            ? Center(
                                child: RiftrEmptyState(
                                  icon: Icons.gavel,
                                  title: 'No open disputes',
                                  subtitle:
                                      'Buyer-seller mediation handles routine cases.',
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.base, 0, AppSpacing.base, AppSpacing.xl),
                                itemCount: _disputes.length,
                                itemBuilder: (ctx, i) =>
                                    _buildDisputeCard(_disputes[i]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> d) {
    // orderId is used by the resolve callbacks via the dispute-map (`d`),
    // not directly here — closures pull it out of `d` themselves.
    final shippingMethod = d['shippingMethod'] as String? ?? 'unknown';
    final trackingNumber = d['trackingNumber'] as String?;
    final reason = d['disputeReason'] as String? ?? 'Unknown reason';
    final reasonCode = d['disputeReasonCode'] as String?;
    final description = d['disputeDescription'] as String?;
    final disputeStatus = d['disputeStatus'] as String? ?? 'open';
    final totalPaid = (d['totalPaid'] as num?)?.toDouble() ?? 0;
    final sellerPayout = (d['sellerPayout'] as num?)?.toDouble() ?? 0;
    final buyerName = d['buyerName'] as String? ?? '(buyer)';
    final sellerName = d['sellerName'] as String? ?? '(seller)';
    final items = (d['items'] as List?) ?? [];
    final proposedPercent = d['proposedRefundPercent'] as int?;
    final proposedAmount = (d['proposedRefundAmount'] as num?)?.toDouble();

    final itemNames = items
        .map((i) => '${i['quantity']}× ${i['cardName']}')
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RiftrCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text('DISPUTED',
                    style: AppTextStyles.tiny.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(disputeStatus.toUpperCase(),
                    style: AppTextStyles.tiny.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
              const Spacer(),
              Text('€${totalPaid.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyBold.copyWith(fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(itemNames,
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Buyer: $buyerName  →  Seller: $sellerName',
                style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.sm),

            // Reason + shipping context
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.rounded),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason: $reason${reasonCode != null ? '  ($reasonCode)' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description,
                        style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Shipping: $shippingMethod${trackingNumber != null ? '  ·  Tracking: $trackingNumber' : '  ·  No tracking'}',
                    style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    'Seller payout if shipped: €${sellerPayout.toStringAsFixed(2)}',
                    style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
                  ),
                  if (proposedPercent != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Seller proposed: $proposedPercent% (€${(proposedAmount ?? 0).toStringAsFixed(2)}) — buyer hasn\'t accepted',
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.amber400, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Discogs-Modell-Hinweis: Plattform macht keine Refunds (ZAG-Compliance).
            // Buyer-Win passiert ueber Stripe-Chargeback / Schlichtung / Zivilrecht
            // — siehe Eskalations-Screen im Order-Detail (BuyerEscalationView).
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.rounded),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Discogs-Modell: Riftr issued KEINE Refunds. Buyer-Win '
                      'via Stripe-Chargeback (Buyer-Side) oder Schlichtung. '
                      'Admin kann hier Verkaeufer-Win schliessen oder Verkaeufer-'
                      'Account sanktionieren.',
                      style: AppTextStyles.tiny.copyWith(
                          color: AppColors.textMuted, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3 Aktionen: Reject (Seller-Win) / Pause Listings / Ban Account
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                RiftrButton(
                  label: 'Reject (Seller wins)',
                  icon: Icons.gavel,
                  style: RiftrButtonStyle.primary,
                  fullWidth: false,
                  onPressed: () => _rejectRefund(d),
                ),
                RiftrButton(
                  label: 'Pause listings 30d',
                  icon: Icons.pause_circle_outline,
                  style: RiftrButtonStyle.secondary,
                  fullWidth: false,
                  onPressed: () =>
                      _sanctionSeller(d, actionType: 'pauseListings'),
                ),
                RiftrButton(
                  label: 'Ban account',
                  icon: Icons.block,
                  style: RiftrButtonStyle.danger,
                  fullWidth: false,
                  onPressed: () => _sanctionSeller(d, actionType: 'ban'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Drei Kinds fuer den Reason-Prompt — kontrollieren Titel und Confirm-Button-
/// Style. Reject (Seller-Win) ist der „normale" Schliessungs-Pfad.
/// pauseListings / banSeller sind Verkaeufer-Sanktionen ohne Geldbewegung.
enum _PromptKind {
  rejectRefund,
  pauseListings,
  banSeller,
}
