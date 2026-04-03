import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/market/card_price_data.dart';
import '../services/market_service.dart';
import '../services/firestore_collection_service.dart';
import '../theme/app_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/riftr_toast.dart';
import 'scanner_screen.dart';

/// Condition for a scanned card.
enum CardCondition { nm, lp, mp, hp }

extension CardConditionLabel on CardCondition {
  String get label => switch (this) {
    CardCondition.nm => 'NM',
    CardCondition.lp => 'LP',
    CardCondition.mp => 'MP',
    CardCondition.hp => 'HP',
  };
}

/// Per-card state in the results list.
class _ResultEntry {
  final ScannedCardEntry scanEntry;
  RiftCard card; // mutable for variant switching
  CardCondition condition;
  int quantity;
  bool selected;

  _ResultEntry({
    required this.scanEntry,
    required this.card,
    this.condition = CardCondition.nm,
    required this.quantity,
    this.selected = true,
  });

  CardPriceData? get priceData => MarketService.instance.getPrice(card.id);
}

/// Shows all scanned cards with condition picker, quantity, and bulk actions.
class ScanResultsScreen extends StatefulWidget {
  final List<ScannedCardEntry> entries;
  final bool defaultToListings;

  const ScanResultsScreen({
    super.key,
    required this.entries,
    this.defaultToListings = false,
  });

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  late final List<_ResultEntry> _results;

  @override
  void initState() {
    super.initState();
    _results = widget.entries.map((e) => _ResultEntry(
      scanEntry: e,
      card: e.card,
      quantity: e.quantity,
    )).toList();
  }

  int get _selectedCount => _results.where((r) => r.selected).fold(0, (t, r) => t + r.quantity);

  double get _totalPrice {
    double total = 0;
    for (final r in _results) {
      if (!r.selected) continue;
      final price = r.priceData?.currentPrice ?? 0;
      total += price * r.quantity;
    }
    return total;
  }

  void _addToCollection() {
    final selected = _results.where((r) => r.selected).toList();
    if (selected.isEmpty) return;

    final col = FirestoreCollectionService.instance;
    int added = 0;

    for (final r in selected) {
      final isFoil = FirestoreCollectionService.isFoilVariant(r.card.setId, r.card.rarity);
      col.setQuantity(
        r.card.id,
        col.getQuantity(r.card.id) + r.quantity,
        foil: isFoil,
      );
      added += r.quantity;
    }

    RiftrToast.success(context, '$added cards added to collection');
    Navigator.pop(context);
  }

  void _createListings() {
    final selected = _results.where((r) => r.selected).toList();
    if (selected.isEmpty) return;

    // TODO: Create listings via ListingService
    // For now, show toast with count
    final count = selected.fold<int>(0, (t, r) => t + r.quantity);
    RiftrToast.info(context, 'Creating $count listings...');
    Navigator.pop(context);
  }

  void _switchVariant(_ResultEntry entry, RiftCard newCard) {
    setState(() => entry.card = newCard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'SCAN RESULTS (${_results.fold<int>(0, (t, r) => t + r.quantity)})',
                      style: AppTextStyles.bodyBold.copyWith(letterSpacing: 1.5),
                    ),
                  ),
                  // Scan more button
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ScannerScreen(
                        defaultToListings: widget.defaultToListings,
                      )),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.amber500),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.camera_alt, size: 16, color: AppColors.amber400),
                        const SizedBox(width: 4),
                        Text('Scan +', style: AppTextStyles.small.copyWith(color: AppColors.amber400)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _results.length,
                itemBuilder: (context, index) => _buildResultTile(_results[index]),
              ),
            ),

            // Bottom bar: total + actions
            Container(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceLight)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_selectedCount cards selected',
                        style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
                      Text('€${_totalPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.amber400)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _addToCollection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.amber500,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Center(
                              child: Text('Add to Collection',
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.background)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: GestureDetector(
                          onTap: _createListings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.amber500),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Center(
                              child: Text('Create Listings',
                                style: AppTextStyles.bodyBold.copyWith(color: AppColors.amber400)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(_ResultEntry entry) {
    final price = entry.priceData;
    final hasAlternatives = entry.scanEntry.alternatives.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: entry.selected ? AppColors.surface : AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: entry.selected ? AppColors.surfaceLight : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => setState(() => entry.selected = !entry.selected),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm, top: 4),
                child: Icon(
                  entry.selected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: entry.selected ? AppColors.amber400 : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),

            // Card image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: CardImage(
                imageUrl: entry.card.imageUrl,
                fallbackText: entry.card.name,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(entry.card.name,
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (price != null && price.currentPrice > 0)
                        Text('€${price.currentPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Set + rarity
                  Text(
                    '${entry.card.setId ?? ''} #${entry.card.collectorNumber ?? ''} · ${entry.card.rarity ?? ''}',
                    style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Condition picker
                  Row(
                    children: CardCondition.values.map((c) {
                      final isActive = entry.condition == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => entry.condition = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.amber500 : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.badge),
                            ),
                            child: Text(c.label,
                              style: AppTextStyles.micro.copyWith(
                                color: isActive ? AppColors.background : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Quantity stepper + variant switch
                  Row(
                    children: [
                      // Qty stepper
                      GestureDetector(
                        onTap: () {
                          if (entry.quantity > 1) setState(() => entry.quantity--);
                        },
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(child: Icon(Icons.remove, size: 16, color: AppColors.textSecondary)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${entry.quantity}',
                          style: AppTextStyles.bodyBold),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => entry.quantity++),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(child: Icon(Icons.add, size: 16, color: AppColors.textSecondary)),
                        ),
                      ),
                      const Spacer(),
                      // Variant switch hint
                      if (hasAlternatives)
                        GestureDetector(
                          onTap: () => _showVariantPicker(entry),
                          child: Text(
                            'Also: ${entry.scanEntry.alternatives.length} variant${entry.scanEntry.alternatives.length > 1 ? 's' : ''}',
                            style: AppTextStyles.micro.copyWith(
                              color: AppColors.amber400,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVariantPicker(_ResultEntry entry) {
    final all = [entry.scanEntry.card, ...entry.scanEntry.alternatives];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select variant', style: AppTextStyles.bodyBold),
            const SizedBox(height: AppSpacing.md),
            ...all.map((card) {
              final isSelected = card.id == entry.card.id;
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CardImage(imageUrl: card.imageUrl, fallbackText: card.name, width: 36, height: 50, fit: BoxFit.cover),
                ),
                title: Text(card.displayName, style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                )),
                subtitle: Text('${card.setId} · ${card.rarity}',
                  style: AppTextStyles.micro.copyWith(color: AppColors.textMuted)),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.amber400) : null,
                onTap: () {
                  _switchVariant(entry, card);
                  Navigator.pop(ctx);
                },
              );
            }),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }
}
