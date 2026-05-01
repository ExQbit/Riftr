import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/market/order_model.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';

/// Informational modal shown when a buyer chooses the Widerruf path
/// from the [RefundPathChoiceSheet].
///
/// **Wichtige rechtliche Klarstellung (2026-05-01):**
/// Dieser Modal ist reine Aufklärung — KEINE Widerrufserklärung.
/// Ein Button-Tap im App-UI ist KEINE „eindeutige Erklärung gegenüber
/// dem Verkäufer" iSd § 355 BGB. Der eigentliche Widerruf passiert
/// durch eine direkte Erklärung des Käufers an den Verkäufer (Brief
/// oder E-Mail). Riftr loggt den Tap NICHT, ändert KEINEN Order-Status,
/// und behauptet NICHTS rechtlich Verbindliches.
///
/// Der „Compose email"-Button öffnet den nativen E-Mail-Client mit einem
/// vorgefüllten Subject und Mustertext (basierend auf Anlage 1 D der
/// Riftr-AGB). Der Käufer trägt selbst die Verkäufer-Email ein und
/// schickt selbst raus — Riftr ist kein Bote in Phase 1. Phase 2
/// (KI-Anwalt-Empfehlung): App-Bote-Mechanismus mit dokumentierter
/// Weiterleitung + Versand-Log + Bounce-Handling.
class WiderrufModal extends StatelessWidget {
  final MarketOrder order;

  const WiderrufModal({super.key, required this.order});

  /// Convenience: show as a Riftr sheet.
  static Future<void> show(BuildContext context, MarketOrder order) {
    return showRiftrSheet<void>(
      context: context,
      builder: (_) => WiderrufModal(order: order),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '___________';
    final yy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yy-$mm-$dd';
  }

  Future<void> _composeEmail(BuildContext context) async {
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final subject = 'Right of withdrawal — Order $shortId';

    // Pre-fill items list (one per line).
    final itemsText = order.items.isEmpty
        ? '- ___________'
        : order.items
            .map((i) => '- ${i.cardName} × ${i.quantity}')
            .join('\n');

    // Buyer address from shippingAddress snapshot (= the address the
    // buyer used at checkout). User can edit before sending.
    String addressText = '___________';
    final addr = order.shippingAddress;
    if (addr != null && addr.isComplete) {
      final lines = <String>[
        if (addr.street.isNotEmpty) addr.street,
        [addr.zip, addr.city].where((s) => s.isNotEmpty).join(' '),
        if (addr.country.isNotEmpty) addr.country,
      ].where((s) => s.isNotEmpty).toList();
      addressText = lines.join('\n');
    }

    final orderedOn = _formatDate(order.paidAt ?? order.createdAt);
    final receivedOn = _formatDate(order.deliveredAt);
    final today = _formatDate(DateTime.now());
    final buyerName = (order.buyerName?.trim().isNotEmpty == true)
        ? order.buyerName!
        : '___________';

    // Body based on Anhang 1 D (Muster-Widerrufsformular). All fields
    // pre-filled from the order; the buyer can edit before sending.
    final body = 'Hello,\n\n'
        'I hereby give notice that I withdraw from my purchase '
        'contract for the following order on the Riftr marketplace:\n\n'
        'Order ID: $shortId\n'
        'Ordered on: $orderedOn\n'
        'Received on: $receivedOn\n\n'
        'Items:\n'
        '$itemsText\n\n'
        'Name:\n'
        '$buyerName\n\n'
        'Address:\n'
        '$addressText\n\n'
        'Date: $today\n\n'
        'Please refund the payment via the same method I used '
        '(processed via Stripe).\n\n'
        'Best regards';

    final uri = Uri(
      scheme: 'mailto',
      // Recipient pre-filled if we have sellerEmail-Snapshot (Item 5,
      // 2026-05-01). Sonst leer — Käufer trägt selbst ein.
      path: order.sellerEmail ?? '',
      query: _encodeQueryParameters({
        'subject': subject,
        'body': body,
      }),
    );

    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  // url_launcher's Uri constructor encodes query params with '+' for spaces
  // which mail apps sometimes mishandle. Build the query string manually
  // with %20 encoding to be safe.
  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the right of withdrawal',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You have 14 days from receipt to withdraw without giving '
            'any reason. This screen explains your rights — it is not '
            'itself a withdrawal.',
            style: AppTextStyles.bodySmallSecondary,
          ),
          const SizedBox(height: AppSpacing.base),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.rounded),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to actually withdraw:',
                  style: AppTextStyles.bodyBold.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '1. Send a clear withdrawal statement to the seller '
                  '(letter or email). The seller contact details are in '
                  'the order confirmation in the Riftr app.\n'
                  '2. Return the goods to the seller without delay.\n'
                  '3. The seller refunds your payment via Stripe.\n\n'
                  'For full instructions, see Legal → Right of withdrawal.',
                  style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Riftr is not a party to your contract with the seller and '
            'cannot accept your withdrawal. Tapping "Understood" below '
            'does not create a withdrawal — only your direct statement '
            'to the seller does.',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Compose-email helper. Pre-fills subject + body so the buyer
          // does not have to start from a blank page. Recipient is left
          // empty — the buyer adds the seller's email themselves.
          RiftrButton(
            label: 'Compose email to seller',
            style: RiftrButtonStyle.secondary,
            icon: Icons.mail_outline,
            onPressed: () => _composeEmail(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          RiftrButton(
            label: 'Understood',
            style: RiftrButtonStyle.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
