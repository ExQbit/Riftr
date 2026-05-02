import 'package:flutter/material.dart';
import '../../data/shipping_rates.dart';
import '../../models/market/listing_model.dart';
import '../../screens/seller_reviews_screen.dart';
import '../../services/profile_service.dart';
import '../../theme/app_components.dart';
import '../../theme/app_theme.dart';
import 'condition_badge.dart';
import 'seller_status_badge.dart';

/// Single seller listing tile for card detail view.
class ListingTile extends StatelessWidget {
  final MarketListing listing;
  final VoidCallback? onBuy;
  final VoidCallback? onAddToCart;
  /// Tap-on-seller-name → Market-Discover gets filtered to this seller's
  /// active listings. All other Discover filters stack on top.
  final VoidCallback? onViewSeller;

  const ListingTile({
    super.key,
    required this.listing,
    this.onBuy,
    this.onAddToCart,
    this.onViewSeller,
  });

  @override
  Widget build(BuildContext context) {
    final buyerCountry = ProfileService.instance.ownProfile?.country;
    // Listing-tile shows the price for buying ONE copy alone — bundleCardCount=1.
    // (When this listing is added to a multi-card cart, the cart-screen
    // re-computes shipping with the actual bundle size.)
    final quote = (buyerCountry != null && listing.sellerCountry != null)
        ? listing.shippingQuoteFor(buyerCountry, bundleCardCount: 1)
        : null;
    final shippingCost = quote?.price;
    final method = quote?.method;

    return RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Seller info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seller name + flag — tap navigates to Discover filtered
                // to this seller's active listings. Chevron indicates
                // tappability (matches cart_screen.dart seller-header pattern).
                GestureDetector(
                  onTap: onViewSeller,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        listing.sellerName,
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (listing.sellerCountry != null) ...[
                        const SizedBox(width: 6),
                        // Emoji flag — sized slightly larger than surrounding
                        // text for visual recognition. bodyLarge (15sp) matches
                        // the V2 scale.
                        Text(
                          _countryFlag(listing.sellerCountry!),
                          style: AppTextStyles.bodyLarge,
                        ),
                      ],
                      if (onViewSeller != null) ...[
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right,
                            size: 14, color: AppColors.textMuted),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    // Rating (tappable → reviews screen).
                    // Touch-target is provided by the Row cross-axis expansion:
                    // the parent Row is stretched to 44dp by the Cart/Buy
                    // buttons on the right, so this rating block inherits
                    // ≥44dp height naturally. No SizedBox wrap needed — that
                    // would add redundant height on top of the Row-height.
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerReviewsScreen(
                            sellerId: listing.sellerId,
                            sellerName: listing.sellerName,
                          ),
                        ),
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.amber400,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            listing.sellerRating.toStringAsFixed(1),
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.amber300,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const SizedBox(width: AppSpacing.sm),
                    SellerStatusBadge(
                      isCommercial: listing.sellerIsCommercial,
                      compact: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // "Setting up payouts" / "DAC7 paused" indicators —
                    // only render in views that bypass the buyer-side
                    // visibility filter (ListingService._visibleToBuyers),
                    // typically the seller's own myListings. Lets the
                    // seller understand WHY their listing is hidden from
                    // buyers right now.
                    if (!listing.sellerStripeReady) ...[
                      RiftrBadge(
                        label: 'Setting up payouts',
                        type: RiftrBadgeType.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (listing.sellerVolumeSuspended) ...[
                      RiftrBadge(
                        label: 'DAC7 paused',
                        type: RiftrBadgeType.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      '${listing.sellerSales} sales',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ConditionBadge(condition: listing.condition),
                    const SizedBox(width: 6),
                    // Language flag emoji — bodyLarge for visual recognition.
                    Text(
                      listing.language == 'CN' ? '🇨🇳' : '🇬🇧',
                      style: AppTextStyles.bodyLarge,
                    ),
                    // NOTE: Quantity-Indikator (×N) lebt jetzt als Badge auf
                    // dem Cart-Button (oben rechts), NICHT mehr inline hier.
                    // Vorher hat sich das `×3` mit dem Versand-Preis aus der
                    // rechten Price+Shipping-Spalte ueberlappt sobald Seller-
                    // Name lang war.
                  ],
                ),
              ],
            ),
          ),

          // Price + Shipping
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${listing.price.toStringAsFixed(2)}',
                style: AppTextStyles.bodyBold.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              if (shippingCost != null && method != null)
                Text(
                  '+€${shippingCost.toStringAsFixed(2)} ${method.shortLabel}',
                  style: AppTextStyles.micro,
                )
              else
                Text(
                  '+ shipping',
                  style: AppTextStyles.micro,
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.small),

          // Cart + Buy form a paired primary-action cluster. Both render
          // as full 44dp-tall tiles with identical radius (md=8dp) so they
          // visually read as two equal-weight buttons — not "small icon +
          // big pill". Cart is a 44×44 square (icon-only), Buy is a
          // width-auto pill (text). Icon size 20 fills the 44dp cleanly.

          // Cart button — primary action (Add to Cart)
          // Quantity-Badge (×N) als kleines Overlay oben rechts wenn 2+ Stock.
          // Keine Behinderung anderer Layout-Elemente — der Badge sitzt nur
          // auf dem Cart-Button.
          if (onAddToCart != null) ...[
            GestureDetector(
              onTap: onAddToCart,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.amber500,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.add_shopping_cart, size: 20, color: AppColors.textOnPrimary),
                  ),
                  if (listing.availableQty > 1)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.amber500, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '×${listing.availableQty}',
                          style: AppTextStyles.micro.copyWith(
                            color: AppColors.amber400,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
          ],

          // Buy button — primary action (Buy Now)
          GestureDetector(
            onTap: onBuy,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: onBuy != null ? AppColors.win : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Buy',
                style: AppTextStyles.small.copyWith(
                  color: onBuy != null ? AppColors.textOnPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert ISO country code to flag emoji (e.g. "DE" → "🇩🇪").
  static String _countryFlag(String code) {
    return code.toUpperCase().codeUnits
        .map((c) => String.fromCharCode(0x1F1E6 - 0x41 + c))
        .join();
  }
}
