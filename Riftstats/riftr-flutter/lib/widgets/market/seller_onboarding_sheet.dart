import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../data/shipping_rates.dart';
import '../../models/market/seller_profile.dart';
import '../../models/profile_model.dart';
import '../../services/seller_service.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/demo_service.dart';

/// Multi-step onboarding sheet for first-time sellers.
/// Step 0: Name + Email + Address → Step 1: Email Verification Code
/// → Step 2: Stripe Connect Setup → Step 3: Done
class SellerOnboardingSheet extends StatefulWidget {
  const SellerOnboardingSheet({super.key});

  @override
  State<SellerOnboardingSheet> createState() => _SellerOnboardingSheetState();
}

class _SellerOnboardingSheetState extends State<SellerOnboardingSheet> {
  int _step = 0;
  bool _saving = false;
  bool _sendingCode = false;
  bool _verifying = false;
  bool _settingUpStripe = false;
  String? _error;

  // Step 0 fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String? _selectedCountry;

  // Step 0 — Verkaeufer-Status (2026-05-01, BACKLOG Ticket 1).
  // Default false (= privat). User MUSS aktiv waehlen — keine stille
  // Re-Klassifizierung durch Riftr (§ 308 Nr. 4 BGB).
  bool _isCommercial = false;
  final _legalEntityNameController = TextEditingController();
  final _vatIdController = TextEditingController();
  String? _vatIdError;
  bool _termsAccepted = false;

  // Step 1 fields
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());
  bool _codeSent = false;

  String get _codeValue => _codeControllers.map((c) => c.text).join();

  bool get _isDemo => DemoService.instance.isActive;

  @override
  void initState() {
    super.initState();

    // Pre-fill from existing data
    final seller = SellerService.instance.profile;
    final userProfile = ProfileService.instance.ownProfile;
    final authUser = AuthService.instance.currentUser;

    _nameController.text =
        seller?.displayName ?? userProfile?.displayName ?? authUser?.displayName ?? '';
    _emailController.text =
        seller?.email ?? authUser?.email ?? '';
    _streetController.text = seller?.address?.street ?? userProfile?.street ?? '';
    _cityController.text = seller?.address?.city ?? userProfile?.city ?? '';
    _zipController.text = seller?.address?.zip ?? userProfile?.zip ?? '';
    _selectedCountry =
        seller?.address?.country ?? seller?.country ?? userProfile?.country;

    // Status-Pre-Fill: wenn der User schon einmal als gewerblich gespeichert
    // wurde, vorhandene Werte vorbefuellen. Sonst bleibt _isCommercial=false
    // und der User muss aktiv waehlen.
    if (seller?.isCommercialSeller == true) {
      _isCommercial = true;
      _legalEntityNameController.text = seller?.legalEntityName ?? '';
      _vatIdController.text = seller?.vatId ?? '';
      _termsAccepted = true; // Schon einmal akzeptiert → bleibt akzeptiert
    }

    // Skip completed steps
    if (seller != null && seller.hasAddress && !seller.emailVerified) {
      _step = 1;
      _codeSent = true; // Assume code was already sent
    } else if (seller != null && seller.emailVerified && seller.stripeAccountId == null) {
      _step = 2; // Email verified but no Stripe yet
    } else if (seller != null && seller.emailVerified && seller.stripeAccountId != null) {
      _step = 3; // All done
    }

    // Listen for verification status changes
    if (!_isDemo) {
      SellerService.instance.addListener(_onSellerChanged);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _legalEntityNameController.dispose();
    _vatIdController.dispose();
    for (final c in _codeControllers) { c.dispose(); }
    for (final f in _codeFocusNodes) { f.dispose(); }
    if (!_isDemo) {
      SellerService.instance.removeListener(_onSellerChanged);
    }
    super.dispose();
  }

  void _onSellerChanged() {
    if (!mounted) return;
    final seller = SellerService.instance;
    if (seller.emailVerified && _step == 1) {
      setState(() => _step = 2); // Advance to Stripe setup
    }
    if (seller.profile?.stripeAccountId != null && _step == 2) {
      setState(() => _step = 3); // Stripe done, show success
    }
  }

  bool get _formValid {
    final basicValid = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().contains('@') &&
        _streetController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _zipController.text.trim().isNotEmpty &&
        _selectedCountry != null;
    if (!basicValid) return false;
    if (!_isCommercial) return true;
    // Commercial-Pflichtfelder: Firmierung + USt-IdNr (Format-valid) + Checkbox
    return _legalEntityNameController.text.trim().isNotEmpty &&
        SellerProfile.validateVatId(_vatIdController.text) == null &&
        _termsAccepted;
  }

  // ─── Actions ───

  Future<void> _saveAndSendCode() async {
    if (!_formValid) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final address = SellerAddress(
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      zip: _zipController.text.trim(),
      country: _selectedCountry!,
    );

    if (_isDemo) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _codeSent = true;
        _step = 1;
      });
      return;
    }

    // Save seller profile (incl. status declaration: privat/gewerblich)
    final ok = await SellerService.instance.saveProfile(
      displayName: _nameController.text.trim(),
      email: email,
      address: address,
      isCommercialSeller: _isCommercial,
      vatId: _isCommercial
          ? SellerProfile.canonicalVatId(_vatIdController.text)
          : null,
      legalEntityName: _isCommercial
          ? _legalEntityNameController.text.trim()
          : null,
    );
    if (!ok || !mounted) {
      setState(() {
        _saving = false;
        _error = 'Failed to save profile.';
      });
      return;
    }

    // Write address back to user profile (central source)
    final current = ProfileService.instance.ownProfile ?? const UserProfile();
    ProfileService.instance.updateProfile(current.copyWith(
      country: address.country,
      street: address.street,
      city: address.city,
      zip: address.zip,
    ));

    // Send verification code
    final sent = await SellerService.instance.sendVerificationCode(email);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (sent) {
        _codeSent = true;
        _step = 1;
      } else {
        _error = 'Failed to send verification code.';
      }
    });
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _sendingCode = true;
      _error = null;
    });

    if (_isDemo) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _sendingCode = false);
      return;
    }

    final sent = await SellerService.instance.sendVerificationCode(email);
    if (!mounted) return;
    setState(() {
      _sendingCode = false;
      if (!sent) _error = 'Failed to resend code.';
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeValue;
    if (code.length != 6) return;

    setState(() {
      _verifying = true;
      _error = null;
    });

    if (_isDemo) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _step = 2;
      });
      return;
    }

    final ok = await SellerService.instance.verifyEmailCode(code);
    if (!mounted) return;
    setState(() {
      _verifying = false;
      if (ok) {
        _step = 2; // Advance to Stripe setup
      } else {
        _error = 'Invalid or expired code. Please try again.';
      }
    });
  }

  Future<void> _setupStripe() async {
    setState(() {
      _settingUpStripe = true;
      _error = null;
    });

    if (_isDemo) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _settingUpStripe = false;
        _step = 3;
      });
      return;
    }

    final url = await SellerService.instance.createStripeAccount();
    if (!mounted) return;

    if (url == null) {
      setState(() {
        _settingUpStripe = false;
        _error = 'Failed to create Stripe account. Try again.';
      });
      return;
    }

    // Open Stripe onboarding in browser
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;
    setState(() => _settingUpStripe = false);
    // SellerService listener will detect stripeAccountId and advance to step 3
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap outside any focused TextField → keyboard dismiss.
      // HitTestBehavior.opaque catches taps on empty sheet area; the
      // sheet sits in its own showModalBottomSheet route so the
      // AppShell-level global handler doesn't reach here.
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Banking Setup',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isDemo ? 'Demo Mode — verification will be simulated' : 'One-time setup for selling & payouts',
            style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.base),

          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 20),

          // Step content
          if (_step == 0) _buildDetailsStep(),
          if (_step == 1) _buildVerifyStep(),
          if (_step == 2) _buildStripeStep(),
          if (_step == 3) _buildDoneStep(),

          // Error
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTextStyles.small.copyWith(color: AppColors.loss),
            ),
          ],
        ],
        ),
      ),
    );
  }

  // ─── Step Indicator ───

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(0, 'Details'),
        _stepLine(0),
        _stepDot(1, 'Verify'),
        _stepLine(1),
        _stepDot(2, 'Payouts'),
        _stepLine(2),
        _stepDot(3, 'Done'),
      ],
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _step >= step;
    final isCurrent = _step == step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.amberMuted
                  : AppColors.background,
              border: Border.all(
                color: isActive
                    ? AppColors.amber400
                    : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: _step > step
                  ? Icon(Icons.check, size: 14, color: AppColors.amber400)
                  : Text(
                      '${step + 1}',
                      style: AppTextStyles.small.copyWith(
                        color: isActive ? AppColors.amber400 : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.micro.copyWith(
              color: isActive ? AppColors.amber400 : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(int afterStep) {
    final active = _step > afterStep;
    return Container(
      height: 2,
      width: 24,
      margin: const EdgeInsets.only(bottom: 18),
      color: active
          ? AppColors.amber400
          : AppColors.border,
    );
  }

  // ─── Step 0: Name + Email + Address ───

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verkaeufer-Status-Wahl (BACKLOG Ticket 1, 2026-05-01).
        // Default ist privat — User muss aktiv waehlen, keine stille
        // Re-Klassifizierung durch Riftr (§ 308 Nr. 4 BGB).
        Text(
          'SELLER STATUS',
          style: AppTextStyles.tiny.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        _statusOptionCard(
          isSelected: !_isCommercial,
          title: 'Private seller',
          subtitle:
              'Selling occasional cards from your own collection. No '
              'statutory withdrawal right under § 312g BGB.',
          onTap: () => setState(() => _isCommercial = false),
        ),
        const SizedBox(height: AppSpacing.sm),
        _statusOptionCard(
          isSelected: _isCommercial,
          title: 'Commercial seller (§ 14 BGB)',
          subtitle:
              'Selling regularly as a business. Buyers get the 14-day '
              'right of withdrawal. Requires VAT ID + legal entity name.',
          onTap: () => setState(() => _isCommercial = true),
        ),
        const SizedBox(height: AppSpacing.lg),

        _textField('FULL NAME', _nameController, 'Your real name'),
        const SizedBox(height: 14),
        _textField('EMAIL', _emailController, 'your@email.com',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _textField('STREET', _streetController, 'Street address'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _textField('CITY', _cityController, 'City'),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _textField('ZIP', _zipController, 'ZIP'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Country dropdown
        Text(
          'COUNTRY',
          style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              hint: Text(
                'Select country',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              dropdownColor: AppColors.surface,
              borderRadius: AppRadius.baseBR,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 20),
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              items: ShippingRates.countries.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text('${entry.value} (${entry.key})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCountry = value),
            ),
          ),
        ),

        // Commercial-conditional fields: Firmierung + USt-IdNr + Pflicht-Hinweis.
        if (_isCommercial) ...[
          const SizedBox(height: AppSpacing.lg),
          _textField('LEGAL ENTITY NAME', _legalEntityNameController,
              'e.g. Max Mustermann e. K. or Riftr UG'),
          const SizedBox(height: 14),
          _textField(
            'VAT ID',
            _vatIdController,
            'e.g. DE123456789',
            onChanged: (value) {
              setState(() {
                _vatIdError = SellerProfile.validateVatId(value);
              });
            },
          ),
          if (_vatIdError != null && _vatIdController.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _vatIdError!,
              style: AppTextStyles.tiny.copyWith(color: AppColors.loss),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _termsCheckbox(),
        ],

        const SizedBox(height: 20),

        // Continue button
        _actionButton(
          label: _saving ? 'Sending code...' : 'Continue & Verify Email',
          enabled: _formValid && !_saving,
          onTap: _saveAndSendCode,
        ),
      ],
    );
  }

  // ─── Status-Option-Card (Privat/Gewerblich) ───
  Widget _statusOptionCard({
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amberMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.rounded),
          border: Border.all(
            color: isSelected ? AppColors.amber400 : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.amber400 : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
          ],
        ),
      ),
    );
  }

  // ─── Pflicht-Hinweis-Checkbox fuer gewerbliche Verkaeufer ───
  Widget _termsCheckbox() {
    return GestureDetector(
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
            color:
                _termsAccepted ? AppColors.amber400 : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'I confirm I am acting as an entrepreneur (§ 14 BGB) and '
              'accept the additional obligations: trade registration, '
              'VAT filing, bookkeeping. I am responsible for ensuring '
              'my Stripe account reflects this status.',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Email Verification ───

  Widget _buildVerifyStep() {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : SellerService.instance.profile?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.baseBR,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 32,
                color: AppColors.amber400,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Check Your Email',
                style: AppTextStyles.bodyBold.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _isDemo
                    ? 'Demo mode — enter any 6 digits'
                    : 'We sent a 6-digit code to\n$email',
                style: AppTextStyles.small.copyWith(color: AppColors.textMuted, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Code input
        Text(
          'VERIFICATION CODE',
          style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCodeBoxes(),
        const SizedBox(height: AppSpacing.md),

        // Resend link
        Center(
          child: GestureDetector(
            onTap: _sendingCode ? null : _resendCode,
            child: Text(
              _sendingCode ? 'Sending...' : 'Didn\'t receive it? Resend code',
              style: AppTextStyles.small.copyWith(
                color: _sendingCode ? AppColors.textMuted : AppColors.amber400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Verify button
        _actionButton(
          label: _verifying ? 'Verifying...' : 'Verify',
          enabled: _codeValue.length == 6 && !_verifying,
          onTap: _verifyCode,
        ),
      ],
    );
  }

  Widget _buildCodeBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final hasValue = _codeControllers[i].text.isNotEmpty;
        return Container(
          width: 44,
          height: 56,
          margin: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(
              color: hasValue
                  ? AppColors.amber400
                  : AppColors.border,
            ),
          ),
          child: Center(
            child: TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: _codeControllers[i],
              focusNode: _codeFocusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.w900, height: 1, letterSpacing: 0),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: '0',
                hintStyle: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.border,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty && i < 5) {
                _codeFocusNodes[i + 1].requestFocus();
              }
              if (value.isEmpty && i > 0) {
                _codeFocusNodes[i - 1].requestFocus();
              }
            },
          ),
          ),
        );
      }),
    );
  }

  // ─── Step 2: Stripe Connect Setup ───

  Widget _buildStripeStep() {
    final hasStripe = SellerService.instance.profile?.stripeAccountId != null;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amberMuted,
              border: Border.all(
                color: AppColors.amberMuted,
                width: 2,
              ),
            ),
            child: Icon(Icons.account_balance_outlined, size: 28, color: AppColors.amber400),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Set Up Payouts',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          _isDemo
              ? 'Demo mode — Stripe setup will be simulated'
              : 'Connect your bank account via Stripe to receive payouts.',
          style: AppTextStyles.small.copyWith(color: AppColors.textMuted, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Stripe handles all payment data securely. Riftr never sees your bank details.',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        if (hasStripe) ...[
          const SizedBox(height: AppSpacing.base),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.winMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.winBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.win),
                SizedBox(width: 6),
                Text(
                  'Stripe account connected',
                  style: AppTextStyles.small.copyWith(color: AppColors.win, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (hasStripe)
          _actionButton(
            label: 'Continue',
            enabled: true,
            onTap: () => setState(() => _step = 3),
          )
        else
          _actionButton(
            label: _settingUpStripe ? 'Opening Stripe...' : 'Set Up Payments',
            enabled: !_settingUpStripe,
            onTap: _setupStripe,
          ),
        if (!hasStripe && !_settingUpStripe) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: GestureDetector(
              onTap: () {
                // Check if Stripe was completed while browser was open
                final profile = SellerService.instance.profile;
                if (profile?.stripeAccountId != null) {
                  setState(() => _step = 3);
                }
              },
              child: Text(
                'I already completed Stripe setup',
                style: AppTextStyles.small.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Step 3: Done ───

  Widget _buildDoneStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.winMuted,
              border: Border.all(
                color: AppColors.winBorder,
                width: 2,
              ),
            ),
            child: Icon(Icons.check, size: 32, color: AppColors.win),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'All set up!',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Your profile is verified. You can now sell and receive payouts.',
          style: AppTextStyles.small.copyWith(color: AppColors.textMuted, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        _actionButton(
          label: 'Done',
          enabled: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  // ─── Shared Widgets ───

  Widget _textField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Container(
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
            keyboardType: keyboardType,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {});
              onChanged?.call(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.amberMuted
                : AppColors.border,
            borderRadius: AppRadius.baseBR,
            border: Border.all(
              color: enabled
                  ? AppColors.amber400
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold.copyWith(
              color: enabled ? AppColors.amber400 : AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
