import 'package:flutter/material.dart';
import '../../models/market/seller_profile.dart';
import '../../services/seller_service.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import '../riftr_toast.dart';

/// Self-Reclassification: Privat → Gewerblich.
///
/// **Rechtshintergrund (BACKLOG Pre-Launch Legal Track Ticket 4):**
/// Wenn ein Verkaeufer seinen Status aendern muss (z. B. weil er die
/// DAC7-Schwellen reisst oder freiwillig zu gewerblich wechselt),
/// MUSS er das selbst aktiv tun. Riftr darf NICHT stillschweigend
/// re-klassifizieren — das waere ein Verstoss gegen § 308 Nr. 4 BGB
/// (unangemessene Aenderungsklausel).
///
/// Reverse-Pfad (Gewerblich → Privat) ist NICHT in diesem Sheet — das
/// ist DAC7-Counter-Reset-Risiko und braucht eigene UX + Backend-Logik.
///
/// Erfasst die gleichen Pflichtfelder wie der erste Onboarding-Step
/// fuer gewerbliche Verkaeufer (Firmierung, USt-IdNr, Pflicht-Hinweis-
/// Checkbox), pre-filled mit den bereits vorhandenen Profil-Daten.
/// Email-Verifikation und Stripe-Onboarding bleiben unangetastet —
/// nur der Status-Block wird aktualisiert.
class SellerReclassificationSheet extends StatefulWidget {
  const SellerReclassificationSheet({super.key});

  /// Convenience: show as a Riftr sheet.
  static Future<bool?> show(BuildContext context) {
    return showRiftrSheet<bool>(
      context: context,
      builder: (_) => const SellerReclassificationSheet(),
    );
  }

  @override
  State<SellerReclassificationSheet> createState() =>
      _SellerReclassificationSheetState();
}

class _SellerReclassificationSheetState
    extends State<SellerReclassificationSheet> {
  final _legalEntityNameController = TextEditingController();
  final _vatIdController = TextEditingController();
  String? _vatIdError;
  bool _termsAccepted = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _legalEntityNameController.dispose();
    _vatIdController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _legalEntityNameController.text.trim().isNotEmpty &&
      SellerProfile.validateVatId(_vatIdController.text) == null &&
      _termsAccepted;

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final seller = SellerService.instance.profile;
    if (seller == null || seller.address == null) {
      setState(() {
        _saving = false;
        _error = 'Seller profile incomplete — finish onboarding first.';
      });
      return;
    }

    final ok = await SellerService.instance.saveProfile(
      displayName: seller.displayName ?? '',
      email: seller.email ?? '',
      address: seller.address!,
      isCommercialSeller: true,
      vatId: SellerProfile.canonicalVatId(_vatIdController.text),
      legalEntityName: _legalEntityNameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop(true);
      RiftrToast.success(
        context,
        'Switched to commercial seller status.',
      );
    } else {
      setState(() => _error = 'Failed to save. Try again.');
    }
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
            'Switch to commercial seller',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You declare yourself as an entrepreneur (§ 14 BGB). Buyers '
            'purchasing from you will get the 14-day right of withdrawal. '
            'You take on additional obligations (trade registration, '
            'VAT filing, bookkeeping).',
            style: AppTextStyles.bodySmallSecondary.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),

          _label('LEGAL ENTITY NAME'),
          _input(
            controller: _legalEntityNameController,
            hint: 'e.g. Max Mustermann e. K. or Riftr UG',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),

          _label('VAT ID'),
          _input(
            controller: _vatIdController,
            hint: 'e.g. DE123456789',
            onChanged: (value) => setState(() {
              _vatIdError = SellerProfile.validateVatId(value);
            }),
          ),
          if (_vatIdError != null && _vatIdController.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _vatIdError!,
              style: AppTextStyles.tiny.copyWith(color: AppColors.loss),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          GestureDetector(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _termsAccepted
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: _termsAccepted
                      ? AppColors.amber400
                      : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'I confirm I am acting as an entrepreneur (§ 14 BGB) '
                    'and accept the additional obligations: trade '
                    'registration, VAT filing, bookkeeping. I am '
                    'responsible for ensuring my Stripe account reflects '
                    'this status (individual → company).',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.loss),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: RiftrButton(
                  label: 'Cancel',
                  style: RiftrButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: RiftrButton(
                  label: _saving ? 'Saving...' : 'Switch to commercial',
                  style: RiftrButtonStyle.primary,
                  onPressed: (_isValid && !_saving) ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.tiny.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1,
        ),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.rounded),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          autocorrect: false,
          enableSuggestions: false,
          controller: controller,
          style: AppTextStyles.bodySmall
              .copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md),
            border: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
