import 'package:flutter/material.dart';
import '../../models/market/seller_profile.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import 'seller_reclassification_sheet.dart';

/// Three-stage banner for DAC7 / PStTG private-seller volume status.
///
/// **Why**: BACKLOG Ticket 3 — private sellers must be transparently
/// notified when they're approaching or hitting the DAC7 thresholds
/// (20 Tx / €1.200 soft, 30 Tx / €1.800 hard) so they can self-declare
/// as commercial in time. Renders nothing for users without a seller
/// profile, for commercial sellers (exempt), or below the soft threshold.
///
/// Stages (driven by `seller.dac7Status`):
/// - `soft`:      gold-tinted info, "approaching threshold"
/// - `hard`:      amber warning with day-countdown until suspension
/// - `suspended`: red error, listings paused, CTA opens
///                [SellerReclassificationSheet]
class Dac7StatusBanner extends StatelessWidget {
  final SellerProfile seller;

  const Dac7StatusBanner({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final status = seller.dac7Status;
    if (status == 'none') return const SizedBox.shrink();

    final count = seller.currentYearDac7Count;
    final gross = seller.currentYearDac7GrossRevenue;
    final daysLeft = seller.daysUntilVolumeSuspension;

    final spec = switch (status) {
      'soft' => _BannerSpec(
          icon: Icons.info_outline,
          accent: AppColors.amber400,
          background: AppColors.amberMuted,
          border: AppColors.amberBorderMuted,
          title: 'Approaching commercial threshold',
          body:
              'You have $count completed sales (€${gross.toStringAsFixed(2)}) '
              'this year. At 30 sales or €1.800 you must register as a '
              'commercial seller (DAC7).',
          ctaLabel: 'Learn more',
          ctaStyle: RiftrButtonStyle.text,
        ),
      'hard' => _BannerSpec(
          icon: Icons.warning_amber_rounded,
          accent: AppColors.amber500,
          background: AppColors.amberMuted,
          border: AppColors.amber500,
          title: daysLeft != null && daysLeft > 0
              ? 'Action required: $daysLeft '
                  '${daysLeft == 1 ? 'day' : 'days'} until suspension'
              : 'Action required: deadline expired',
          body:
              'You reached the DAC7 threshold ($count sales, '
              '€${gross.toStringAsFixed(2)}). Switch to commercial seller '
              'before the deadline or your listings will be paused.',
          ctaLabel: 'Switch to commercial',
          ctaStyle: RiftrButtonStyle.primary,
        ),
      'suspended' => _BannerSpec(
          icon: Icons.block,
          accent: AppColors.loss,
          background: AppColors.errorMuted,
          border: AppColors.loss,
          title: 'Listings paused — DAC7 deadline expired',
          body:
              'Your listings are currently paused. Switch to commercial '
              'seller to resume selling.',
          ctaLabel: 'Switch to commercial',
          ctaStyle: RiftrButtonStyle.primary,
        ),
      _ => null,
    };

    if (spec == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: spec.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(spec.icon, size: 20, color: spec.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  spec.title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: spec.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              spec.body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          if (status != 'soft') ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: SizedBox(
                width: double.infinity,
                child: RiftrButton(
                  label: spec.ctaLabel,
                  style: spec.ctaStyle,
                  onPressed: () =>
                      SellerReclassificationSheet.show(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerSpec {
  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
  final String title;
  final String body;
  final String ctaLabel;
  final RiftrButtonStyle ctaStyle;

  const _BannerSpec({
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaStyle,
  });
}
