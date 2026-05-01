import 'package:flutter/material.dart';
import '../theme/app_components.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_header.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/riftr_drag_handle.dart';

/// Legal-Übersichtsscreen: Verweis auf AGB, Datenschutz, Widerrufsbelehrung.
///
/// **AGB-Anhang 1 — Widerrufsbelehrung (2026-05-01):**
/// Die App muss Verbraucher-Käufern eine eindeutig auffindbare
/// Widerrufsbelehrung zur Verfügung stellen (Anlage 1 zu Art. 246a § 1
/// Abs. 2 EGBGB). Direkter Einstieg über Profil → Legal; aus der
/// Bestellbestätigung wird auf [WiderrufsbelehrungScreen] verlinkt, sofern
/// die Bestellung von einem gewerblichen Verkäufer stammt
/// (`order.sellerIsCommercial == true`).
///
/// UI-Sprache: Englisch (App-Konvention). Cardmarket-Pattern: das gesetzlich
/// bindende deutsche Original liegt im Repo als
/// `Riftr_AGB_Anhang_1_Widerrufsbelehrung.md` und ist Source of Truth bei
/// rechtlichen Konflikten.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

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
                child: RiftrDragHandle(
                    style: RiftrDragHandleStyle.fullscreen),
              ),
              const GoldOrnamentHeader(title: 'LEGAL'),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base),
                  children: [
                    _LegalEntry(
                      icon: Icons.gavel_outlined,
                      title: 'Right of withdrawal',
                      subtitle:
                          'For purchases from commercial sellers (§ 312g BGB)',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WiderrufsbelehrungScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LegalEntry(
                      icon: Icons.description_outlined,
                      title: 'Terms and Conditions',
                      subtitle: 'Available at marketplace launch',
                      onTap: null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LegalEntry(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Available at marketplace launch (GDPR)',
                      onTap: null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text(
                        'Riftr UG (haftungsbeschränkt) i. G. — final '
                        'address will be published after commercial '
                        'registry entry. Contact: support@getriftr.app',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _LegalEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return RiftrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: disabled
                  ? AppColors.textMuted
                  : AppColors.amber400),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontWeight: FontWeight.w800,
                    color: disabled
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!disabled)
            Icon(Icons.chevron_right,
                size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Right of withdrawal — informal English translation of the binding
/// German Widerrufsbelehrung (Anlage 1 zu Art. 246a § 1 Abs. 2 EGBGB).
///
/// Cardmarket-Pattern (siehe Cardmarket_Reference/cm_Widerruf_Magic.md):
/// die App zeigt eine englische Übersetzung mit klarem Disclaimer, dass
/// der deutsche Originaltext rechtlich bindend ist. Das deutsche Original
/// liegt im Repo als `Riftr_AGB_Anhang_1_Widerrufsbelehrung.md` und ist
/// Source of Truth bei rechtlichen Konflikten. Bei Änderungen am Anhang
/// IMMER beide Quellen synchron aktualisieren.
class WiderrufsbelehrungScreen extends StatelessWidget {
  const WiderrufsbelehrungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: true,
        child: DragToDismiss(
          onDismissed: () => Navigator.of(context).pop(),
          backgroundColor: AppColors.background,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(
                    top: AppSpacing.md, bottom: AppSpacing.sm),
                child: RiftrDragHandle(
                    style: RiftrDragHandleStyle.fullscreen),
              ),
              const GoldOrnamentHeader(title: 'RIGHT OF WITHDRAWAL'),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    AppSpacing.lg,
                  ),
                  children: const [
                    _Disclaimer(),
                    SizedBox(height: AppSpacing.lg),
                    _Section(
                      title: 'A. Scope of application',
                      body:
                          'The statutory right of withdrawal under § 312g '
                          'in conjunction with §§ 355 et seq. of the '
                          'German Civil Code (BGB) applies exclusively to '
                          'purchases from commercial sellers (entrepreneurs '
                          'within the meaning of § 14 BGB) on the Riftr '
                          'platform. Purchases from private sellers '
                          '(consumer-to-consumer / P2P) are not subject to '
                          'a statutory right of withdrawal; in such cases, '
                          'only the refund mechanisms set out in § X '
                          'Refund Policy of the Riftr Terms apply.\n\n'
                          'The Riftr app indicates the seller status '
                          '(commercial / private) clearly before contract '
                          'conclusion. This indicator is visible in the '
                          'listing view and in the order confirmation.',
                    ),
                    _Section(
                      title: 'B. Right of withdrawal',
                      body:
                          'You have the right to withdraw from this '
                          'contract within fourteen days without giving '
                          'any reason.\n\n'
                          'The withdrawal period is fourteen days from the '
                          'day on which you, or a third party named by '
                          'you, who is not the carrier, takes possession '
                          'of the goods.\n\n'
                          'To exercise your right of withdrawal, you must '
                          'inform the seller of the goods by means of a '
                          'clear statement (e.g. a letter sent by post or '
                          'an email) of your decision to withdraw from '
                          'this contract. The contact details of the '
                          'commercial seller can be found in the order '
                          'confirmation in the Riftr app and in the '
                          'respective seller profile.\n\n'
                          'Additionally, you may declare the withdrawal '
                          'to the seller via the complaint function '
                          'provided in the Riftr app; in this case, Riftr '
                          'UG (haftungsbeschränkt) i. G. forwards your '
                          'declaration to the seller.\n\n'
                          'You may use the attached model withdrawal form '
                          '(Section D), which is not, however, mandatory.\n\n'
                          'To meet the withdrawal deadline, it is '
                          'sufficient that you send the notification of '
                          'exercising your right of withdrawal before the '
                          'withdrawal period has expired.',
                    ),
                    _Section(
                      title: 'Consequences of withdrawal',
                      body:
                          'If you withdraw from this contract, the seller '
                          'shall reimburse you for all payments received '
                          'from you, including delivery costs (with the '
                          'exception of additional costs resulting from '
                          'your choice of a delivery method other than '
                          'the cheapest standard delivery offered by the '
                          'seller), without undue delay and at the latest '
                          'within fourteen days from the day on which the '
                          'notification of your withdrawal from this '
                          'contract was received by the seller.\n\n'
                          'For this refund, the seller will use the same '
                          'means of payment that you used for the '
                          'original transaction, unless expressly agreed '
                          'otherwise; in no event will you be charged '
                          'fees for this refund. The refund is processed '
                          'technically via the payment service provider '
                          'Stripe Payments Europe Limited.\n\n'
                          'The seller may withhold the refund until the '
                          'goods have been returned, or until you have '
                          'provided proof that the goods have been sent '
                          'back, whichever is the earlier.\n\n'
                          'You shall return or hand over the goods to '
                          'the seller without undue delay and in any '
                          'event no later than fourteen days from the '
                          'day on which you notify us of the withdrawal '
                          'from this contract. The deadline is met if '
                          'you send the goods before the period of '
                          'fourteen days has expired.\n\n'
                          'You bear the direct costs of returning the '
                          'goods.\n\n'
                          'You only have to pay for any loss of value of '
                          'the goods if this loss of value is due to '
                          'handling that is not necessary to inspect the '
                          'condition, properties and functioning of the '
                          'goods.',
                    ),
                    _Section(
                      title: 'C. Relationship to refund mechanisms',
                      body:
                          'The statutory right of withdrawal exists '
                          'independently and alongside the refund '
                          'mechanisms set out in § X Refund Policy of the '
                          'Riftr Terms. Buyers may choose which path to '
                          'pursue:\n\n'
                          'a) Right of withdrawal (commercial sellers '
                          'only): exclusively the rules under §§ 355 et '
                          'seq. BGB apply; no fault needs to be '
                          'demonstrated. The platform service fee remains '
                          'with the platform, since no defect '
                          'attributable to the seller is involved.\n\n'
                          'b) Complaint via the Riftr complaint function: '
                          'the reason-code-based rules of the Refund '
                          'Policy apply. The fault question depends on '
                          'the reason code chosen by the buyer.\n\n'
                          'If the buyer selects the reason code "not '
                          'arrived" or "wrong card" in the complaint '
                          'workflow and the order originates from a '
                          'commercial seller, the Riftr app actively '
                          'asks the buyer whether they would like to '
                          'exercise the statutory right of withdrawal '
                          'instead of the platform-internal complaint '
                          'path. The choice is recorded in the audit log.',
                    ),
                    _Section(
                      title: 'D. Model withdrawal form',
                      body:
                          'If you wish to withdraw from the contract, '
                          'please fill in this form and send it back to '
                          'the respective seller (contact details in the '
                          'order confirmation in the Riftr app):\n\n'
                          'I/We (*) hereby give notice that I/we (*) '
                          'withdraw from my/our (*) contract for the '
                          'purchase of the following goods (*) / the '
                          'provision of the following service (*):\n\n'
                          '_______________________________________\n\n'
                          'Ordered on (*) / received on (*):\n'
                          '_______________________________________\n\n'
                          'Order number (Riftr Order ID, if available):\n'
                          '_______________________________________\n\n'
                          'Name of the consumer(s):\n'
                          '_______________________________________\n\n'
                          'Address of the consumer(s):\n'
                          '_______________________________________\n\n'
                          'Signature of the consumer(s) '
                          '(only when notified on paper):\n'
                          '_______________________________________\n\n'
                          'Date:\n'
                          '_______________________________________\n\n'
                          '(*) Delete as appropriate.',
                    ),
                    _Section(
                      title: 'E. Platform contact',
                      body:
                          'For questions regarding the application of '
                          'the right of withdrawal on the Riftr platform, '
                          'Riftr UG (haftungsbeschränkt) i. G. is '
                          'available at the following contact details:\n\n'
                          'Riftr UG (haftungsbeschränkt) i. G.\n'
                          '[Address will be added after UG registration]\n'
                          'Email: support@getriftr.app\n\n'
                          'The withdrawal itself must be declared to the '
                          'seller, not to Riftr. Riftr is not a party to '
                          'the purchase contract and cannot accept the '
                          'withdrawal directly or decide on it.',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _StandFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: AppColors.amberBorderMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.amber400),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Disclaimer: This is an English translation of our '
              'withdrawal instructions. For all legal matters please '
              'refer to the original German text (Anhang 1 zur Riftr-AGB, '
              '"Widerrufsbelehrung"), which is the legally binding '
              'version.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyBold.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.amber400,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandFooter extends StatelessWidget {
  const _StandFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'Last updated: 30 April 2026 — Riftr UG '
        '(haftungsbeschränkt) i. G. — Annex 1 to the Riftr Terms. '
        'In case of conflict, the binding German version '
        '(Riftr_AGB_Anhang_1_Widerrufsbelehrung.md) takes precedence.',
        style: AppTextStyles.tiny.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    );
  }
}
