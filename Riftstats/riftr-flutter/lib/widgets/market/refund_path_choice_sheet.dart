import 'package:flutter/material.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';

/// Möglicher Auswahl-Wert des Sheets.
enum RefundPathChoice {
  /// Käufer wählt den plattform-internen Reklamations-Pfad.
  reklamation,

  /// Käufer wählt das gesetzliche Widerrufsrecht (§ 312g BGB).
  /// Frontend zeigt anschließend ein Modal mit der Widerrufsbelehrung
  /// (Anhang 1 zur Riftr AGB).
  widerruf,
}

/// Reklamations-Pfad-Auswahl-Sheet.
///
/// **Anforderung aus AGB-Anhang 1 (Widerrufsbelehrung) Abschnitt C
/// (2026-05-01):** Wählt der Käufer im Reklamations-Workflow der App
/// den Reason-Code `not_arrived` oder `wrong_card` UND stammt die Bestellung
/// von einem gewerblichen Verkäufer (§ 14 BGB), MUSS die App den Käufer
/// aktiv fragen, ob er anstelle des plattform-internen Reklamations-Pfades
/// das gesetzliche Widerrufsrecht ausüben möchte.
///
/// **Anti-Dark-Pattern (UWG/UCPD-Schutz):**
/// - Beide Optionen sind visuell gleichwertig (gleiche Größe, gleiche
///   Buttons-Form, neutrale Default-Auswahl)
/// - Keine Default-Vorauswahl
/// - Weder Widerruf noch Reklamation wird als „empfohlen" markiert
///
/// Returns die Käufer-Auswahl als [RefundPathChoice], oder `null` wenn
/// der Käufer das Sheet abbricht (Swipe-down ohne Button-Tap).
class RefundPathChoiceSheet extends StatelessWidget {
  const RefundPathChoiceSheet({super.key});

  /// Zeigt das Sheet. Returns die Käufer-Auswahl (oder null bei Abbruch).
  /// Caller MUSS den Sheet-Zeitstempel vor dem Aufruf erfassen
  /// (`widerrufHinweisShownAt`) und den Auswahl-Zeitstempel nach dem
  /// Return (`widerrufHinweisChosenAt`) — beide gehen ins openDispute-
  /// Audit-Log.
  static Future<RefundPathChoice?> show(BuildContext context) {
    return showRiftrSheet<RefundPathChoice>(
      context: context,
      builder: (ctx) => const RefundPathChoiceSheet(),
    );
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
            'Which option would you like?',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Since the seller is commercial, you have two consumer options:',
            style: AppTextStyles.bodySmallSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Option A: Widerrufsrecht — keine Default-Markierung
          _OptionCard(
            title: 'Right of withdrawal (§ 312g BGB)',
            bullets: [
              'No proof of fault required',
              'You pay return shipping',
              'Service fee stays with the platform',
              'Deadline: 14 days after receipt',
            ],
            onTap: () => Navigator.pop(context, RefundPathChoice.widerruf),
          ),
          const SizedBox(height: AppSpacing.md),

          // Option B: Reklamation — gleiche visuelle Gewichtung
          _OptionCard(
            title: 'Complaint about defect',
            bullets: [
              'Seller fault must be established',
              'On clear seller fault: full refund incl. service fee',
              'Seller may propose a partial refund',
              'After 7 days seller silence: auto-refund',
            ],
            onTap: () => Navigator.pop(context, RefundPathChoice.reklamation),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            'Riftr does not decide. Both paths are settled between you and the seller.',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final List<String> bullets;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.bullets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        b,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
