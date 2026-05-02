import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/payment_fees.dart' as fees;
import '../../data/shipping_rates.dart';
import '../../models/market/listing_model.dart';
import '../../models/market/seller_profile.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/seller_service.dart';
import '../../services/demo_service.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import '../drag_to_dismiss.dart';
import '../form_section_label.dart';
import '../riftr_drag_handle.dart';
import 'condition_badge.dart';

/// Single cart item for multi-item checkout.
class CartCheckoutItem {
  final MarketListing listing;
  final int quantity;
  const CartCheckoutItem({required this.listing, required this.quantity});
}

/// Checkout bottom sheet for buying a listing.
class CheckoutSheet extends StatefulWidget {
  final MarketListing listing;
  final List<CartCheckoutItem>? cartItems;
  final int initialQuantity;

  const CheckoutSheet({
    super.key,
    required this.listing,
    this.cartItems,
    this.initialQuantity = 1,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String? _selectedCountry;
  ShippingMethod _shippingMethod = ShippingMethod.letter;
  late int _quantity;
  bool _loading = false;
  String? _error;

  MarketListing get _listing => widget.listing;
  List<CartCheckoutItem>? get _cartItems => widget.cartItems;
  bool get _isCart => _cartItems != null && _cartItems!.isNotEmpty;
  bool get _isDemo => DemoService.instance.isActive;


  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(1, widget.listing.availableQty);
    _loadAddress();

    // If listing requires insured, force it
    final anyInsured = _isCart
        ? _cartItems!.any((c) => c.listing.insuredOnly)
        : _listing.insuredOnly;
    if (anyInsured) {
      _shippingMethod = ShippingMethod.insured;
    } else {
      // Smart-pick the cheapest tier that can carry the bundle, honouring
      // Cardmarket's >€25 tracked-required policy. Falls back to `letter`
      // (the previous default) when we can't compute a quote.
      final bundleCount = _isCart
          ? _cartItems!.fold<int>(0, (sum, c) => sum + c.quantity)
          : _quantity;
      final bundleValue = _isCart
          ? _cartItems!
              .fold<double>(0, (sum, c) => sum + c.listing.price * c.quantity)
          : _listing.price * _quantity;
      final addr = ProfileService.instance.ownProfile?.country;
      if (addr != null && _listing.sellerCountry != null) {
        final quote = ShippingRates.quoteForBundle(
          _listing.sellerCountry!,
          addr,
          cardCount: bundleCount,
          forceTracked: ShippingRates.requiresTracking(bundleValue: bundleValue),
        );
        if (quote != null) _shippingMethod = quote.method;
      }
    }

    // Cap quantity to available (single-item mode only)
    if (!_isCart) {
      final maxQty = _listing.availableQty;
      if (_quantity > maxQty) _quantity = maxQty;
    }
  }

  Future<void> _loadAddress() async {
    // Priority: 1) SharedPreferences (remembers last purchase, per-user)
    //           2) Profile address  3) Seller profile
    final prefs = await SharedPreferences.getInstance();
    final uid = AuthService.instance.uid;
    // Per-user keys — prevents User B from seeing User A's saved checkout
    // address on the same device (privacy + order-integrity bug).
    final nameKey = uid == null ? 'buyer_name' : 'buyer_name_$uid';
    final streetKey = uid == null ? 'buyer_street' : 'buyer_street_$uid';
    final cityKey = uid == null ? 'buyer_city' : 'buyer_city_$uid';
    final zipKey = uid == null ? 'buyer_zip' : 'buyer_zip_$uid';
    final countryKey = uid == null ? 'buyer_country' : 'buyer_country_$uid';

    final savedName = prefs.getString(nameKey);
    final savedStreet = prefs.getString(streetKey);
    if (savedStreet != null && savedStreet.isNotEmpty) {
      if (savedName != null && savedName.isNotEmpty) _nameController.text = savedName;
      _streetController.text = savedStreet;
      _cityController.text = prefs.getString(cityKey) ?? '';
      _zipController.text = prefs.getString(zipKey) ?? '';
      if (mounted) setState(() => _selectedCountry = prefs.getString(countryKey));
      return;
    }

    // Name stays empty — user must enter their real name manually.
    final profile = ProfileService.instance.ownProfile;
    if (profile != null && profile.hasAddress) {
      _streetController.text = profile.street!;
      _cityController.text = profile.city!;
      _zipController.text = profile.zip!;
      if (mounted) setState(() => _selectedCountry = profile.country);
      return;
    }

    // Fall back to seller profile address (not name)
    final seller = SellerService.instance.profile;
    _streetController.text = seller?.address?.street ?? '';
    _cityController.text = seller?.address?.city ?? '';
    _zipController.text = seller?.address?.zip ?? '';
    if (mounted) {
      setState(() {
        _selectedCountry = seller?.address?.country ??
            seller?.country ??
            profile?.country;
      });
    }
  }

  Future<void> _saveAddress() async {
    final name = _nameController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final zip = _zipController.text.trim();

    // Save to SharedPreferences (legacy, fast local cache) with per-user keys.
    final prefs = await SharedPreferences.getInstance();
    final uid = AuthService.instance.uid;
    final suffix = uid == null ? '' : '_$uid';
    await prefs.setString('buyer_name$suffix', name);
    await prefs.setString('buyer_street$suffix', street);
    await prefs.setString('buyer_city$suffix', city);
    await prefs.setString('buyer_zip$suffix', zip);
    if (_selectedCountry != null) {
      await prefs.setString('buyer_country$suffix', _selectedCountry!);
    }

    // Write back to profile (central source of truth)
    final current = ProfileService.instance.ownProfile ?? const UserProfile();
    ProfileService.instance.updateProfile(current.copyWith(
      country: _selectedCountry,
      street: street,
      city: city,
      zip: zip,
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

  double get _subtotal => _isCart
      ? _cartItems!.fold(0.0, (sum, c) => sum + c.listing.price * c.quantity)
      : _listing.price * _quantity;

  double get _shippingCost {
    if (_selectedCountry == null || _listing.sellerCountry == null) return 2.00;
    return ShippingRates.getRate(
        _listing.sellerCountry!, _selectedCountry!, _shippingMethod);
  }

  /// Service-Gebuehr-Staffel (Phase-1) — Source-of-Truth ist
  /// `lib/data/payment_fees.dart`, das spiegelt 1:1 die Backend-Funktion
  /// `calculateOrderFees`. CheckoutSheet ist immer Single-Seller (Multi-
  /// Seller-Cart wird in cart_screen mit Toast geblockt, Phase 4 holt das
  /// nach), daher `sellerCount: 1` hier hardcoded.
  double get _serviceFee => fees.serviceFeeEurFor(_subtotal);
  double get _total => _subtotal + _shippingCost + _serviceFee;

  bool get _canPay => _addressValid && !_loading;

  Future<void> _handlePay() async {
    if (!_canPay) return;
    setState(() { _loading = true; _error = null; });
    await _executePurchase();
  }

  /// Phase-2 Buy-Flow: Direct Charge ueber `createPaymentIntent` Cloud
  /// Function. Backend liefert clientSecret + orderId zurueck. Stripe-
  /// PaymentSheet sammelt Karte + 3DS-Authentifizierung. Webhook
  /// (`payment_intent.amount_capturable_updated`) flippt Order-Status auf
  /// "paid" + sendet Push an Verkaeufer. Capture passiert spaeter in
  /// markShipped (capture_method: manual).
  Future<void> _executePurchase() async {
    final address = SellerAddress(
      name: _nameController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      zip: _zipController.text.trim(),
      country: _selectedCountry!,
    );

    // Persist address for next purchase.
    _saveAddress();

    if (_isDemo) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop('demo-order');
      return;
    }

    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

    // orderId outside try so the catch-Block kann ihn fuer Cleanup nutzen
    // (User-Cancel-Pfad muss `cancelPendingOrder` mit der orderId rufen).
    String? orderId;
    try {
      // 1. Build CF call params. Single-seller is the only path in Phase 2;
      //    Multi-Seller-Cart blockiert in cart_screen mit Toast (Phase 4).
      final callable = functions.httpsCallable('createPaymentIntent');
      final params = <String, dynamic>{
        'shippingMethod': _shippingMethod.name,
        'shippingAddress': address.toJson(),
        'sellerCount': 1,
        'chargeIndex': 0,
      };
      if (_isCart) {
        params['items'] = _cartItems!
            .map((c) => {
                  'listingId': c.listing.id,
                  'quantity': c.quantity,
                })
            .toList();
      } else {
        params['listingId'] = _listing.id;
        params['quantity'] = _quantity;
      }

      final result = await callable.call<Map<String, dynamic>>(params);
      final clientSecret = result.data['clientSecret'] as String?;
      orderId = result.data['orderId'] as String?;

      if (clientSecret == null || orderId == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Failed to create payment';
          });
        }
        return;
      }

      // 2. Initialize + present Stripe PaymentSheet. User picks Apple Pay /
      //    Google Pay / Card. 3DS-Challenge wird nativ gehandhabt.
      //
      // Apple Pay / Google Pay sind in Stripe TEST-MODE NICHT funktional —
      // sie ziehen ECHTE Karten aus dem Wallet, Stripe-Test-Mode rejected
      // die. Statt Tester mit "Payment failed"-Errors zu verwirren, hide
      // die Buttons komplett wenn pk_test_* aktiv ist. Bei Live-Switch zu
      // pk_live_* werden Apple/Google Pay automatisch wieder verfuegbar.
      final isStripeTestMode = Stripe.publishableKey.startsWith('pk_test_');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Riftr',
          applePay: isStripeTestMode
              ? null
              : const PaymentSheetApplePay(merchantCountryCode: 'DE'),
          googlePay: isStripeTestMode
              ? null
              : const PaymentSheetGooglePay(merchantCountryCode: 'DE'),
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

      // 3. Auth erfolgreich. Webhook flippt Order auf "paid" + notifiziert
      //    Verkaeufer. Pop mit orderId — Cart-Screen zeigt Success-Toast.
      if (mounted) Navigator.of(context).pop(orderId);
    } on StripeException catch (e) {
      // User-cancel: explizit cancelPendingOrder rufen damit der Order in
      // Firestore von `pending_payment` auf `cancelled` flippt + die Listing-
      // Reservation freigegeben wird. Sonst strandet der Listing bis zum
      // payment_intent.canceled-Webhook (defensive parallel) oder zur PI-
      // Auto-Expiry (24h, kein Webhook).
      if (e.error.code == FailureCode.Canceled) {
        if (orderId != null) {
          try {
            await functions
                .httpsCallable('cancelPendingOrder')
                .call({'orderId': orderId});
          } catch (cancelErr) {
            // Best-effort — der Webhook-Fallback raeumt sonst spaeter auf.
            debugPrint('cancelPendingOrder failed: $cancelErr');
          }
        }
        if (mounted) setState(() => _loading = false);
      } else {
        // Card-Decline / Stripe-Error: payment_intent.payment_failed Webhook
        // raeumt das Backend selbst auf. Frontend zeigt nur den Fehler.
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.error.localizedMessage ?? 'Payment failed';
          });
        }
      }
    } catch (e) {
      // Andere Fehler (Network, CF-Throw, etc.). Order ist evtl. erstellt,
      // PI evtl. erstellt — sicher cleanup'n falls orderId schon vorliegt.
      if (orderId != null) {
        try {
          await functions
              .httpsCallable('cancelPendingOrder')
              .call({'orderId': orderId});
        } catch (_) {
          // Best-effort — Webhook-Fallback / 24h PI-Expiry raeumt sonst auf.
        }
      }
      if (mounted) {
        String msg = 'Purchase failed';
        if (e is FirebaseFunctionsException) {
          msg = e.message ?? msg;
          // Map technical Stripe-not-onboarded message to a friendly
          // sentence — the CF returns the raw flag values which are
          // confusing for buyers. The real fix (S2-S5) hides such
          // listings from buyer queries entirely.
          if (msg.contains('Stripe account is not fully onboarded') ||
              msg.contains('charges_enabled=false')) {
            msg = 'This seller is still setting up payouts. '
                'Please try again later.';
          }
          if (e.code == 'unknown') {
            msg = 'No internet connection. Please check your network and try again.';
          }
        }
        setState(() {
          _loading = false;
          _error = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = _listing.availableQty;

    final scrollContent = SingleChildScrollView(
      // 120dp bottom padding clears the pinned Pay pill (mirrors
      // CardPreviewOverlay + BulkCheckoutSheet) so the last form field
      // never sits flush against the CTA.
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, 120),
      child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Title
          Text(
            _isCart
                ? 'Buy ${_cartItems!.fold(0, (sum, c) => sum + c.quantity)} cards'
                : 'Buy ${_listing.cardName}',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
            const SizedBox(height: AppSpacing.base),

            // ── Order Summary ──
            if (_isCart)
              ...(_cartItems!.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            ConditionBadge(condition: c.listing.condition),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                c.listing.cardName,
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.quantity > 1) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '×${c.quantity}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '€${(c.listing.price * c.quantity).toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              )))
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ConditionBadge(condition: _listing.condition),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _listing.language == 'CN' ? '🇨🇳' : '🇬🇧',
                              style: AppTextStyles.labelMedium,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'from ${_listing.sellerName}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          '€${_listing.price.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyBold.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    if (_listing.sellerCountry != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Ships from ${_countryFlag(_listing.sellerCountry!)}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // Pre-Release banner
            if (_listing.isPreRelease)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.amberMuted,
                  borderRadius: AppRadius.baseBR,
                  border: Border.all(color: AppColors.amberBorderMuted),
                ),
                child: Row(children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.amber400),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(
                    'Pre-Release — this order will ship after ${_listing.preReleaseDate}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.amber400),
                  )),
                ]),
              ),

            const SizedBox(height: AppSpacing.base),

            // ── Quantity (only if multi-qty available, single-item mode) ──
            if (!_isCart && maxQty > 1) ...[
              FormSectionLabel('QUANTITY'),
              const SizedBox(height: 6),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _qtyButton(Icons.remove, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_quantity',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    _qtyButton(Icons.add, () {
                      if (_quantity < maxQty) setState(() => _quantity++);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],

            // ── Shipping Address ──
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
            // Country dropdown
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
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text('Country', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
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
            const SizedBox(height: AppSpacing.base),

            // ── Shipping Method ──
            FormSectionLabel('SHIPPING METHOD'),
            const SizedBox(height: AppSpacing.sm),
            ..._buildShippingOptions(),
            const SizedBox(height: AppSpacing.base),

            // ── Price Breakdown ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.rounded),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _priceRow('Subtotal', '€${_subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.xs),
                  _priceRow('Shipping (${_shippingMethod.shortLabel})',
                      '€${_shippingCost.toStringAsFixed(2)}'),
                  if (_serviceFee > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _priceRow('Service Fee', '€${_serviceFee.toStringAsFixed(2)}'),
                  ],
                  Divider(color: AppColors.border, height: 16),
                  _priceRow('Total', '€${_total.toStringAsFixed(2)}',
                      bold: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Error message rendered ONLY by the Positioned overlay above
            // the Pay button (line ~717). Avoid the in-scroll duplicate
            // we used to have here — same _error showed up twice.

          ],
        ),
      ); // closes Column → SingleChildScrollView → scrollContent assignment

    // Phase-2 Pay-Button: einheitlich amber/primary (Buy-Aktion in allen
    // Detail-Views, siehe CLAUDE.md → Card-Detail Action Buttons).
    final payButtonStyle = RiftrButtonStyle.primary;
    final payLabel = _loading
        ? 'Paying…'
        : 'Pay €${_total.toStringAsFixed(2)}';

    // Architecture mirrors CardPreviewOverlay (Cards-Tab pattern) and the
    // refactored BulkCheckoutSheet so all three sheets share one feel:
    //   Scaffold + SafeArea(top:true, bottom:false) + Stack
    //   DragToDismiss wraps Column[handle, Expanded(scrollContent)]
    //   Positioned(bottom:22) Pay pill
    //   No gradient fade (Card-Preview convention)
    return Scaffold(
      backgroundColor: AppColors.background,
      // Default true → Flutter shrinks the Scaffold body when the keyboard
      // appears, our Expanded(scrollContent) follows. Address-form fields
      // stay visible above the keyboard without bouncing.
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
                    child:
                        RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
                  ),
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
                style: payButtonStyle,
                isLoading: _loading,
                height: 56,
                radius: AppRadius.pill,
                onPressed: _canPay ? _handlePay : null,
              ),
            ),
            if (_error != null)
              Positioned(
                left: AppSpacing.base,
                right: AppSpacing.base,
                bottom: 22 + 48 + AppSpacing.sm,
                child: Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.loss),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  List<Widget> _buildShippingOptions() {
    final methods = _listing.insuredOnly
        ? [ShippingMethod.insured]
        : ShippingMethod.values;

    return methods.map((method) {
      final selected = method == _shippingMethod;
      final cost = _selectedCountry != null && _listing.sellerCountry != null
          ? ShippingRates.getRate(
              _listing.sellerCountry!, _selectedCountry!, method)
          : null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => setState(() => _shippingMethod = method),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.win : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.rounded),
              border: Border.all(
                color: selected ? AppColors.win : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 16,
                      color: selected ? AppColors.background : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      method.shortLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selected ? AppColors.background : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (cost != null)
                  Text(
                    '€${cost.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      // Bei selected: dark Text auf gruenem Hintergrund (gleiche
                      // Logik wie das Method-Label-Text einen Schritt weiter oben).
                      // Vorher: AppColors.win auf AppColors.win = unlesbar.
                      color: selected ? AppColors.background : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
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
    // Bold = Total row (16sp w900) — matches cart_screen Total formatting.
    // Non-bold rows: bodySmall (13sp) — design-doc primary minimum size.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bold
          ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w900)
          : AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        Text(value, style: bold
          ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w900)
          : AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }

  static String _countryFlag(String code) {
    return code.toUpperCase().codeUnits
        .map((c) => String.fromCharCode(0x1F1E6 - 0x41 + c))
        .join();
  }
}
