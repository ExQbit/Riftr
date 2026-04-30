import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/payment_fees.dart' as fees;
import '../data/shipping_rates.dart';
import '../models/cart_item.dart';
import '../services/card_service.dart';
import '../services/cart_service.dart';
import '../services/listing_service.dart';
import '../services/profile_service.dart';
import '../widgets/market/bulk_checkout_sheet.dart';
import '../widgets/market/checkout_sheet.dart';
import '../theme/app_components.dart';
import '../theme/app_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/gold_header.dart';
import '../widgets/qty_stepper_row.dart';
import '../widgets/riftr_drag_handle.dart';
import '../widgets/market/condition_badge.dart';
import '../models/market/listing_model.dart';
import '../widgets/riftr_toast.dart';

/// Full-screen cart with DragToDismiss.
/// Single container per seller: header, items, more-from-seller, subtotal.
class CartScreen extends StatefulWidget {
  final VoidCallback? onGoToDiscover;
  final void Function(String sellerId, String sellerName)? onViewAuthor;
  const CartScreen({super.key, this.onGoToDiscover, this.onViewAuthor});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    CartService.instance.addListener(_refresh);
    ListingService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_refresh);
    ListingService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // bottom:false so the Stack reaches the physical screen edge —
        // Positioned(bottom: 22) for the Checkout button then matches the
        // exact spacing of CardPreviewOverlay's pill buttons.
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
                  const SizedBox(height: AppSpacing.md),
                  const RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: cart.isEmpty
                        ? _buildEmptyState()
                        : _buildCartContent(cart),
                  ),
                ],
              ),
            ),
            if (!cart.isEmpty)
              Positioned(
                left: AppSpacing.base,
                right: AppSpacing.base,
                bottom: 22,
                child: _buildCheckoutButton(cart),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──

  Widget _buildEmptyState() {
    return Center(
      child: RiftrEmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        subtitle: 'Discover cards to add to your cart',
        buttonLabel: 'Discover cards',
        onButtonPressed: () {
          Navigator.of(context).pop();
          widget.onGoToDiscover?.call();
        },
      ),
    );
  }

  // ── Cart Content ──

  Widget _buildCartContent(CartService cart) {
    final bySeller = cart.itemsBySeller;
    final buyerCountry = ProfileService.instance.ownProfile?.country;

    // Fixed Checkout-Button (im Stack ueberhalb des Scroll-Views) verdeckt
    // sonst die letzten ~80–110 dp der Grand-Total-Karte. Bottom-Spacer muss
    // groesser sein als button_height (56) + bottom-offset (22) + safe-area-
    // bottom (Home-Indicator) + Atemluft.
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Header
          const GoldOrnamentHeader(title: 'CART'),
          const SizedBox(height: AppSpacing.base),

          // Sub-header „X orders · Y cards" steht unten im Grand-Total-Card
          // schon — nicht doppelt anzeigen.

          // Seller groups
          ...bySeller.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            child: _buildSellerCard(entry.key, entry.value, buyerCountry),
          )),

          // Grand total
          _buildGrandTotal(cart, buyerCountry),
          // Bottom buffer: 22 (button bottom-offset) + 56 (button height)
          // + safe-area-bottom + 24 dp breathing room — sorgt dafuer dass
          // die Grand-Total-Karte vollstaendig ueber den Checkout-Button
          // gescrollt werden kann.
          SizedBox(height: 22 + 56 + bottomSafe + AppSpacing.lg),
        ],
      ),
    );
  }

  // ── Seller Card (single container for everything) ──

  Widget _buildSellerCard(String sellerId, List<CartItem> items, String? buyerCountry) {
    final seller = items.first;
    final sellerSubtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
    // Bundle size = total card-copies in this seller's basket. Drives the
    // letter→tracked→insured auto-upgrade.
    //
    // NOTE: CartItem doesn't carry the listing's `insuredOnly` flag (the
    // snapshot was modeled before that flag existed on listings), so we
    // can't honour insured-only at this level. Same gap as the previous
    // `cheapestRate(...)` call — checkout sheet re-validates against the
    // live listing and forces insured there.
    final bundleCount = items.fold<int>(0, (sum, i) => sum + i.quantity);
    final bundleValue =
        items.fold<double>(0, (sum, i) => sum + i.pricePerCard * i.quantity);
    final quote = (buyerCountry != null && seller.sellerCountry != null)
        ? ShippingRates.quoteForBundle(
            seller.sellerCountry!,
            buyerCountry,
            cardCount: bundleCount,
            forceTracked: ShippingRates.requiresTracking(bundleValue: bundleValue),
            bundleValue: bundleValue,
          )
        : null;
    final shippingCost = quote?.price ?? 1.80;
    final methodLabel = quote?.method.shortLabel ?? 'Letter';

    // Two-tone seller card (3-level layering, matches mockup):
    //   Page bg     → background  (#020617, slate-950, darkest)
    //   Outer card  → surfaceLight (#1E293B, slate-800, brightest of the 3)
    //   Items inset → surface     (#0F172A, slate-900, mid-tone, darker than outer)
    //
    // Header has no explicit bg → outer surfaceLight shows through, reads as
    // a "title bar" above the inset items panel. clipBehavior clips the
    // inset's edges to the outer rounded corners.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seller header band (uses outer surfaceLight) ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onViewAuthor != null
                ? () => widget.onViewAuthor!(sellerId, seller.sellerName)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(children: [
                  // Avatar (32px gold circle)
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [AppColors.amber600, AppColors.amber400]),
                    ),
                    child: Center(
                      child: Text(
                        seller.sellerName.isNotEmpty
                            ? seller.sellerName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.background),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(seller.sellerName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800)),
                  if (widget.onViewAuthor != null)
                    Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textMuted),
                  if (seller.sellerCountry != null) ...[
                    const SizedBox(width: 6),
                    Text(_countryFlag(seller.sellerCountry!),
                        style: AppTextStyles.bodyLarge),
                  ],
                  if (seller.sellerRating != null && seller.sellerRating! > 0) ...[
                    const SizedBox(width: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(seller.sellerRating!.toStringAsFixed(1),
                          style: AppTextStyles.captionBold
                              .copyWith(color: AppColors.textMuted)),
                    ]),
                  ],
                ]),
              ),
            ),
          ),

          // ── Items + footer (inset, surface bg, darker than outer) ──
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) => _buildCartItem(item)),

                _buildMoreFromSeller(sellerId, items),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child:
                      Divider(color: AppColors.border, height: 1),
                ),
                _priceRow(
                    'Subtotal', '€${sellerSubtotal.toStringAsFixed(2)}'),
                _priceRow('Shipping ($methodLabel)',
                    '€${shippingCost.toStringAsFixed(2)}'),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart Item Row ──

  Widget _buildCartItem(CartItem item) {
    // Layout (per user-spec mockup):
    //   [Image 52×80] | Column[
    //                     Name (bodyBold, ellipsis maxLines:2),
    //                     Meta-Wrap (Set# captionBold textMuted, Cond, Flag),
    //                     Row[Stepper (compact 32-tall) ←spacer→ Price+per-unit (right)]
    //                  ]
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            child: CardImage(
              imageUrl: item.imageUrl,
              fallbackText: item.cardName,
              width: 52, height: 80,
              card: CardService.getLookup()[item.cardId],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.cardName,
                    style: AppTextStyles.bodyBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    if (item.setCode != null || item.collectorNumber != null)
                      Text(
                        [
                          if (item.setCode != null) item.setCode!,
                          if (item.collectorNumber != null)
                            '#${item.collectorNumber!}',
                        ].join(' '),
                        style: AppTextStyles.captionBold
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ConditionBadge(
                        condition: CardCondition.values.firstWhere(
                            (c) => c.name == item.condition,
                            orElse: () => CardCondition.NM)),
                    if (item.language != null)
                      Text(item.language == 'CN' ? '🇨🇳' : '🇬🇧',
                          style: AppTextStyles.bodyLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Stepper ←→ Price row (both bottom-aligned to thumbnail)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStepper(item),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('€${item.lineTotal.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        if (item.quantity > 1)
                          Text(
                              '€${item.pricePerCard.toStringAsFixed(2)} ea',
                              style: AppTextStyles.micro
                                  .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── +/- Stepper ──
  // Uses shared QtyStepperRow (lib/widgets/qty_stepper_row.dart).
  // showTrashAtOne: true — at quantity 1, minus becomes trash icon;
  // tapping it invokes updateQuantity(…, 0) which removes the item.

  Widget _buildStepper(CartItem item) {
    return QtyStepperRow(
      quantity: item.quantity,
      compact: true, // 32-tall row, fits inline beside name+meta
      onDecrement: () => CartService.instance
          .updateQuantity(item.listingId, item.quantity - 1),
      onIncrement: item.quantity < item.maxQuantity
          ? () => CartService.instance
              .updateQuantity(item.listingId, item.quantity + 1)
          : null,
    );
  }

  // ── More from seller ──

  Widget _buildMoreFromSeller(String sellerId, List<CartItem> cartItems) {
    final cartListingIds = cartItems.map((i) => i.listingId).toSet();
    final allOther = ListingService.instance.allActive
        .where((l) => l.sellerId == sellerId && !cartListingIds.contains(l.id))
        .where((l) => l.availableQty > 0)
        .toList();

    if (allOther.isEmpty) return const SizedBox.shrink();

    // Relevance: prefer same set/domain as cart items
    final lookup = CardService.getLookup();
    final cartSets = cartItems.map((i) => i.setCode).whereType<String>().toSet();
    final cartDomains = <String>{};
    for (final ci in cartItems) {
      final card = lookup[ci.cardId];
      if (card != null) cartDomains.addAll(card.domains);
    }

    int relevance(MarketListing l) {
      int score = 0;
      final card = lookup[l.cardId];
      if (card != null) {
        if (cartSets.contains(card.setId)) score += 2;
        if (card.domains.any(cartDomains.contains)) score += 1;
      }
      return score;
    }

    allOther.sort((a, b) => relevance(b).compareTo(relevance(a)));

    final shown = allOther.take(6).toList();
    final totalOther = allOther.length;
    final hasMore = totalOther > 6;
    final sellerName = cartItems.first.sellerName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(color: AppColors.border, height: 1),
        ),
        Text('More from $sellerName',
          style: AppTextStyles.small.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: shown.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              if (i < shown.length) return _buildMoreCard(shown[i]);
              // "All X listings →" button
              return SizedBox(
                width: 90,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onGoToDiscover?.call();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.amber400, width: 2),
                          ),
                          child: Icon(Icons.arrow_forward, color: AppColors.amber400, size: 18),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('All $totalOther',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoreCard(MarketListing listing) {
    final card = CardService.getLookup()[listing.cardId];
    final isBattlefield = card?.isBattlefield == true;
    return SizedBox(
      width: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Battlefield cards are landscape-oriented (native art is wider
              // than tall). Wrap in RotatedBox(quarterTurns:1) so the
              // landscape image fills the 90×126 portrait slot fully without
              // cropping/letterboxing — same pattern as cards_screen,
              // collection_screen, smart_cart_review_sheet.
              SizedBox(
                width: 90, height: 126,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  child: isBattlefield
                      ? RotatedBox(
                          quarterTurns: 1,
                          child: CardImage(
                            imageUrl: listing.imageUrl,
                            fallbackText: listing.cardName,
                            fit: BoxFit.cover,
                            card: card,
                          ),
                        )
                      : CardImage(
                          imageUrl: listing.imageUrl,
                          fallbackText: listing.cardName,
                          width: 90, height: 126,
                          card: card,
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.minimum),
              Text(listing.cardName,
                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('€${listing.price.toStringAsFixed(2)}',
                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
          // Gold "+" button (top right) — 44×44 touch-target, 24dp visual circle.
          Positioned(
            top: -14, right: -14,
            child: SizedBox(
              width: 44, height: 44,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final ok = await CartService.instance.addItem(CartItem.fromListing(listing));
                  if (mounted && ok) {
                    RiftrToast.cart(context, 'Added to cart');
                  }
                },
                child: Center(
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.amber500,
                      shape: BoxShape.circle,
                    ),
                    // Pure white per FAB/Badge exception (theme-independent contrast).
                    child: Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grand Total (separate card) ──

  /// Compute total shipping and seller count for the cart, sharing logic
  /// with `_buildCheckoutButton`. Returns `(totalShipping, sellerCount)`.
  ({double totalShipping, int sellerCount}) _cartTotals(
      CartService cart, String? buyerCountry) {
    final bySeller = cart.itemsBySeller;
    double totalShipping = 0;
    for (final entry in bySeller.entries) {
      final sc = entry.value.first.sellerCountry;
      final bundleCount =
          entry.value.fold<int>(0, (sum, i) => sum + i.quantity);
      final bundleValue = entry.value
          .fold<double>(0, (sum, i) => sum + i.pricePerCard * i.quantity);
      final price = (buyerCountry != null && sc != null)
          ? ShippingRates.quoteForBundle(sc, buyerCountry,
                  cardCount: bundleCount,
                  forceTracked: ShippingRates.requiresTracking(
                      bundleValue: bundleValue),
                  bundleValue: bundleValue)
              ?.price
          : null;
      totalShipping += price ?? 1.80;
    }
    return (totalShipping: totalShipping, sellerCount: bySeller.length);
  }

  Widget _buildGrandTotal(CartService cart, String? buyerCountry) {
    final totals = _cartTotals(cart, buyerCountry);
    final totalShipping = totals.totalShipping;
    final sellerCount = totals.sellerCount;

    // Service-Gebuehr (Phase-1 Staffel) — wird hier transparent vor dem
    // Checkout angezeigt damit der User weiss was er zahlt. Multi-Seller-
    // Aufschlag (+0.30 € pro zusaetzlichem Seller) wird mitberechnet auch
    // wenn Multi-Seller-Checkout in Phase 2 noch geblockt ist (Toast in
    // _startCheckout) — so sieht User schon die Phase-4-Staffel-Vorschau.
    final serviceFee = fees.serviceFeeEurFor(
      cart.subtotal,
      sellerCount: sellerCount,
    );
    final grandTotal = cart.subtotal + totalShipping + serviceFee;
    final isMultiSeller = sellerCount >= 2;

    return RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sellerCount ${sellerCount == 1 ? 'order' : 'orders'} · '
            '${cart.totalItems} ${cart.totalItems == 1 ? 'card' : 'cards'}',
            style: AppTextStyles.bodySmallSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Breakdown rows — same pattern as per-seller block above.
          _priceRow('Subtotal', '€${cart.subtotal.toStringAsFixed(2)}'),
          _priceRow('Shipping', '€${totalShipping.toStringAsFixed(2)}'),
          _serviceFeeRow(serviceFee, isMultiSeller: isMultiSeller),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              Text('€${grandTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  /// Service-Gebuehr-Zeile mit info-Icon. Tap-Handler zeigt Toast mit Erklaerung.
  Widget _serviceFeeRow(double amount, {required bool isMultiSeller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Toast hat maxWidth: 280 + maxLines: 2 — Texte muessen
              // entsprechend kompakt sein. „Service fee:"-Prefix entfernt
              // weil der User gerade auf das Label getippt hat (= Kontext
              // bekannt). Nur das Wesentliche: Range + Multi-Aufschlag +
              // Was-ist-drin in einem knappen Satz.
              RiftrToast.info(
                context,
                isMultiSeller
                    ? '€0.49–€1.99 by order size + €0.30 per extra seller. '
                        'Covers payment & platform costs.'
                    : '€0.49–€1.99 by order size. '
                        'Covers payment & platform costs.',
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Service fee',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 4),
                Icon(Icons.info_outline,
                    size: 13, color: AppColors.textMuted),
              ],
            ),
          ),
          Text('€${amount.toStringAsFixed(2)}',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Checkout Button (full width, gold, no Clear button) ──

  Widget _buildCheckoutButton(CartService cart) {
    final buyerCountry = ProfileService.instance.ownProfile?.country;
    final totals = _cartTotals(cart, buyerCountry);
    // Match the Grand-Total card: include Service-Gebuehr im Button-Label
    // damit der angekuendigte Pay-Betrag mit dem Stripe-Sheet-Charge matched.
    final serviceFee = fees.serviceFeeEurFor(
      cart.subtotal,
      sellerCount: totals.sellerCount,
    );
    final grandTotal = cart.subtotal + totals.totalShipping + serviceFee;

    // Card-Preview-pattern button: height 56, pill radius. Positioned
    // wrapper (in build()) provides the bottom: 22 anchoring + horizontal
    // margins, so the button itself is just the styled RiftrButton.
    return RiftrButton(
      label: 'Checkout €${grandTotal.toStringAsFixed(2)}',
      style: RiftrButtonStyle.primary,
      height: 56,
      radius: AppRadius.pill,
      onPressed: () => _startCheckout(cart),
    );
  }

  // ── Checkout ──

  Future<void> _startCheckout(CartService cart) async {
    final bySeller = cart.itemsBySeller;
    if (bySeller.isEmpty) return;

    // Single seller → existing CheckoutSheet (unchanged UX).
    if (bySeller.length == 1) {
      final items = bySeller.values.first;
      final firstListing = MarketListing.fromCartItem(items.first);
      final cartCheckoutItems = items.map((i) => CartCheckoutItem(
        listing: MarketListing.fromCartItem(i),
        quantity: i.quantity,
      )).toList();

      // Same Card-Preview push pattern as BulkCheckoutSheet: Fade 200ms,
      // sheet renders its own Scaffold + DragToDismiss for drag-from-anywhere.
      final result = await Navigator.of(context).push<String>(
        PageRouteBuilder<String>(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          pageBuilder: (ctx, anim, secondaryAnim) => CheckoutSheet(
            listing: firstListing,
            cartItems: cartCheckoutItems,
          ),
          transitionsBuilder: (ctx, anim, secondaryAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

      if (result != null && mounted) {
        await cart.clearAll();
        if (!mounted) return;
        Navigator.of(context).pop();
        RiftrToast.success(context, 'Order placed!');
      }
      return;
    }

    // Phase 4 (2026-04-28): Multi-Seller-Cart. BulkCheckoutSheet macht den
    // SetupIntent-Flow + sequenziellen PI-Loop ueber `processMultiSellerCart`.
    // Returns: count of successfully placed orders (0 = sheet cancelled,
    // N>0 = N orders erstellt, Cart kann geleert werden).
    final placedCount = await Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (ctx, anim, secondaryAnim) => const BulkCheckoutSheet(),
        transitionsBuilder: (ctx, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (!mounted) return;

    if (placedCount != null && placedCount > 0) {
      // Multi-seller success: alle N Orders erstellt, Cart raeumen
      await cart.clearAll();
      if (!mounted) return;
      Navigator.of(context).pop();
      RiftrToast.success(
        context,
        placedCount == 1
            ? 'Order placed!'
            : 'All $placedCount orders placed!',
      );
    }
    // placedCount null/0 = User hat abgebrochen ODER Backend-Fehler hat
    // Rollback ausgeloest (BulkCheckoutSheet zeigt den Fehler intern).
    // Cart bleibt erhalten, User kann erneut versuchen.
  }

  // ── Helpers ──

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _countryFlag(String code) =>
      code.toUpperCase().codeUnits.map((c) => String.fromCharCode(0x1F1E6 - 0x41 + c)).join();
}
