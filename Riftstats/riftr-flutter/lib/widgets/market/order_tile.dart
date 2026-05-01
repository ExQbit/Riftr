import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/market/order_model.dart';
import '../../services/card_service.dart';
import '../../services/notification_inbox_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import '../card_image.dart';
import '../card_ribbon.dart';
import 'condition_badge.dart';
import 'order_detail_screen.dart';
import 'refund_path_choice_sheet.dart';
import 'widerruf_modal.dart';
import '../riftr_toast.dart';

enum OrderRole { buyer, seller }

/// Displays a single order with status badge, expandable details, and action buttons.
class OrderTile extends StatefulWidget {
  final MarketOrder order;
  final OrderRole role;
  final Future<void> Function(String orderId, String tracking)? onMarkShipped;
  final Future<void> Function(String orderId)? onConfirmDelivery;
  final Future<void> Function(String orderId)? onCancel;
  /// Opens a dispute. Optional Audit-Felder (Discogs-Modell, 2026-05-01)
  /// für den Widerrufsrechts-Hinweis-Dialog bei wrong_card/not_arrived
  /// + gewerblichen Verkäufern.
  final Future<void> Function(
    String orderId,
    String reason,
    String description, {
    String reasonCodeChoice,
    DateTime? widerrufHinweisShownAt,
    DateTime? widerrufHinweisChosenAt,
  })? onOpenDispute;
  final Future<void> Function(String orderId, int rating, String comment, List<String> tags)? onSubmitReview;
  final VoidCallback? onViewDispute;
  /// Fires when user taps the Seller section-card inside Order Detail.
  /// Host should switch to Market Discover with seller filter applied.
  final void Function(String sellerId, String sellerName)? onViewSellerListings;

  const OrderTile({
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
  State<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<OrderTile> {
  String? _loadingAction;

  MarketOrder get order => widget.order;
  OrderRole get role => widget.role;

  bool get _loading => _loadingAction != null;

  /// Returns list of (label, onTap, color, icon) for inline action buttons.
  List<(String, VoidCallback, Color)> get _inlineActions {
    final actions = <(String, VoidCallback, Color)>[];

    // Seller: paid + cancelRequested → Decline + Accept (same style as Cancel + Ship)
    if (role == OrderRole.seller && order.status == OrderStatus.paid && order.cancelRequested) {
      actions.add(('Decline', () async {
        HapticFeedback.lightImpact();
        final ok = await OrderService.instance.declineCancel(order.id);
        if (context.mounted) {
          if (ok) {
            RiftrToast.info(context, 'Cancel declined');
          } else {
            RiftrToast.error(context, 'Failed');
          }
        }
      }, AppColors.loss));
      actions.add(('Accept', () async {
        HapticFeedback.lightImpact();
        final ok = await OrderService.instance.acceptCancel(order.id);
        if (context.mounted) {
          if (ok) {
            RiftrToast.info(context, 'Order cancelled & refunded');
          } else {
            RiftrToast.error(context, 'Failed');
          }
        }
      }, AppColors.amber500));
    }
    // Seller: paid (no cancel request) → Cancel + Ship
    else if (role == OrderRole.seller && order.status == OrderStatus.paid) {
      if (widget.onCancel != null) {
        actions.add(('Cancel', () { HapticFeedback.lightImpact(); _performAction('Cancel', () => widget.onCancel!(order.id)); }, AppColors.loss));
      }
      if (widget.onMarkShipped != null) {
        if (order.isPreReleaseBlocked) {
          actions.add(('Ships ${order.preReleaseDate}', () {
            HapticFeedback.lightImpact();
            RiftrToast.info(context, 'Shipping unlocked on ${order.preReleaseDate}');
          }, AppColors.textMuted));
        } else {
          actions.add(('Ship', () { HapticFeedback.lightImpact(); _showTrackingDialog(context); }, AppColors.amber500));
        }
      }
    }

    // Buyer: shipped → [Problem | Received]
    // Problem left (narrow, destructive/loss), Received right (wide, primary).
    // Matches V2 dialog-pair convention: destructive LEFT, confirm RIGHT
    // (same as Cancel+Ship in Sales, Cancel+Save in Edit-Tracking, etc.)
    if (role == OrderRole.buyer && order.status == OrderStatus.shipped) {
      if (widget.onOpenDispute != null) {
        actions.add(('Problem', () { HapticFeedback.lightImpact(); _showDisputeDialog(context); }, AppColors.loss));
      }
      if (widget.onConfirmDelivery != null) {
        actions.add(('Received', () { HapticFeedback.lightImpact(); _performAction('Received', () => widget.onConfirmDelivery!(order.id)); }, AppColors.win));
      }
    }

    // Buyer: completed + not rated → Rate
    if (_canRate) {
      actions.add(('Rate', () { HapticFeedback.lightImpact(); _showRatingDialog(context); }, AppColors.amber500));
    }

    return actions;
  }

  Future<void> _performAction(String actionLabel, Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loadingAction = actionLabel);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counterpartyName = role == OrderRole.buyer
        ? order.sellerName ?? 'Seller'
        : order.buyerName ?? 'Buyer';
    final roleLabel = role == OrderRole.buyer ? 'from' : 'to';

    final hasUpdate = NotificationInboxService.instance.hasUnseenForOrder(order.id);

    return GestureDetector(
      onTap: () {
        // Mark this order's notifications as seen when tapped
        if (hasUpdate) {
          NotificationInboxService.instance.markSeenForOrder(order.id);
        }
        _openDetailScreen(context);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RiftrCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            radius: AppRadius.listItem,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail — pass `card:` so the CardImage paints the BANNED /
                // ERRATA ribbon overlay automatically (CardRibbon.forCard).
            SizedBox(
              width: 40,
              height: 56,
              child: Transform.scale(
                scale: 1.25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  child: CardImage(
                    imageUrl: order.imageUrl,
                    fallbackText: order.cardName,
                    width: 40,
                    height: 56,
                    card: order.items.isNotEmpty
                        ? CardService.getLookup()[order.items.first.cardId]
                        : null,
                    ribbonSize: CardRibbonSize.compact,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: card name(s) + status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.items.length > 1
                              ? '${order.cardName} +${order.items.length - 1} more'
                              : order.cardName,
                          // body (14sp) — bumped from bodySmall for readability.
                          // Creates clearer hierarchy vs. tiny (11sp) meta line.
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _statusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Info row: condition, qty, foil, counterparty, price
                  Row(
                    children: [
                      ConditionBadge(condition: order.condition),
                      if (order.totalQuantity > 1) ...[
                        const SizedBox(width: 6),
                        Text(
                          '×${order.totalQuantity}',
                          style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                      // Foil star — shown if any item in the order is foil.
                      // Uses '★' per app-wide Foil-Indicator standard
                      // (V2 §15.17) — matches CardPriceTile / CollectionSection.
                      if (order.items.any((i) => i.isFoil)) ...[
                        const SizedBox(width: 6),
                        Text(
                          '★',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.amber300,
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$roleLabel $counterpartyName',
                          style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '€${order.totalPaid.toStringAsFixed(2)}',
                        // body (14sp) — matches card-name size for consistent hierarchy.
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                    ],
                  ),

                  // Inline action buttons
                  if (_inlineActions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (int i = 0; i < _inlineActions.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: _inlineActions[i].$3 == AppColors.loss ? 1 : 2,
                            child: _actionButton(_inlineActions[i].$1, _inlineActions[i].$3, _inlineActions[i].$2),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // Amber dot for unseen order notifications
      if (hasUpdate)
        Positioned(
          top: -4, right: -4,
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: AppColors.amber400,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
    );
  }

  /// Opens the full-screen order detail via Navigator.push.
  void _openDetailScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return OrderDetailScreen(
            order: order,
            role: role,
            onMarkShipped: widget.onMarkShipped,
            onConfirmDelivery: widget.onConfirmDelivery,
            onCancel: widget.onCancel,
            onOpenDispute: widget.onOpenDispute,
            onSubmitReview: widget.onSubmitReview,
            onViewDispute: widget.onViewDispute,
            onViewSellerListings: widget.onViewSellerListings,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  bool get _canRate =>
      role == OrderRole.buyer &&
      order.status.isCompleted &&
      order.buyerRating == null &&
      widget.onSubmitReview != null;

  void _showDisputeDialog(BuildContext context) {
    const reasons = [
      'Not arrived',
      'Wrong condition (worse than listed)',
      'Wrong card received',
      'Damaged in shipping',
    ];
    String? selectedReason;
    final descController = TextEditingController();

    showRiftrSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORT A PROBLEM', style: AppTextStyles.h2.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.lg),
              ...reasons.map((reason) {
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
                        border: Border.all(
                          color: isSelected ? AppColors.amber500 : AppColors.border,
                        ),
                      ),
                      child: Row(children: [
                        Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 16, color: isSelected ? AppColors.background : AppColors.textMuted),
                        const SizedBox(width: AppSpacing.sm),
                        Text(reason, style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.background : AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                );
              }),
              if (selectedReason != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Details (optional)', style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: descController, maxLength: 300, maxLines: 3, minLines: 2,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Which card? What happened?',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true, fillColor: AppColors.background,
                    counterStyle: AppTextStyles.micro.copyWith(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.amber400)),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(children: [
                _actionButton('Cancel', AppColors.loss, () => Navigator.pop(ctx)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _actionButton('Submit', AppColors.win, () async {
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
                    final choice = await RefundPathChoiceSheet.show(context);
                    hinweisChosenAt = DateTime.now();
                    if (choice == null) {
                      // Käufer hat das Sheet abgebrochen — nichts tun.
                      return;
                    }
                    if (choice == RefundPathChoice.widerruf) {
                      // Widerruf-Pfad: zeige reines Aufklaerungs-Modal.
                      // Wir rufen openDispute NICHT auf und loggen den Tap
                      // NICHT — ein Tap ist keine Erklaerung iSd § 355 BGB.
                      // Der Modal hilft dem Kaeufer, eine Email an den
                      // Verkaeufer zu schreiben. Phase 2: App-Bote.
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

  static const _reviewTags = ['Schneller Versand', 'Wie beschrieben', 'Gut verpackt', 'Gute Kommunikation'];

  void _showRatingDialog(BuildContext context) {
    int selectedRating = 0;
    final commentController = TextEditingController();
    final selectedTags = <String>{};

    showRiftrSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RATE THIS SELLER', style: AppTextStyles.h2.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Icon(
                        star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40, color: AppColors.amber400),
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
                      isActive ? selectedTags.remove(tag) : selectedTags.add(tag);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.amber500 : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive ? AppColors.background : AppColors.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
                controller: commentController, maxLength: 300, maxLines: 3, minLines: 1,
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Any feedback? (optional)',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.background,
                  counterStyle: AppTextStyles.micro.copyWith(fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(children: [
                _actionButton('Cancel', AppColors.loss, () => Navigator.pop(ctx)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _actionButton('Submit', AppColors.win, () {
                  if (selectedRating <= 0) return;
                  Navigator.pop(ctx);
                  _performAction('Rate', () => widget.onSubmitReview!(order.id, selectedRating, commentController.text.trim(), selectedTags.toList()));
                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackingDialog(BuildContext context) {
    final controller = TextEditingController();
    showRiftrSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MARK AS SHIPPED', style: AppTextStyles.h2.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: controller, autofocus: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tracking number (optional)',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true, fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR,
                  borderSide: BorderSide(color: AppColors.amber400, width: 2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              _actionButton('Cancel', AppColors.loss, () => Navigator.pop(ctx)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _actionButton('Ship', AppColors.amber500, () {
                Navigator.pop(ctx);
                _performAction('Ship', () => widget.onMarkShipped!(order.id, controller.text.trim()));
              })),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    final isThisLoading = _loadingAction == label;
    final disabled = _loading;
    return GestureDetector(
      onTap: disabled ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedOpacity(
        opacity: disabled && !isThisLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.pillBR,
          ),
          child: isThisLoading
              ? Center(
                  child: SizedBox(
                    height: 13,
                    width: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(color: AppColors.background, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  Widget _statusBadge(OrderStatus status) {
    // Show "Cancel Requested" instead of "Paid" when cancelRequested
    if (status == OrderStatus.paid && order.cancelRequested) {
      return const RiftrBadge(label: 'Cancel Requested', type: RiftrBadgeType.warning);
    }
    final type = switch (status) {
      OrderStatus.delivered || OrderStatus.autoCompleted => RiftrBadgeType.success,
      OrderStatus.shipped => RiftrBadgeType.success,
      OrderStatus.paid => RiftrBadgeType.gold,
      OrderStatus.pendingPayment || OrderStatus.disputed => RiftrBadgeType.warning,
      OrderStatus.refunded || OrderStatus.cancelled => RiftrBadgeType.error,
    };
    return RiftrBadge(label: status.label, type: type);
  }

}
