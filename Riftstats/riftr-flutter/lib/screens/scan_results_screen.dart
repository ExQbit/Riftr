import 'package:flutter/material.dart';
// Conditional import: need ScannedCardEntry type on both platforms.
// Mobile gets the real scanner, web gets a stub (compile-time swap).
import 'scanner_screen.dart'
    if (dart.library.html) 'scanner_screen_stub.dart';
import '../models/card_model.dart';
import '../models/market/card_price_data.dart';
import '../models/market/listing_model.dart' as market;
import '../services/market_service.dart';
import '../services/firestore_collection_service.dart';
import '../services/listing_service.dart';
import '../services/seller_service.dart';
import '../theme/app_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/qty_stepper_row.dart';
import '../widgets/riftr_drag_handle.dart';
import '../widgets/market/seller_onboarding_sheet.dart';
import '../widgets/riftr_toast.dart';
import '../theme/app_components.dart';

/// Condition for a scanned card.
enum CardCondition { nm, lp, mp, hp }

extension CardConditionLabel on CardCondition {
  String get label => switch (this) {
    CardCondition.nm => 'NM',
    CardCondition.lp => 'LP',
    CardCondition.mp => 'MP',
    CardCondition.hp => 'HP',
  };

  market.CardCondition get toMarket => switch (this) {
    CardCondition.nm => market.CardCondition.NM,
    CardCondition.lp => market.CardCondition.LP,
    CardCondition.mp => market.CardCondition.GD,
    CardCondition.hp => market.CardCondition.PL,
  };
}

/// Per-card state in the results list.
class _ResultEntry {
  final ScannedCardEntry scanEntry;
  RiftCard card;
  CardCondition condition;
  int quantity;
  bool isFoil;
  bool selected;
  double? manualPrice;

  _ResultEntry({
    required this.scanEntry,
    required this.card,
    this.condition = CardCondition.nm,
    required this.quantity,
    required this.isFoil,
    this.selected = true,
  });

  CardPriceData? get priceData => MarketService.instance.getPrice(card.id);

  bool get isFoilEditable {
    if (card.type?.toLowerCase() == 'rune' && !card.isPromo) return false;
    if (card.setId == 'OGS') return true;
    final r = card.rarity?.toLowerCase() ?? '';
    return r == 'common' || r == 'uncommon';
  }

  bool get hasFoil {
    if (card.type?.toLowerCase() != 'rune') return true;
    return card.isPromo;
  }
}

/// Grouped listing for batch creation.
class _GroupedListing {
  final _ResultEntry entry; // representative entry (for card data)
  final double price;
  int totalQty;

  _GroupedListing({required this.entry, required this.price, required this.totalQty});
}

/// Drag-to-dismiss bottom sheet showing scanned cards with pricing + actions.
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

  // Price modifier slider: -10% to +10% in 1% steps (21 stops)
  int _modifierPercent = 0; // -10 to +10, default 0 = Market

  @override
  void initState() {
    super.initState();
    // Merge fuer DISPLAY — identische Karten (selbe id+isFoil) werden hier
    // zu einer Zeile mit „×N"-Counter zusammengefasst. Sauberere Uebersicht
    // bei vielen Scans derselben Karte. Wichtig: das Merge ist NUR fuer die
    // Result-Screen-UI; beim Pop zurueck zum Scanner werden die Eintraege
    // wieder per `_entriesToReturn()` in Einzeln-Entries auseinandergefaltet
    // (jeder Scan = 1 Thumbnail im Bottom-Strip). Vorher hatte das Pop die
    // gemergte Quantity zurueck in den Scanner gegeben → User sah nur 1
    // Thumbnail mit ×2 statt 2 separate.
    final merged = <String, _ResultEntry>{};
    for (final e in widget.entries) {
      final key = '${e.card.id}_${e.isFoil}';
      if (merged.containsKey(key)) {
        merged[key]!.quantity += e.quantity;
      } else {
        merged[key] = _ResultEntry(
          scanEntry: e,
          card: e.card,
          quantity: e.quantity,
          isFoil: e.isFoil,
        );
      }
    }
    _results = merged.values.toList();
  }

  int get _selectedCount =>
      _results.where((r) => r.selected).fold(0, (t, r) => t + r.quantity);

  double _effectivePrice(_ResultEntry r) {
    if (r.manualPrice != null) return r.manualPrice!;
    final pd = r.priceData;
    final basePrice = pd != null ? pd.getPrice(r.isFoil) : 0.0;
    final price = basePrice > 0 ? basePrice : (pd?.currentPrice ?? 0.0);
    final modifier = 1.0 + _modifierPercent / 100.0;
    return (price * modifier * 100).roundToDouble() / 100;
  }

  double get _totalPrice {
    double total = 0;
    for (final r in _results) {
      if (!r.selected) continue;
      total += _effectivePrice(r) * r.quantity;
    }
    return total;
  }

  // ══════════════════════════════════════════════
  // ── Actions ──
  /// Rebuild ScannedCardEntries from current results (preserving edits).
  /// Merged-Display-Quantity wird hier wieder in Einzeln-Entries
  /// auseinander gefaltet — eine `_ResultEntry` mit quantity=N wird zu
  /// N `ScannedCardEntry`-Objekten mit jeweils quantity=1. Damit sieht
  /// der Scanner-Bottom-Strip nach Pop genau so viele Thumbnails wie
  /// echte Scan-Aktionen vorausgegangen sind, der Result-Screen-Merge
  /// ist nur Display-Layer.
  ///
  /// Wenn der User die Quantity manuell hochzaehlt (z.B. von 2 auf 5),
  /// kommen entsprechend 5 Einzeln-Entries zurueck. Wenn er auf 0
  /// runterzieht, wird die Karte komplett entfernt (keine Entries fuer
  /// diese Zeile zurueckgegeben).
  List<ScannedCardEntry> _entriesToReturn() {
    final out = <ScannedCardEntry>[];
    for (final r in _results) {
      for (int i = 0; i < r.quantity; i++) {
        out.add(ScannedCardEntry(
          card: r.card,
          alternatives: r.scanEntry.alternatives,
          isFoil: r.isFoil,
          quantity: 1,
        ));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════

  void _addToCollection() {
    final selected = _results.where((r) => r.selected).toList();
    if (selected.isEmpty) return;

    final col = FirestoreCollectionService.instance;
    int added = 0;

    for (final r in selected) {
      final existing = r.isFoil
          ? col.getFoilQuantity(r.card.id)
          : col.getQuantity(r.card.id);
      col.setQuantity(r.card.id, existing + r.quantity, foil: r.isFoil);
      added += r.quantity;
    }

    RiftrToast.success(context, '$added cards added to collection');
    Navigator.pop(context);
  }

  Future<void> _createListings() async {
    final selected = _results.where((r) => r.selected).toList();
    if (selected.isEmpty) return;

    // Gate: Suspended sellers
    final sellerProfile = SellerService.instance.profile;
    if (sellerProfile != null && sellerProfile.suspended) {
      if (mounted) RiftrToast.error(context, 'Your seller account is suspended.');
      return;
    }

    // Gate: Onboarding
    if (!SellerService.instance.isReady) {
      final completed = await showRiftrSheet<bool>(
        context: context,
        builder: (_) => const SellerOnboardingSheet(),
      );
      if (completed != true || !mounted) return;
    }

    // Group selected entries by card.id + isFoil + condition + price
    // so 3× Eye of the Herald (NM, Foil, €0.37) → 1 listing with qty=3
    final grouped = <String, _GroupedListing>{};
    for (final r in selected) {
      final price = _effectivePrice(r);
      if (price <= 0) continue;
      final key = '${r.card.id}_${r.isFoil}_${r.condition.name}_${price.toStringAsFixed(2)}';
      if (grouped.containsKey(key)) {
        grouped[key]!.totalQty += r.quantity;
      } else {
        grouped[key] = _GroupedListing(entry: r, price: price, totalQty: r.quantity);
      }
    }

    final listings = ListingService.instance;
    final col = FirestoreCollectionService.instance;
    int created = 0;
    int failed = 0;
    int totalCards = 0;

    for (final g in grouped.values) {
      final r = g.entry;

      final listingId = await listings.createListing(
        cardId: r.card.id,
        cardName: r.card.name,
        imageUrl: r.card.imageUrl,
        condition: r.condition.toMarket,
        price: g.price,
        quantity: g.totalQty,
        isFoil: r.isFoil,
        setId: r.card.setId,
        setCode: r.card.setId,
        collectorNumber: r.card.collectorNumber,
      );

      if (listingId != null) {
        created++;
        totalCards += g.totalQty;
        // Add scanned cards to collection
        final existing = r.isFoil
            ? col.getFoilQuantity(r.card.id)
            : col.getQuantity(r.card.id);
        col.setQuantity(r.card.id, existing + g.totalQty,
            foil: r.isFoil, costPrice: g.price);
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    if (failed == 0) {
      RiftrToast.success(context, '$created listing${created > 1 ? 's' : ''} created ($totalCards cards)');
    } else {
      RiftrToast.error(context, '$created created, $failed failed');
    }
    Navigator.pop(context);
  }

  // ══════════════════════════════════════════════
  // ── Build ──
  // ══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return DragToDismiss(
      onDismissed: () => Navigator.pop(context, _entriesToReturn()),
      backgroundColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Drag handle — fullscreen style (DragToDismiss-context).
              const SizedBox(height: AppSpacing.md),
              const RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
              const SizedBox(height: AppSpacing.md),

              // Price modifier slider
              _buildModifierSlider(),

              // Results list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => _buildResultTile(_results[i]),
                ),
              ),

              // Bottom bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── Price Modifier Slider ──
  // ══════════════════════════════════════════════

  Widget _buildModifierSlider() {
    final label = _modifierPercent == 0
        ? 'Market'
        : '${_modifierPercent > 0 ? '+' : ''}$_modifierPercent%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + current value (same font size)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRICE MODIFIER',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  )),
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.amber400,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          // Slider: -10 to +10 in 1% steps
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.amber500,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.amber500,
              overlayColor: AppColors.amber500.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _modifierPercent.toDouble(),
              min: -10,
              max: 10,
              divisions: 20,
              onChanged: (v) => setState(() => _modifierPercent = v.round()),
            ),
          ),
          // Tick labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-10%', style: AppTextStyles.labelSmall.copyWith(
                  color: _modifierPercent == -10 ? AppColors.amber400 : AppColors.textMuted)),
              Text('-5%', style: AppTextStyles.labelSmall.copyWith(
                  color: _modifierPercent == -5 ? AppColors.amber400 : AppColors.textMuted)),
              Text('Market', style: AppTextStyles.labelSmall.copyWith(
                  color: _modifierPercent == 0 ? AppColors.amber400 : AppColors.textMuted)),
              Text('+5%', style: AppTextStyles.labelSmall.copyWith(
                  color: _modifierPercent == 5 ? AppColors.amber400 : AppColors.textMuted)),
              Text('+10%', style: AppTextStyles.labelSmall.copyWith(
                  color: _modifierPercent == 10 ? AppColors.amber400 : AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── Card Tile ──
  // ══════════════════════════════════════════════

  Widget _buildResultTile(_ResultEntry entry) {
    final displayPrice = _effectivePrice(entry);

    // Variant badge
    String? badgeText;
    Color? badgeColor;
    if (entry.card.isPromo) {
      badgeText = 'PROMO';
      badgeColor = AppColors.amber400;
    } else if (entry.card.alternateArt) {
      badgeText = 'Alt Art';
      badgeColor = AppColors.mind;
    } else if (entry.card.signature) {
      badgeText = 'Signature';
      badgeColor = AppColors.amber400;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: RiftrCard(
        padding: const EdgeInsets.all(AppSpacing.base),
        borderColor: entry.selected ? AppColors.surfaceLight : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (tappable for variants) + checkbox badge
            GestureDetector(
              onTap: () => _showVariantPicker(entry),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  // Battlefield reference images are landscape — rotate 90°
                  // to portrait so the result-screen tile matches the rest.
                  child: entry.card.type?.toLowerCase() == 'battlefield'
                      ? SizedBox(
                          width: 72, height: 100,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: CardImage(
                              imageUrl: entry.card.imageUrl,
                              fallbackText: entry.card.name,
                              fit: BoxFit.cover,
                              card: entry.card,
                            ),
                          ),
                        )
                      : CardImage(
                          imageUrl: entry.card.imageUrl,
                          fallbackText: entry.card.name,
                          width: 72, height: 100, fit: BoxFit.cover,
                          card: entry.card,
                        ),
                ),
                // Checkbox badge — 44×44 touch-target, visual 16×16 at top-left.
                Positioned(
                  left: 4, top: 4,
                  child: SizedBox(
                    width: 44, height: 44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => entry.selected = !entry.selected),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: entry.selected ? AppColors.amber500 : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.minimal),
                            border: entry.selected
                                ? null
                                : Border.all(color: AppColors.textMuted, width: 1),
                          ),
                          child: entry.selected
                              ? Icon(Icons.check, size: 12, color: AppColors.textOnPrimary)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: AppSpacing.medium),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name + editable price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(entry.card.name,
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (displayPrice > 0)
                        // 44dp touch-target via vertical padding wrap.
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showPriceEditor(entry),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 12,
                                    color: entry.manualPrice != null
                                        ? AppColors.amber400
                                        : AppColors.textMuted),
                                const SizedBox(width: 3),
                                Text('€${displayPrice.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800,
                                      color: entry.manualPrice != null
                                          ? AppColors.amber400
                                          : AppColors.textPrimary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Row 2: Set + rarity + badge
                  Row(children: [
                    Text(
                      '${entry.card.setId ?? ''} #${entry.card.collectorNumber ?? ''} · ${entry.card.rarity ?? ''}',
                      style: AppTextStyles.bodySmall.copyWith( color: AppColors.textMuted),
                    ),
                    if (badgeText != null) ...[
                      Text(' · ', style: AppTextStyles.bodySmall.copyWith( color: AppColors.textMuted)),
                      Text(badgeText, style: AppTextStyles.bodySmall.copyWith(color: badgeColor, fontWeight: FontWeight.w800)),
                    ],
                  ]),
                  const SizedBox(height: AppSpacing.small),

                  // Row 3: Condition chips — 44dp touch-target, 26dp visual.
                  Row(
                    children: CardCondition.values.map((c) {
                      final isActive = entry.condition == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SizedBox(
                          height: 44,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => entry.condition = c),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.amber500 : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(AppRadius.minimal),
                                ),
                                child: Text(c.label,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isActive ? AppColors.background : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // Row 4: Quantity stepper + Foil
                  Row(
                    children: [
                      QtyStepperRow(
                        quantity: entry.quantity,
                        onDecrement: () {
                          if (entry.quantity <= 1) {
                            setState(() => _results.remove(entry));
                          } else {
                            setState(() => entry.quantity--);
                          }
                        },
                        onIncrement: () => setState(() => entry.quantity++),
                      ),
                      const Spacer(),
                      // Foil toggle / label — native Switch for 44dp tap target.
                      if (entry.hasFoil)
                        entry.isFoilEditable
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('Foil',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: entry.isFoil
                                          ? AppColors.amber400
                                          : AppColors.textSecondary,
                                    )),
                                const SizedBox(width: 6),
                                Switch.adaptive(
                                  value: entry.isFoil,
                                  activeColor: AppColors.amber400,
                                  onChanged: (v) => setState(() => entry.isFoil = v),
                                ),
                              ])
                            : Text('★ Foil',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.amber400,
                                  fontWeight: FontWeight.w700,
                                )),
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

  // ══════════════════════════════════════════════
  // ── Bottom Bar ──
  // ══════════════════════════════════════════════

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedCount cards selected',
                  style: AppTextStyles.bodySmall.copyWith( color: AppColors.textSecondary)),
              Text('€${_totalPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: RiftrButton(
                  label: 'Add to Collection',
                  style: RiftrButtonStyle.primary,
                  onPressed: _addToCollection,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: RiftrButton(
                  label: 'Create Listings',
                  style: RiftrButtonStyle.secondary,
                  onPressed: _createListings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── Price Editor Sheet ──
  // ══════════════════════════════════════════════

  void _showPriceEditor(_ResultEntry entry) {
    final controller = TextEditingController(
      text: _effectivePrice(entry).toStringAsFixed(2),
    );
    showRiftrSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.card.name,
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '€ ',
                prefixStyle: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.amber400, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  borderSide: BorderSide(color: AppColors.amber400),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            RiftrButton(
              label: 'Confirm',
              style: RiftrButtonStyle.primary,
              onPressed: () {
                final parsed = double.tryParse(controller.text);
                if (parsed != null && parsed > 0) {
                  setState(() => entry.manualPrice = parsed);
                }
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (entry.manualPrice != null)
              // 44dp touch-target for text-link action.
              SizedBox(
                height: 44,
                width: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => entry.manualPrice = null);
                    Navigator.pop(ctx);
                  },
                  child: Center(
                    child: Text('Reset to modifier price',
                        style: AppTextStyles.micro.copyWith(color: AppColors.amber400)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── Variant Picker ──
  // ══════════════════════════════════════════════

  void _showVariantPicker(_ResultEntry entry) {
    final all = [entry.scanEntry.card, ...entry.scanEntry.alternatives];
    showRiftrSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large preview — battlefield rotated 90° for portrait fit
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                  child: entry.card.type?.toLowerCase() == 'battlefield'
                      ? SizedBox(
                          width: 120, height: 168,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: CardImage(
                              imageUrl: entry.card.imageUrl,
                              fallbackText: entry.card.name,
                              fit: BoxFit.cover,
                              card: entry.card,
                            ),
                          ),
                        )
                      : CardImage(
                          imageUrl: entry.card.imageUrl,
                          fallbackText: entry.card.name,
                          width: 120, height: 168, fit: BoxFit.cover,
                          card: entry.card,
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (all.length > 1) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select variant', style: AppTextStyles.bodyBold),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...all.map((card) {
                  final isSelected = card.id == entry.card.id;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.minimal),
                      // Battlefield rotation — same treatment as the
                      // editor sheet variant tiles.
                      child: card.type?.toLowerCase() == 'battlefield'
                          ? SizedBox(
                              width: 36, height: 50,
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: CardImage(
                                  imageUrl: card.imageUrl,
                                  fallbackText: card.name,
                                  fit: BoxFit.cover,
                                  card: card,
                                ),
                              ),
                            )
                          : CardImage(
                              imageUrl: card.imageUrl,
                              fallbackText: card.name,
                              width: 36, height: 50, fit: BoxFit.cover,
                              card: card,
                            ),
                    ),
                    title: Text(card.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        )),
                    subtitle: Text(
                        '${card.setId} #${card.collectorNumber ?? ''} · ${card.rarity}',
                        style: AppTextStyles.micro.copyWith(color: AppColors.textMuted)),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColors.amber400, size: 20)
                        : null,
                    onTap: () {
                      setState(() => entry.card = card);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
