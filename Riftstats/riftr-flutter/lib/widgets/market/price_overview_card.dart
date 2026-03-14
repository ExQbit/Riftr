import 'package:flutter/material.dart';
import '../../models/market/card_price_data.dart';
import '../../theme/app_theme.dart';

/// Grid card showing Buy From / Market / Trend / change stats.
/// Pass [showFoil] to display foil-specific or non-foil-specific stats.
class PriceOverviewCard extends StatelessWidget {
  final CardPriceData data;
  final bool showFoil;

  const PriceOverviewCard({
    super.key,
    required this.data,
    this.showFoil = false,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve variant-specific values, fallback to primary if variant has no data
    final variantPrice = data.getPrice(showFoil);
    final hasVariantData = variantPrice > 0;

    final low = hasVariantData ? data.getLow(showFoil) : data.low30d;
    final trend = hasVariantData ? data.getTrend(showFoil) : data.high30d;
    final price = hasVariantData ? variantPrice : data.currentPrice;
    final monthChg = hasVariantData ? data.getMonthChange(showFoil) : data.monthChange;
    final weekChg = hasVariantData ? data.getWeekChange(showFoil) : data.weekChange;
    final dayChg = hasVariantData ? data.getDayChange(showFoil) : data.dayChange;

    // If variant low/trend are 0, fall back to primary
    final displayLow = low > 0 ? low : data.low30d;
    final displayTrend = trend > 0 ? trend : data.high30d;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRICE OVERVIEW',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _cell('Buy From', '€${displayLow.toStringAsFixed(2)}', AppColors.loss)),
              const SizedBox(width: 12),
              Expanded(child: _cell('Market', '€${price.toStringAsFixed(2)}', AppColors.amber300)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _cell('Trend', '€${displayTrend.toStringAsFixed(2)}', AppColors.win)),
              const SizedBox(width: 12),
              Expanded(child: _cell('vs 30d Avg', _fmtPct(monthChg), _pctColor(monthChg))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _cell('vs 7d Avg', _fmtPct(weekChg), _pctColor(weekChg))),
              const SizedBox(width: 12),
              Expanded(child: _cell('24h Change', _fmtPct(dayChg), _pctColor(dayChg))),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtPct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';
  static Color _pctColor(double v) => v >= 0 ? AppColors.win : AppColors.loss;

  Widget _cell(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
