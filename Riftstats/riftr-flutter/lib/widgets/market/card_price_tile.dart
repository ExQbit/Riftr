import 'package:flutter/material.dart';
import '../../models/market/card_price_data.dart';
import '../../theme/app_theme.dart';
import '../card_image.dart';

/// List tile: [Card Image] [Name + Set] [Sparkline] [Price + Change]
class CardPriceTile extends StatelessWidget {
  final CardPriceData data;
  final int? quantity;
  final VoidCallback? onTap;

  /// Show a foil star indicator in the subtitle row
  final bool showFoilStar;

  /// Override the displayed price (e.g. foil price instead of currentPrice)
  final double? priceOverride;

  /// Override change display text + color (for custom metrics like cost basis).
  /// If null, falls back to data.dayChange.
  final String? changeText;
  final bool? changePositive;

  const CardPriceTile({
    super.key,
    required this.data,
    this.quantity,
    this.onTap,
    this.showFoilStar = false,
    this.priceOverride,
    this.changeText,
    this.changePositive,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePositive ?? data.isPositive;
    final changeColor = isPositive ? AppColors.win : AppColors.loss;
    final changeSign = isPositive ? '+' : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Card image (battlefields rotated to fit portrait thumbnail)
            SizedBox(
              width: 32,
              height: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: data.imageUrl != null
                    ? (data.isBattlefield
                        ? RotatedBox(
                            quarterTurns: 1,
                            child: CardImage(
                              imageUrl: data.imageUrl,
                              fallbackText: data.cardName,
                              fit: BoxFit.cover,
                            ),
                          )
                        : CardImage(
                            imageUrl: data.imageUrl,
                            fallbackText: data.cardName,
                            width: 32,
                            height: 44,
                            fit: BoxFit.cover,
                          ))
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 10),

            // Name + set + quantity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.cardName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (data.setId != null)
                        Text(
                          data.setId!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (showFoilStar) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '★',
                          style: TextStyle(
                            color: AppColors.amber300,
                            fontSize: 9,
                          ),
                        ),
                      ],
                      if (quantity != null && quantity! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '×$quantity',
                            style: const TextStyle(
                              color: AppColors.amber300,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price + change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${(priceOverride ?? data.currentPrice).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  changeText ?? '$changeSign${data.dayChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 32,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.style, size: 16, color: AppColors.textMuted),
    );
  }
}
