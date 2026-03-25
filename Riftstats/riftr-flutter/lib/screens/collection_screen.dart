import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_components.dart';
import '../theme/app_theme.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';
import '../services/firestore_collection_service.dart';
import '../services/market_service.dart';
import '../services/demo_service.dart';
import '../widgets/card_preview.dart';
import '../widgets/card_image.dart';
import '../widgets/gold_header.dart';
import '../widgets/section_divider.dart';
import '../widgets/filter_chip_dropdown.dart';
import '../widgets/gold_line.dart';


class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => CollectionScreenState();
}

class CollectionScreenState extends State<CollectionScreen> {
  List<RiftCard> _allCards = [];
  List<RiftCard> _filtered = [];
  bool _loading = true;

  final _collectionService = FirestoreCollectionService.instance;
  final _demo = DemoService.instance;
  final _searchController = TextEditingController();
  final _filterScrollController = ScrollController();

  String _ownershipFilter = 'all'; // 'all', 'owned', 'missing'
  bool _setsExpanded = false;
  String? _selectedType;
  String? _selectedRarity;
  String? _selectedSet;
  String? _selectedKeyword;
  int? _selectedCost;
  Set<String> _selectedDomains = {};

  bool get _isDemo => _demo.isActive;

  int _getQuantity(String cardId) {
    if (_isDemo) return _demo.getQuantity(cardId);
    return _collectionService.getQuantity(cardId);
  }

  int _getFoilQuantity(String cardId) {
    if (_isDemo) return _demo.getFoilQuantity(cardId);
    return _collectionService.getFoilQuantity(cardId);
  }

  int _getTotalQuantity(String cardId) {
    if (_isDemo) return _demo.getTotalQuantity(cardId);
    return _collectionService.getTotalQuantity(cardId);
  }

  int get _uniqueOwned {
    if (_isDemo) return _demo.uniqueOwned;
    return _collectionService.uniqueOwned;
  }

  int get _totalCopies {
    if (_isDemo) return _demo.totalCopies;
    return _collectionService.totalCopies;
  }

  void _increment(String cardId, {bool foil = false}) {
    if (_isDemo) {
      if (foil) {
        _demo.setQuantity(cardId, _demo.getFoilQuantity(cardId) + 1, foil: true);
      } else {
        _demo.setQuantity(cardId, _demo.getQuantity(cardId) + 1);
      }
    } else {
      final priceData = MarketService.instance.getPrice(cardId);
      // Use same price logic as _HoldingEntry.unitPrice so cost basis matches display
      final marketPrice = priceData == null ? 0.0 : foil
          ? (priceData.foilPrice > 0 ? priceData.foilPrice : priceData.currentPrice)
          : (priceData.nonFoilPrice > 0 ? priceData.nonFoilPrice : priceData.currentPrice);
      _collectionService.increment(cardId, costPrice: marketPrice > 0 ? marketPrice : null, foil: foil);
    }
  }

  void _decrement(String cardId, {bool foil = false}) {
    if (_isDemo) {
      if (foil) {
        final qty = _demo.getFoilQuantity(cardId);
        if (qty > 0) _demo.setQuantity(cardId, qty - 1, foil: true);
      } else {
        final qty = _demo.getQuantity(cardId);
        if (qty > 0) _demo.setQuantity(cardId, qty - 1);
      }
    } else {
      // Block if open orders would be violated
      final newTotal = _collectionService.getTotalQuantity(cardId) - 1;
      final warning = _collectionService.canReduce(cardId, newTotal);
      if (warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warning),
            backgroundColor: AppColors.loss,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      _collectionService.decrement(cardId, foil: foil);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCards();
    _collectionService.addListener(_onCollectionChanged);
    _demo.addListener(_onCollectionChanged);
  }

  void _onCollectionChanged() {
    _applyFilters();
    // Show toast if listings were auto-adjusted
    final msg = _collectionService.consumeListingSyncMessage();
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.amber500,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadCards() async {
    final cards = await CardService.loadCards();
    setState(() {
      _allCards = cards;
      _filtered = cards;
      _loading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filtered = _allCards.where((card) {
        // Text search
        if (query.isNotEmpty) {
          final nameMatch = card.name.toLowerCase().contains(query);
          final displayMatch = card.displayName.toLowerCase().contains(query);
          final textMatch = card.textPlain?.toLowerCase().contains(query) ?? false;
          final cn = query.startsWith('#') ? query.substring(1) : query;
          final cnNum = cn.replaceAll(RegExp(r'[^0-9]'), '');
          final cnSuffix = cn.replaceAll(RegExp(r'[0-9]'), '');
          final cnMatch = cnNum.isNotEmpty && card.collectorNumber != null &&
              card.collectorNumber!.startsWith(cnNum) &&
              (cnSuffix.isEmpty || card.collectorNumber!.endsWith(cnSuffix));
          if (!nameMatch && !displayMatch && !textMatch && !cnMatch) return false;
        }

        // Ownership filter (count normal + foil)
        final totalQty = _getTotalQuantity(card.id);
        if (_ownershipFilter == 'owned' && totalQty == 0) return false;
        if (_ownershipFilter == 'missing' && totalQty > 0) return false;

        // Type filter
        if (_selectedType != null && card.type != _selectedType) return false;

        // Rarity filter
        if (_selectedRarity != null && card.rarity != _selectedRarity) return false;

        // Set filter
        if (_selectedSet != null && card.setId != _selectedSet) return false;

        // Domain filter: 2 selected = exact combo, 1 = any match
        if (_selectedDomains.isNotEmpty) {
          if (_selectedDomains.length == 2) {
            if (!_selectedDomains.every((d) => card.domains.contains(d))) return false;
          } else {
            if (!card.domains.any((d) => _selectedDomains.contains(d))) return false;
          }
        }

        // Keyword filter
        if (_selectedKeyword != null) {
          if (!card.keywords.contains(_selectedKeyword)) return false;
        }

        // Cost filter — React: '6+' means energy >= 6
        if (_selectedCost != null) {
          if (_selectedCost == 6) {
            if ((card.energy ?? 0) < 6) return false;
          } else {
            if (card.energy != _selectedCost) return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    _collectionService.removeListener(_onCollectionChanged);
    _demo.removeListener(_onCollectionChanged);
    super.dispose();
  }

  void resetScroll() {
    if (_filterScrollController.hasClients) _filterScrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber400),
      );
    }

    return _buildCardGrid();
  }

  // React: bg-slate-900 border border-amber-500/10 rounded-3xl p-6
  // Ring: 140x140, stroke=#d97706, strokeWidth=10, text-2xl font-black text-white, "Complete" text-[9px]
  // Stats: text-[10px] font-black uppercase labels, text-lg font-black values
  // Per-set bars: h-2 rounded-full bg-amber-500
  Widget _buildProgressHeader() {
    final totalUnique = _allCards.length;
    final ownedUnique = _uniqueOwned;
    final totalCopies = _totalCopies;
    final percentage = totalUnique > 0 ? (ownedUnique / totalUnique * 100) : 0.0;

    // Per-set breakdown
    final sets = CardService.getBaseSets();
    final setTotals = <String, int>{};
    final setOwned = <String, int>{};
    for (final s in sets) {
      setTotals[s] = _allCards.where((c) => c.setId == s).length;
      setOwned[s] = _allCards
          .where((c) => c.setId == s && _getTotalQuantity(c.id) > 0)
          .length;
    }

    return GestureDetector(
      onTap: () => setState(() => _setsExpanded = !_setsExpanded),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.amber500.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Progress ring
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(percentage / 100),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: AppTextStyles.displaySmall,
                          ),
                          Text(
                            'COMPLETE',
                            style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Stats section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIQUE CARDS',
                        style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.h2.copyWith(fontSize: 19, fontWeight: FontWeight.w900),
                          children: [
                            TextSpan(text: '$ownedUnique '),
                            TextSpan(
                              text: '/ $totalUnique',
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.slate600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'TOTAL COPIES',
                        style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalCopies',
                        style: AppTextStyles.h2.copyWith(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.amber400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Set bars (collapsible)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, right: AppSpacing.xl),
                child: Column(
                  children: sets.map((s) {
                    final total = setTotals[s] ?? 0;
                    final owned = setOwned[s] ?? 0;
                    final pct = total > 0 ? owned / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(s, style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadius.fullBR,
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: AppColors.surfaceLight,
                                color: AppColors.amber500,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '$owned/$total (${(pct * 100).toStringAsFixed(1)}%)',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _setsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
      // Arrow overlaid on bottom-right of the card
      Positioned(
        right: 24,
        bottom: 16,
        child: AnimatedRotation(
          turns: _setsExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.keyboard_arrow_down, size: 28, color: AppColors.amber500),
        ),
      ),
    ]),
    );
  }

  // React: flex gap-2, pills: px-4 py-2 rounded-full text-xs font-bold
  // Active: bg-amber-600 text-white, Inactive: bg-slate-900 text-slate-400 border border-slate-800
  Widget _buildOwnershipPills() {
    final total = _allCards.length;
    final owned = _uniqueOwned;
    final missing = total - owned;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          _buildPill('All ($total)', 'all'),
          const SizedBox(width: AppSpacing.sm),
          _buildPill('Owned ($owned)', 'owned'),
          const SizedBox(width: AppSpacing.sm),
          _buildPill('Missing ($missing)', 'missing'),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value) {
    return RiftrPill(
      label: label,
      isActive: _ownershipFilter == value,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _ownershipFilter = value);
        _applyFilters();
      },
    );
  }

  Widget _buildFilterRow() {
    final types = CardService.getTypes();
    final rarities = CardService.getRarities();
    final sets = CardService.getSets();
    final keywords = CardService.getKeywords();
    const domains = ['Fury', 'Mind', 'Chaos', 'Calm', 'Body', 'Order'];

    return Column(
      children: [
        // Row 1: Dropdown chips — React: flex gap-2
        SingleChildScrollView(
          controller: _filterScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: [
              FilterChipDropdown(
                label: _selectedType ?? 'Type',
                defaultLabel: 'Type',
                isActive: _selectedType != null,
                activeValue: _selectedType,
                items: types,
                onSelected: (v) {
                  setState(() => _selectedType = _selectedType == v ? null : v);
                  _applyFilters();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChipDropdown(
                label: _selectedRarity ?? 'Rarity',
                defaultLabel: 'Rarity',
                isActive: _selectedRarity != null,
                activeValue: _selectedRarity,
                items: rarities,
                onSelected: (v) {
                  setState(() => _selectedRarity = _selectedRarity == v ? null : v);
                  _applyFilters();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChipDropdown(
                label: _selectedSet ?? 'Set',
                defaultLabel: 'Set',
                isActive: _selectedSet != null,
                activeValue: _selectedSet,
                items: sets,
                onSelected: (v) {
                  setState(() => _selectedSet = _selectedSet == v ? null : v);
                  _applyFilters();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChipDropdown(
                label: _selectedKeyword ?? 'Keyword',
                defaultLabel: 'Keyword',
                isActive: _selectedKeyword != null,
                activeValue: _selectedKeyword,
                items: keywords,
                onSelected: (v) {
                  setState(() => _selectedKeyword = _selectedKeyword == v ? null : v);
                  _applyFilters();
                },
              ),
            ],
          ),
        ),

        const GoldLine(),

        // Row 2: Domain icons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: domains.map((domain) {
              final isActive = _selectedDomains.contains(domain);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_selectedDomains.contains(domain)) {
                      _selectedDomains.remove(domain);
                    } else if (_selectedDomains.length < 2) {
                      _selectedDomains.add(domain);
                    } else {
                      _selectedDomains = {_selectedDomains.last, domain};
                    }
                  });
                  _applyFilters();
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.fullBR,
                    color: isActive ? AppColors.amber400.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(
                      color: isActive ? AppColors.amber400.withValues(alpha: 0.8) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.4,
                    child: RuneIcon(domain: domain),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const GoldLine(),

        // Row 3: Cost circles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final label = i == 6 ? '6+' : '$i';
              final cost = i;
              final isActive = _selectedCost == cost;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCost = _selectedCost == cost ? null : cost);
                  _applyFilters();
                },
                child: Opacity(
                  opacity: isActive ? 1.0 : 0.6,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.amber500 : AppColors.surfaceLight,
                      border: isActive ? Border.all(color: AppColors.amber300, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }


  /// Build grid rows — all cards same size (3 per row), battlefields rotated in cell.
  List<List<({RiftCard card, int span})>> _buildGridRows() {
    final rows = <List<({RiftCard card, int span})>>[];
    var currentRow = <({RiftCard card, int span})>[];

    for (final card in _filtered) {
      currentRow.add((card: card, span: 1));
      if (currentRow.length == 3) {
        rows.add(currentRow);
        currentRow = [];
      }
    }
    if (currentRow.isNotEmpty) rows.add(currentRow);
    return rows;
  }

  Widget _buildCardGrid() {
    final rows = _buildGridRows();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        const gridPadding = 2.0;
        final totalWidth = constraints.maxWidth - gridPadding * 2;
        final colWidth = (totalWidth - gap * 2) / 3;
        final portraitHeight = colWidth * 1.5 + 18;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: rows.length + 1, // +1 for header
          itemBuilder: (context, index) {
            // Header: ornament + progress + ownership + search + filters + divider
            if (index == 0) {
              return Column(
                children: [
                  const GoldOrnamentHeader(title: 'CLAIM YOUR LEGACY'),
                  _buildProgressHeader(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SectionDivider(icon: Icons.collections_bookmark, label: 'OWNERSHIP'),
                  ),
                  _buildOwnershipPills(),
                  const GoldLine(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        autocorrect: false,
                        enableSuggestions: false,
                        controller: _searchController,
                        onChanged: (_) => _applyFilters(),
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          hintStyle: AppTextStyles.bodySecondary,
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          border: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: const BorderSide(color: AppColors.amber400)),
                        ),
                      ),
                    ),
                  ),
                  _buildFilterRow(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SectionDivider(
                      icon: Icons.inventory_2_outlined,
                      label: '${_filtered.length} CARDS · ${_filtered.where((c) => _getTotalQuantity(c.id) > 0).length} OWNED',
                    ),
                  ),
                ],
              );
            }

            final rowIndex = index - 1;
            final row = rows[rowIndex];
            return Padding(
              padding: EdgeInsets.fromLTRB(gridPadding, 0, gridPadding, rowIndex < rows.length - 1 ? gap : 0),
              child: SizedBox(
                height: portraitHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(
                        flex: row[i].span,
                        child: _buildCardCell(row[i].card),
                      ),
                    ],
                    // Fill incomplete rows with empty spacers to maintain 3-column grid
                    for (var i = row.length; i < 3; i++) ...[
                      const SizedBox(width: gap),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // React CollectionCardItem:
  // Outer: relative overflow-hidden rounded-xl
  // Image: w-full h-full object-cover, unowned: grayscale opacity-40
  // Badge: absolute bottom-1 left-1, owned: bg-amber-600 text-white, unowned: bg-slate-800/80 text-slate-500 border-slate-600
  // Name: text-xs font-bold text-center mt-1, owned: text-white, unowned: text-slate-600
  Widget _buildCardCell(RiftCard card) {
    final qty = _getQuantity(card.id);
    final foilQty = _getFoilQuantity(card.id);
    final totalQty = qty + foilQty;
    final isOwned = totalQty > 0;

    return GestureDetector(
      onTap: () => _showEditOverlay(card),
      onLongPress: () => _showCardPreview(card),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.baseBR,
                    child: card.isBattlefield
                        ? RotatedBox(
                            quarterTurns: 1,
                            child: CardImage(
                              imageUrl: card.imageUrl,
                              fallbackText: card.displayName,
                              fit: BoxFit.cover,
                              greyscale: !isOwned,
                            ),
                          )
                        : CardImage(
                            imageUrl: card.imageUrl,
                            fallbackText: card.displayName,
                            fit: BoxFit.cover,
                            greyscale: !isOwned,
                          ),
                  ),
                ),
                // Promo badge for OGNX cards
                if (card.isSpecialVariant)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: card.isMetal
                            ? AppColors.foilGold
                            : AppColors.nonFoilPurple,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        card.isMetal ? 'METAL' : 'PROMO',
                        style: AppTextStyles.micro.copyWith(
                          fontSize: 8,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Quantity badge — React: absolute bottom-1 left-1
                Positioned(
                  bottom: 4, // bottom-1
                  left: 4, // left-1
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOwned ? AppColors.amber600 : AppColors.surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6), // rounded-md
                      border: isOwned ? null : Border.all(color: AppColors.slate600),
                    ),
                    child: qty > 0 && foilQty > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$qty+$foilQty',
                                style: AppTextStyles.small.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '★',
                                style: AppTextStyles.micro.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                              ),
                            ],
                          )
                        : Text(
                            '$totalQty',
                            style: AppTextStyles.small.copyWith(
                              color: isOwned ? AppColors.textPrimary : AppColors.textMuted,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs), // mt-1
          // Name — React: text-xs font-bold, owned=text-white, unowned=text-slate-600
          Text(
            card.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isOwned ? AppColors.textPrimary : AppColors.slate600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  void _showEditOverlay(RiftCard card) {
    showRiftrSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentQty = _getQuantity(card.id);
            final currentFoilQty = _getFoilQuantity(card.id);
            // OGS cards are always non-foil — single normal counter
            // Promos (OGNX/SFDX) are always foil — single foil counter
            // Rare/Epic/Showcase are foil-only — single foil counter
            // Common/Uncommon (non-OGS) have both normal + foil variants
            final isOGS = card.setId == 'OGS';
            final foilOnly = !isOGS && (card.isPromo || (card.rarity != 'Common' && card.rarity != 'Uncommon'));
            final normalOnly = isOGS;
            final showBothVariants = !foilOnly && !normalOnly;
            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card name
                  Text(
                    card.name,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    [card.type, card.rarity, card.setLabel].whereType<String>().join(' · '),
                    style: AppTextStyles.bodySmallSecondary,
                  ),
                  const SizedBox(height: 20),

                  // Normal +/- controls (only for Common/Uncommon non-promo)
                  if (showBothVariants)
                    const Text('Normal', style: AppTextStyles.caption),
                  if (!foilOnly)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountButton(
                          icon: Icons.remove,
                          onTap: currentQty > 0
                              ? () {
                                  HapticFeedback.lightImpact();
                                  _decrement(card.id);
                                  setSheetState(() {});
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            '$currentQty',
                            style: AppTextStyles.display,
                          ),
                        ),
                        _buildCountButton(
                          icon: Icons.add,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _increment(card.id);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),

                  // Foil +/- controls (Common/Uncommon: second row; Promo/Rare+: only row)
                  if (showBothVariants || foilOnly) ...[
                    if (showBothVariants) const SizedBox(height: AppSpacing.base),
                    if (showBothVariants)
                      Text('Foil', style: AppTextStyles.caption.copyWith(color: const Color(0xFFD4AF37))),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountButton(
                          icon: Icons.remove,
                          onTap: currentFoilQty > 0
                              ? () {
                                  HapticFeedback.lightImpact();
                                  _decrement(card.id, foil: true);
                                  setSheetState(() {});
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            '$currentFoilQty',
                            style: AppTextStyles.display.copyWith(
                              color: foilOnly ? AppColors.textPrimary : const Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                        _buildCountButton(
                          icon: Icons.add,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _increment(card.id, foil: true);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCountButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? AppColors.amber400.withValues(alpha: 0.2) : AppColors.border,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.amber400 : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.amber400 : AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  void _showCardPreview(RiftCard card) {
    Navigator.of(context).push(CardPreviewRoute(card: card));
  }
}

// React: SVG circle cx=70 cy=70 r=60, strokeWidth=10
// Background: rgba(255,255,255,0.05), Progress: #d97706 (amber-600)
class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10; // r=60 in 140px container

    // Background ring — React: rgba(255,255,255,0.05)
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc — React: #d97706 (amber-600)
    final progressPaint = Paint()
      ..color = AppColors.amber600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
