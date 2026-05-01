import 'package:flutter/material.dart';
import '../../models/market/seller_profile.dart';
import '../../theme/app_theme.dart';

/// Reusable imprint card for commercial sellers. Renders nothing when
/// the seller is private — DSGVO-conform default (kein PII-Leak ohne
/// Pflicht-Veröffentlichung).
///
/// **Rechtsgrundlage**: § 5 DDG (frühere TMG § 5) und Art. 30 DSA
/// verpflichten gewerbliche Anbieter (§ 14 BGB), Firmierung, ladungs-
/// fähige Anschrift, USt-IdNr und Email-Kontakt **leicht erkennbar,
/// unmittelbar erreichbar und ständig verfügbar** zu halten.
///
/// Typische Einbau-Stellen:
/// - **Bestellbestätigung / Order-Detail** (sichtbar nach Vertragsschluss)
/// - **Verkäufer-Profilseite** (sichtbar vor Vertragsschluss)
class SellerImprintCard extends StatelessWidget {
  final bool isCommercial;
  final String? legalEntityName;
  final String? vatId;
  final SellerAddress? address;
  final String? email;

  const SellerImprintCard({
    super.key,
    required this.isCommercial,
    this.legalEntityName,
    this.vatId,
    this.address,
    this.email,
  });

  bool get _hasAnyContent =>
      (legalEntityName?.trim().isNotEmpty == true) ||
      (vatId?.trim().isNotEmpty == true) ||
      (address != null && address!.isComplete) ||
      (email?.trim().isNotEmpty == true);

  @override
  Widget build(BuildContext context) {
    if (!isCommercial) return const SizedBox.shrink();
    if (!_hasAnyContent) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined,
                  size: 18, color: AppColors.amber400),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Seller imprint',
                style: AppTextStyles.bodyBold.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (legalEntityName?.trim().isNotEmpty == true)
            _row('Company', legalEntityName!),
          if (vatId?.trim().isNotEmpty == true) _row('VAT ID', vatId!),
          if (address != null && address!.isComplete)
            _row('Address', _formatAddress(address!)),
          if (email?.trim().isNotEmpty == true) _row('Email', email!),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Information per § 5 DDG / Art. 30 DSA — required for '
            'commercial sellers.',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(SellerAddress a) {
    final lines = <String>[
      a.street.trim(),
      [a.zip.trim(), a.city.trim()].where((s) => s.isNotEmpty).join(' '),
      a.country.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return lines.join('\n');
  }
}
