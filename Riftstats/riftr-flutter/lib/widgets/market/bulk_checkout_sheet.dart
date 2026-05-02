import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/payment_fees.dart' as fees;
import '../../data/shipping_rates.dart';
import '../../models/market/listing_model.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/profile_service.dart';
import '../../services/seller_service.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import '../drag_to_dismiss.dart';
import '../form_section_label.dart';
import '../gold_header.dart';
import '../riftr_drag_handle.dart';
import '../riftr_toast.dart';
import 'condition_badge.dart';

/// Phase 4 (2026-04-28): Multi-Seller-Cart-Checkout.
///
/// Flow:
///   1. Buyer fills/confirms shipping address
///   2. Tap "Pay" → `setupCardForCart` Cloud-Function liefert SetupIntent-clientSecret
///   3. Stripe-PaymentSheet zeigt Karten-Eingabe + 3DS-Challenge
///   4. SetupIntent confirmed → Buyer-`paymentMethodId` gespeichert
///   5. `processMultiSellerCart` Cloud-Function loopt sequenziell ueber alle
///      Seller-Groups, erstellt PaymentIntents mit `off_session: true`,
///      `confirm: true`, `capture_method: "manual"`. Service-Gebuehr nur
///      auf erstem PI; alle anderen tragen nur ihre Provision.
///   6. Bei Teilfehler: alle vorherigen PIs auto-cancelled (Auth-Release),
///      kein Geld floss, alle Listings freigegeben. Cart bleibt intakt.
///   7. Bei Voll-Erfolg: Sheet returns `count > 0`; cart_screen zeigt Toast,
///      raeumt Cart-Items.
///
/// Single-Seller-Carts (=1 Seller) gehen NICHT durch hier — die nutzen
/// CheckoutSheet (= einfacher Direct-Charge-Pfad). cart_screen routes.
class BulkCheckoutSheet extends StatefulWidget {
  const BulkCheckoutSheet({super.key});

  @override
  State<BulkCheckoutSheet> createState() => _BulkCheckoutSheetState();
}

class _BulkCheckoutSheetState extends State<BulkCheckoutSheet> {
  static final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String? _selectedCountry;

  bool _loading = false;
  String? _error;

  // Progress state for the multi-seller-PI-loop. Backend processes
  // sequentially but returns only at the end (all-success or first-failure
  // with rollback) — so we show a generic "processing N orders" loading.
  int _sellerCount = 0;

  CartService get _cart => CartService.instance;

  @override
  void initState() {
    super.initState();
    _sellerCount = _cart.itemsBySeller.length;
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = AuthService.instance.uid;
    final suffix = uid == null ? '' : '_$uid';

    final savedName = prefs.getString('buyer_name$suffix');
    final savedStreet = prefs.getString('buyer_street$suffix');
    if (savedStreet != null && savedStreet.isNotEmpty) {
      if (savedName != null && savedName.isNotEmpty) _nameController.text = savedName;
      _streetController.text = savedStreet;
      _cityController.text = prefs.getString('buyer_city$suffix') ?? '';
      _zipController.text = prefs.getString('buyer_zip$suffix') ?? '';
      if (mounted) setState(() => _selectedCountry = prefs.getString('buyer_country$suffix'));
      return;
    }

    final profile = ProfileService.instance.ownProfile;
    if (profile != null && profile.hasAddress) {
      _streetController.text = profile.street!;
      _cityController.text = profile.city!;
      _zipController.text = profile.zip!;
      if (mounted) setState(() => _selectedCountry = profile.country);
      return;
    }

    final seller = SellerService.instance.profile;
    _streetController.text = seller?.address?.street ?? '';
    _cityController.text = seller?.address?.city ?? '';
    _zipController.text = seller?.address?.zip ?? '';
    if (mounted) {
      setState(() {
        _selectedCountry =
            seller?.address?.country ?? seller?.country ?? profile?.country;
      });
    }
  }

  Future<void> _saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = AuthService.instance.uid;
    final suffix = uid == null ? '' : '_$uid';
    await prefs.setString('buyer_name$suffix', _nameController.text.trim());
    await prefs.setString('buyer_street$suffix', _streetController.text.trim());
    await prefs.setString('buyer_city$suffix', _cityController.text.trim());
    await prefs.setString('buyer_zip$suffix', _zipController.text.trim());
    if (_selectedCountry != null) {
      await prefs.setString('buyer_country$suffix', _selectedCountry!);
    }

    final current = ProfileService.instance.ownProfile ?? const UserProfile();
    ProfileService.instance.updateProfile(current.copyWith(
      country: _selectedCountry,
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      zip: _zipController.text.trim(),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  bool get _addressValid =>
      _nameController.text.trim().isNotEmpty &&
      _streetController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _zipController.text.trim().isNotEmpty &&
      _selectedCountry != null;

  // ── Cost computation (DRY mit cart_screen) ─────────────────────────

  /// Per-seller bundle shipping. Smart-pick (Cardmarket-style) — letter
  /// fuer kleine Bundles, tracked ueber €25 forced.
  double _shippingFor(String sellerId) {
    final picks = _cart.itemsBySeller[sellerId] ?? [];
    if (picks.isEmpty) return 0;
    final country = picks.first.sellerCountry;
    if (country == null || _selectedCountry == null) return 1.80;
    final bundleCount = picks.fold<int>(0, (s, i) => s + i.quantity);
    final bundleValue = picks.fold<double>(
        0, (s, i) => s + i.pricePerCard * i.quantity);
    final quote = ShippingRates.quoteForBundle(
      country,
      _selectedCountry!,
      cardCount: bundleCount,
      forceTracked: ShippingRates.requiresTracking(bundleValue: bundleValue),
    );
    return quote?.price ?? 1.80;
  }

  /// Phase 4: CartItem traegt keinen `insuredOnly`-Flag. Insured-Listings
  /// werden im Backend (`processMultiSellerCart`) ueber das jeweilige Listing-
  /// Doc geprueft und per-Seller-Group als `effectiveMethod: "insured"`
  /// erzwungen. Frontend default = letter / tracked nach Bundle-Value.
  ShippingMethod _methodFor(String sellerId) {
    final picks = _cart.itemsBySeller[sellerId] ?? [];
    if (picks.isEmpty) return ShippingMethod.letter;
    final bundleValue = picks.fold<double>(
        0, (s, i) => s + i.pricePerCard * i.quantity);
    if (ShippingRates.requiresTracking(bundleValue: bundleValue)) {
      return ShippingMethod.tracked;
    }
    return ShippingMethod.letter;
  }

  double _subtotalFor(String sellerId) {
    final picks = _cart.itemsBySeller[sellerId] ?? [];
    return picks.fold<double>(
        0, (s, i) => s + i.pricePerCard * i.quantity);
  }

  double get _grandSubtotal => _cart.itemsBySeller.keys
      .fold<double>(0, (s, id) => s + _subtotalFor(id));
  double get _grandShipping => _cart.itemsBySeller.keys
      .fold<double>(0, (s, id) => s + _shippingFor(id));
  double get _serviceFee => fees.serviceFeeEurFor(
        _grandSubtotal,
        sellerCount: _sellerCount,
      );
  double get _grandTotal => _grandSubtotal + _grandShipping + _serviceFee;

  bool get _canPay => _addressValid && !_loading && _sellerCount >= 2;

  // ── Pay handler ─────────────────────────────────────────────────────

  Future<void> _handlePay() async {
    if (!_canPay) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _saveAddress();

    try {
      // Step 1: SetupIntent — Buyer-Karte einmalig authorize-en (mit 3DS).
      final setupResult = await _functions
          .httpsCallable('setupCardForCart')
          .call<Map<String, dynamic>>({});
      final setupClientSecret = setupResult.data['clientSecret'] as String?;
      final setupIntentId = setupResult.data['setupIntentId'] as String?;
      if (setupClientSecret == null || setupIntentId == null) {
        throw Exception('Failed to start card setup');
      }

      // Step 2: Stripe-PaymentSheet (SetupMode) zeigt Karten-Eingabe.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: setupClientSecret,
          merchantDisplayName: 'Riftr',
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              background: AppColors.background,
              componentBackground: AppColors.surface,
              componentBorder: AppColors.border,
              componentDivider: AppColors.border,
              componentText: AppColors.textPrimary,
              primaryText: AppColors.textPrimary,
              secondaryText: AppColors.textSecondary,
              placeholderText: AppColors.textMuted,
              icon: AppColors.textSecondary,
              primary: AppColors.amber500,
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
              shadow: PaymentSheetShadowParams(color: Colors.transparent),
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: AppColors.amber500,
                  text: AppColors.background,
                ),
              ),
            ),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // Step 3: PaymentSheet closed without throwing → SetupIntent ist
      // im Status `succeeded`. Backend resolved den `paymentMethodId` aus
      // dem SetupIntent in `processMultiSellerCart` selbst (= eine Round-
      // Trip weniger und vermeidet Flutter-Stripe-SDK-API-Inkonsistenz).
      if (!mounted) return;

      // Step 4: processMultiSellerCart — Backend macht den sequenziellen
      // PI-Loop. Returns either all_succeeded or HttpsError mit Rollback.
      final addressJson = {
        'name': _nameController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'zip': _zipController.text.trim(),
        'country': _selectedCountry!,
      };
      final items = <Map<String, dynamic>>[];
      for (final entry in _cart.itemsBySeller.entries) {
        for (final i in entry.value) {
          items.add({'listingId': i.listingId, 'quantity': i.quantity});
        }
      }

      // Phase 4: Multi-Seller-Path uses 'tracked' as cart-level default
      // (Cardmarket-style — fast verlustfrei). Backend forciert per Seller-
      // Group auf 'insured' wenn ein Listing der Group `insuredOnly: true`
      // hat (siehe processMultiSellerCart, anyInsured-Check).
      const shippingMethod = 'tracked';

      final processResult = await _functions
          .httpsCallable('processMultiSellerCart')
          .call<Map<String, dynamic>>({
        'setupIntentId': setupIntentId,
        'items': items,
        'shippingMethod': shippingMethod,
        'shippingAddress': addressJson,
      });

      final orderIds = (processResult.data['orderIds'] as List?) ?? [];
      if (!mounted) return;
      Navigator.of(context).pop(orderIds.length);
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled) {
        if (mounted) {
          final msg = e.error.localizedMessage ?? 'Card setup failed';
          setState(() {
            _loading = false;
            _error = msg;
          });
          // Phase 4 UX-Fix: Error als Toast (= sticky/floating, immer
          // sichtbar). Inline-Error im Sheet rendert ganz unten unter dem
          // ganzen scrollbaren Content und ist real out-of-view → User
          // tappte Pay, sah nix passieren, rote Zeile war hinter Address-
          // Form versteckt.
          RiftrToast.error(context, msg);
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      // Phase 4 Toast-Polish: User-facing-Wording ohne Implementation-Details.
      // Backend-HttpsError-messages sind seit Phase 4 kuratiert (kein
      // "seller X/N", kein "decline_code"-Leak). Falls trotzdem etwas
      // Technisches durchkommt: generischer Fallback.
      String msg = 'Payment couldn\'t be completed. Please try again.';
      if (e is FirebaseFunctionsException) {
        if (e.code == 'unknown') {
          msg = 'No internet connection. Please check your network and try again.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          // Nur uebernehmen wenn's nicht-leer ist — Backend kuratiert die
          // User-faceability.
          msg = e.message!;
        }
        // Stripe-not-onboarded → Buyer-friendly wording.
        if (msg.contains('Stripe account is not fully onboarded') ||
            msg.contains('charges_enabled=false')) {
          msg = 'One of the sellers in your cart is still setting up '
              'payouts. Please try again later or remove that seller '
              'from your cart.';
        }
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = msg;
        });
        RiftrToast.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Per-seller summary cards
          for (final entry in _cart.itemsBySeller.entries) ...[
            _buildSellerSummary(entry.key, entry.value),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.base),

          // Address
          FormSectionLabel('SHIPPING ADDRESS'),
          const SizedBox(height: AppSpacing.sm),
          _textField('Full Name', _nameController),
          const SizedBox(height: AppSpacing.sm),
          _textField('Street', _streetController),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(flex: 2, child: _textField('City', _cityController)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _textField('ZIP', _zipController)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.rounded),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('Country',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ),
                isExpanded: true,
                dropdownColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                style: AppTextStyles.bodySmall,
                items: ShippingRates.countries.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCountry = v),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Grand total breakdown
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.rounded),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _priceRow('Subtotal',
                    '€${_grandSubtotal.toStringAsFixed(2)}'),
                _priceRow('Shipping ($_sellerCount sellers)',
                    '€${_grandShipping.toStringAsFixed(2)}'),
                _priceRow('Service fee',
                    '€${_serviceFee.toStringAsFixed(2)}'),
                Divider(color: AppColors.border, height: 16),
                _priceRow('Total',
                    '€${_grandTotal.toStringAsFixed(2)}',
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Multi-seller info banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.amberMuted,
              borderRadius: BorderRadius.circular(AppRadius.rounded),
              border: Border.all(color: AppColors.amberBorderMuted),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.amber400),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You\'re buying from $_sellerCount sellers. We charge each seller separately. '
                    'If any charge fails, all are auto-rolled back — your card isn\'t charged.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.loss),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );

    final payLabel = _loading
        ? 'Processing $_sellerCount orders…'
        : 'Pay €${_grandTotal.toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DragToDismiss(
              onDismissed: () => Navigator.of(context).pop(),
              backgroundColor: AppColors.background,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
                  ),
                  const GoldOrnamentHeader(title: 'CHECKOUT'),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(child: scrollContent),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.base,
              right: AppSpacing.base,
              bottom: 22,
              child: RiftrButton(
                label: payLabel,
                style: RiftrButtonStyle.primary,
                isLoading: _loading,
                height: 56,
                radius: AppRadius.pill,
                onPressed: _canPay ? _handlePay : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerSummary(String sellerId, List items) {
    final firstItem = items.first;
    final sellerName = firstItem.sellerName as String? ?? 'Seller';
    final subtotal = _subtotalFor(sellerId);
    final shipping = _shippingFor(sellerId);
    final method = _methodFor(sellerId);

    return RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.storefront_outlined, color: AppColors.amber400, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                sellerName,
                style: AppTextStyles.bodyBold.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${items.length} ${items.length == 1 ? 'card' : 'cards'}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // Item rows
          ...items.map<Widget>((i) {
            // CartItem speichert condition als String (Enum-Name) — wir
            // konvertieren zum Enum-Wert mit NM-Fallback fuer Bad-Data.
            final cond = CardCondition.values.firstWhere(
              (c) => c.name == (i.condition as String),
              orElse: () => CardCondition.NM,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  ConditionBadge(condition: cond),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${i.cardName}${i.quantity > 1 ? '  ×${i.quantity}' : ''}',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('€${(i.pricePerCard * i.quantity).toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.xs),
          _priceRow('Subtotal', '€${subtotal.toStringAsFixed(2)}'),
          _priceRow('Shipping (${method.shortLabel})',
              '€${shipping.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Container(
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
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    // Bold = Total row → titleMedium 16sp w900 (matches cart_screen).
    // Non-bold rows → bodySmall 13sp (design-doc primary minimum).
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold
                ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w900)
                : AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        Text(value,
            style: bold
                ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w900)
                : AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
      ],
    );
  }
}

