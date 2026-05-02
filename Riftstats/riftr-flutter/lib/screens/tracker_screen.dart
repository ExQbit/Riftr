import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/card_image.dart';
import '../widgets/tap_scale.dart';
import '../widgets/gold_header.dart';
import '../widgets/section_divider.dart';
import '../widgets/gold_line.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/domain_filter_row.dart';
import '../widgets/riftr_search_bar.dart';
import '../widgets/legend_filter_dropdown.dart';
import '../widgets/riftr_drag_handle.dart';
import '../widgets/deck/deck_set_badges.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../theme/app_components.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../models/match_model.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import '../services/match_service.dart';
import '../services/firestore_deck_service.dart';
import '../widgets/riftr_toast.dart';
import '../services/demo_service.dart';

/// Match Tracker — Fighting-game style battle flow.
/// Flow: Pick Deck → Pick Opponent → VS Screen → Battle (score tracking)
class TrackerScreen extends StatefulWidget {
  final void Function(bool hidden)? onFullscreenChanged;
  final VoidCallback? onGoToDecks;
  const TrackerScreen({super.key, this.onFullscreenChanged, this.onGoToDecks});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> with TickerProviderStateMixin {
  // Canonical domain order from AppColors.domainOrder.
  static List<String> _sortDomains(List<String> domains) {
    final order = AppColors.domainOrder;
    final sorted = List<String>.from(domains);
    sorted.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return sorted;
  }

  // State
  String _step = 'deck'; // 'deck', 'opponent', 'vs', 'battle'
  List<RiftCard> _legends = [];
  bool _loading = true;

  // Per-user SharedPrefs key — prevents match-context preference leaking
  // across accounts on the same device.
  static String _matchContextKeyFor(String? uid) {
    const base = 'riftbound-tracker-match-context';
    return uid == null ? base : '${base}_$uid';
  }
  String _matchContext = 'casual';
  final Set<String> _legendFilters = {};
  String _deckSearch = '';
  final TextEditingController _deckSearchController = TextEditingController();
  final TextEditingController _legendSearchController = TextEditingController();
  final Set<String> _domainFilters = {};
  // Arsenal pagination — 25 initial, +25 per "Load more" tap.
  int _deckDisplayCount = 25;
  static const _matchContexts = [
    ('casual', 'Casual'),
    ('nexus-night', 'Nexus Night'),
    ('skirmish', 'Skirmish'),
    ('regional', 'Regional'),
    ('sealed', 'Sealed'),
    ('draft', 'Draft'),
    ('online', 'Online'),
  ];

  DeckData? _selectedDeck;  // Selected deck for match
  RiftCard? _myLegend;
  RiftCard? _oppLegend;
  String _legendSearch = '';

  bool _isFirst = true;
  int _myScore = 0;
  int _oppScore = 0;
  String? _pendingResult; // 'win', 'loss', 'draw'
  List<Map<String, dynamic>> _games = [];

  // Legend browser overlay
  bool _showLegendBrowser = false;

  // Coin flip
  bool _isFlipping = false;

  // VS animation
  bool _vsReady = false;
  late AnimationController _vsController;
  late Animation<double> _vsScale;

  // Coin flip Y-rotation
  late AnimationController _coinFlipCtrl;

  // Round announce
  bool _showRoundBadge = false;
  bool _showFightBadge = false;
  bool _roundBadgeSettled = false;

  // Hero card breathing animation (6s infinite, scale 1.0 → 1.005 → 1.0)
  late AnimationController _breatheCtrl;

  @override
  void initState() {
    super.initState();
    _vsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _vsScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vsController, curve: Curves.elasticOut),
    );
    _coinFlipCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _breatheCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _loadLegends();
    _loadMatchContext();
    FirestoreDeckService.instance.addListener(_onDecksChanged);
    DemoService.instance.addListener(_onDecksChanged);
  }

  @override
  void dispose() {
    // Reset status-bar backdrop in case user navigates away while in the
    // opponent picker — otherwise the surface color leaks into other tabs.
    AppShell.topBgNotifier.value = AppColors.background;
    _vsController.dispose();
    _coinFlipCtrl.dispose();
    _breatheCtrl.dispose();
    _deckSearchController.dispose();
    _legendSearchController.dispose();
    FirestoreDeckService.instance.removeListener(_onDecksChanged);
    DemoService.instance.removeListener(_onDecksChanged);
    super.dispose();
  }

  void _onDecksChanged() {
    if (mounted) setState(() {});
  }

  static const _fullscreenSteps = {'opponent', 'vs', 'battle'};

  void _setStep(String newStep) {
    final wasFullscreen = _fullscreenSteps.contains(_step);
    final isFullscreen = _fullscreenSteps.contains(newStep);
    _step = newStep;
    if (wasFullscreen != isFullscreen) {
      widget.onFullscreenChanged?.call(isFullscreen);
    }
    // Status-bar backdrop: opponent picker's top half is surface-colored, so
    // bleed surface into the status-bar area for a seamless look. Other
    // fullscreen steps (vs, battle) use image-filled halves — leave
    // backdrop as scaffold default.
    AppShell.topBgNotifier.value =
        newStep == 'opponent' ? AppColors.surface : AppColors.background;
  }

  Future<void> _loadLegends() async {
    final cards = await CardService.loadCards();
    setState(() {
      // Base sets + promo alt-arts (unique variants), exclude Metal & promo dupes
      const promoSets = {'OGNX', 'SFDX'};
      final baseLegends = cards
          .where((c) => c.isLegend && !c.isMetal &&
              (!promoSets.contains(c.setId) || c.alternateArt))
          .toList();

      // Where both overnumbered + signature share a col#, keep signature, drop overnumbered
      final sigNums = <int>{};
      for (final c in baseLegends) {
        if (c.signature) sigNums.add(c.collectorNumberInt);
      }

      _legends = baseLegends
          .where((c) => !c.overnumbered || !sigNums.contains(c.collectorNumberInt))
          .toList();

      // Group by champion name, standard first then variants
      // Champion group order: by standard card's set + collector number (like Cards tab)
      final setOrder = {'UNL': 0, 'SFD': 1, 'SFDX': 2, 'OGS': 3, 'OGSX': 4, 'OGN': 5, 'OGNX': 6};
      int variantOrder(RiftCard c) {
        if (c.signature) return 3;
        if (c.overnumbered) return 2;
        if (c.alternateArt) return 1;
        return 0;
      }

      // Find each champion's standard card for group ordering
      final groups = <String, List<RiftCard>>{};
      for (final c in _legends) {
        final champion = c.name.split(',').first.trim();
        (groups[champion] ??= []).add(c);
      }

      // Sort within each group: standard first, then variants
      for (final cards in groups.values) {
        cards.sort((a, b) {
          final vo = variantOrder(a).compareTo(variantOrder(b));
          if (vo != 0) return vo;
          return a.collectorNumberInt.compareTo(b.collectorNumberInt);
        });
      }

      // Sort groups by their standard card's set + collector number
      final sortedGroups = groups.entries.toList()..sort((a, b) {
        final aStd = a.value.first;
        final bStd = b.value.first;
        final setComp = (setOrder[aStd.setId] ?? 99).compareTo(setOrder[bStd.setId] ?? 99);
        if (setComp != 0) return setComp;
        return aStd.collectorNumberInt.compareTo(bStd.collectorNumberInt);
      });

      _legends = sortedGroups.expand((e) => e.value).toList();
      _loading = false;
    });
  }

  Future<void> _loadMatchContext() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_matchContextKeyFor(AuthService.instance.uid));
    if (saved != null && mounted) {
      setState(() => _matchContext = saved);
    }
  }

  Future<void> _setMatchContext(String value) async {
    setState(() => _matchContext = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_matchContextKeyFor(AuthService.instance.uid), value);
  }

  String _shortName(String name) {
    return name.contains(',') ? name.split(',')[0].trim() : name;
  }

  void _selectDeck(DeckData deck) {
    // Find the legend card for this deck
    final legend = _legends.where((l) => l.id == deck.legendId).firstOrNull ??
        _legends.where((l) => l.name == deck.legendName).firstOrNull;

    setState(() {
      _selectedDeck = deck;
      _myLegend = legend;
      _legendSearch = '';
      _setStep('opponent');
    });
  }

  void _selectOpponent(RiftCard legend) {
    setState(() {
      _oppLegend = legend;
      _legendSearch = '';
      _setStep('vs');
      _vsReady = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _vsReady = true);
      _vsController.forward(from: 0);
    });
  }

  void _startBattle() {
    setState(() {
      _myScore = 0;
      _oppScore = 0;
      _pendingResult = null;
      _games = [];
      _setStep('battle');
    });
    _startRoundAnnounce();
  }

  void _startRoundAnnounce() {
    setState(() {
      _showRoundBadge = true;
      _showFightBadge = false;
      _roundBadgeSettled = false;
    });
    // 0.6s: settle round badge (shrink + fade)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _roundBadgeSettled = true);
    });
    // 1.0s: show FIGHT badge (over settled round badge)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _showFightBadge = true);
    });
    // 2.4s: hide FIGHT
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _showFightBadge = false);
    });
    // 2.6s: done
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _showRoundBadge = false);
    });
  }

  void _finishGame() {
    final result = _myScore > _oppScore
        ? 'win'
        : _myScore < _oppScore
            ? 'loss'
            : 'draw';
    setState(() {
      _pendingResult = result;
    });
  }

  void _handleRematch() {
    if (_pendingResult == null || _games.length >= 2) return;
    setState(() {
      _games.add({
        'myScore': _myScore,
        'oppScore': _oppScore,
        'result': _pendingResult,
        'isFirst': _isFirst,
      });
      _myScore = 0;
      _oppScore = 0;
      _pendingResult = null;
      _isFirst = !_isFirst;
      _setStep('battle');
    });
    _startRoundAnnounce();
  }

  Future<void> _saveAndReset() async {
    final allGames = [
      ..._games,
      {
        'myScore': _myScore,
        'oppScore': _oppScore,
        'result': _pendingResult ?? 'loss',
        'isFirst': _isFirst,
      }
    ];

    final myWins = allGames.where((g) => g['result'] == 'win').length;
    final oppWins = allGames.where((g) => g['result'] == 'loss').length;
    final seriesResult = myWins > oppWins ? 'win' : myWins < oppWins ? 'loss' : 'draw';

    final totalMyScore = allGames.fold<int>(0, (s, g) => s + (g['myScore'] as int));
    final totalOppScore = allGames.fold<int>(0, (s, g) => s + (g['oppScore'] as int));

    final format = allGames.length == 1 ? 'bo1' : allGames.length == 2 ? 'bo2' : 'bo3';

    final match = MatchData(
      deckId: _selectedDeck?.id ?? '',
      deckName: _selectedDeck?.name ?? _shortName(_myLegend!.name),
      legendName: _myLegend!.name,
      opponent: _oppLegend!.name,
      isFirst: _isFirst,
      myScore: totalMyScore,
      oppScore: totalOppScore,
      result: seriesResult,
      format: format,
      games: allGames.map((g) => GameResult(
        myScore: g['myScore'] as int,
        oppScore: g['oppScore'] as int,
        result: g['result'] as String,
        isFirst: g['isFirst'] as bool,
      )).toList(),
      timestamp: DateTime.now(),
    );

    try {
      if (DemoService.instance.isActive) {
        DemoService.instance.addMatch(match);
      } else {
        await MatchService.instance.addMatch(match);
      }
    } catch (e) {
      debugPrint('Save match error: $e');
    }

    final label = seriesResult == 'win' ? 'Win' : seriesResult == 'loss' ? 'Loss' : 'Draw';
    if (mounted) {
      RiftrToast.success(context, 'Match saved: $label (${allGames.length} game${allGames.length > 1 ? 's' : ''})');
    }

    setState(() {
      _setStep('deck');
      _selectedDeck = null;
      _myLegend = null;
      _oppLegend = null;
      _games = [];
      _pendingResult = null;
    });
  }

  void _goBack() {
    setState(() {
      if (_step == 'battle' && _pendingResult != null) {
        // Result shown → back to score editing
        _pendingResult = null;
      } else if (_step == 'battle') {
        _setStep('vs');
      } else if (_step == 'vs') {
        _oppLegend = null;
        _setStep('opponent');
      } else if (_step == 'opponent') {
        _myLegend = null;
        _selectedDeck = null;
        _setStep('deck');
      }
    });
  }

  void _doCoinFlip() {
    if (_isFlipping) return;
    setState(() => _isFlipping = true);
    HapticFeedback.mediumImpact();
    _coinFlipCtrl.forward(from: 0);

    // Rapid toggle like React (80ms intervals, 6-9 times)
    final flipCount = 6 + math.Random().nextInt(4);
    int flips = 0;
    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) { timer.cancel(); return; }
      flips++;
      if (flips >= flipCount) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() {
            _isFirst = math.Random().nextBool();
            _isFlipping = false;
          });
          HapticFeedback.heavyImpact();
        });
      } else {
        setState(() => _isFirst = !_isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.amber400),
      );
    }

    return switch (_step) {
      'deck' => _buildDeckPicker(),
      'opponent' => _buildOpponentPicker(),
      'vs' => _buildVsScreen(),
      'battle' => _buildBattleScreen(),
      _ => _buildDeckPicker(),
    };
  }

  // Autocomplete source: deck names from the tracker's own deck list.
  List<String> _suggestDeckNames(String q) {
    if (q.trim().isEmpty) return const [];
    final isDemo = DemoService.instance.isActive;
    final decks = isDemo ? DemoService.instance.decks : FirestoreDeckService.instance.decks;
    return _matchNames(q, decks.map((d) => d.name));
  }

  // Autocomplete source: unique legend names from all decks.
  List<String> _suggestLegendNames(String q) {
    if (q.trim().isEmpty) return const [];
    final isDemo = DemoService.instance.isActive;
    final decks = isDemo ? DemoService.instance.decks : FirestoreDeckService.instance.decks;
    return _matchNames(q, decks.map((d) => d.legendName ?? '').where((n) => n.isNotEmpty));
  }

  /// Starts-with matches ranked before contains-matches, deduplicated, max 5.
  List<String> _matchNames(String query, Iterable<String> source) {
    final lower = query.trim().toLowerCase();
    final starts = <String>[];
    final contains = <String>[];
    final seen = <String>{};
    for (final name in source) {
      if (seen.contains(name)) continue;
      final nLower = name.toLowerCase();
      if (nLower.startsWith(lower)) {
        seen.add(name);
        starts.add(name);
      } else if (nLower.contains(lower)) {
        seen.add(name);
        contains.add(name);
      }
      if (starts.length >= 5) break;
    }
    final combined = [...starts, ...contains];
    return combined.length > 5 ? combined.sublist(0, 5) : combined;
  }

  // ============================================
  // DECK PICKER (first step)
  // ============================================
  Widget _buildDeckPicker() {
    final isDemo = DemoService.instance.isActive;
    final decks = isDemo ? DemoService.instance.decks : FirestoreDeckService.instance.decks;
    final lookup = CardService.getLookup();
    final validDecks = decks.where((d) => d.isFullyValid(lookup)).toList();

    // Build unique legend options from decks (sorted by deck count descending)
    final legendCounts = <String, ({String shortName, String? imageUrl, int count})>{};
    for (final deck in validDecks) {
      final legendName = deck.legendName;
      if (legendName == null) continue;
      final shortName = _shortName(legendName);
      final existing = legendCounts[shortName];
      legendCounts[shortName] = (
        shortName: shortName,
        imageUrl: existing?.imageUrl ?? deck.legendImageUrl,
        count: (existing?.count ?? 0) + 1,
      );
    }
    final legendOptions = legendCounts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Apply all filters
    var filteredDecks = validDecks.toList();
    if (_deckSearch.isNotEmpty) {
      final q = _deckSearch.toLowerCase();
      filteredDecks = filteredDecks.where((d) =>
          d.name.toLowerCase().contains(q) ||
          (d.legendName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    if (_legendFilters.isNotEmpty) {
      filteredDecks = filteredDecks.where((d) {
        final shortName = d.legendName != null ? _shortName(d.legendName!) : '';
        return _legendFilters.contains(shortName);
      }).toList();
    }
    if (_domainFilters.isNotEmpty) {
      filteredDecks = filteredDecks.where((d) =>
          _domainFilters.length == 2
              ? _domainFilters.every((f) => d.domains.contains(f)) // exact combo
              : d.domains.any((domain) => _domainFilters.contains(domain))
      ).toList();
    }

    // Sort newest-first by updatedAt fallback createdAt (same pattern as Decks tab).
    filteredDecks.sort((a, b) {
      final dateA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final dateB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    // Client-side pagination — show first N, expand on "Load more" tap.
    final displayedDecks = filteredDecks.take(_deckDisplayCount).toList();
    final hasMore = filteredDecks.length > _deckDisplayCount;

    return Column(
      children: [
        const GoldOrnamentHeader(title: 'CHOOSE YOUR BATTLE'),

        // Match context dropdown — custom build matching React pattern
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: Center(
            child: _MatchContextDropdown(
              value: _matchContext,
              items: _matchContexts,
              onChanged: _setMatchContext,
            ),
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: RiftrSearchBar(
            controller: _deckSearchController,
            hintText: 'Search decks...',
            onChanged: (v) => setState(() {
              _deckSearch = v;
              _deckDisplayCount = 25; // reset pagination on filter change
            }),
            onSuggest: _suggestDeckNames,
            onSuggestionTap: (v) => setState(() {
              _deckSearch = v;
              _deckDisplayCount = 25;
            }),
          ),
        ),

        const GoldLine(),

        // Domain filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: DomainFilterRow(
            active: _domainFilters,
            onToggle: (d) => setState(() {
              if (_domainFilters.contains(d)) {
                _domainFilters.remove(d);
              } else if (_domainFilters.length < 2) {
                _domainFilters.add(d);
              }
              _deckDisplayCount = 25; // reset pagination on filter change
            }),
          ),
        ),

        const GoldLine(),

        // Legend filter dropdown
        if (legendOptions.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
            child: LegendFilterDropdown(
              legends: legendOptions,
              activeFilters: _legendFilters,
              onToggle: (shortName) => setState(() {
                if (_legendFilters.contains(shortName)) {
                  _legendFilters.remove(shortName);
                } else {
                  _legendFilters.add(shortName);
                }
                _deckDisplayCount = 25; // reset pagination on filter change
              }),
              onClear: () => setState(() {
                _legendFilters.clear();
                _deckDisplayCount = 25;
              }),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: SectionDivider(
                icon: Icons.layers,
                label: _legendFilters.isEmpty
                    ? 'YOUR ARSENAL'
                    : 'YOUR ARSENAL (${filteredDecks.length})',
              )),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (filteredDecks.isEmpty) ...[
          const Spacer(flex: 2),
          RiftrEmptyState(
            icon: Icons.layers,
            title: _legendFilters.isNotEmpty ? 'No Matching Decks' : 'No Decks Yet',
            subtitle: _legendFilters.isNotEmpty
                ? 'Try clearing filters or create a new deck'
                : 'Create a deck in the Decks tab first',
            buttonLabel: _legendFilters.isNotEmpty ? 'Clear Filters' : 'Create a Deck',
            buttonIcon: _legendFilters.isNotEmpty ? Icons.filter_list_off : Icons.layers,
            onButtonPressed: _legendFilters.isNotEmpty
                ? () => setState(() {
                    _legendFilters.clear();
                    _deckDisplayCount = 25;
                  })
                : widget.onGoToDecks,
          ),
          const Spacer(flex: 3),
        ] else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
              // +1 slot for the "Load more" button when more decks are hidden.
              itemCount: displayedDecks.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Last slot when paginating = "Load more" button.
                if (hasMore && index == displayedDecks.length) {
                  final remaining = filteredDecks.length - _deckDisplayCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: RiftrButton(
                      label: 'Load more ($remaining remaining)',
                      style: RiftrButtonStyle.secondary,
                      icon: Icons.expand_more,
                      onPressed: () => setState(() => _deckDisplayCount += 25),
                    ),
                  );
                }
                final deck = displayedDecks[index];

                // React: rounded-2xl py-2 px-2 bg-slate-900/80 border-slate-800
                return TapScale(
                  onTap: () => _selectDeck(deck),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgBR, // rounded-2xl
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Legend image: w-14 h-[84px] = 56x84
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox(
                            width: 64, height: 96,
                            child: deck.legendImageUrl != null
                                ? CardImage(imageUrl: deck.legendImageUrl, fallbackText: deck.legendName ?? '', fit: BoxFit.cover)
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      border: Border.all(color: AppColors.textMuted, style: BorderStyle.none),
                                    ),
                                    child: Center(child: Text('No\nLegend', textAlign: TextAlign.center, style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6), // gap-1.5
                        // Domain icons: w-8 h-8 plain images, no circle border
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: deck.domains.isNotEmpty
                              ? _sortDomains(deck.domains).take(2).map((d) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: RuneIcon(domain: d, size: 32),
                                )).toList()
                              : [
                                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.border)),
                                  const SizedBox(height: AppSpacing.xs),
                                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.border)),
                                ],
                        ),
                        const SizedBox(width: 6),
                        // Deck info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // text-lg font-bold
                              Text(deck.name, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              // Description: text-xs text-slate-500 mb-1.5
                              if (deck.description != null && deck.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                                  child: Text(deck.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                ),
                              if (deck.description == null || deck.description!.isEmpty)
                                const SizedBox(height: AppSpacing.xs),
                              // Set badges (UNL/SFD/OGN/OGS) — ersetzen die alten
                              // Main/BF/Side-Completion-Badges. Selbe Optik wie
                              // im Decks-Tab → My Decks. Logik in DeckSetBadges
                              // (lib/widgets/deck/deck_set_badges.dart).
                              DeckSetBadges(
                                mainDeck: deck.mainDeck,
                                sideboard: deck.sideboard,
                              ),
                              // NO form dots — React doesn't show them here
                            ],
                          ),
                        ),
                        // Chevron: size-20 text-amber-500/30
                        Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ============================================
  // OPPONENT PICKER — React: fullscreen legend browser
  // Fixed inset-0, bg-black/80 backdrop-blur, header, search, 3-col grid
  // ============================================
  // ============================================
  // OPPONENT SELECT — React: fullscreen with SELECT badge
  // Top half: "Tap to select opponent", bottom half: your legend
  // ============================================
  Widget _buildOpponentPicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    return DragToDismiss(
      onDismissed: _goBack,
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Two halves
          Column(
            children: [
              // Top half — opponent placeholder (tap to open browser)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showLegendBrowser = true),
                  child: Container(
                    color: AppColors.surface,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, color: AppColors.textMuted, size: 48),
                          const SizedBox(height: AppSpacing.base),
                          Text(
                            'Tap to select opponent',
                            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom half — your legend card
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_myLegend?.imageUrl != null)
                      CardImage(
                        imageUrl: _myLegend!.imageUrl,
                        fallbackText: _myLegend!.name,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.6),
                        width: double.infinity,
                        height: double.infinity,
                      )
                    else
                      Container(color: AppColors.surface),
                    // Gradient overlay
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.background.withValues(alpha: 0.5),
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Drag handle (top center)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: const RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
          ),

          // SELECT badge (centered, 70vw, pulsing)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: screenWidth * 0.7,
                  child: Image.asset(
                    'assets/badges/select-badge.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Legend browser overlay
          if (_showLegendBrowser) _buildLegendBrowserOverlay(),
        ],
      ),
    );
  }

  // ============================================
  // LEGEND BROWSER OVERLAY — React: z-99999 fullscreen
  // ============================================
  Widget _buildLegendBrowserOverlay() {
    final query = _legendSearch.toLowerCase();
    final filtered = _legends.where((l) {
      if (query.isEmpty) return true;
      return l.name.toLowerCase().contains(query);
    }).toList();

    final hasCustom = _legendSearch.trim().isNotEmpty;
    final extraItems = hasCustom ? 1 : 0;

    return Positioned.fill(
      child: DragToDismiss(
        onDismissed: () => setState(() {
          _showLegendBrowser = false;
          _legendSearch = '';
        }),
        // Surface matches the opponent-picker's top half + topBgNotifier
        // status-bar strip — no seam between status bar, overlay body, and
        // underlying context.
        backgroundColor: AppColors.surface,
        child: Container(
          color: AppColors.surface,
          child: Column(
          children: [
            // Drag handle
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: AppSpacing.sm),
              child: const RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
            ),
            // Header
            const GoldOrnamentHeader(title: 'CHOOSE YOUR OPPONENT'),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
              child: RiftrSearchBar(
                controller: _legendSearchController,
                hintText: 'Search legend...',
                onChanged: (v) => setState(() => _legendSearch = v),
                onSuggest: _suggestLegendNames,
                onSuggestionTap: (v) => setState(() => _legendSearch = v),
              ),
            ),

                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2 / (3 + 0.4),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length + extraItems,
                    itemBuilder: (context, index) {
                      // Custom name option (last)
                      if (hasCustom && index == filtered.length) {
                        return GestureDetector(
                          onTap: () {
                            _selectOpponent(RiftCard.custom(_legendSearch.trim()));
                            setState(() {
                              _showLegendBrowser = false;
                              _legendSearch = '';
                            });
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: AppRadius.baseBR,
                                    border: Border.all(color: AppColors.slate600, width: 1, strokeAlign: BorderSide.strokeAlignInside),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.sm),
                                      child: Text(
                                        'Use "${_legendSearch.trim()}"',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.slate300, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text('Custom', style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }

                      // Legend card
                      final legend = filtered[index];

                      return GestureDetector(
                        onTap: () {
                          _selectOpponent(legend);
                          setState(() {
                            _showLegendBrowser = false;
                            _legendSearch = '';
                          });
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: AppRadius.baseBR,
                                child: CardImage(
                                  imageUrl: legend.imageUrl,
                                  fallbackText: _shortName(legend.displayName),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _shortName(legend.displayName),
                              style: AppTextStyles.small.copyWith(color: AppColors.slate300, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  // ============================================
  // SHARED: Card half (used in VS, Battle, Result)
  // ============================================
  Widget _buildCardHalf({
    required RiftCard legend,
    required bool isFlipped,
    bool isTop = false,
    bool breathe = false,
  }) {
    Widget imageWidget = legend.imageUrl != null
        ? CardImage(
            imageUrl: legend.imageUrl,
            fallbackText: legend.name,
            fit: BoxFit.cover,
            alignment: Alignment(0, isTop ? -0.6 : -0.6),
            width: double.infinity,
            height: double.infinity,
          )
        : Container(
            color: AppColors.surface,
            child: Center(
              child: Text(
                legend.name == 'Unknown' ? '?' : _shortName(legend.displayName)[0],
                style: AppTextStyles.scoreSmall.copyWith(color: AppColors.slate600),
              ),
            ),
          );

    if (isFlipped) {
      imageWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationZ(math.pi),
        child: imageWidget,
      );
    }

    // Subtle breathing: scale 1.0 → 1.005 → 1.0 over 6s (like React card-breathe)
    if (breathe) {
      imageWidget = AnimatedBuilder(
        animation: _breatheCtrl,
        builder: (context, child) {
          // sin curve: 0→1→0 over one cycle → scale 1.0 → 1.005 → 1.0
          final scale = 1.0 + 0.005 * math.sin(_breatheCtrl.value * 2 * math.pi);
          return Transform.scale(scale: scale, child: child);
        },
        child: imageWidget,
      );
    }

    // React gradient: from-slate-950/50 via-transparent to-slate-950/80
    final gradient = LinearGradient(
      begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
      end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
      colors: [
        AppColors.background.withValues(alpha: 0.5), // slate-950 at 50%
        Colors.transparent,
        AppColors.background.withValues(alpha: 0.8), // slate-950 at 80%
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        Container(decoration: BoxDecoration(gradient: gradient)),
      ],
    );
  }

  // ============================================
  // SHARED: Diagonal corner ribbon (1ST/2ND, WIN/LOSS/DRAW)
  // ============================================
  Widget _buildCornerRibbon({
    required String text,
    required Color color,
    required bool isTopRight,
    bool rotateText = false,
  }) {
    final ribbonChild = Container(
      width: 210,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Transform.translate(
        offset: const Offset(-8, 0), // nudge text left to optically center
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            height: 1.0,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: isTopRight ? 35 : null,
            bottom: isTopRight ? null : 35,
            right: isTopRight ? -42 : null,
            left: isTopRight ? null : -42,
            child: Transform(
              alignment: Alignment.center,
              // React: rotate(45deg) scaleY(-1) scaleX(-1) for opponent
              transform: rotateText
                  ? (Matrix4.rotationZ(math.pi / 4)..scale(-1.0, -1.0))
                  : Matrix4.rotationZ(math.pi / 4),
              child: ribbonChild,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SHARED: Game dots pill (Bo2/Bo3 progress)
  // ============================================
  Widget _buildGameDotsPill({bool invertColors = false}) {
    if (_games.isEmpty && _pendingResult == null) return const SizedBox.shrink();

    final dots = <Widget>[];
    for (final g in _games) {
      final r = g['result'] as String;
      Color dotColor;
      if (invertColors) {
        dotColor = r == 'win' ? AppColors.loss : r == 'loss' ? AppColors.win : AppColors.draw;
      } else {
        dotColor = r == 'win' ? AppColors.win : r == 'loss' ? AppColors.loss : AppColors.draw;
      }
      dots.add(Container(
        width: 12, height: 12,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
      ));
    }

    // Current game dot — AnimatedContainer for smooth color transitions
    if (_pendingResult != null) {
      final r = _pendingResult!;
      Color dotColor;
      if (invertColors) {
        dotColor = r == 'win' ? AppColors.loss : r == 'loss' ? AppColors.win : AppColors.draw;
      } else {
        dotColor = r == 'win' ? AppColors.win : r == 'loss' ? AppColors.loss : AppColors.draw;
      }
      dots.add(AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 12, height: 12,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
      ));
    } else {
      // In-progress dot
      dots.add(Container(
        width: 12, height: 12,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        ),
      ));
    }

    // Remaining dots
    final remaining = math.max(0, 2 - _games.length - (_pendingResult != null ? 1 : 0));
    for (var i = 0; i < remaining; i++) {
      dots.add(Container(
        width: 10, height: 10,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: AppRadius.fullBR,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: dots),
    );
  }

  // ============================================
  // SHARED: FAB button with entrance animation + press feedback
  // React: tracker-fab-enter 0.35s (scale 0.3→1, opacity 0→1)
  // React: active:scale-90 (scale down on press)
  // ============================================
  Widget _buildFab({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    Color? shadowColor,
    double iconSize = 22,
    bool animate = true,
    Key? key,
  }) {
    final button = TapScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        // FAB icon stays pure white (not textPrimary) for max contrast on
        // colored FAB backgrounds (amber, success, etc.) in both themes.
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );

    if (!animate) return button;

    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final scale = 0.3 + value * 0.7;
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: button,
    );
  }

  // ============================================
  // VS SCREEN — React: fullscreen with badge images
  // ============================================
  Widget _buildVsScreen() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Coin flip Y-rotation
    Widget vsBadge = Image.asset(
      'assets/badges/vs-badge.png',
      fit: BoxFit.contain,
    );

    if (_isFlipping) {
      vsBadge = AnimatedBuilder(
        animation: _coinFlipCtrl,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_coinFlipCtrl.value * math.pi * 4), // 2 full rotations
            child: child,
          );
        },
        child: vsBadge,
      );
    }

    return Container(
      color: AppColors.background, // bg-slate-950
      child: Stack(
        children: [
          // Two halves
          Column(
            children: [
              Expanded(child: _buildCardHalf(legend: _oppLegend!, isFlipped: true, isTop: true, breathe: true)),
              Expanded(child: _buildCardHalf(legend: _myLegend!, isFlipped: false, isTop: false, breathe: true)),
            ],
          ),

          // Diagonal ribbons (1ST/2ND) — opponent ribbon rotated for their POV.
          // Player-role tokens: 1st = blue, 2nd = orange (matches Stats-Screen).
          Positioned(
            top: 0, right: 0,
            child: IgnorePointer(
              child: _buildCornerRibbon(
                text: !_isFirst ? '1ST' : '2ND',
                color: !_isFirst ? AppColors.firstPlayer : AppColors.secondPlayer,
                isTopRight: true,
                rotateText: true,
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0,
            child: IgnorePointer(
              child: _buildCornerRibbon(
                text: _isFirst ? '1ST' : '2ND',
                color: _isFirst ? AppColors.firstPlayer : AppColors.secondPlayer,
                isTopRight: false,
              ),
            ),
          ),

          // VS Badge (centered, 80vw)
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isFirst = !_isFirst);
                },
                onLongPress: _doCoinFlip,
                child: SizedBox(
                  width: 80, height: 80,
                  child: OverflowBox(
                    maxWidth: screenWidth * 0.8,
                    maxHeight: screenWidth * 0.8,
                    child: AnimatedBuilder(
                      animation: _vsScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _vsReady ? _vsScale.value : 0,
                          child: child,
                        );
                      },
                      child: vsBadge,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // FABs (bottom-right, Row: back + battle)
          Positioned(
            bottom: 0,
            right: AppSpacing.md,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFab(
                    icon: Icons.arrow_back,
                    color: AppColors.surfaceLight, // secondary FAB fill
                    onTap: _goBack,
                    iconSize: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildFab(
                    icon: LucideIcons.swords,
                    color: AppColors.amber500,
                    onTap: _startBattle,
                    shadowColor: AppColors.amber600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BATTLE SCREEN — score tracking + result display (merged)
  // When _pendingResult is null: score buttons + round badge
  // When _pendingResult is set: colored scores + FINISH badge + ribbons
  // ============================================
  Widget _buildBattleScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasResult = _pendingResult != null;

    // Round badge for battle phase
    final roundBadge = _games.isEmpty
        ? 'assets/badges/round1-badge.png'
        : _games.length == 1
            ? 'assets/badges/round2-badge.png'
            : 'assets/badges/final-badge.png';

    // Result-phase colors & labels — uses established win/loss/draw tokens
    // (same as _buildGameDotsPill) instead of ad-hoc amber400 for draw.
    final result = _pendingResult ?? 'win';
    final myColor = result == 'win'
        ? AppColors.success
        : result == 'loss'
            ? AppColors.error
            : AppColors.draw;
    final oppColor = result == 'win'
        ? AppColors.error
        : result == 'loss'
            ? AppColors.success
            : AppColors.draw;
    final myLabel = result == 'win' ? 'WIN' : result == 'loss' ? 'LOSS' : 'DRAW';
    final oppLabel = result == 'win' ? 'LOSS' : result == 'loss' ? 'WIN' : 'DRAW';
    final canRematch = _games.length < 2;

    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // ── Two halves with card images ──
          Column(
            children: [
              // Opponent half (top)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCardHalf(legend: _oppLegend!, isFlipped: true, isTop: true, breathe: hasResult),
                    // Result: dark overlay + colored score
                    if (hasResult) ...[
                      Container(color: Colors.black.withValues(alpha: 0.3)),
                      Align(
                        alignment: const Alignment(0, -0.4),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('opp-score-$_pendingResult'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            final scale = 0.5 + value * 0.65; // 0.5 → 1.15 (elasticOut overshoots)
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.scale(scale: scale.clamp(0.5, 1.3), child: child),
                            );
                          },
                          child: Text(
                            '$_oppScore',
                            style: AppTextStyles.score.copyWith(
                              color: oppColor,
                              shadows: [Shadow(color: oppColor.withValues(alpha: 0.4), blurRadius: 20)],
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Battle: score buttons (rotated 180°)
                    if (!hasResult)
                      Positioned(
                        left: 0, right: 0, top: 0, bottom: 0,
                        child: Align(
                          alignment: const Alignment(0, -0.1),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationZ(math.pi),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _TapScaleButton(
                                  hitPadding: const EdgeInsets.all(20),
                                  onTap: () {
                                    if (_oppScore > 0) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _oppScore--);
                                    }
                                  },
                                  child: Container(
                                    width: 68, height: 68,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Icon(Icons.remove, color: AppColors.textPrimary, size: 30),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '$_oppScore',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.scoreLarge,
                                  ),
                                ),
                                _TapScaleButton(
                                  hitPadding: const EdgeInsets.all(20),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _oppScore++);
                                  },
                                  child: Container(
                                    width: 68, height: 68,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Icon(Icons.add, color: AppColors.textPrimary, size: 30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Your half (bottom)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCardHalf(legend: _myLegend!, isFlipped: false, isTop: false, breathe: hasResult),
                    // Result: dark overlay + colored score
                    if (hasResult) ...[
                      Container(color: Colors.black.withValues(alpha: 0.3)),
                      Align(
                        alignment: const Alignment(0, 0.4),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('my-score-$_pendingResult'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            final scale = 0.5 + value * 0.65;
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.scale(scale: scale.clamp(0.5, 1.3), child: child),
                            );
                          },
                          child: Text(
                            '$_myScore',
                            style: AppTextStyles.score.copyWith(
                              color: myColor,
                              shadows: [Shadow(color: myColor.withValues(alpha: 0.4), blurRadius: 20)],
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Battle: score buttons
                    if (!hasResult)
                      Positioned(
                        left: 0, right: 0, top: 0, bottom: 0,
                        child: Align(
                          alignment: const Alignment(0, 0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TapScaleButton(
                                hitPadding: const EdgeInsets.all(20),
                                onTap: () {
                                  if (_myScore > 0) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _myScore--);
                                  }
                                },
                                child: Container(
                                  width: 68, height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(Icons.remove, color: AppColors.textPrimary, size: 30),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '$_myScore',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.scoreLarge,
                                ),
                              ),
                              _TapScaleButton(
                                hitPadding: const EdgeInsets.all(20),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _myScore++);
                                },
                                child: Container(
                                  width: 68, height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(Icons.add, color: AppColors.textPrimary, size: 30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Result: WIN/LOSS/DRAW corner ribbons ──
          if (hasResult) ...[
            Positioned(
              key: const ValueKey('pos-ribbon-opp'),
              top: 0, right: 0,
              child: IgnorePointer(
                child: _buildCornerRibbon(text: oppLabel, color: oppColor, isTopRight: true, rotateText: true),
              ),
            ),
            Positioned(
              key: const ValueKey('pos-ribbon-my'),
              bottom: 0, left: 0,
              child: IgnorePointer(
                child: _buildCornerRibbon(text: myLabel, color: myColor, isTopRight: false),
              ),
            ),
          ],

          // ── Battle: round badge (settles at 0.3 opacity) ──
          if (!hasResult)
            Positioned.fill(
              key: const ValueKey('pos-round-badge'),
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _showRoundBadge
                        ? (_roundBadgeSettled ? 0.3 : 1.0)
                        : 0.3,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      scale: _showRoundBadge && !_roundBadgeSettled ? 1.0 : 0.9,
                      child: SizedBox(
                        width: screenWidth * 0.7,
                        child: Image.asset(roundBadge, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Battle: FIGHT badge (during announce) ──
          if (!hasResult && _showFightBadge)
            Positioned.fill(
              key: const ValueKey('pos-fight-badge'),
              child: IgnorePointer(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.scale(scale: 0.5 + value * 0.5, child: child),
                      );
                    },
                    child: SizedBox(
                      width: screenWidth * 0.85,
                      child: Image.asset('assets/badges/fight-badge.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),

          // ── Result: FINISH badge (tappable to cycle win/loss/draw) ──
          // React: vs-slam 0.5s (scale 0→1.3→1) then vs-idle 3s infinite (scale 1→1.025→1)
          if (hasResult)
            Positioned.fill(
              key: const ValueKey('pos-finish-badge'),
              child: Center(
                child: _TapScaleButton(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _pendingResult = _pendingResult == 'win'
                          ? 'loss'
                          : _pendingResult == 'loss'
                              ? 'draw'
                              : 'win';
                    });
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, slamValue, child) {
                      return AnimatedBuilder(
                        animation: _breatheCtrl,
                        builder: (context, child) {
                          // After slam completes, add idle breathing (scale 1→1.025→1)
                          final breatheScale = 1.0 + 0.025 * math.sin(_breatheCtrl.value * 2 * math.pi);
                          // Slam: scale 0→overshoot→1, elasticOut handles the overshoot
                          final slamScale = slamValue.clamp(0.0, 1.5);
                          return Opacity(
                            opacity: slamValue.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: slamScale * breatheScale,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 80, height: 80,
                      child: OverflowBox(
                        maxWidth: screenWidth * 0.8,
                        maxHeight: screenWidth * 0.8,
                        child: Image.asset('assets/badges/finish-badge.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Game dots (bottom, your perspective) ──
          if (_games.isNotEmpty)
            Positioned(
              key: const ValueKey('pos-dots-bottom'),
              bottom: 12, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Center(child: _buildGameDotsPill()),
              ),
            ),

          // ── Game dots (top, opponent perspective, rotated) ──
          if (_games.isNotEmpty)
            Positioned(
              key: const ValueKey('pos-dots-top'),
              top: 12, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationZ(math.pi),
                    child: _buildGameDotsPill(invertColors: true),
                  ),
                ),
              ),
            ),

          // ── Back FAB — slides right↔left depending on phase ──
          // Battle: left side. Result: slides to right (next to save).
          // Uses right-anchored positioning so AnimatedPositioned can smoothly animate.
          AnimatedPositioned(
            key: const ValueKey('pos-battle-back'),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            bottom: 0,
            right: hasResult ? 80 : screenWidth - AppSpacing.md - 56, // 56 = fab size
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: _buildFab(
                icon: Icons.arrow_back,
                color: AppColors.surfaceLight, // secondary FAB fill
                onTap: _goBack,
                iconSize: 20,
                animate: false,
              ),
            ),
          ),

          // ── Action FABs (bottom-right) ──
          Positioned(
            key: const ValueKey('pos-battle-action'),
            bottom: 0, right: AppSpacing.md,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: !hasResult
                // Battle: Finish button
                ? _buildFab(
                    icon: Icons.check,
                    color: AppColors.amber500,
                    onTap: _finishGame,
                    iconSize: 24,
                    shadowColor: AppColors.amber600,
                    key: const ValueKey('battle-finish'),
                  )
                // Result: Rematch + Save stacked
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canRematch) ...[
                        _buildFab(icon: LucideIcons.swords, color: AppColors.amber500, onTap: _handleRematch, key: const ValueKey('rematch')),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _buildFab(icon: Icons.check, color: AppColors.success, onTap: _saveAndReset, iconSize: 24, key: const ValueKey('save')),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Match context dropdown — matches React's custom dropdown with amber accents.
/// Button: slate-900/80 bg, amber-500/20 border, rounded-lg
/// Panel: slate-900 bg, amber-500/20 border, border-left accent on active item
class _MatchContextDropdown extends StatefulWidget {
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  const _MatchContextDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_MatchContextDropdown> createState() => _MatchContextDropdownState();
}

class _MatchContextDropdownState extends State<_MatchContextDropdown> {
  final _buttonKey = GlobalKey();
  OverlayEntry? _overlay;

  void _toggle() {
    if (_overlay != null) {
      _close();
      return;
    }
    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final top = offset.dy + size.height + 6;
    final centerX = offset.dx + size.width / 2;

    _overlay = OverlayEntry(
      builder: (context) {
        const panelWidth = 192.0; // w-48
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: top,
              left: centerX - panelWidth / 2,
              width: panelWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.amber500),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((ctx) {
                    final isActive = widget.value == ctx.$1;
                    return GestureDetector(
                      onTap: () {
                        widget.onChanged(ctx.$1);
                        _close();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.amber500
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isActive ? AppColors.amber500 : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          ctx.$2,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isActive ? AppColors.background : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _overlay != null;
    final label = widget.items.firstWhere((c) => c.$1 == widget.value).$2;

    return GestureDetector(
      key: _buttonKey,
      onTap: _toggle,
      child: SizedBox(
        height: 44, // Apple HIG touch-target minimum
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.amber500,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.background, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isOpen ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: AppColors.background,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Tap scale-down feedback — mirrors React's `active:scale-90`.
///
/// `hitPadding` extends the touch-target beyond the visible child via
/// `HitTestBehavior.opaque` — the transparent padding still counts as hit
/// area. Used for score +/- buttons so a finger landing slightly off-target
/// still registers (beta-tester feedback: hard to hit precisely).
class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets hitPadding;
  const _TapScaleButton({
    required this.child,
    required this.onTap,
    this.hitPadding = EdgeInsets.zero,
  });

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Padding(
        padding: widget.hitPadding,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: widget.child,
        ),
      ),
    );
  }
}
