import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';
import '../widgets/deck/deck_menu_sheet.dart';
import '../widgets/deck/deck_set_badges.dart';
import '../widgets/riftr_toast.dart';
// Conditional import: deck image export uses dart:io + path_provider on
// mobile. On web we swap in a stub that shows a "mobile only" toast.
import '../widgets/deck/deck_export_image.dart'
    if (dart.library.html) '../widgets/deck/deck_export_image_stub.dart';
import '../services/notification_inbox_service.dart';
import '../widgets/card_image.dart';
import '../widgets/card_preview.dart';
import '../widgets/card_selection_modal.dart';
import '../widgets/filter_chip_dropdown.dart';
import '../widgets/gold_header.dart';
import '../widgets/gold_line.dart';
import '../widgets/domain_filter_row.dart';
import '../widgets/riftr_search_bar.dart';
import '../widgets/legend_filter_dropdown.dart';
import '../widgets/section_divider.dart';
import '../widgets/tap_scale.dart';
import '../theme/app_theme.dart';
import '../theme/app_components.dart';
import '../services/firestore_deck_service.dart';
import '../services/demo_service.dart';
import '../services/match_service.dart';
import '../services/card_service.dart';
import '../services/meta_deck_service.dart';
import '../services/firestore_collection_service.dart';
import '../services/public_deck_service.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../models/meta_deck_model.dart';
import '../models/public_deck_model.dart';
import '../widgets/energy_curve_chart.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/riftr_drag_handle.dart';

class DecksScreen extends StatefulWidget {
  /// Sub-tab badge: new meta decks imported since last viewed.
  static bool hasUnreadMeta = false;

  final ValueChanged<bool>? onFullscreenChanged;
  final void Function(String authorId, String authorName)? onNavigateToAuthor;
  final void Function(String deckName, Map<String, int> missingCards)? onStartDeckShopping;
  final VoidCallback? onDeckViewerClosed;
  const DecksScreen({super.key, this.onFullscreenChanged, this.onNavigateToAuthor, this.onStartDeckShopping, this.onDeckViewerClosed});

  @override
  State<DecksScreen> createState() => DecksScreenState();
}

class DecksScreenState extends State<DecksScreen> {
  final _service = FirestoreDeckService.instance;
  final _demo = DemoService.instance;

  /// Track a deck view — only once per user per deck (persisted across sessions).
  /// Per-user SharedPrefs key to prevent view-tracking bleeding across accounts.
  Future<void> _trackView(String deckId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = AuthService.instance.uid;
    final key = uid == null ? 'viewedDecks' : 'viewedDecks_$uid';
    final viewed = prefs.getStringList(key) ?? [];
    if (viewed.contains(deckId)) return;
    viewed.add(deckId);
    await prefs.setStringList(key, viewed);
    if (type == 'meta') {
      MetaDeckService.instance.incrementViewCount(deckId);
    } else {
      PublicDeckService.instance.incrementViewCount(deckId);
    }
  }

  /// Switch to the Public Decks sub-tab
  void showPublicDecks() {
    setState(() { _tabIndex = 2; });
  }

  /// Open a public deck in the viewer (called from other screens)
  void viewPublicDeck(PublicDeckData deck) {
    setState(() { _viewingPublicDeck = deck; });
    widget.onFullscreenChanged?.call(true);
  }

  // View state
  String? _editingDeckId;
  String? _lastEditedDeckId;
  bool _startInEditMode = false;
  MetaDeck? _viewingMetaDeck;
  PublicDeckData? _viewingPublicDeck;
  final _newNameController = TextEditingController();
  final _newDescController = TextEditingController();

  // Overview state
  int _tabIndex = 0; // 0 = My, 1 = Meta, 2 = Public, 3 = Following
  final _tabScrollController = ScrollController();
  final _filterScrollController = ScrollController();
  String _deckSearch = '';
  final _searchController = TextEditingController();
  final Set<String> _domainFilters = {};
  // Single source of truth for sort across all 4 sub-tabs.
  // Possible values: 'newest' | 'oldest' | 'popular' | 'trending'.
  // Per-tab availability:
  //   My Decks → newest, oldest
  //   Meta / Public / Following → all four
  // On tab-switch, value is reset to 'newest' if not available in the new
  // tab (handled in _buildTabPill onTap).
  String _publicSort = 'newest';
  final Set<String> _legendFilters = {}; // multi-select legend filter

  // Shared filters (single-select)
  String? _setFilter;
  String? _eventFilter;
  List<MetaDeck> _metaDecks = [];
  bool _metaLoading = true;

  // Per-sub-tab client-side pagination (25 initial, +25 per "Load more" tap).
  // Counters stay independent across tabs — scrolling through My Decks
  // doesn't affect Meta's paging. All counters reset on filter/sort change
  // via _resetPagination() so the user always starts at the top of a fresh
  // result set.
  int _myDecksDisplayCount = 25;
  int _metaDecksDisplayCount = 25;
  int _publicDecksDisplayCount = 25;
  int _followingDecksDisplayCount = 25;

  void _resetPagination() {
    _myDecksDisplayCount = 25;
    _metaDecksDisplayCount = 25;
    _publicDecksDisplayCount = 25;
    _followingDecksDisplayCount = 25;
  }

  bool get _isDemo => _demo.isActive;

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
    _demo.addListener(_refresh);
    MatchService.instance.addListener(_refresh);
    PublicDeckService.instance.addListener(_refresh);
    FollowService.instance.addListener(_refresh);
    MarketService.instance.addListener(_refresh);
    MetaDeckService.instance.addListener(_onMetaDecksChanged);
    _loadMetaDecks();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onMetaDecksChanged() {
    final firestore = MetaDeckService.instance.decks;
    if (firestore.isNotEmpty) {
      _metaDecks = firestore;
      _metaLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadMetaDecks() async {
    _metaDecks = await MetaDeckService.loadDecks();
    if (mounted) setState(() => _metaLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    _newDescController.dispose();
    _tabScrollController.dispose();
    _filterScrollController.dispose();
    _service.removeListener(_refresh);
    _demo.removeListener(_refresh);
    MatchService.instance.removeListener(_refresh);
    MetaDeckService.instance.removeListener(_onMetaDecksChanged);
    PublicDeckService.instance.removeListener(_refresh);
    FollowService.instance.removeListener(_refresh);
    MarketService.instance.removeListener(_refresh);
    _sortOverlay?.remove();
    _sortOverlay = null;
    super.dispose();
  }

  void _resetScrollPositions() {
    if (_tabScrollController.hasClients) _tabScrollController.jumpTo(0);
    if (_filterScrollController.hasClients) _filterScrollController.jumpTo(0);
  }

  /// Called from main.dart when navigating back to Decks tab
  void resetScroll() => _resetScrollPositions();

  /// Whether the screen is in a fullscreen overlay (deck editor, meta deck viewer, etc.)
  bool get isFullscreen => _editingDeckId != null || _viewingMetaDeck != null || _viewingPublicDeck != null;

  DeckData? _getDeck(String id) {
    if (_isDemo) return _demo.getDeck(id);
    return _service.getDeck(id);
  }

  List<DeckData> get _decks => _isDemo ? _demo.decks : _service.decks;

  /// Autocomplete source — up to 5 deck names matching the query
  /// (case-insensitive, starts-with ranked before contains).
  List<String> _suggestDeckNames(String q) {
    if (q.trim().isEmpty) return const [];
    final lower = q.trim().toLowerCase();
    final starts = <String>[];
    final contains = <String>[];
    final seen = <String>{};
    for (final deck in _decks) {
      final name = deck.name;
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

  @override
  Widget build(BuildContext context) {
    // Viewer overlays — rendered on top of the overview so scroll position is preserved
    if (_viewingPublicDeck != null) {
      final pd = _viewingPublicDeck!;
      return Stack(children: [
        Offstage(child: _buildOverview()),
        _MetaDeckViewer(
        metaDeck: pd.toMetaDeck(),
        likeCollection: 'publicDecks',
        onBack: () { setState(() => _viewingPublicDeck = null); widget.onFullscreenChanged?.call(false); widget.onDeckViewerClosed?.call(); },
        onCopy: () {
          if (_isDemo) {
            _demo.incrementViewCount(pd.name);
            _demo.createDeck(pd.toDeckData().withResolvedKeys().copyWith(name: '${pd.name} (Copy)'));
          } else {
            if (pd.id != null) PublicDeckService.instance.incrementViewCount(pd.id!);
            PublicDeckService.instance.copyToMyDecks(pd);
          }
          RiftrToast.success(context, 'Deck copied!');
        },
        onNavigateToAuthor: widget.onNavigateToAuthor,
        onStartDeckShopping: widget.onStartDeckShopping,
      ),
      ]);
    }
    if (_viewingMetaDeck != null) {
      return Stack(children: [
        Offstage(child: _buildOverview()),
        _MetaDeckViewer(
          metaDeck: _viewingMetaDeck!,
          onBack: () { setState(() => _viewingMetaDeck = null); widget.onFullscreenChanged?.call(false); },
          onCopy: () => _copyMetaDeck(_viewingMetaDeck!),
        onNavigateToAuthor: widget.onNavigateToAuthor,
        onStartDeckShopping: widget.onStartDeckShopping,
      ),
      ]);
    }
    if (_editingDeckId != null) {
      final deck = _getDeck(_editingDeckId!);
      if (deck == null) { _editingDeckId = null; return _buildOverview(); }
      return Stack(children: [
        Offstage(child: _buildOverview()),
        _DeckEditor(deck: deck, startInEditMode: _startInEditMode, onBack: () {
          final editedId = _editingDeckId;
          setState(() { _lastEditedDeckId = editedId; _editingDeckId = null; _startInEditMode = false; });
          widget.onFullscreenChanged?.call(false);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _lastEditedDeckId == editedId) setState(() => _lastEditedDeckId = null);
          });
        }, onNavigateToAuthor: widget.onNavigateToAuthor, onStartDeckShopping: widget.onStartDeckShopping),
      ]);
    }
    return _buildOverview();
  }

  Future<void> _copyMetaDeck(MetaDeck meta) async {
    final deckData = meta.toDeckData().withResolvedKeys().copyWith(name: '${meta.name} (Copy)');
    if (_isDemo) {
      _demo.createDeck(deckData);
    } else {
      final id = await _service.createDeck(name: deckData.name);
      await _service.updateDeck(deckData.copyWith(id: id));
    }
    if (mounted) RiftrToast.success(context, 'Deck copied!');
  }

  // ============================================
  // OVERVIEW
  // ============================================
  Widget _buildOverview() {

    return Column(
      children: [
        const GoldOrnamentHeader(title: 'FORGE YOUR STRATEGY'),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: RiftrSearchBar(
            controller: _searchController,
            hintText: 'Search decks...',
            onChanged: (v) => setState(() {
              _deckSearch = v;
              _resetPagination();
            }),
            onSuggest: _suggestDeckNames,
            onSuggestionTap: (v) => setState(() {
              _deckSearch = v;
              _resetPagination();
            }),
          ),
        ),

        // Tab pills row
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: SingleChildScrollView(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
            children: [
              _buildTabPill('My Decks', 0),
              const SizedBox(width: 6),
              _buildTabPill('Meta', 1, showDot: DecksScreen.hasUnreadMeta),
              const SizedBox(width: 6),
              _buildTabPill('Public', 2),
              if (FollowService.instance.myFollowing.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildTabPill('Following', 3),
              ],
              // Sort dropdown — visible on every sub-tab. Available options
              // depend on `_tabIndex` (My Decks: newest/oldest only; others
              // get all four). _publicSort is reset to 'newest' on tab-
              // switch when the active option is unavailable in the new tab.
              const SizedBox(width: 6),
              _buildSortButton(),
            ],
          )),
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
              } else {
                _domainFilters.add(d);
              }
              _resetPagination();
            }),
          ),
        ),

        const GoldLine(),

        // Legend dropdown
        _buildLegendDropdown(),

        // Set/Event filters (Meta, Public, Following)
        if (_tabIndex >= 1) _buildSetEventFilterRow(),

        // Content
        Expanded(child: switch (_tabIndex) {
          0 => _buildMyDecks(),
          1 => _buildMetaDecks(),
          2 => _buildPublicDecks(),
          3 => _buildFollowingDecks(),
          _ => _buildMyDecks(),
        }),
      ],
    );
  }

  final _sortButtonKey = GlobalKey();
  OverlayEntry? _sortOverlay;

  void _closeSortOverlay() {
    _sortOverlay?.remove();
    _sortOverlay = null;
    if (mounted) setState(() {});
  }

  /// Sort options available in the current sub-tab. My Decks supports only
  /// newest/oldest (no `viewCount` / `trendingScore` data on `DeckData`);
  /// Meta/Public/Following get all four. Single source of truth used by
  /// both `_buildSortButton` and `_toggleSortOverlay` so the dropdown
  /// always matches the pill's available state.
  List<({String value, IconData icon, String label})> _sortOptionsForTab() {
    if (_tabIndex == 0) {
      return const [
        (value: 'newest', icon: Icons.schedule, label: 'Newest'),
        (value: 'oldest', icon: Icons.history, label: 'Oldest'),
      ];
    }
    return const [
      (value: 'newest', icon: Icons.schedule, label: 'Newest'),
      (value: 'oldest', icon: Icons.history, label: 'Oldest'),
      (value: 'popular', icon: Icons.file_download_outlined, label: 'Popular'),
      (value: 'trending', icon: Icons.local_fire_department, label: 'Trending'),
    ];
  }

  void _toggleSortOverlay() {
    if (_sortOverlay != null) { _closeSortOverlay(); return; }
    final renderBox = _sortButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final top = offset.dy + renderBox.size.height + 4;

    final options = _sortOptionsForTab();

    _sortOverlay = OverlayEntry(builder: (context) => Stack(children: [
      // Dismiss scrim
      Positioned.fill(child: GestureDetector(onTap: _closeSortOverlay, child: Container(color: Colors.transparent))),
      // Dropdown panel
      Positioned(top: top, left: 0, right: 0, child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: options.map((o) {
          final isActive = o.value == _publicSort;
          return GestureDetector(
            onTap: () {
              setState(() {
                _publicSort = o.value;
                _resetPagination();
              });
              _closeSortOverlay();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isActive ? AppColors.amber500 : Colors.transparent,
                border: Border(left: BorderSide(color: isActive ? AppColors.amber500 : Colors.transparent, width: 2)),
              ),
              child: Row(children: [
                Icon(o.icon, size: 16, color: isActive ? AppColors.background : AppColors.textMuted),
                const SizedBox(width: 10),
                Text(o.label, style: AppTextStyles.bodyLarge.copyWith(color: isActive ? AppColors.background : AppColors.textMuted, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
              ]),
            ),
          );
        }).toList()),
      )),
    ]));
    Overlay.of(context).insert(_sortOverlay!);
    setState(() {});
  }

  Widget _buildSortButton() {
    final options = _sortOptionsForTab();
    final current = options.firstWhere(
      (o) => o.value == _publicSort,
      orElse: () => options.first,
    );
    // Highlight when the user picked something other than the default.
    // 'newest' is the rest-state across all tabs.
    final highlighted = _publicSort != 'newest';
    final isOpen = _sortOverlay != null;

    return _SortPill(
      key: _sortButtonKey,
      label: current.label,
      icon: current.icon,
      trailingIcon: isOpen ? Icons.expand_less : Icons.expand_more,
      isActive: highlighted || isOpen,
      onTap: _toggleSortOverlay,
    );
  }

  Widget _buildTabPill(String label, int index, {bool showDot = false}) {
    final active = _tabIndex == index;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RiftrPill(
          label: label,
          isActive: active,
          onTap: () {
            setState(() {
              _tabIndex = index;
              // Reset sort when active option isn't supported in the new
              // tab (e.g. switching from Meta with 'trending' active into
              // My Decks which only supports newest/oldest).
              final available = _sortOptionsForTab().map((o) => o.value).toSet();
              if (!available.contains(_publicSort)) _publicSort = 'newest';
            });
            if (index == 1) {
              // Meta dot disappears when user opens Meta sub-tab
              NotificationInboxService.instance.markAllSeenByType('meta_decks');
            }
            _resetScrollPositions();
          },
        ),
        if (showDot && !active)
          Positioned(
            top: -2, right: -2,
            child: Container(width: 8, height: 8, decoration: BoxDecoration(
              color: AppColors.amber400, shape: BoxShape.circle,
            )),
          ),
      ],
    );
  }

  String _shortName(String name) =>
      name.contains(',') ? name.split(',')[0].trim() : name;

  Widget _buildLegendDropdown() {
    // Build legend options with images + counts for current tab
    final legendCounts = <String, ({String shortName, String? imageUrl, int count})>{};

    if (_tabIndex == 1) {
      // Meta decks — use MetaDeckService legend filters
      for (final lf in MetaDeckService.getLegendFilters()) {
        legendCounts[lf.shortName] = (
          shortName: lf.shortName,
          imageUrl: lf.imageUrl,
          count: lf.count,
        );
      }
    } else if (_tabIndex == 2 || _tabIndex == 3) {
      // Public / Following — extract from public decks
      final allPublic = _isDemo ? _demo.publicDecks : PublicDeckService.instance.decks;
      final publicDecks = _tabIndex == 3
          ? allPublic.where((d) => FollowService.instance.myFollowing.contains(d.authorId)).toList()
          : allPublic;
      for (final deck in publicDecks) {
        if (deck.legendName == null) continue;
        final short = _shortName(deck.legendName!);
        final existing = legendCounts[short];
        legendCounts[short] = (
          shortName: short,
          imageUrl: existing?.imageUrl ?? deck.legendImageUrl,
          count: (existing?.count ?? 0) + 1,
        );
      }
    } else {
      // My Decks — extract from user decks
      for (final deck in _decks) {
        if (deck.legendName == null) continue;
        final short = _shortName(deck.legendName!);
        final existing = legendCounts[short];
        legendCounts[short] = (
          shortName: short,
          imageUrl: existing?.imageUrl ?? deck.legendImageUrl,
          count: (existing?.count ?? 0) + 1,
        );
      }
    }

    final legendOptions = legendCounts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Hide only when there are zero legends in scope. Previously this used
    // `<= 1` to skip useless 1-option dropdowns, but that broke layout
    // consistency between sub-tabs (Following often has ≤1 unique legend
    // and lost the filter slot entirely while Meta/Public/My-Decks kept
    // theirs). Showing a 1-option dropdown is harmless and keeps the
    // filter row identical across all 4 sub-tabs.
    if (legendOptions.isEmpty) return const SizedBox.shrink();

    return Padding(
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
          _resetPagination();
        }),
        onClear: () => setState(() {
          _legendFilters.clear();
          _resetPagination();
        }),
      ),
    );
  }

  Widget _buildSetEventFilterRow() {
    // Collect available sets based on active tab
    final List<String> sets;
    if (_tabIndex == 1) {
      sets = _metaDecks.expand((d) => d.sets).toSet().toList()..sort();
    } else {
      // Public / Following — derive sets from card IDs.
      // Following narrows to followed authors (mirrors _buildLegendDropdown
      // and _filteredPublicDecks(followingOnly: true)) so users don't see
      // set-filter chips for sets that aren't actually present in the decks
      // they can browse — selecting one would just empty the list.
      final lookup = CardService.getLookup();
      final allPublic = _isDemo ? _demo.publicDecks : PublicDeckService.instance.decks;
      final scopedDecks = _tabIndex == 3
          ? allPublic
              .where((d) => FollowService.instance.myFollowing.contains(d.authorId))
              .toList()
          : allPublic;
      final setNames = <String>{};
      for (final deck in scopedDecks) {
        for (final id in deck.mainDeck.keys) {
          final c = lookup[id];
          if (c?.setId != null) setNames.add(c!.setId!);
        }
      }
      sets = setNames.toList()..sort();
    }

    // Events only relevant for meta tab
    final eventFilters = _tabIndex == 1 ? MetaDeckService.getEventFilters() : <EventFilter>[];
    final events = eventFilters.map((e) => e.shortName).toList();
    // Map shortName → source for filtering
    final eventSourceMap = {for (final e in eventFilters) e.shortName: e.source};
    final eventDisplayFilter = _eventFilter != null
        ? eventFilters.where((e) => e.source == _eventFilter).map((e) => e.shortName).firstOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      child: SingleChildScrollView(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          FilterChipDropdown(
            label: _setFilter ?? 'Set',
            defaultLabel: 'Set',
            isActive: _setFilter != null,
            activeValue: _setFilter,
            items: sets,
            onSelected: (value) => setState(() {
              _setFilter = _setFilter == value ? null : value;
              _resetPagination();
            }),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(width: 6),
            FilterChipDropdown(
              label: eventDisplayFilter ?? 'Tournament',
              defaultLabel: 'Tournament',
              isActive: _eventFilter != null,
              activeValue: eventDisplayFilter,
              items: events,
              onSelected: (value) {
                final source = eventSourceMap[value];
                setState(() {
                  _eventFilter = _eventFilter == source ? null : source;
                  _resetPagination();
                });
              },
            ),
          ],
        ]),
      ),
    );
  }


  bool get _hasActiveFilters => _deckSearch.isNotEmpty || _domainFilters.isNotEmpty || _legendFilters.isNotEmpty || _setFilter != null || _eventFilter != null;

  void _clearAllFilters() {
    setState(() {
      _deckSearch = '';
      _searchController.clear();
      _domainFilters.clear();
      _legendFilters.clear();
      _setFilter = null;
      _eventFilter = null;
      _resetPagination();
    });
  }

  // ---- My Decks ----
  /// Shared "$count DECKS" header used by all 4 sub-tabs (My / Meta /
  /// Public / Following). Icon varies per tab so callers pass it in. Removes
  /// the My-Decks "OF Y" total-count format and the inline Clear pill that
  /// existed only in My Decks — cross-filter clearing now happens via the
  /// individual filter components (LegendFilterDropdown's X, Domain-Pill
  /// toggle) and the Empty-State "Clear Filters" CTA, identical across tabs.
  Widget _buildResultsHeader(IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SectionDivider(icon: icon, label: '$count DECKS'),
    );
  }

  Widget _buildMyDecks() {
    var decks = _decks;

    if (_deckSearch.isNotEmpty) {
      final query = _deckSearch.toLowerCase();
      decks = decks.where((d) => d.name.toLowerCase().contains(query) || (d.legendName?.toLowerCase().contains(query) ?? false)).toList();
    }
    if (_domainFilters.isNotEmpty) {
      decks = decks.where((d) => _domainFilters.length == 2
          ? _domainFilters.every((f) => d.domains.contains(f))
          : d.domains.any((domain) => _domainFilters.contains(domain))).toList();
    }
    if (_legendFilters.isNotEmpty) {
      decks = decks.where((d) {
        if (d.legendName == null) return false;
        final short = _shortName(d.legendName!);
        return _legendFilters.contains(short);
      }).toList();
    }

    decks = List.of(decks);
    decks.sort((a, b) {
      final dateA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final dateB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      // My Decks supports only newest/oldest (no viewCount/trendingScore
      // on DeckData). _publicSort is reset to 'newest' when entering this
      // tab from one with popular/trending active.
      return _publicSort == 'oldest'
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return Stack(children: [
      if (decks.isEmpty)
        Positioned.fill(
          child: Column(
            children: [
              const Spacer(flex: 2),
              RiftrEmptyState(
                icon: Icons.layers,
                title: _hasActiveFilters ? 'No Matching Decks' : 'No Decks Yet',
                subtitle: _hasActiveFilters
                    ? 'Try clearing filters or create a new deck'
                    : 'Tap + to build your first deck',
                buttonLabel: _hasActiveFilters ? 'Clear Filters' : null,
                buttonIcon: _hasActiveFilters ? Icons.filter_list_off : null,
                onButtonPressed: _hasActiveFilters ? _clearAllFilters : null,
              ),
              const Spacer(flex: 3),
            ],
          ),
        )
      else
        Column(children: [
          _buildResultsHeader(Icons.layers, decks.length),
          Expanded(child: Builder(builder: (_) {
            final displayedDecks = decks.take(_myDecksDisplayCount).toList();
            final hasMore = decks.length > _myDecksDisplayCount;
            return ListView.builder(
              key: const PageStorageKey('myDecks'),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
              itemCount: displayedDecks.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (hasMore && index == displayedDecks.length) {
                  final remaining = decks.length - _myDecksDisplayCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: RiftrButton(
                      label: 'Load more ($remaining remaining)',
                      style: RiftrButtonStyle.secondary,
                      icon: Icons.expand_more,
                      onPressed: () => setState(() => _myDecksDisplayCount += 25),
                    ),
                  );
                }
                return _buildDeckCard(displayedDecks[index]);
              },
            );
          })),
        ]),
      // FAB — open create view (pulses when no decks)
      if (_tabIndex == 0) Positioned(right: AppSpacing.lg, bottom: 68 + MediaQuery.of(context).viewPadding.bottom,
        child: _PulsingFab(
          pulse: decks.isEmpty && !_hasActiveFilters,
          onTap: _showNewDeckSheet,
        ),
      ),
    ]);
  }

  // ---- New Deck Sheet ----
  void _showNewDeckSheet() {
    _newNameController.clear();
    _newDescController.clear();
    final hasName = ValueNotifier<bool>(false);
    _newNameController.addListener(() {
      hasName.value = _newNameController.text.trim().isNotEmpty;
    });
    showRiftrSheet(
      context: context,
      builder: (ctx) => _NewDeckSheetContent(
        nameController: _newNameController,
        descController: _newDescController,
        hasName: hasName,
        onCreate: () async {
          final name = _newNameController.text.trim();
          final desc = _newDescController.text.trim();
          Navigator.of(ctx).pop();
          final String id;
          if (_isDemo) {
            id = _demo.createDeck(DeckData(name: name, description: desc.isNotEmpty ? desc : null));
          } else {
            id = await _service.createDeck(name: name);
            if (desc.isNotEmpty) {
              final created = _service.getDeck(id);
              if (created != null) _service.updateDeck(created.copyWith(description: desc));
            }
          }
          setState(() { _editingDeckId = id; _startInEditMode = true; });
          widget.onFullscreenChanged?.call(true);
        },
      ),
    ).then((_) {
      hasName.dispose();
    });
  }

  // ---- Meta Decks ----
  /// Apply screen-level sort to a meta-deck list.
  /// - newest/oldest → `createdAt`, tiebreaker `placementRank`
  /// - popular     → `viewCount` DESC (Firestore-tracked)
  /// - trending    → "Recent Tournament Performers": decks with `createdAt`
  ///   in the last 7 days come first; within each cohort sorted by
  ///   `placementRank` ASC (best placement first), with newer-first as
  ///   tiebreaker. Doesn't require copyTimestamps (which MetaDeck doesn't
  ///   carry) — uses only existing fields. Semantic match for tournament-
  ///   curated content: "trending" = "what just won".
  List<MetaDeck> _sortMetaDecks(List<MetaDeck> decks) {
    final list = List<MetaDeck>.from(decks);
    switch (_publicSort) {
      case 'oldest':
        list.sort((a, b) {
          final dA = a.createdAt ?? DateTime(2000);
          final dB = b.createdAt ?? DateTime(2000);
          final cmp = dA.compareTo(dB);
          return cmp != 0 ? cmp : a.placementRank.compareTo(b.placementRank);
        });
      case 'popular':
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      case 'trending':
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        list.sort((a, b) {
          final aRecent = (a.createdAt ?? DateTime(2000)).isAfter(cutoff);
          final bRecent = (b.createdAt ?? DateTime(2000)).isAfter(cutoff);
          if (aRecent != bRecent) return aRecent ? -1 : 1;
          final placeCmp = a.placementRank.compareTo(b.placementRank);
          if (placeCmp != 0) return placeCmp;
          final dA = a.createdAt ?? DateTime(2000);
          final dB = b.createdAt ?? DateTime(2000);
          return dB.compareTo(dA);
        });
      case 'newest':
      default:
        list.sort((a, b) {
          final dA = a.createdAt ?? DateTime(2000);
          final dB = b.createdAt ?? DateTime(2000);
          final cmp = dB.compareTo(dA);
          return cmp != 0 ? cmp : a.placementRank.compareTo(b.placementRank);
        });
    }
    return list;
  }

  Widget _buildMetaDecks() {
    if (_metaLoading) return Center(child: CircularProgressIndicator(color: AppColors.amber400));

    // Service-level newestFirst is irrelevant — we re-sort below per
    // _publicSort. Pass true to keep the old behavior for in-service
    // tiebreakers; the final order comes from _sortMetaDecks.
    final filtered = MetaDeckService.filter(
      decks: _metaDecks,
      legends: _legendFilters,
      events: _eventFilter != null ? {_eventFilter!} : {},
      domains: _domainFilters,
      search: _deckSearch,
      newestFirst: true,
    );

    // Set filter (single-select), then screen-level sort.
    final afterSetFilter = _setFilter == null
        ? filtered
        : filtered.where((d) => d.sets.contains(_setFilter)).toList();
    final sorted = _sortMetaDecks(afterSetFilter);

    return Column(children: [
      _buildResultsHeader(Icons.emoji_events, sorted.length),
      Expanded(
        child: sorted.isEmpty
            ? RiftrEmptyState(
                icon: Icons.emoji_events,
                title: 'No Matching Meta Decks',
                subtitle: _hasActiveFilters
                    ? 'Try adjusting your filters'
                    : 'Meta decks will appear here after tournaments',
                buttonLabel: _hasActiveFilters ? 'Clear Filters' : null,
                buttonIcon: _hasActiveFilters ? Icons.filter_list_off : null,
                onButtonPressed: _hasActiveFilters ? _clearAllFilters : null,
              )
            : Builder(builder: (_) {
                final displayed = sorted.take(_metaDecksDisplayCount).toList();
                final hasMore = sorted.length > _metaDecksDisplayCount;
                return ListView.builder(
                  key: const PageStorageKey('metaDecks'),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
                  itemCount: displayed.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (hasMore && index == displayed.length) {
                      final remaining = sorted.length - _metaDecksDisplayCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: RiftrButton(
                          label: 'Load more ($remaining remaining)',
                          style: RiftrButtonStyle.secondary,
                          icon: Icons.expand_more,
                          onPressed: () => setState(() => _metaDecksDisplayCount += 25),
                        ),
                      );
                    }
                    return _buildMetaDeckCard(displayed[index]);
                  },
                );
              }),
      ),
    ]);
  }

  // ---- Public Decks ----
  List<PublicDeckData> _filteredPublicDecks({bool followingOnly = false}) {
    var decks = _isDemo ? _demo.publicDecks : PublicDeckService.instance.decks;

    // Filter to following only
    if (followingOnly) {
      final following = FollowService.instance.myFollowing;
      decks = decks.where((d) => following.contains(d.authorId)).toList();
    }

    // Search
    if (_deckSearch.isNotEmpty) {
      final q = _deckSearch.toLowerCase();
      decks = decks.where((d) =>
          d.name.toLowerCase().contains(q) ||
          (d.description?.toLowerCase().contains(q) ?? false) ||
          (d.legendName?.toLowerCase().contains(q) ?? false) ||
          d.authorName.toLowerCase().contains(q)).toList();
    }

    // Domain filter
    if (_domainFilters.isNotEmpty) {
      decks = decks.where((d) => _domainFilters.every((f) => d.domains.contains(f))).toList();
    }

    // Legend filter
    if (_legendFilters.isNotEmpty) {
      decks = decks.where((d) {
        if (d.legendName == null) return false;
        final short = _shortName(d.legendName!);
        return _legendFilters.contains(short);
      }).toList();
    }

    // Set filter (single-select) — derive sets from card IDs
    if (_setFilter != null) {
      final lookup = CardService.getLookup();
      decks = decks.where((d) {
        for (final id in d.mainDeck.keys) {
          final c = lookup[id];
          if (c?.setId == _setFilter) return true;
        }
        for (final id in d.sideboard.keys) {
          final c = lookup[id];
          if (c?.setId == _setFilter) return true;
        }
        return false;
      }).toList();
    }

    // Sort. Service preorders by publishedAt DESC, but we re-sort
    // explicitly so behavior is predictable and 'oldest' is supported.
    decks = List.from(decks);
    switch (_publicSort) {
      case 'oldest':
        decks.sort((a, b) {
          final dA = a.publishedAt ?? DateTime(2000);
          final dB = b.publishedAt ?? DateTime(2000);
          return dA.compareTo(dB);
        });
      case 'popular':
        decks.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      case 'trending':
        decks.sort((a, b) => b.trendingScore.compareTo(a.trendingScore));
      case 'newest':
      default:
        decks.sort((a, b) {
          final dA = a.publishedAt ?? DateTime(2000);
          final dB = b.publishedAt ?? DateTime(2000);
          return dB.compareTo(dA);
        });
    }

    return decks;
  }

  Widget _buildPublicDecks() {
    final decks = _filteredPublicDecks();
    return _buildPublicDeckList(
      decks,
      emptyLabel: 'No public decks yet',
      storageKey: 'publicDecks',
      displayCount: _publicDecksDisplayCount,
      onLoadMore: () => setState(() => _publicDecksDisplayCount += 25),
    );
  }

  Widget _buildFollowingDecks() {
    final decks = _filteredPublicDecks(followingOnly: true);
    return _buildPublicDeckList(
      decks,
      emptyLabel: 'No decks from followed players',
      storageKey: 'followingDecks',
      displayCount: _followingDecksDisplayCount,
      onLoadMore: () => setState(() => _followingDecksDisplayCount += 25),
    );
  }

  Widget _buildPublicDeckList(
    List<PublicDeckData> decks, {
    required String emptyLabel,
    required String storageKey,
    required int displayCount,
    required VoidCallback onLoadMore,
  }) {
    final displayed = decks.take(displayCount).toList();
    final hasMore = decks.length > displayCount;
    return Column(children: [
      _buildResultsHeader(Icons.public, decks.length),
      Expanded(
        child: decks.isEmpty
            ? RiftrEmptyState(
                icon: Icons.explore,
                title: emptyLabel,
                subtitle: 'Be the first to publish a deck!',
                buttonLabel: 'Discover Decks',
                buttonIcon: Icons.explore,
                onButtonPressed: () => setState(() => _tabIndex = 2),
              )
            : ListView.builder(
                key: PageStorageKey(storageKey),
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
                itemCount: displayed.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (hasMore && index == displayed.length) {
                    final remaining = decks.length - displayCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: RiftrButton(
                        label: 'Load more ($remaining remaining)',
                        style: RiftrButtonStyle.secondary,
                        icon: Icons.expand_more,
                        onPressed: onLoadMore,
                      ),
                    );
                  }
                  return _buildPublicDeckCard(displayed[index]);
                },
              ),
      ),
    ]);
  }

  Widget _buildPublicDeckCard(PublicDeckData deck) {
    final uid = AuthService.instance.uid;
    final isOwn = uid != null && deck.authorId == uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RiftrCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () {
        setState(() => _viewingPublicDeck = deck);
        widget.onFullscreenChanged?.call(true);
        if (!_isDemo && deck.id != null) _trackView(deck.id!, 'public');
      },
      child: Builder(builder: (_) {
        // Calculate deck price (Legend + Battlefields + Main + Side)
        final _lookup = CardService.getLookup();
        double _deckPrice = 0;
        bool _hasPrice = false;
        void _addPrice(String key, int qty) {
          final c = _lookup[key];
          if (c != null) {
            final price = MarketService.instance.getPrice(c.id);
            if (price != null && price.standardPrice > 0) {
              _deckPrice += price.standardPrice * qty;
              _hasPrice = true;
            }
          }
        }
        if (deck.legendId != null && deck.legendId!.isNotEmpty) _addPrice(deck.legendId!, 1);
        for (final bf in deck.battlefields) _addPrice(bf.id, 1);
        for (final entry in deck.mainDeck.entries) _addPrice(entry.key, entry.value);
        for (final entry in deck.sideboard.entries) _addPrice(entry.key, entry.value);
        return Stack(children: [
        Row(children: [
          // Legend image
          ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(width: 64, height: 96,
            child: deck.legendImageUrl != null
                ? CardImage(imageUrl: deck.legendImageUrl, fallbackText: deck.legendName ?? '', fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Center(child: Icon(Icons.person, color: AppColors.slate600))))),
          const SizedBox(width: 6),
          // Domains (canonical order)
          Column(mainAxisAlignment: MainAxisAlignment.center, children: deck.domains.isNotEmpty
              ? _sortDomains(deck.domains).take(2).map((d) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: RuneIcon(domain: d, size: 32))).toList()
              : [_emptyDomainCircle(), const SizedBox(height: AppSpacing.xs), _emptyDomainCircle()]),
          const SizedBox(width: AppSpacing.sm),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(deck.name, style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (deck.description != null && deck.description!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 1),
              child: Text(deck.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))),
          const SizedBox(height: 2),
          // Author + date
          _buildAuthorDateRow(
            authorName: deck.authorName,
            authorId: deck.authorId,
            date: deck.publishedAt,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Set badges — derived from card IDs in mainDeck
          _buildSetBadgesAndStats(deck.mainDeck, deck.sideboard,
            viewCount: deck.viewCount, likeCount: deck.likeCount),
        ])),
      ]),
      // Price badge — bottom-left over legend image
      if (_hasPrice) Positioned(
        left: 0, bottom: 0,
        child: _DeckPriceBadge(price: _deckPrice),
      ),
      // Menu icon — bottom-right
      Positioned(bottom: -10, right: -13, child: GestureDetector(
        onTap: () => _showMetaPublicMenu(deck.id ?? '', deck.name, deck.legendName, deck.legendImageUrl, null,
          deck.mainDeck, deck.sideboard, deck.battlefields, deck.domains, deck.runeCount1, deck.runeCount2,
          onCopy: () async {
            if (_isDemo) {
              _demo.incrementViewCount(deck.name);
              _demo.createDeck(deck.toDeckData().copyWith(name: '${deck.name} (Copy)'));
            } else {
              if (deck.id != null) PublicDeckService.instance.incrementViewCount(deck.id!);
              await PublicDeckService.instance.copyToMyDecks(deck);
            }
            if (mounted) RiftrToast.success(context, 'Deck copied!');
          }),
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: EdgeInsets.all(AppSpacing.md),
          child: Icon(Icons.more_vert, color: AppColors.textMuted, size: 22)),
      )),
    ]);
    }),
    ));
  }

  // ---- My Deck Card ----
  // React: bg-slate-900 border border-slate-800 rounded-2xl py-2 px-2
  Widget _buildBadge(String label, int current, int max) {
    final isComplete = current == max;
    return RiftrBadge(
      label: '$label $current/$max',
      type: isComplete ? RiftrBadgeType.gold : RiftrBadgeType.neutral,
    );
  }

  Widget _buildAuthorDateRow({
    required String authorName,
    String? authorId,
    DateTime? date,
  }) {
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
        : null;
    final uid = AuthService.instance.uid;
    final isOwnProfile = authorId != null && authorId == uid;

    // Author-name is a secondary text-link inside an already-tappable deck
    // card. The 44dp touch-target rule is intentionally relaxed here because:
    // (a) the parent card tap opens the deck viewer — primary interaction
    //     always works regardless of where the user taps.
    // (b) wrapping the text in SizedBox(height: 44) balloons the row via
    //     Row cross-axis expansion, breaking card density (Meta-card
    //     reference is the target compact look).
    // Trade-off acknowledged in SKILL.md §1 Touch-Targets exception.
    return Row(children: [
      Text('by ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      Flexible(
        child: GestureDetector(
          onTap: authorId != null
              ? () => widget.onNavigateToAuthor?.call(authorId, authorName)
              : null,
          child: Text(
            isOwnProfile ? 'You' : authorName,
            style: AppTextStyles.captionBold.copyWith(color: AppColors.amber400, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      if (dateStr != null) ...[
        const SizedBox(width: 6),
        Text(dateStr, style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ]);

  }

  /// Validation-status icon for a deck tile.
  /// Valid → solid green check. Invalid → red error icon, tappable:
  /// tap opens a sheet listing every validation issue (missing legend,
  /// wrong card counts, banned cards, wrong-domain cards, …).
  /// Beide Icons werden in identischem 44×44 SizedBox + Center
  /// gerendert damit sie an exakt der gleichen Position sitzen
  /// (vorher: valid war nackter Icon, invalid in 44×44 Wrapper →
  /// unterschiedliche Layout-Position).
  /// Icon-Size 18 (vorher 16) — minimal größer für bessere Sichtbarkeit.
  Widget _validationStatusIcon(DeckData deck, Map<String, RiftCard> lookup) {
    if (deck.isFullyValid(lookup)) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(Icons.check_circle, color: AppColors.success, size: 18),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showValidationIssuesSheet(deck, lookup),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(Icons.error, color: AppColors.error, size: 18),
        ),
      ),
    );
  }

  /// Shows all validation issues as a dismissable bottom sheet.
  void _showValidationIssuesSheet(DeckData deck, Map<String, RiftCard> lookup) {
    final issues = deck.validationIssues(lookup);
    if (issues.isEmpty) return; // defensive — shouldn't be called when valid
    showRiftrSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet title — canonical convention (bodyLarge w500 textPrimary).
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Deck issues',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.rounded),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < issues.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, thickness: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.cancel, color: AppColors.error, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              issues[i],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(DeckData deck) {
    final isLastEdited = _lastEditedDeckId == deck.id;
    final lookup = CardService.getLookup();
    return GestureDetector(
      onTap: () { setState(() => _editingDeckId = deck.id); widget.onFullscreenChanged?.call(true); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBR,
          border: Border.all(color: isLastEdited ? AppColors.amber400 : AppColors.border, width: isLastEdited ? 1.5 : 1),
          boxShadow: isLastEdited ? [BoxShadow(color: AppColors.amber400.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1)] : null,
        ),
        child: Builder(builder: (_) {
          // Calculate deck price (Legend + Battlefields + Main + Side)
          double deckPrice = 0;
          bool hasPrice = false;
          void addPrice(String key, int qty) {
            final c = lookup[key];
            if (c != null) {
              final price = MarketService.instance.getPrice(c.id);
              if (price != null && price.standardPrice > 0) {
                deckPrice += price.standardPrice * qty;
                hasPrice = true;
              }
            }
          }
          if (deck.legendId != null && deck.legendId!.isNotEmpty) addPrice(deck.legendId!, 1);
          for (final bf in deck.battlefields) addPrice(bf.id, 1);
          for (final entry in deck.mainDeck.entries) addPrice(entry.key, entry.value);
          for (final entry in deck.sideboard.entries) addPrice(entry.key, entry.value);
          return Stack(children: [
          // Top-right: published globe + validation icon
          Positioned(top: 2, right: 2, child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_isDemo ? _demo.publishedDeckNames.contains(deck.name)
                : (AuthService.instance.uid != null &&
                    PublicDeckService.instance.myPublishedDeckNames(AuthService.instance.uid!).contains(deck.name)))
              Padding(padding: EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(Icons.public, color: AppColors.amber400, size: 14)),
            _validationStatusIcon(deck, lookup),
          ])),
          Row(children: [
            // Legend — match tracker: 64x96
            ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(width: 64, height: 96,
              child: deck.legendImageUrl != null
                  ? CardImage(imageUrl: deck.legendImageUrl, fallbackText: deck.legendName ?? '', fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside)),
                      child: Center(child: Text('No\nLegend', textAlign: TextAlign.center,
                        style: AppTextStyles.micro.copyWith(color: AppColors.slate600, fontWeight: FontWeight.bold)))))),
            const SizedBox(width: 6),
            // Domains — React: flex flex-col gap-1 w-8 h-8
            Column(mainAxisAlignment: MainAxisAlignment.center, children: deck.domains.isNotEmpty
                ? _sortDomains(deck.domains).take(2).map((d) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: RuneIcon(domain: d, size: 32))).toList()
                : [_emptyDomainCircle(), const SizedBox(height: AppSpacing.xs), _emptyDomainCircle()]),
            const SizedBox(width: AppSpacing.sm),
            // Text content (right padding for published/valid badges)
            Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Name — React: text-lg font-bold text-white
              Text(deck.name, style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (deck.description != null && deck.description!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 1),
                  child: Text(deck.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))),
              const SizedBox(height: 2),
              // Author + date row — show original author/date for copied decks
              _buildAuthorDateRow(
                authorName: deck.sourceAuthor ?? AuthService.instance.currentUser?.displayName ?? 'You',
                authorId: deck.sourceAuthor != null ? null : AuthService.instance.uid,
                date: deck.sourceDate ?? deck.createdAt,
              ),
              const SizedBox(height: AppSpacing.xs),
              // Set badges (no views/likes for own decks)
              DeckSetBadges(mainDeck: deck.mainDeck, sideboard: deck.sideboard),
            ]))),
          ]),
          // Menu icon — bottom-right (consistent with Meta/Public tiles)
          Positioned(bottom: -10, right: -13, child: GestureDetector(
            onTap: () => _showDeckMenu(deck, context),
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: EdgeInsets.all(AppSpacing.md),
              child: Icon(Icons.more_vert, color: AppColors.textMuted, size: 22)))),
          // Price badge — bottom-left over legend image
          if (hasPrice) Positioned(
            left: 0, bottom: 0,
            child: _DeckPriceBadge(price: deckPrice),
          ),
        ]);
        }),
      ),
    );
  }

  Widget _emptyDomainCircle() => Container(width: 32, height: 32, decoration: BoxDecoration(
    shape: BoxShape.circle, color: AppColors.surfaceLight,
    border: Border.all(color: AppColors.border, style: BorderStyle.solid)));

  /// Menu for Meta/Public/Following deck tiles.
  void _showMetaPublicMenu(String deckId, String deckName, String? legendName, String? legendImageUrl, String? chosenChampionId,
      Map<String, int> mainDeck, Map<String, int> sideboard, List<DeckCard> battlefields,
      List<String> domains, int runeCount1, int runeCount2,
      {required VoidCallback onCopy, String? authorInfo, String? placement}) {
    showDeckMenuSheet(context: context, items: [
      DeckMenuItem(icon: Icons.copy, label: 'Copy to My Decks', onTap: onCopy),
      const DeckMenuItem.divider(),
      DeckMenuItem(icon: Icons.description_outlined, label: 'Export Text', onTap: () {
        exportDeckText(context,
          legendName: legendName, chosenChampionId: chosenChampionId,
          mainDeck: mainDeck, sideboard: sideboard, battlefields: battlefields,
          domains: domains, runeCount1: runeCount1, runeCount2: runeCount2);
      }),
      DeckMenuItem(icon: Icons.image_outlined, label: 'Export Image', onTap: () {
        _exportDeckImage(deckName: deckName, legendName: legendName, legendImageUrl: legendImageUrl,
          chosenChampionId: chosenChampionId, mainDeck: mainDeck, sideboard: sideboard,
          battlefields: battlefields, domains: domains, runeCount1: runeCount1, runeCount2: runeCount2,
          authorInfo: authorInfo, placement: placement);
      }),
    ]);
  }

  void _exportDeckImage({
    required String deckName, String? legendName, String? legendImageUrl,
    String? chosenChampionId, required Map<String, int> mainDeck,
    required Map<String, int> sideboard, required List<DeckCard> battlefields,
    required List<String> domains, required int runeCount1, required int runeCount2,
    String? authorInfo, String? placement,
  }) {
    DeckImageExporter.export(context,
      deckName: deckName, legendName: legendName, legendImageUrl: legendImageUrl,
      chosenChampionId: chosenChampionId, mainDeck: mainDeck, sideboard: sideboard,
      battlefields: battlefields, domains: domains, runeCount1: runeCount1, runeCount2: runeCount2,
      authorInfo: authorInfo, placement: placement);
  }

  /// Sort domains into canonical display order (AppColors.domainOrder).
  static List<String> _sortDomains(List<String> domains) {
    final order = AppColors.domainOrder;
    final sorted = List<String>.from(domains);
    sorted.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return sorted;
  }

  /// Shared row: Set badges (left) + Views/Likes (right).
  /// Set-Order + Promo-Filter leben jetzt in DeckSetBadges.
  Widget _buildSetBadgesAndStats(Map<String, int> mainDeck, Map<String, int> sideboard, {int viewCount = 0, int likeCount = 0}) {
    return Row(children: [
      // Set badges (DeckSetBadges = same widget used in tracker + My Decks).
      DeckSetBadges(mainDeck: mainDeck, sideboard: sideboard),
      // Fixed gap then views + likes (flows after badges, no Spacer)
      const SizedBox(width: AppSpacing.sm),
      Icon(Icons.visibility_outlined, size: 13, color: AppColors.textMuted),
      const SizedBox(width: 2),
      Text(_compact(viewCount), style: AppTextStyles.bodySmallSecondary),
      const SizedBox(width: 8),
      Icon(Icons.favorite_border, size: 13, color: AppColors.textMuted),
      const SizedBox(width: 2),
      Text(_compact(likeCount), style: AppTextStyles.bodySmallSecondary),
    ]);
  }

  static String _compact(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1000).round()}k';
  }

  // _buildSetBadgesOnly entfernt — ersetzt durch DeckSetBadges
  // (lib/widgets/deck/deck_set_badges.dart). Single Source of Truth fuer
  // Tracker + Decks-Tab.

  // ---- Meta Deck Card ----
  // React: bg-slate-900 border-slate-700 rounded-2xl, placement badge top-right, copy icon right
  Widget _buildMetaDeckCard(MetaDeck meta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RiftrCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () {
          setState(() => _viewingMetaDeck = meta);
          widget.onFullscreenChanged?.call(true);
          if (!_isDemo) _trackView(meta.id, 'meta');
        },
        child: Stack(children: [
          Row(children: [
            // Legend image — match tracker: 64x96
            ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(width: 64, height: 96,
              child: meta.legendImageUrl != null
                  ? CardImage(imageUrl: meta.legendImageUrl, fallbackText: meta.legendName ?? '', fit: BoxFit.cover)
                  : Container(color: AppColors.surfaceLight))),
            const SizedBox(width: 6),
            // Domains
            Column(mainAxisAlignment: MainAxisAlignment.center,
              children: meta.sortedDomains.$1.take(2).map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2), child: RuneIcon(domain: d, size: 32))).toList()),
            const SizedBox(width: AppSpacing.sm),
            // Text
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Name + placement badge
              Row(children: [
                Expanded(child: Text(meta.name, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _placementColor(meta.placement).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                    border: Border.all(color: _placementColor(meta.placement).withValues(alpha: 0.3)),
                  ),
                  child: Text(meta.placement, style: AppTextStyles.sectionLabel.copyWith(color: _placementColor(meta.placement))),
                ),
              ]),
              if (meta.description.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 1),
                  child: Text(meta.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))),
              const SizedBox(height: 2),
              // Pilot + event + date row.
              // Format:
              //   pilot known   → "by [Pilot] · [Event] · [date]"
              //   pilot unknown → "[Event] · [date]"   (drop hanging "by")
              // The OLD layout was "by [Event] · [date]" which read as if
              // the EVENT had piloted the deck — playerName was being
              // dropped on the floor. Now structured.
              // Pilot/event/date row — these are the disambiguators when
              // multiple decks share a name (e.g. two "Kai'Sa Control"
              // decks differ only by pilot; "Jax Calm/Body Gear" Nanjing
              // vs "Jax Body/Calm Gear" Dalian differ only by source).
              // Source uses captionBold (not muted) so it pops as the
              // tiebreaker when no pilot is present — pilot stays the
              // primary differentiator (amber400) when available.
              Builder(builder: (_) {
                final pilot = meta.pilotLabel;
                return Row(children: [
                  if (pilot != null) ...[
                    Text('by ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                    Flexible(child: Text(pilot,
                        style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.amber400, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (meta.source.isNotEmpty || meta.createdAt != null)
                      Text(' · ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  ],
                  if (meta.source.isNotEmpty) ...[
                    Flexible(child: Text(meta.shortEventName,
                        style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                  ],
                  if (meta.createdAt != null)
                    Text(_formatDate(meta.createdAt!),
                        style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
                ]);
              }),
              const SizedBox(height: AppSpacing.xs),
              // Set badges (derived from cards, like Public tiles)
              _buildSetBadgesAndStats(meta.mainDeck, meta.sideboard,
                viewCount: meta.viewCount, likeCount: meta.likeCount),
            ])),
          ]),
          // Price badge — bottom-left over legend image
          Builder(builder: (_) {
            final lookup = CardService.getLookup();
            double deckPrice = 0;
            bool hasPrice = false;
            void addPrice(String key, int qty) {
              final c = lookup[key];
              if (c != null) {
                final price = MarketService.instance.getPrice(c.id);
                if (price != null && price.standardPrice > 0) {
                  deckPrice += price.standardPrice * qty;
                  hasPrice = true;
                }
              }
            }
            if (meta.legendId != null && meta.legendId!.isNotEmpty) addPrice(meta.legendId!, 1);
            for (final bf in meta.battlefields) addPrice(bf.id, 1);
            for (final entry in meta.mainDeck.entries) addPrice(entry.key, entry.value);
            for (final entry in meta.sideboard.entries) addPrice(entry.key, entry.value);
            if (!hasPrice) return const SizedBox.shrink();
            return Positioned(
              left: 0, bottom: 0,
              child: _DeckPriceBadge(price: deckPrice),
            );
          }),
          // Menu icon — bottom-right
          Positioned(bottom: -10, right: -13, child: GestureDetector(
            onTap: () => _showMetaPublicMenu(meta.id, meta.name, meta.legendName, meta.legendImageUrl, meta.chosenChampionId,
              meta.mainDeck, meta.sideboard, meta.battlefields, meta.domains, meta.runeCount1, meta.runeCount2,
              onCopy: () => _copyMetaDeck(meta), authorInfo: meta.description, placement: meta.placement),
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: EdgeInsets.all(AppSpacing.md),
              child: Icon(Icons.more_vert, color: AppColors.textMuted, size: 22)))),
        ]),
      ),
    );
  }

  Color _placementColor(String p) {
    if (p.contains('1st')) return AppColors.tournamentGold;
    if (p.contains('2nd')) return AppColors.tournamentSilver;
    if (p.contains('3rd') || p.contains('4th')) return AppColors.tournamentBronze;
    return AppColors.amber400;
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.year}';
  }

  // ---- Deck Menu + Dialogs ----
  void _showDeckMenu(DeckData deck, BuildContext btnContext) {
    if (deck.id == null) return;
    final uid = AuthService.instance.uid;
    final lookup = CardService.getLookup();
    final demoUid = _isDemo ? 'demo' : uid;
    final isPublished = demoUid != null && (_isDemo
        ? _demo.publishedDeckNames.contains(deck.name)
        : PublicDeckService.instance.myPublishedDeckNames(demoUid).contains(deck.name));
    final publishCount = _isDemo
        ? _demo.publishedCount
        : (uid != null ? PublicDeckService.instance.myPublishCount(uid) : 0);
    final atLimit = publishCount >= PublicDeckService.publishLimit;
    final canPublish = deck.isFullyValid(lookup) && !atLimit && !isPublished;

    showDeckMenuSheet(context: context, items: [
      if (!isPublished)
        DeckMenuItem(icon: Icons.public,
          label: !deck.isFullyValid(lookup) ? 'Publish (deck incomplete)' : atLimit ? 'Publish (limit reached)' : 'Publish',
          onTap: canPublish ? () => _publishDeck(deck) : () {
            RiftrToast.error(context, !deck.isFullyValid(lookup)
                ? 'Deck must be complete to publish'
                : 'Free limit reached (2 decks). Pro coming soon!');
          })
      else
        DeckMenuItem(icon: Icons.public, label: 'Published', onTap: null),
      DeckMenuItem(icon: Icons.edit, label: 'Edit Info', onTap: () => _showEditInfoDialog(deck)),
      DeckMenuItem(icon: Icons.copy, label: 'Duplicate', onTap: () {
        if (_isDemo) { _demo.duplicateDeck(deck.id!); } else { _service.duplicateDeck(deck); }
      }),
      const DeckMenuItem.divider(),
      DeckMenuItem(icon: Icons.description_outlined, label: 'Export Text', onTap: () {
        exportDeckText(context,
          legendName: deck.legendName, chosenChampionId: deck.chosenChampionId,
          mainDeck: deck.mainDeck, sideboard: deck.sideboard, battlefields: deck.battlefields,
          domains: deck.domains, runeCount1: deck.runeCount1, runeCount2: deck.runeCount2);
      }),
      DeckMenuItem(icon: Icons.image_outlined, label: 'Export Image', onTap: () {
        DeckImageExporter.export(context,
          deckName: deck.name, legendName: deck.legendName, legendImageUrl: deck.legendImageUrl,
          chosenChampionId: deck.chosenChampionId, mainDeck: deck.mainDeck, sideboard: deck.sideboard,
          battlefields: deck.battlefields, domains: deck.domains, runeCount1: deck.runeCount1, runeCount2: deck.runeCount2,
          authorInfo: 'by ${ProfileService.instance.ownProfile?.displayName ?? 'You'}');
      }),
      const DeckMenuItem.divider(),
      DeckMenuItem(icon: Icons.delete_outline, label: 'Delete', isDestructive: true, onTap: () {
        if (_isDemo) { _demo.deleteDeck(deck.id!); } else { _service.deleteDeck(deck.id!); }
      }),
    ]);
  }

  Future<void> _publishDeck(DeckData deck) async {
    bool success;
    if (_isDemo) {
      success = _demo.publishDeck(deck);
    } else {
      success = await PublicDeckService.instance.publishDeck(deck);
    }
    if (!mounted) return;
    if (success) {
      RiftrToast.success(context, 'Deck published!');
    } else {
      RiftrToast.error(context, 'Failed to publish deck');
    }
  }

  OverlayEntry? _menuOverlay;

  void _showOverlayMenu(BuildContext btnContext, List<Widget> items) {
    _menuOverlay?.remove();
    final box = btnContext.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final top = offset.dy + box.size.height + 4;

    _menuOverlay = OverlayEntry(builder: (context) {
      return Stack(children: [
        Positioned.fill(child: GestureDetector(onTap: () { _menuOverlay?.remove(); _menuOverlay = null; },
          child: Container(color: Colors.transparent))),
        Positioned(top: top, left: 0, right: 0, child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24)],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: items)),
        )),
      ]);
    });
    Overlay.of(btnContext).insert(_menuOverlay!);
  }

  Widget _overlayMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final c = isDestructive ? AppColors.loss : AppColors.textPrimary;
    return GestureDetector(
      onTap: () { _menuOverlay?.remove(); _menuOverlay = null; onTap(); },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppTextStyles.bodyLarge.copyWith(color: c, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
        ]),
      ),
    );
  }

  void _exportDeck(DeckData deck) {
    final lookup = CardService.getLookup();
    final buf = StringBuffer();
    // Legend
    if (deck.legendName != null) {
      buf.writeln('// Legend');
      buf.writeln('1 ${deck.legendName}');
    }
    // Champion — separate Champion units from main deck
    final championEntries = <MapEntry<String, int>>[];
    final regularEntries = <MapEntry<String, int>>[];
    for (final e in deck.mainDeck.entries) {
      final card = lookup[e.key];
      if (card != null && card.isChampion) {
        championEntries.add(MapEntry(card.name, e.value));
      } else {
        regularEntries.add(MapEntry(lookup[e.key]?.name ?? e.key, e.value));
      }
    }
    if (championEntries.isNotEmpty) {
      buf.writeln('// Champion');
      championEntries.sort((a, b) => a.key.compareTo(b.key));
      for (final e in championEntries) { buf.writeln('${e.value} ${e.key}'); }
    }
    // Runes
    if (deck.domains.isNotEmpty) {
      buf.writeln('// Runes');
      final runes = <String>[];
      runes.add('${deck.runeCount1} ${deck.domains[0]}');
      if (deck.domains.length > 1) runes.add('${deck.runeCount2} ${deck.domains[1]}');
      runes.sort((a, b) => a.substring(a.indexOf(' ')).compareTo(b.substring(b.indexOf(' '))));
      for (final r in runes) { buf.writeln(r); }
    }
    // Battlefields — sorted by name
    if (deck.battlefields.isNotEmpty) {
      buf.writeln('// Battlefields');
      final bfs = deck.battlefields.map((bf) => bf.name).toList()..sort();
      for (final name in bfs) { buf.writeln('1 $name'); }
    }
    // Main Deck — sorted by name (regular cards only, champions separated above)
    if (regularEntries.isNotEmpty) {
      buf.writeln('// Main Deck');
      regularEntries.sort((a, b) => a.key.compareTo(b.key));
      for (final e in regularEntries) { buf.writeln('${e.value} ${e.key}'); }
    }
    // Sideboard — sorted by name
    if (deck.sideboard.isNotEmpty) {
      buf.writeln('// Sideboard');
      final entries = deck.sideboard.entries.map((e) => MapEntry(lookup[e.key]?.name ?? e.key, e.value)).toList();
      entries.sort((a, b) => a.key.compareTo(b.key));
      for (final e in entries) { buf.writeln('${e.value} ${e.key}'); }
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      RiftrToast.info(context, 'Deck copied to clipboard');
    }
  }

  void _showEditInfoDialog(DeckData deck) {
    if (deck.id == null) return;
    final nameCtrl = TextEditingController(text: deck.name);
    final descCtrl = TextEditingController(text: deck.description ?? '');
    showRiftrSheet(
      context: context,
      builder: (ctx) => _EditDeckSheetContent(
        nameController: nameCtrl,
        descController: descCtrl,
        onSave: () {
          final name = nameCtrl.text.trim();
          if (name.isNotEmpty) {
            final desc = descCtrl.text.trim();
            final updated = deck.copyWith(name: name, description: desc.isEmpty ? null : desc);
            if (_isDemo) { _demo.updateDeck(updated); } else { _service.updateDeck(updated); }
          }
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

// ============================================
// NEW DECK SHEET CONTENT (StatefulWidget for stable FocusNodes)
// ============================================
class _NewDeckSheetContent extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final ValueNotifier<bool> hasName;
  final VoidCallback onCreate;

  const _NewDeckSheetContent({
    required this.nameController,
    required this.descController,
    required this.hasName,
    required this.onCreate,
  });

  @override
  State<_NewDeckSheetContent> createState() => _NewDeckSheetContentState();
}

class _NewDeckSheetContentState extends State<_NewDeckSheetContent> {
  late final FocusNode _nameFocus;
  late final FocusNode _descFocus;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _descFocus = FocusNode();
    _nameFocus.addListener(_forceKeyboard);
    _descFocus.addListener(_forceKeyboard);
  }

  void _forceKeyboard() {
    if (_nameFocus.hasFocus || _descFocus.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEW DECK', style: AppTextStyles.h2.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.lg),
          Text('DECK NAME', style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.nameController,
            focusNode: _nameFocus,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _descFocus.requestFocus(),
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Dark Witch Aggro',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded),
                borderSide: BorderSide(color: AppColors.amber400, width: 2)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('DESCRIPTION (OPTIONAL)', style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.descController,
            focusNode: _descFocus,
            textInputAction: TextInputAction.done,
            maxLines: 3,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe your deck strategy...',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded),
                borderSide: BorderSide(color: AppColors.amber400, width: 2)),
            ),
          ),
            const SizedBox(height: AppSpacing.lg),
            ValueListenableBuilder<bool>(
              valueListenable: widget.hasName,
              builder: (_, enabled, _) => RiftrButton(
                label: 'Create Deck',
                onPressed: enabled ? widget.onCreate : null,
              ),
            ),
          ],
        ),
      );
  }
}

// ============================================
// EDIT DECK SHEET CONTENT (StatefulWidget for stable FocusNodes)
// ============================================
class _EditDeckSheetContent extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditDeckSheetContent({
    required this.nameController,
    required this.descController,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditDeckSheetContent> createState() => _EditDeckSheetContentState();
}

class _EditDeckSheetContentState extends State<_EditDeckSheetContent> {
  late final FocusNode _nameFocus;
  late final FocusNode _descFocus;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _descFocus = FocusNode();
    _nameFocus.addListener(_forceKeyboard);
    _descFocus.addListener(_forceKeyboard);
  }

  void _forceKeyboard() {
    if (_nameFocus.hasFocus || _descFocus.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EDIT DECK', style: AppTextStyles.h2.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.nameController,
            focusNode: _nameFocus,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _descFocus.requestFocus(),
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded),
                borderSide: BorderSide(color: AppColors.amber400, width: 2)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.descController,
            focusNode: _descFocus,
            textInputAction: TextInputAction.done,
            maxLines: 2,
            maxLength: 100,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              counterStyle: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded),
                borderSide: BorderSide(color: AppColors.amber400, width: 2)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: RiftrButton(
              label: 'Cancel',
              onPressed: widget.onCancel,
              style: RiftrButtonStyle.secondary,
            )),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RiftrButton(
              label: 'Save',
              onPressed: widget.onSave,
            )),
          ]),
        ],
      ),
    );
  }
}

// ============================================
// META DECK VIEWER
// ============================================
class _MetaDeckViewer extends StatefulWidget {
  final MetaDeck metaDeck;
  final VoidCallback onBack;
  final VoidCallback onCopy;
  final void Function(String authorId, String authorName)? onNavigateToAuthor;
  final void Function(String deckName, Map<String, int> missingCards)? onStartDeckShopping;
  final String likeCollection; // 'meta_decks' or 'publicDecks'
  const _MetaDeckViewer({required this.metaDeck, required this.onBack, required this.onCopy, this.onNavigateToAuthor, this.onStartDeckShopping, this.likeCollection = 'meta_decks'});
  @override
  State<_MetaDeckViewer> createState() => _MetaDeckViewerState();
}

class _MetaDeckViewerState extends State<_MetaDeckViewer> with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _showCollectionStatus = false;
  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _load();
    // Listen to collection changes so the "missing X cards" badge
    // updates after the user adds cards via scanner / market / manual
    // edit. Mirrors the listener pattern in _DeckEditorState — the
    // viewer was missing this hook, so beta testers saw a stale
    // missing-count after scanning their physical deck.
    FirestoreCollectionService.instance.addListener(_refresh);
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    FirestoreCollectionService.instance.removeListener(_refresh);
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await CardService.loadCards();
    setState(() => _loading = false);
    _fabAnim.forward();
  }

  void _showViewerMenu(MetaDeck meta) {
    showDeckMenuSheet(context: context, items: [
      DeckMenuItem(icon: Icons.copy, label: 'Copy to My Decks', onTap: widget.onCopy),
      const DeckMenuItem.divider(),
      DeckMenuItem(icon: Icons.description_outlined, label: 'Export Text', onTap: () {
        exportDeckText(context,
          legendName: meta.legendName, chosenChampionId: meta.chosenChampionId,
          mainDeck: meta.mainDeck, sideboard: meta.sideboard, battlefields: meta.battlefields,
          domains: meta.domains, runeCount1: meta.runeCount1, runeCount2: meta.runeCount2);
      }),
      DeckMenuItem(icon: Icons.image_outlined, label: 'Export Image', onTap: () {
        DeckImageExporter.export(context,
          deckName: meta.name, legendName: meta.legendName, legendImageUrl: meta.legendImageUrl,
          chosenChampionId: meta.chosenChampionId, mainDeck: meta.mainDeck, sideboard: meta.sideboard,
          battlefields: meta.battlefields, domains: meta.domains, runeCount1: meta.runeCount1, runeCount2: meta.runeCount2,
          authorInfo: meta.description.isNotEmpty ? meta.description : null, placement: meta.placement);
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.metaDeck;
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.amber400));
    final lookup = CardService.getLookup();
    final badge = _collectionBadge(meta);
    final missingCount = badge != null ? badge['missing'] as int : 0;
    final missingCards = badge != null ? badge['missingCards'] as Map<String, int> : <String, int>{};

    return DragToDismiss(
      onDismissed: widget.onBack,
      backgroundColor: AppColors.background,
      child: Stack(children: [
      Column(children: [
        // Drag handle
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
          child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
        ),
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0), child: Stack(children: [
          // 3-dot menu top-right
          Positioned(top: 0, right: 0, child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showViewerMenu(meta),
            child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 22)))),
          // Centered content
          Column(children: [
          Text(meta.name, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          if (meta.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(meta.description, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.xs),
          // Pilot + event + date row — see tile-layout sibling for rationale.
          // "by [Pilot] · [Event] · [date]" when pilot known,
          // "[Event] · [date]" otherwise.
          Builder(builder: (_) {
            final pilot = meta.pilotLabel;
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (pilot != null) ...[
                Text('by ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                Text(pilot,
                    style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.amber400, fontWeight: FontWeight.bold)),
                if (meta.source.isNotEmpty || meta.createdAt != null)
                  Text(' · ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              ],
              if (meta.source.isNotEmpty) ...[
                Text(meta.shortEventName,
                    style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
              ],
              if (meta.createdAt != null)
                Text(
                  '${meta.createdAt!.day.toString().padLeft(2, '0')}.${meta.createdAt!.month.toString().padLeft(2, '0')}.${meta.createdAt!.year}',
                  style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
                ),
            ]);
          }),
        ])]),),
        const SizedBox(height: AppSpacing.sm),
        // Placement badge (only for meta decks with placement)
        if (meta.placement.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            RiftrBadge(label: meta.placement, type: RiftrBadgeType.gold),
          ])),
        // Collection + price badge (identical to DeckEditor)
        if (badge != null)
          Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Column(children: [
            GestureDetector(
              onTap: () => setState(() => _showCollectionStatus = !_showCollectionStatus),
              child: Container(
                height: 44, // Apple HIG touch-target minimum
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  // Active state = solid color (amber for missing, success
                  // for complete) — gives clear "toggle is ON" feedback,
                  // matches the visual weight of primary CTAs like
                  // "Add all to cart". Default stays dezent outlined.
                  color: _showCollectionStatus
                      ? (badge['missing'] == 0 ? AppColors.success : AppColors.amber500)
                      : AppColors.surface,
                  borderRadius: AppRadius.pillBR,
                  border: _showCollectionStatus
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _showCollectionStatus && badge['missing'] == 0
                        ? '✓ All ${badge['totalNeeded']} cards · €${(badge['deckCost'] as double).toStringAsFixed(2)}'
                        : _showCollectionStatus && (badge['missing'] as int) > 0
                            ? '${badge['totalOwned']}/${badge['totalNeeded']} owned · €${(badge['missingCost'] as double).toStringAsFixed(2)} missing'
                            : badge['missing'] == 0
                                ? '✓ All ${badge['totalNeeded']} cards owned'
                                : '${badge['totalOwned']}/${badge['totalNeeded']} owned · ${badge['missing']} missing',
                    style: AppTextStyles.captionBold.copyWith(
                      color: _showCollectionStatus
                          ? (badge['missing'] == 0 ? AppColors.textPrimary : AppColors.textOnPrimary)
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text('€', style: AppTextStyles.bodySmall.copyWith(
                    color: _showCollectionStatus
                        ? (badge['missing'] == 0 ? AppColors.textPrimary : AppColors.textOnPrimary)
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w900)),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(_showCollectionStatus ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: _showCollectionStatus
                        ? (badge['missing'] == 0 ? AppColors.textPrimary : AppColors.textOnPrimary)
                        : AppColors.textMuted),
                ]),
              ),
            ),
          ])),
        Expanded(child: Builder(builder: (_) {
          final legendMissing = _showCollectionStatus && meta.legendId != null && _getQty(meta.legendId!) == 0;
          final bfMissingIds = _showCollectionStatus
              ? meta.battlefields.where((bf) => _getQty(bf.id) == 0).map((bf) => bf.id).toSet()
              : <String>{};
          return ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, 120), children: [
          // Legend + Runes headers on same line
          Row(children: [
            Expanded(flex: 3, child: _sectionHeaderSingle('LEGEND (1/1)', align: TextAlign.center)),
            const SizedBox(width: AppSpacing.base),
            if (meta.domains.length >= 2) Expanded(flex: 2, child: _sectionHeaderSingle('RUNES (${meta.runeCount1 + meta.runeCount2}/12)', align: TextAlign.center)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // Legend + Runes content — vertically centered
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Legend column
            Expanded(flex: 3, child: Column(children: [
              if (meta.legendImageUrl != null)
                Stack(children: [
                  Opacity(opacity: legendMissing ? 0.5 : 1.0,
                    child: ColorFiltered(colorFilter: legendMissing ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                      child: AspectRatio(aspectRatio: 744 / 1039,
                        child: ClipRRect(borderRadius: AppRadius.baseBR,
                          child: CardImage(imageUrl: meta.legendImageUrl, fallbackText: meta.legendName ?? '', fit: BoxFit.cover))))),
                  // Price badge on legend
                  if (_showCollectionStatus && meta.legendId != null) ...[
                    () {
                      final lp = _getCardMinPrice(meta.legendId!);
                      if (lp == null || lp <= 0) return const SizedBox.shrink();
                      return Positioned(bottom: 4, right: 4, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: legendMissing ? AppColors.amber400 : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.rounded)),
                        child: Text('€${lp.toStringAsFixed(2)}',
                          style: AppTextStyles.small.copyWith(color: legendMissing ? AppColors.textOnPrimary : AppColors.textPrimary,
                            fontWeight: FontWeight.w800)),
                      ));
                    }(),
                  ],
                ])
              else AspectRatio(aspectRatio: 744 / 1039, child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.baseBR))),
            ])),
            const SizedBox(width: AppSpacing.base),
            // Runes column (read-only, canonical order)
            if (meta.domains.length >= 2) Expanded(flex: 2, child: Builder(builder: (_) {
              final (doms, rc1, rc2) = meta.sortedDomains;
              return Column(children: [
                RuneIcon(domain: doms[0], size: 64),
                const SizedBox(height: AppSpacing.xs),
                Text(doms[0], style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                Text('$rc1', style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.base),
                RuneIcon(domain: doms[1], size: 64),
                const SizedBox(height: AppSpacing.xs),
                Text(doms[1], style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                Text('$rc2', style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold)),
              ]);
            })),
          ]),
          const SizedBox(height: AppSpacing.base),
          // Battlefields
          _sectionHeaderSingle('BATTLEFIELDS (${meta.battlefields.length}/3)'),
          const SizedBox(height: AppSpacing.sm),
          if (meta.battlefields.isNotEmpty) _buildBfRow(meta.battlefields, lookup, missingIds: bfMissingIds),
          const SizedBox(height: AppSpacing.base),
          // Main Deck — React: 3-column grid of full card images
          _sectionHeaderSingle('MAIN DECK (${meta.mainCount}/40)'),
          const SizedBox(height: AppSpacing.sm),
          _buildFullCardGrid(meta.mainDeck, lookup,
            getQuantity: _showCollectionStatus ? _getQty : null,
            getPrice: _showCollectionStatus ? (id) => _getCardMinPrice(id) ?? 0 : null,
            chosenChampionId: meta.chosenChampionId,
            legendTag: () { final l = meta.legendId != null ? lookup[meta.legendId] : null; return l?.championTag; }()),
          const SizedBox(height: AppSpacing.base),
          // Side Deck
          _sectionHeaderSingle('SIDE DECK (${meta.sideCount}/8)'),
          const SizedBox(height: AppSpacing.sm),
          if (meta.sideboard.isNotEmpty) _buildFullCardGrid(meta.sideboard, lookup,
            getQuantity: _showCollectionStatus ? _getQty : null,
            getPrice: _showCollectionStatus ? (id) => _getCardMinPrice(id) ?? 0 : null)
          else Center(child: Text('Empty', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted))),
          const SizedBox(height: AppSpacing.base),
          // Energy Curve
          if (meta.mainDeck.isNotEmpty) EnergyCurveChart(cards: meta.mainDeck),
        ]);
        })),
      ]),
      // Copy + Like FABs — animated slide-up
      AnimatedBuilder(
        animation: _fabAnim,
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_fabAnim.value);
          final bottomInset = MediaQuery.of(context).viewPadding.bottom;
          final deckId = widget.metaDeck.id;
          final liked = PublicDeckService.instance.isLiked(deckId);
          return Stack(children: [
            // Like FAB — left (same size + style as Copy FAB)
            Positioned(left: AppSpacing.base, bottom: 22 * t, child: Opacity(opacity: t.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  PublicDeckService.instance.toggleLike(deckId, widget.likeCollection);
                  setState(() {});
                },
                child: Container(width: 56, height: 56, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: liked ? AppColors.loss : AppColors.surface,
                  border: liked ? null : Border.all(color: AppColors.border, width: 1.5),
                  ),
                  // FAB icon stays pure white when on colored bg (liked = loss) for
                  // theme-independent contrast; outlined state uses muted grey.
                  child: Icon(liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.white : AppColors.textMuted, size: 22))))),
            // Copy FAB — right
            Positioned(right: AppSpacing.base, bottom: 22 * t, child: Opacity(opacity: t.clamp(0.0, 1.0),
              child: GestureDetector(onTap: widget.onCopy,
                child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.amber500,
                  ),
                  // FAB icon stays pure white on amber for theme-independent contrast.
                  child: Icon(Icons.copy, color: Colors.white, size: 22))))),
            // Shop Missing Cards FAB — above copy FAB
            if (missingCount > 0 && missingCards.isNotEmpty)
              Positioned(right: AppSpacing.base, bottom: 22 * t + 65, child: Opacity(opacity: t.clamp(0.0, 1.0),
                child: GestureDetector(
                  onTap: () {
                    debugPrint('SHOP FAB: missingCount=$missingCount, missingCards=${missingCards.length} entries, keys=${missingCards.keys.take(5)}');
                    widget.onStartDeckShopping?.call(widget.metaDeck.name, missingCards);
                  },
                  child: Stack(clipBehavior: Clip.none, children: [
                    _ShopFab(pulse: true),
                    Positioned(right: -4, top: -4, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: Text('$missingCount', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textPrimary, letterSpacing: 0)),
                    )),
                  ]),
                ),
              )),
          ]);
        },
      ),
    ]),
    );
  }

  Widget _sectionHeaderSingle(String title, {TextAlign align = TextAlign.left}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(title, textAlign: align, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 0.5)));
  }

  // Full card image grid — React: grid grid-cols-3 gap-3, aspect-[2/3]
  int _getQty(String key) {
    final card = CardService.getLookup()[key];
    final resolvedId = card?.id ?? key;
    return FirestoreCollectionService.instance.getQuantity(resolvedId);
  }

  double? _getCardMinPrice(String key) {
    final card = CardService.getLookup()[key];
    final resolvedId = card?.id ?? key;
    final p = MarketService.instance.getPrice(resolvedId);
    return p?.standardPrice;
  }

  Map<String, dynamic>? _collectionBadge(MetaDeck meta) {
    final lookup = CardService.getLookup();
    // Build rawCards by ADDING quantities (spread operator would overwrite duplicates)
    final rawCards = Map<String, int>.from(meta.mainDeck);
    for (final e in meta.sideboard.entries) {
      rawCards[e.key] = (rawCards[e.key] ?? 0) + e.value;
    }
    if (meta.legendId != null && meta.legendId!.isNotEmpty) { rawCards[meta.legendId!] = (rawCards[meta.legendId!] ?? 0) + 1; }
    for (final bf in meta.battlefields) { rawCards[bf.id] = (rawCards[bf.id] ?? 0) + 1; }
    // Resolve keys to UUIDs
    final deckCards = <String, int>{};
    for (final e in rawCards.entries) {
      final card = lookup[e.key];
      final resolvedId = card?.id ?? e.key;
      deckCards[resolvedId] = (deckCards[resolvedId] ?? 0) + e.value;
    }
    final totalNeeded = deckCards.values.fold(0, (s, q) => s + q);
    final totalOwned = deckCards.entries.fold(0, (s, e) => s + e.value.clamp(0, _getQty(e.key)));

    double deckCost = 0, missingCost = 0;
    final missingCards = <String, int>{};
    for (final e in deckCards.entries) {
      final owned = _getQty(e.key);
      final need = e.value - owned;
      if (need > 0) {
        missingCards[e.key] = need;
      }
      final price = MarketService.instance.getPrice(e.key);
      if (price == null) continue;
      final cardPrice = price.standardPrice;
      if (cardPrice <= 0) continue;
      deckCost += cardPrice * e.value;
      if (need > 0) {
        missingCost += cardPrice * need;
      }
    }

    return {
      'totalNeeded': totalNeeded, 'totalOwned': totalOwned, 'missing': totalNeeded - totalOwned,
      'deckCost': deckCost, 'missingCost': missingCost, 'missingCards': missingCards,
    };
  }

  Widget _buildFullCardGrid(Map<String, int> cardMap, Map<String, RiftCard> lookup, {
    int Function(String)? getQuantity,
    double Function(String)? getPrice,
    String? chosenChampionId,
    String? legendTag,
  }) {
    final entries = cardMap.entries.toList();
    // Sort CC to front (same logic as editor grid)
    final ccIds = <String>{};
    if (chosenChampionId != null && chosenChampionId.isNotEmpty && cardMap.containsKey(chosenChampionId)) {
      ccIds.add(chosenChampionId);
    } else if (legendTag != null) {
      for (final e in entries) {
        final card = lookup[e.key];
        if (card != null && card.isChampion && card.tags.contains(legendTag)) {
          ccIds.add(e.key);
        }
      }
    }
    if (ccIds.isNotEmpty) {
      entries.sort((a, b) {
        final aIsCC = ccIds.contains(a.key) ? 0 : 1;
        final bIsCC = ccIds.contains(b.key) ? 0 : 1;
        return aIsCC.compareTo(bIsCC);
      });
    }
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 744.0 / 1039.0, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final card = lookup[e.key];
        final qty = e.value;
        final maxCopies = card != null ? getMaxCopies(card) : 3;
        final atLimit = qty >= maxCopies;
        final owned = getQuantity?.call(e.key);
        final isFullyMissing = owned != null && owned == 0;
        final isPartiallyMissing = owned != null && owned > 0 && owned < qty;
        return GestureDetector(
          onTap: () { if (card != null) Navigator.of(context).push(CardPreviewRoute(card: card)); },
          onLongPress: () { if (card != null) Navigator.of(context).push(CardPreviewRoute(card: card)); },
          child: Builder(builder: (_) {
            final isCC = ccIds.contains(e.key);
            return Column(children: [
            Expanded(child: Stack(clipBehavior: Clip.none, children: [
              // Card image with grayscale if fully missing + gold border if CC
              Opacity(opacity: isFullyMissing ? 0.5 : 1.0,
                child: ColorFiltered(
                  colorFilter: isFullyMissing ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Container(
                    decoration: isCC ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.base + 2),
                      border: Border.all(color: AppColors.amber500, width: 2.5),
                    ) : null,
                    child: ClipRRect(borderRadius: BorderRadius.circular(isCC ? AppRadius.base - 0.5 : AppRadius.base),
                      child: card?.imageUrl != null
                          ? CardImage(imageUrl: card!.imageUrl!, fallbackText: card.displayName, fit: BoxFit.cover, card: card)
                          : Container(color: AppColors.surface))))),
              // CC badge
              if (isCC)
                Positioned(top: -2, left: -2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text('CC', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.background)),
                )),
              // Partially missing: red ring
              if (isPartiallyMissing && !isCC)
                Positioned.fill(child: Container(decoration: BoxDecoration(
                  borderRadius: AppRadius.baseBR,
                  border: Border.all(color: AppColors.loss.withValues(alpha: 0.6), width: 1.5)))),
              // Quantity badge (bottom-left)
              Positioned(bottom: 2, left: 2, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: atLimit ? AppColors.loss : AppColors.amber600,
                  borderRadius: BorderRadius.circular(AppRadius.rounded)),
                child: Text('$qty/$maxCopies',
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
              )),
              // Price badge (bottom-right)
              if (getPrice != null) ...[
                () {
                  final cardPrice = getPrice(e.key);
                  if (cardPrice <= 0) return const SizedBox.shrink();
                  final isMissing = isFullyMissing || isPartiallyMissing;
                  return Positioned(bottom: 2, right: 2, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: isMissing ? AppColors.amber400 : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.rounded)),
                    child: Text('€${cardPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.small.copyWith(color: isMissing ? AppColors.textOnPrimary : AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                  ));
                }(),
              ],
            ])),
          ]);
          }),
        );
      },
    );
  }

  Widget _buildBfRow(List<DeckCard> bfs, Map<String, RiftCard> lookup, {Set<String> missingIds = const {}}) {
    return Row(children: bfs.map((bf) {
      final isMissing = missingIds.contains(bf.id);
      return Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: GestureDetector(
          onLongPress: () { final c = lookup[bf.id]; if (c != null) Navigator.of(context).push(CardPreviewRoute(card: c)); },
          child: Stack(children: [
            Opacity(opacity: isMissing ? 0.5 : 1.0,
              child: ColorFiltered(colorFilter: isMissing ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.rounded),
                  child: AspectRatio(aspectRatio: 1039 / 744,
                    child: bf.imageUrl != null
                        ? CardImage(imageUrl: bf.imageUrl!, fallbackText: bf.name, fit: BoxFit.cover)
                        : Container(color: AppColors.surface))))),
            // Price badge on battlefield
            if (_showCollectionStatus) ...[
              () {
                final bfPrice = _getCardMinPrice(bf.id);
                if (bfPrice == null || bfPrice <= 0) return const SizedBox.shrink();
                return Positioned(bottom: 4, right: 4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMissing ? AppColors.amber400 : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text('€${bfPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.small.copyWith(color: isMissing ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w800)),
                ));
              }(),
            ],
          ]),
        ),
      ));
    }).toList());
  }
}

// ============================================
// DECK EDITOR
// ============================================
class _DeckEditor extends StatefulWidget {
  final DeckData deck;
  final VoidCallback onBack;
  final bool startInEditMode;
  final void Function(String authorId, String authorName)? onNavigateToAuthor;
  final void Function(String deckName, Map<String, int> missingCards)? onStartDeckShopping;
  const _DeckEditor({required this.deck, required this.onBack, this.startInEditMode = false, this.onNavigateToAuthor, this.onStartDeckShopping});
  @override
  State<_DeckEditor> createState() => _DeckEditorState();
}

class _DeckEditorState extends State<_DeckEditor> with SingleTickerProviderStateMixin {
  List<RiftCard> _allCards = [];
  bool _loading = true;
  late bool _editing = widget.startInEditMode;
  bool _showCollectionStatus = false;
  DeckData? _editSnapshot; // snapshot taken when entering edit mode
  final _firestore = FirestoreDeckService.instance;
  final _demo = DemoService.instance;
  final _collection = FirestoreCollectionService.instance;
  final _marketService = MarketService.instance;
  bool get _isDemo => _demo.isActive;
  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _load();
    _firestore.addListener(_refresh);
    _demo.addListener(_refresh);
    _collection.addListener(_refresh);
  }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { _fabAnim.dispose(); _firestore.removeListener(_refresh); _demo.removeListener(_refresh); _collection.removeListener(_refresh); super.dispose(); }
  Future<void> _load() async {
    _allCards = await CardService.loadCards();
    if (_editing) { _editSnapshot = _deck; }
    setState(() => _loading = false);
    _fabAnim.forward();
  }

  bool get _hasUnsavedChanges {
    if (_editSnapshot == null) return false;
    final current = _deck;
    final snap = _editSnapshot!;
    return current.legendId != snap.legendId
        || current.runeCount1 != snap.runeCount1
        || current.runeCount2 != snap.runeCount2
        || current.battlefields.length != snap.battlefields.length
        || current.mainDeck.length != snap.mainDeck.length
        || current.sideboard.length != snap.sideboard.length
        || current.mainDeck.toString() != snap.mainDeck.toString()
        || current.sideboard.toString() != snap.sideboard.toString()
        || current.battlefields.map((b) => b.id).join() != snap.battlefields.map((b) => b.id).join();
  }

  void _enterEditMode() {
    setState(() { _editing = true; _editSnapshot = _deck; });
  }

  void _exitEditMode() {
    setState(() { _editing = false; _editSnapshot = null; _activeCardId = null; });
  }

  void _handleBackPress() {
    if (_editing && _hasUnsavedChanges) {
      _showSaveDiscardDialog();
    } else {
      if (_editing) { _exitEditMode(); }
      widget.onBack();
    }
  }

  void _handleEditFabPress() {
    if (!_editing) {
      _enterEditMode();
    } else if (_hasUnsavedChanges) {
      // Already saved live — just exit edit mode
      _exitEditMode();
    } else {
      _exitEditMode();
    }
  }

  void _showSaveDiscardDialog() {
    showRiftrSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SAVE CHANGES?',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.amber400,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Do you want to save your changes or discard them?',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: RiftrButton(
                  label: 'Discard',
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (_editSnapshot != null) { _updateDeck(_editSnapshot!); }
                    _exitEditMode();
                    widget.onBack();
                  },
                  style: RiftrButtonStyle.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RiftrButton(
                  label: 'Keep',
                  onPressed: () {
                    Navigator.pop(ctx);
                    _exitEditMode();
                    widget.onBack();
                  },
                  icon: Icons.check,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  DeckData get _deck {
    if (_isDemo) return _demo.getDeck(widget.deck.id!) ?? widget.deck;
    return _firestore.getDeck(widget.deck.id!) ?? widget.deck;
  }

  void _updateDeck(DeckData deck) {
    // Clear source attribution on any edit — deck is now the user's
    final cleared = deck.sourceAuthor != null ? deck.clearSource() : deck;
    if (_isDemo) { _demo.updateDeck(cleared); } else { _firestore.updateDeck(cleared); }
  }

  int _getQty(String key) {
    final card = CardService.getLookup()[key];
    final resolvedId = card?.id ?? key;
    return _isDemo ? _demo.getQuantity(resolvedId) : _collection.getQuantity(resolvedId);
  }

  /// Compute collection badge: {totalNeeded, totalOwned, missing} + cost data
  Map<String, dynamic>? _collectionBadge(DeckData deck) {
    if (_editing) return null;
    final lookup = CardService.getLookup();
    // Build rawCards by ADDING quantities (spread operator would overwrite duplicates)
    final rawCards = Map<String, int>.from(deck.mainDeck);
    for (final e in deck.sideboard.entries) {
      rawCards[e.key] = (rawCards[e.key] ?? 0) + e.value;
    }
    if (deck.legendId != null && deck.legendId!.isNotEmpty) { rawCards[deck.legendId!] = (rawCards[deck.legendId!] ?? 0) + 1; }
    for (final bf in deck.battlefields) { rawCards[bf.id] = (rawCards[bf.id] ?? 0) + 1; }
    // Resolve keys to UUIDs
    final deckCards = <String, int>{};
    for (final e in rawCards.entries) {
      final card = lookup[e.key];
      final resolvedId = card?.id ?? e.key;
      deckCards[resolvedId] = (deckCards[resolvedId] ?? 0) + e.value;
    }
    final totalNeeded = deckCards.values.fold(0, (s, q) => s + q);
    final totalOwned = deckCards.entries.fold(0, (s, e) => s + e.value.clamp(0, _getQty(e.key)));

    // Cost calculations — missingCards includes ALL missing, not just those with prices
    double deckCost = 0, missingCost = 0;
    final missingCards = <String, int>{};
    for (final e in deckCards.entries) {
      final owned = _getQty(e.key);
      final need = e.value - owned;
      if (need > 0) {
        missingCards[e.key] = need;
      }
      final price = _marketService.getPrice(e.key);
      if (price == null) continue;
      final cardPrice = price.standardPrice;
      if (cardPrice <= 0) continue;
      deckCost += cardPrice * e.value;
      if (need > 0) {
        missingCost += cardPrice * need;
      }
    }

    return {
      'totalNeeded': totalNeeded, 'totalOwned': totalOwned, 'missing': totalNeeded - totalOwned,
      'deckCost': deckCost, 'missingCost': missingCost, 'missingCards': missingCards,
    };
  }

  double _getCardMinPrice(String key) {
    final card = CardService.getLookup()[key];
    final resolvedId = card?.id ?? key;
    final price = _marketService.getPrice(resolvedId);
    if (price == null) return 0;
    return price.standardPrice;
  }

  Widget _buildAuthorDate() {
    final uid = AuthService.instance.uid;
    final authorName = AuthService.instance.currentUser?.displayName ?? 'You';
    final date = _deck.createdAt;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
        : null;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('by ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      GestureDetector(
        onTap: uid != null ? () => widget.onNavigateToAuthor?.call(uid, authorName) : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44, // Apple HIG touch-target minimum
          child: Align(
            alignment: Alignment.center,
            child: Text(authorName, style: AppTextStyles.captionBold.copyWith(color: AppColors.amber400, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      if (dateStr != null) ...[
        const SizedBox(width: 6),
        Text(dateStr, style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.amber400));
    final deck = _deck;
    final lookup = CardService.getLookup();
    final badge = _collectionBadge(deck);
    final legendMissing = _showCollectionStatus && _hasLegend && _getQty(deck.legendId!) == 0;
    final bfMissingIds = _showCollectionStatus
        ? deck.battlefields.where((bf) => _getQty(bf.id) == 0).map((bf) => bf.id).toSet()
        : <String>{};

    return DragToDismiss(
      onDismissed: _handleBackPress,
      backgroundColor: AppColors.background,
      child: Stack(children: [
      Column(children: [
        // Drag handle
        const Padding(padding: EdgeInsets.only(top: AppSpacing.md),
          child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen)),
        // Header — deck name centered
        Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.legacyXxl, AppSpacing.sm, AppSpacing.legacyXxl, 0), child: Column(children: [
          Text(deck.name, style: AppTextStyles.titleLarge.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w900), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (deck.description != null && deck.description!.isNotEmpty)
            Text(deck.description!, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center, maxLines: 1),
          const SizedBox(height: AppSpacing.xs),
          _buildAuthorDate(),
        ])),
        const SizedBox(height: AppSpacing.sm),
        // Collection + price badge (single toggle)
        if (badge != null)
          Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Column(children: [
            GestureDetector(
              onTap: () => setState(() => _showCollectionStatus = !_showCollectionStatus),
              child: Container(
                height: 44, // Apple HIG touch-target minimum
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  // Active state = solid color (amber for missing, success
                  // for complete) — gives clear "toggle is ON" feedback,
                  // matches the visual weight of primary CTAs like
                  // "Add all to cart". Default stays dezent outlined.
                  color: _showCollectionStatus
                      ? (badge['missing'] == 0 ? AppColors.success : AppColors.amber500)
                      : AppColors.surface,
                  borderRadius: AppRadius.pillBR,
                  border: _showCollectionStatus
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _showCollectionStatus && badge['missing'] == 0
                        ? '✓ All ${badge['totalNeeded']} cards · €${(badge['deckCost'] as double).toStringAsFixed(2)}'
                        : _showCollectionStatus && (badge['missing'] as int) > 0
                            ? '${badge['totalOwned']}/${badge['totalNeeded']} owned · €${(badge['missingCost'] as double).toStringAsFixed(2)} missing'
                            : badge['missing'] == 0
                                ? '✓ All ${badge['totalNeeded']} cards owned'
                                : '${badge['totalOwned']}/${badge['totalNeeded']} owned · ${badge['missing']} missing',
                    style: AppTextStyles.captionBold.copyWith(
                      color: _showCollectionStatus
                          ? (badge['missing'] == 0 ? AppColors.textPrimary : AppColors.textOnPrimary)
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text('€', style: AppTextStyles.bodySmall.copyWith(
                    color: _showCollectionStatus
                        ? (badge['missing'] == 0 ? AppColors.textPrimary : AppColors.textOnPrimary)
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w900)),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(_showCollectionStatus ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: _showCollectionStatus
                        ? (badge['missing'] == 0 ? AppColors.textPrimary : AppColors.textOnPrimary)
                        : AppColors.textMuted),
                ]),
              ),
            ),
            // (Shop FAB replaces inline button — see _buildShopFab below)
          ])),
        // Editor content
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, 120), children: [
          // Legend + Runes side-by-side — headers centered over each column
          // Headers on same line
          Row(children: [
            Expanded(flex: 3, child: _sectionHeaderSingle('LEGEND (${_hasLegend ? "1/1" : "0/1"})', align: TextAlign.center)),
            const SizedBox(width: AppSpacing.base),
            Expanded(flex: 2, child: _sectionHeaderSingle('RUNES (${deck.runeTotal}/12)', align: TextAlign.center)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // Content centered vertically
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 3, child: GestureDetector(
              onTap: _editing ? () => _openCardModal('legend') : null,
              child: deck.legendImageUrl != null && deck.legendImageUrl!.isNotEmpty
                  ? Stack(children: [
                      Opacity(opacity: legendMissing ? 0.5 : 1.0,
                        child: ColorFiltered(colorFilter: legendMissing ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: AspectRatio(aspectRatio: 744 / 1039,
                            child: ClipRRect(borderRadius: AppRadius.baseBR,
                              child: CardImage(imageUrl: deck.legendImageUrl, fallbackText: deck.legendName ?? '', fit: BoxFit.cover))))),
                      // Price badge on legend
                      if (_showCollectionStatus && deck.legendId != null) ...[
                        () {
                          final lp = _getCardMinPrice(deck.legendId!);
                          if (lp <= 0) return const SizedBox.shrink();
                          return Positioned(bottom: 4, right: 4, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: legendMissing ? AppColors.amber400 : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.rounded)),
                            child: Text('€${lp.toStringAsFixed(2)}',
                              style: AppTextStyles.small.copyWith(color: legendMissing ? AppColors.textOnPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.w800)),
                          ));
                        }(),
                      ],
                      // Remove button (edit mode only)
                      // Align(topRight) statt Center → sichtbarer Badge in
                      // der Karten-Ecke (4px Inset durch Positioned), Touch-
                      // Zone bleibt 44×44 HIG-konform.
                      if (_editing) Positioned(top: 4, right: 4, child: GestureDetector(
                        onTap: () => _removeLegend(),
                        child: SizedBox(
                          width: 44, height: 44, // Apple HIG touch-target minimum
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.loss),
                              // Badge icon stays pure white on loss for theme-independent contrast.
                              child: Icon(Icons.close, color: Colors.white, size: 20)),
                          ),
                        ))),
                    ])
                  : GestureDetector(
                    onTap: _editing ? () => _openCardModal('legend') : null,
                    child: AspectRatio(aspectRatio: 744 / 1039, child: Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.baseBR,
                        border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside)),
                      child: Center(child: _editing
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add, color: AppColors.textMuted, size: 32),
                            SizedBox(height: AppSpacing.xs),
                            Text('Tap to select', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ])
                        : Text('No Legend', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)))))),
            )),
            const SizedBox(width: AppSpacing.base),
            Expanded(flex: 2, child: deck.domains.length >= 2
                ? Column(children: [
                    _buildRuneDisplay(deck, 0, deck.domains[0], deck.runeCount1, editable: _editing),
                    const SizedBox(height: AppSpacing.base),
                    _buildRuneDisplay(deck, 1, deck.domains[1], deck.runeCount2, editable: _editing),
                  ])
                : Center(child: Text('Select a\nLegend first', textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)))),
          ]),
          const SizedBox(height: AppSpacing.base),
          // Battlefields
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeaderSingle('BATTLEFIELDS (${deck.battlefields.length}/3)'),
            const SizedBox(height: AppSpacing.sm),
            _buildBfRowEditable(deck.battlefields, lookup, missingIds: bfMissingIds),
          ]),
          const SizedBox(height: AppSpacing.base),
          // Main Deck
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeaderSingle('MAIN DECK (${deck.mainCount}/40)'),
            const SizedBox(height: AppSpacing.sm),
            deck.mainDeck.isNotEmpty || _editing
                ? _buildFullCardGrid(deck.mainDeck, lookup,
                    onAdd: _editing ? () => _openCardModal('main') : null,
                    getQuantity: _showCollectionStatus ? _getQty : null,
                    onQuantityChanged: _editing ? (id, qty) => _changeCardQty(deck, id, qty, isMain: true) : null,
                    getMaxCopies: (id) { final c = lookup[id]; return c != null ? getMaxCopies(c) : 3; },
                    getTotalByName: (id) { final c = lookup[id]; return c != null ? _getTotalByNameInDeck(deck, c.name, lookup) : 0; },
                    canStealArtVersion: (id) => _canStealArtVersionInDeck(deck, id, lookup),
                    onMoveCard: _editing ? (id) => _moveCardToSide(deck, id) : null,
                    moveLabel: 'S',
                    getPrice: _showCollectionStatus ? _getCardMinPrice : null,
                    chosenChampionId: deck.chosenChampionId,
                    legendTag: () { final l = deck.legendId != null ? lookup[deck.legendId] : null; return l?.championTag; }(),
                    onSelectChampion: _editing ? () => _openCardModal('champion') : null)
                : const SizedBox.shrink(),
          ]),
          const SizedBox(height: AppSpacing.base),
          // Side Deck
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeaderSingle('SIDE DECK (${deck.sideCount}/8)'),
            const SizedBox(height: AppSpacing.sm),
            deck.sideboard.isNotEmpty || _editing
                ? _buildFullCardGrid(deck.sideboard, lookup,
                    onAdd: _editing ? () => _openCardModal('side') : null,
                    getQuantity: _showCollectionStatus ? _getQty : null,
                    onQuantityChanged: _editing ? (id, qty) => _changeCardQty(deck, id, qty, isMain: false) : null,
                    getMaxCopies: (id) { final c = lookup[id]; return c != null ? getMaxCopies(c) : 3; },
                    getTotalByName: (id) { final c = lookup[id]; return c != null ? _getTotalByNameInDeck(deck, c.name, lookup) : 0; },
                    canStealArtVersion: (id) => _canStealArtVersionInDeck(deck, id, lookup),
                    onMoveCard: _editing ? (id) => _moveCardToMain(deck, id) : null,
                    moveLabel: 'M',
                    getPrice: _showCollectionStatus ? _getCardMinPrice : null)
                : const SizedBox.shrink(),
          ]),
          if (deck.mainDeck.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            EnergyCurveChart(cards: deck.mainDeck),
          ],
          const SizedBox(height: AppSpacing.base),
        ])),
      ]),
      // 3-dot menu — top right corner
      Positioned(right: AppSpacing.xs, top: AppSpacing.xs, child: Builder(builder: (btnCtx) => GestureDetector(onTap: () => _showEditorMenu(deck, btnCtx),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44, height: 44, // Apple HIG touch-target minimum
          child: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 24),
        )))),
      // Edit/Save FAB — animated slide-up
      AnimatedBuilder(
        animation: _fabAnim,
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_fabAnim.value);
          final bottomInset = MediaQuery.of(context).viewPadding.bottom;
          final unsaved = _editing && _hasUnsavedChanges;
          return Positioned(right: AppSpacing.base, bottom: 22 * t, child: Opacity(opacity: t.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: _handleEditFabPress,
              child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle,
                color: unsaved ? AppColors.success : AppColors.amber500,
                ),
                // FAB icon stays pure white for theme-independent contrast.
                child: Icon(
                  _editing ? (unsaved ? Icons.save : Icons.check) : Icons.edit,
                  color: Colors.white, size: 22)))));
        },
      ),
      // Shop Missing Cards FAB — always visible when cards are missing
      if (!_editing && badge != null && (badge['missing'] as int) > 0 && (badge['missingCards'] as Map<String, int>).isNotEmpty)
        AnimatedBuilder(
          animation: _fabAnim,
          builder: (context, _) {
            final t = Curves.easeOutBack.transform(_fabAnim.value);
            final bottomInset = MediaQuery.of(context).viewPadding.bottom;
            final missingCount = badge['missing'] as int;
            return Positioned(right: AppSpacing.base, bottom: 22 * t + 65, child: Opacity(opacity: t.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: () => widget.onStartDeckShopping?.call(widget.deck.name, badge['missingCards'] as Map<String, int>),
                child: Stack(clipBehavior: Clip.none, children: [
                  _ShopFab(pulse: true),
                  // Badge with count
                  Positioned(right: -4, top: -4, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.rounded),
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Text('$missingCount', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textPrimary, letterSpacing: 0)),
                  )),
                ]),
              ),
            ));
          },
        ),
    ]),
    );
  }

  bool get _hasLegend => _deck.legendId != null && _deck.legendId!.isNotEmpty;

  void _removeLegend() {
    final deck = _deck;
    _updateDeck(deck.copyWith(legendId: '', legendName: '', legendImageUrl: '', domains: [], runeCount1: 0, runeCount2: 0));
  }

  void _removeBattlefield(String bfId) {
    final deck = _deck;
    final bfs = List<DeckCard>.from(deck.battlefields)..removeWhere((b) => b.id == bfId);
    _updateDeck(deck.copyWith(battlefields: bfs));
  }

  void _moveCardToSide(DeckData deck, String cardId) {
    final main = Map<String, int>.from(deck.mainDeck);
    final side = Map<String, int>.from(deck.sideboard);
    final currentMain = main[cardId] ?? 0;
    if (currentMain <= 0) return;
    if (currentMain <= 1) {
      main.remove(cardId);
    } else {
      main[cardId] = currentMain - 1;
    }
    side[cardId] = (side[cardId] ?? 0) + 1;
    _updateDeck(deck.copyWith(mainDeck: main, sideboard: side));
  }

  void _moveCardToMain(DeckData deck, String cardId) {
    final main = Map<String, int>.from(deck.mainDeck);
    final side = Map<String, int>.from(deck.sideboard);
    final currentSide = side[cardId] ?? 0;
    if (currentSide <= 0) return;
    if (currentSide <= 1) {
      side.remove(cardId);
    } else {
      side[cardId] = currentSide - 1;
    }
    main[cardId] = (main[cardId] ?? 0) + 1;
    _updateDeck(deck.copyWith(mainDeck: main, sideboard: side));
  }

  void _changeCardQty(DeckData deck, String cardId, int newQty, {required bool isMain}) {
    final lookup = CardService.getLookup();
    final card = lookup[cardId];
    final maxCopies = card != null ? getMaxCopies(card) : 3;
    final currentQty = isMain ? (deck.mainDeck[cardId] ?? 0) : (deck.sideboard[cardId] ?? 0);

    // Decreasing — always allowed
    if (newQty <= currentQty) {
      final deckMap = Map<String, int>.from(isMain ? deck.mainDeck : deck.sideboard);
      if (newQty <= 0) { deckMap.remove(cardId); } else { deckMap[cardId] = newQty; }
      _updateDeck(deck.copyWith(mainDeck: isMain ? deckMap : null, sideboard: !isMain ? deckMap : null));
      return;
    }

    // Increasing — check name-based limit
    if (card == null) return;
    final nameTotal = _getTotalByNameInDeck(deck, card.name, lookup);

    if (nameTotal < maxCopies) {
      // Under limit → just add
      final deckMap = Map<String, int>.from(isMain ? deck.mainDeck : deck.sideboard);
      deckMap[cardId] = newQty;
      _updateDeck(deck.copyWith(mainDeck: isMain ? deckMap : null, sideboard: !isMain ? deckMap : null));
    } else {
      // At limit → steal from another art version of same card name
      String? stealId;
      bool stealFromMain = true;
      for (final entry in [...deck.mainDeck.entries, ...deck.sideboard.entries]) {
        if (entry.key == cardId) continue;
        final other = lookup[entry.key];
        if (other != null && other.name == card.name && entry.value > 0) {
          stealId = entry.key;
          stealFromMain = deck.mainDeck.containsKey(stealId);
          break;
        }
      }
      if (stealId == null) return; // No other version to steal from

      // Build both maps
      final mainMap = Map<String, int>.from(deck.mainDeck);
      final sideMap = Map<String, int>.from(deck.sideboard);
      final targetMap = isMain ? mainMap : sideMap;
      final stealMap = stealFromMain ? mainMap : sideMap;

      // Decrement steal source
      final oldQty = stealMap[stealId] ?? 0;
      if (oldQty <= 1) { stealMap.remove(stealId); } else { stealMap[stealId] = oldQty - 1; }
      // Increment this card
      targetMap[cardId] = newQty;

      _updateDeck(deck.copyWith(mainDeck: mainMap, sideboard: sideMap));
    }
  }

  // Rune display — large domain icon + domain name + count (optionally editable)
  Widget _buildRuneDisplay(DeckData deck, int idx, String domain, int count, {bool editable = false}) {
    return Column(children: [
      GestureDetector(
        onTap: editable ? () {
          final next = (count % 12) + 1;
          _updateRunesAutoLock(deck, idx, next);
        } : null,
        child: RuneIcon(domain: domain, size: 64),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(domain, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      if (editable)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: count > 0 ? () => _updateRunesAutoLock(deck, idx, count - 1) : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.remove, color: count > 0 ? AppColors.textSecondary : AppColors.textMuted, size: 28))),
          const SizedBox(width: AppSpacing.md),
          Text('$count', style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: count < 12 ? () => _updateRunesAutoLock(deck, idx, count + 1) : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.add, color: count < 12 ? AppColors.textSecondary : AppColors.textMuted, size: 28))),
        ])
      else
        Text('$count', style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }

  void _updateRunesAutoLock(DeckData deck, int domainIndex, int newCount) {
    if (deck.id == null) return;
    final clamped = newCount.clamp(0, 12);
    _updateDeck(deck.copyWith(
      runeCount1: domainIndex == 0 ? clamped : 12 - clamped,
      runeCount2: domainIndex == 1 ? clamped : 12 - clamped,
    ));
  }

  Widget _sectionHeaderSingle(String title, {TextAlign align = TextAlign.left}) => Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    child: Text(title, textAlign: align, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 0.5)));

  String? _activeCardId;

  /// Check if another art version of the same card name exists in the deck (for stealing)
  bool _canStealArtVersionInDeck(DeckData deck, String cardId, Map<String, RiftCard> lookup) {
    final card = lookup[cardId];
    if (card == null) return false;
    for (final entry in [...deck.mainDeck.entries, ...deck.sideboard.entries]) {
      if (entry.key == cardId) continue;
      final other = lookup[entry.key];
      if (other != null && other.name == card.name && entry.value > 0) return true;
    }
    return false;
  }

  /// Total copies by card NAME across both main + side in a deck
  int _getTotalByNameInDeck(DeckData deck, String cardName, Map<String, RiftCard> lookup) {
    int total = 0;
    for (final e in deck.mainDeck.entries) {
      final c = lookup[e.key];
      if (c != null && c.name == cardName) total += e.value;
    }
    for (final e in deck.sideboard.entries) {
      final c = lookup[e.key];
      if (c != null && c.name == cardName) total += e.value;
    }
    return total;
  }

  // Full card grid — React: grid-cols-3 gap-3 aspect-[2/3]
  Widget _buildFullCardGrid(Map<String, int> cardMap, Map<String, RiftCard> lookup, {
    VoidCallback? onAdd, int Function(String)? getQuantity,
    void Function(String cardId, int newQty)? onQuantityChanged, int Function(String cardId)? getMaxCopies,
    int Function(String cardId)? getTotalByName,
    bool Function(String cardId)? canStealArtVersion,
    void Function(String cardId)? onMoveCard, String? moveLabel,
    double Function(String cardId)? getPrice,
    String? chosenChampionId,
    String? legendTag,
    VoidCallback? onSelectChampion,
  }) {
    final entries = cardMap.entries.toList();
    // Determine CC: explicit field, fallback to tag detection
    final ccIds = <String>{};
    if (chosenChampionId != null && chosenChampionId.isNotEmpty && cardMap.containsKey(chosenChampionId)) {
      ccIds.add(chosenChampionId);
    } else if (legendTag != null) {
      for (final e in entries) {
        final card = lookup[e.key];
        if (card != null && card.isChampion && card.tags.contains(legendTag)) {
          ccIds.add(e.key);
        }
      }
    }
    // Sort CCs to front
    if (ccIds.isNotEmpty) {
      entries.sort((a, b) {
        final aIsCC = ccIds.contains(a.key) ? 0 : 1;
        final bIsCC = ccIds.contains(b.key) ? 0 : 1;
        return aIsCC.compareTo(bIsCC);
      });
    }
    // Show CC placeholder slot at position 0 if editing and no CC yet
    final showCCPlaceholder = onSelectChampion != null && ccIds.isEmpty && legendTag != null;
    final showAdd = onAdd != null;
    final isEditable = onQuantityChanged != null;
    final extraSlots = (showCCPlaceholder ? 1 : 0) + (showAdd ? 1 : 0);
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 744.0 / 1039.0, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: entries.length + extraSlots,
      itemBuilder: (context, index) {
        // CC placeholder at position 0
        if (showCCPlaceholder && index == 0) {
          return GestureDetector(
            onTap: onSelectChampion,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.baseBR,
                border: Border.all(color: AppColors.amber500, width: 2, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add, color: AppColors.amber400, size: 28),
                const SizedBox(height: 4),
                Text('Chosen\nChampion', textAlign: TextAlign.center,
                  style: AppTextStyles.tiny.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }
        final adjustedIndex = showCCPlaceholder ? index - 1 : index;
        // Add-card placeholder at the end
        if (adjustedIndex == entries.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.baseBR,
                border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside)),
              child: Center(child: Icon(Icons.add, color: AppColors.textMuted, size: 32)),
            ),
          );
        }
        final e = entries[adjustedIndex];
        final card = lookup[e.key];
        final qty = e.value;
        final owned = getQuantity?.call(e.key);
        final isFullyMissing = owned != null && owned == 0;
        final isPartiallyMissing = owned != null && owned > 0 && owned < qty;
        final isActive = isEditable && _activeCardId == e.key;
        final maxCopies = getMaxCopies?.call(e.key) ?? 3;
        final nameTotal = getTotalByName?.call(e.key) ?? qty;
        final canSteal = canStealArtVersion?.call(e.key) ?? false;
        final atLimit = nameTotal >= maxCopies && !canSteal;
        return GestureDetector(
          onTap: isEditable
              ? () => setState(() {
                  if (_activeCardId == e.key) {
                    _activeCardId = null;
                  } else if (_activeCardId != null) {
                    // Another card is active — close it first
                    _activeCardId = null;
                  } else {
                    _activeCardId = e.key;
                  }
                })
              : () { if (card != null) Navigator.of(context).push(CardPreviewRoute(card: card)); },
          onLongPress: () { if (card != null) Navigator.of(context).push(CardPreviewRoute(card: card)); },
          child: Builder(builder: (_) {
            final isCC = ccIds.contains(e.key);
            return Column(children: [
            Expanded(child: Stack(clipBehavior: Clip.none, children: [
              // Card image with grayscale if fully missing + gold border if CC
              Opacity(opacity: isFullyMissing ? 0.5 : 1.0,
                child: ColorFiltered(
                  colorFilter: isFullyMissing ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Container(
                    decoration: isCC ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.base + 2),
                      border: Border.all(color: AppColors.amber500, width: 2.5),
                    ) : null,
                    child: ClipRRect(borderRadius: BorderRadius.circular(isCC ? AppRadius.base - 0.5 : AppRadius.base),
                      child: card?.imageUrl != null
                          ? CardImage(imageUrl: card!.imageUrl!, fallbackText: card.displayName, fit: BoxFit.cover, card: card)
                          : Container(color: AppColors.surface))))),
              // CC badge (top-left)
              if (isCC)
                Positioned(top: -2, left: -2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text('CC', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.background)),
                )),
              // Partially missing: red ring
              if (isPartiallyMissing && !isCC)
                Positioned.fill(child: Container(decoration: BoxDecoration(
                  borderRadius: AppRadius.baseBR,
                  border: Border.all(color: AppColors.loss.withValues(alpha: 0.6), width: 1.5)))),
              // Quantity badge (bottom-left) — always visible, slightly faded when overlay active
              Positioned(bottom: 2, left: 2, child: Opacity(
                opacity: isActive ? 0.9 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: atLimit ? AppColors.loss : AppColors.amber600, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text('$qty/$maxCopies', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900))))),
              // Price badge (bottom-right) — only when getPrice is provided
              if (getPrice != null) ...[
                () {
                  final cardPrice = getPrice(e.key);
                  if (cardPrice <= 0) return const SizedBox.shrink();
                  final isMissing = isFullyMissing || isPartiallyMissing;
                  return Positioned(bottom: 2, right: 2, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: isMissing ? AppColors.amber400 : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.rounded)),
                    child: Text('€${cardPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.small.copyWith(color: isMissing ? AppColors.textOnPrimary : AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                  ));
                }(),
              ],
              // Edit overlay with +/- buttons and move button
              if (isActive)
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: AppRadius.baseBR),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Move button above +/- (M = to Main)
                    if (onMoveCard != null && moveLabel == 'M') ...[
                      GestureDetector(
                        onTap: () { onMoveCard(e.key); if (qty - 1 <= 0) setState(() => _activeCardId = null); },
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(color: AppColors.order, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                          child: Text(moveLabel!, style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900)))),
                      const SizedBox(height: AppSpacing.small),
                    ],
                    // +/- row (always centered)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      GestureDetector(
                        onTap: () { onQuantityChanged(e.key, qty - 1); if (qty - 1 <= 0) { setState(() => _activeCardId = null); } },
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(color: AppColors.loss, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                          child: Text('−', style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900)))),
                      const SizedBox(width: AppSpacing.lg),
                      GestureDetector(
                        onTap: atLimit ? null : () => onQuantityChanged(e.key, qty + 1),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(color: atLimit ? AppColors.surface : AppColors.amber500, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                          child: Text('+', style: AppTextStyles.subtitle.copyWith(color: atLimit ? AppColors.textMuted : AppColors.textPrimary, fontWeight: FontWeight.w900)))),
                    ]),
                    // Move button below +/- (S = to Side)
                    if (onMoveCard != null && moveLabel == 'S') ...[
                      const SizedBox(height: AppSpacing.small),
                      GestureDetector(
                        onTap: () { onMoveCard(e.key); if (qty - 1 <= 0) setState(() => _activeCardId = null); },
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(color: AppColors.order, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                          child: Text(moveLabel!, style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900)))),
                    ],
                  ]),
                )),
            ])),
          ]);
          }),
        );
      },
    );
  }

  Widget _buildBfRowEditable(List<DeckCard> bfs, Map<String, RiftCard> lookup, {Set<String> missingIds = const {}}) {
    final slots = <Widget>[];
    for (final bf in bfs) {
      final isMissing = missingIds.contains(bf.id);
      slots.add(Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: GestureDetector(
          onTap: _editing ? () => _openCardModal('battlefields', bfSlotIndex: bfs.indexOf(bf)) : null,
          onLongPress: () { final c = lookup[bf.id]; if (c != null) Navigator.of(context).push(CardPreviewRoute(card: c)); },
          child: Stack(children: [
            Opacity(opacity: isMissing ? 0.5 : 1.0,
              child: ColorFiltered(colorFilter: isMissing ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.rounded),
                  child: AspectRatio(aspectRatio: 1039 / 744,
                    child: bf.imageUrl != null
                        ? CardImage(imageUrl: bf.imageUrl!, fallbackText: bf.name, fit: BoxFit.cover) // bf is DeckCard, not RiftCard
                        : Container(color: AppColors.surface))))),
            // Price badge on battlefield
            if (_showCollectionStatus) ...[
              () {
                final bfPrice = _getCardMinPrice(bf.id);
                if (bfPrice <= 0) return const SizedBox.shrink();
                return Positioned(bottom: 4, right: 4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMissing ? AppColors.amber400 : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text('€${bfPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.small.copyWith(color: isMissing ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w800)),
                ));
              }(),
            ],
            // Align(topRight) statt Center → siehe Legend X (gleiche Logik).
            if (_editing) Positioned(top: 4, right: 4, child: GestureDetector(
              onTap: () => _removeBattlefield(bf.id),
              child: SizedBox(
                width: 44, height: 44, // Apple HIG touch-target minimum
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.loss),
                    // Badge icon stays pure white on loss for theme-independent contrast.
                    child: Icon(Icons.close, color: Colors.white, size: 18)),
                ),
              ))),
          ]),
        ),
      )));
    }
    if (bfs.length < 3 && _editing) {
      slots.add(Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: GestureDetector(
          // bfSlotIndex weggelassen (= null) → ADD-Modus: User kann
          // mehrere Battlefields hintereinander auswaehlen ohne das
          // Modal zwischendurch zu schliessen. bfSlotIndex wird NUR
          // beim Tap auf einen existing Slot mitgegeben (= REPLACE-Modus).
          // Vorher: bfSlotIndex: bfs.length — das brach den Multi-Select
          // weil sobald 1 Karte hinzukam, slotIdx < _localBfIds.length
          // wurde und der naechste Tap in Replace statt Add kippte.
          onTap: () => _openCardModal('battlefields'),
          child: AspectRatio(aspectRatio: 1039 / 744,
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.rounded),
                border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside)),
              child: Center(child: Icon(Icons.add, color: AppColors.textMuted, size: 24)),
            ))),
      )));
    }
    // Fill remaining space
    for (int i = bfs.length + (_editing && bfs.length < 3 ? 1 : 0); i < 3; i++) {
      slots.add(const Expanded(child: SizedBox()));
    }
    if (slots.isEmpty) return const SizedBox.shrink();
    return Row(children: slots);
  }

  void _openCardModal(String category, {int? bfSlotIndex}) {
    final initDeck = _deck; // only for initial props
    Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true,
      builder: (_) => CardSelectionModal(
        category: category, allCards: _allCards,
        selectedLegend: initDeck.legendId != null ? _allCards.where((c) => c.id == initDeck.legendId).firstOrNull : null,
        currentMainDeck: initDeck.mainDeck, currentSideboard: initDeck.sideboard,
        selectedBattlefieldIds: initDeck.battlefields.map((b) => b.id).toList(),
        bfSlotIndex: bfSlotIndex,
        chosenChampionId: initDeck.chosenChampionId,
        onLegendSelected: (card) {
          final d = _deck;
          final legendChanged = d.legendId != card.id;
          // Clear CC when legend changes (different champion needed)
          final oldCCId = legendChanged ? d.chosenChampionId : null;
          var newMainDeck = d.mainDeck;
          if (legendChanged && oldCCId != null && newMainDeck.containsKey(oldCCId)) {
            newMainDeck = Map.from(newMainDeck)..remove(oldCCId);
          }
          _updateDeck(d.copyWith(
            legendId: card.id, legendName: card.name, legendImageUrl: card.imageUrl,
            domains: List.from(card.domains),
            runeCount1: card.domains.length >= 2 ? 6 : 12,
            runeCount2: card.domains.length >= 2 ? 6 : 0,
            mainDeck: legendChanged ? newMainDeck : null,
            clearChosenChampion: legendChanged,
          ));
        },
        onConfirm: (mainDeck, sideboard, battlefieldIds) {
          final d = _deck;
          if (category == 'champion') {
            // mainDeck contains only {ccId: 1} from the champion picker
            final ccId = mainDeck.keys.firstOrNull;
            if (ccId != null) {
              final updatedMain = Map<String, int>.from(d.mainDeck);
              // Remove old CC if different
              final oldCCId = d.chosenChampionId;
              if (oldCCId != null && oldCCId != ccId && updatedMain.containsKey(oldCCId)) {
                updatedMain.remove(oldCCId);
              }
              // Add new CC
              if (!updatedMain.containsKey(ccId)) updatedMain[ccId] = 1;
              _updateDeck(d.copyWith(chosenChampionId: ccId, mainDeck: updatedMain));
            }
          } else if (category == 'battlefields') {
            final bfs = battlefieldIds.map((id) {
              final card = _allCards.firstWhere((c) => c.id == id);
              return DeckCard(id: card.id, name: card.name, imageUrl: card.imageUrl);
            }).toList();
            _updateDeck(d.copyWith(battlefields: bfs));
          } else {
            // main or side — apply both since art-stealing can cross-modify
            _updateDeck(d.copyWith(mainDeck: mainDeck, sideboard: sideboard));
          }
        },
      ),
    ));
  }

  OverlayEntry? _editorMenuOverlay;

  void _showEditorMenu(DeckData deck, BuildContext btnContext) {
    _editorMenuOverlay?.remove();
    _editorMenuOverlay = null;
    showDeckMenuSheet(context: context, items: [
      DeckMenuItem(icon: Icons.edit, label: 'Edit Info', onTap: () => _showEditInfoDialog(deck)),
      DeckMenuItem(icon: Icons.copy, label: 'Duplicate', onTap: () {
        if (_isDemo) { _demo.duplicateDeck(deck.id!); } else { _firestore.duplicateDeck(deck); }
        widget.onBack();
      }),
      const DeckMenuItem.divider(),
      DeckMenuItem(icon: Icons.description_outlined, label: 'Export Text', onTap: () {
        exportDeckText(context,
          legendName: deck.legendName, chosenChampionId: deck.chosenChampionId,
          mainDeck: deck.mainDeck, sideboard: deck.sideboard, battlefields: deck.battlefields,
          domains: deck.domains, runeCount1: deck.runeCount1, runeCount2: deck.runeCount2);
      }),
      DeckMenuItem(icon: Icons.image_outlined, label: 'Export Image', onTap: () {
        DeckImageExporter.export(context,
          deckName: deck.name, legendName: deck.legendName, legendImageUrl: deck.legendImageUrl,
          chosenChampionId: deck.chosenChampionId, mainDeck: deck.mainDeck, sideboard: deck.sideboard,
          battlefields: deck.battlefields, domains: deck.domains, runeCount1: deck.runeCount1, runeCount2: deck.runeCount2,
          authorInfo: 'by ${ProfileService.instance.ownProfile?.displayName ?? 'You'}');
      }),
      DeckMenuItem(icon: Icons.upload_file, label: 'Import', onTap: () => _showImportDialog(context)),
      const DeckMenuItem.divider(),
      DeckMenuItem(icon: Icons.delete_outline, label: 'Delete', isDestructive: true, onTap: () => _showDeleteConfirm(deck)),
    ]);
  }

  Widget _editorMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final c = isDestructive ? AppColors.loss : AppColors.textPrimary;
    return GestureDetector(
      onTap: () { _editorMenuOverlay?.remove(); _editorMenuOverlay = null; onTap(); },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppTextStyles.bodyLarge.copyWith(color: c, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
        ]),
      ),
    );
  }

  void _exportDeck(DeckData deck) {
    final lookup = CardService.getLookup();
    final buf = StringBuffer();
    // Legend
    if (deck.legendName != null) {
      buf.writeln('// Legend');
      buf.writeln('1 ${deck.legendName}');
    }
    // Champion — separate Champion units from main deck
    final championEntries = <MapEntry<String, int>>[];
    final regularEntries = <MapEntry<String, int>>[];
    for (final e in deck.mainDeck.entries) {
      final card = lookup[e.key];
      if (card != null && card.isChampion) {
        championEntries.add(MapEntry(card.name, e.value));
      } else {
        regularEntries.add(MapEntry(lookup[e.key]?.name ?? e.key, e.value));
      }
    }
    if (championEntries.isNotEmpty) {
      buf.writeln('// Champion');
      championEntries.sort((a, b) => a.key.compareTo(b.key));
      for (final e in championEntries) { buf.writeln('${e.value} ${e.key}'); }
    }
    // Runes
    if (deck.domains.isNotEmpty) {
      buf.writeln('// Runes');
      final runes = <String>[];
      runes.add('${deck.runeCount1} ${deck.domains[0]}');
      if (deck.domains.length > 1) runes.add('${deck.runeCount2} ${deck.domains[1]}');
      runes.sort((a, b) => a.substring(a.indexOf(' ')).compareTo(b.substring(b.indexOf(' '))));
      for (final r in runes) { buf.writeln(r); }
    }
    // Battlefields — sorted by name
    if (deck.battlefields.isNotEmpty) {
      buf.writeln('// Battlefields');
      final bfs = deck.battlefields.map((bf) => bf.name).toList()..sort();
      for (final name in bfs) { buf.writeln('1 $name'); }
    }
    // Main Deck — sorted by name (regular cards only, champions separated above)
    if (regularEntries.isNotEmpty) {
      buf.writeln('// Main Deck');
      regularEntries.sort((a, b) => a.key.compareTo(b.key));
      for (final e in regularEntries) { buf.writeln('${e.value} ${e.key}'); }
    }
    // Sideboard — sorted by name
    if (deck.sideboard.isNotEmpty) {
      buf.writeln('// Sideboard');
      final entries = deck.sideboard.entries.map((e) => MapEntry(lookup[e.key]?.name ?? e.key, e.value)).toList();
      entries.sort((a, b) => a.key.compareTo(b.key));
      for (final e in entries) { buf.writeln('${e.value} ${e.key}'); }
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      RiftrToast.info(context, 'Deck copied to clipboard');
    }
  }

  String _cardToTtsCode(RiftCard card) {
    final set = card.setId ?? 'UNK';
    final num = card.collectorNumberInt.toString().padLeft(3, '0');
    final variant = card.signature ? '3' : (card.alternateArt || card.overnumbered) ? '2' : '1';
    return '$set-$num-$variant';
  }

  void _exportTts(DeckData deck) {
    final lookup = CardService.getLookup();
    final codes = <String>[];

    void addCodes(String cardId, int qty) {
      final card = lookup[cardId];
      if (card == null) return;
      final code = _cardToTtsCode(card);
      for (var i = 0; i < qty; i++) { codes.add(code); }
    }

    // Legend
    if (deck.legendId != null) addCodes(deck.legendId!, 1);
    // Main Deck
    for (final e in deck.mainDeck.entries) { addCodes(e.key, e.value); }
    // Battlefields
    for (final bf in deck.battlefields) { addCodes(bf.id, 1); }
    // Runes — find rune cards by domain
    if (deck.domains.length >= 2) {
      for (var i = 0; i < 2; i++) {
        final domain = deck.domains[i];
        final count = i == 0 ? deck.runeCount1 : deck.runeCount2;
        final rune = _allCards.where((c) => c.type == 'Rune' && c.domains.contains(domain) && c.isStandard).firstOrNull;
        if (rune != null) { for (var j = 0; j < count; j++) { codes.add(_cardToTtsCode(rune)); } }
      }
    }
    // Sideboard
    for (final e in deck.sideboard.entries) { addCodes(e.key, e.value); }

    Clipboard.setData(ClipboardData(text: codes.join(' ')));
    if (mounted) {
      RiftrToast.info(context, 'TTS codes copied to clipboard');
    }
  }

  void _showDeleteConfirm(DeckData deck) {
    if (deck.id == null) return;
    showRiftrSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DELETE DECK?', style: AppTextStyles.h2.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Text('Are you sure you want to delete "${deck.name}"?', style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(child: RiftrButton(label: 'Cancel',
                onPressed: () => Navigator.pop(ctx), style: RiftrButtonStyle.secondary)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: RiftrButton(label: 'Delete', icon: Icons.delete_outline,
                onPressed: () {
                  Navigator.pop(ctx);
                  if (_isDemo) { _demo.deleteDeck(deck.id!); } else { _firestore.deleteDeck(deck.id!); }
                  widget.onBack();
                }, style: RiftrButtonStyle.danger)),
            ]),
          ],
        ),
      ),
    );
  }

  void _showEditInfoDialog(DeckData deck) {
    if (deck.id == null) return;
    final nameCtrl = TextEditingController(text: deck.name);
    final descCtrl = TextEditingController(text: deck.description ?? '');
    showRiftrSheet(
      context: context,
      builder: (ctx) => _EditDeckSheetContent(
        nameController: nameCtrl,
        descController: descCtrl,
        onSave: () {
          final name = nameCtrl.text.trim();
          if (name.isNotEmpty) {
            final desc = descCtrl.text.trim();
            _updateDeck(_deck.copyWith(name: name, description: desc.isEmpty ? null : desc));
          }
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  // --- Import ---

  static final _ttsCodePattern = RegExp(r'^[A-Z]{2,4}-\d{2,4}-\d+$');

  bool _isTtsFormat(String text) {
    final tokens = text.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return false;
    final ttsCount = tokens.where((t) => _ttsCodePattern.hasMatch(t)).length;
    return ttsCount > tokens.length * 0.5;
  }

  /// Parse TTS codes → import result
  ({RiftCard? legend, Map<String, int> runeMap, List<DeckCard> battlefields, Map<String, int> mainDeck, Map<String, int> sideboard, List<String> errors, List<String> warnings})
  _parseTts(String text) {
    // Build SET-NUM → card lookup (ignoring variant)
    final ttsLookup = <String, RiftCard>{};
    for (final card in _allCards) {
      if (card.setId == null || card.collectorNumber == null) continue;
      final key = '${card.setId}-${card.collectorNumberInt.toString().padLeft(3, '0')}';
      // Prefer standard version
      if (!ttsLookup.containsKey(key) || card.isStandard) ttsLookup[key] = card;
    }

    final codeCounts = <String, int>{};
    final unmatched = <String, int>{};
    for (final token in text.trim().split(RegExp(r'\s+'))) {
      if (!_ttsCodePattern.hasMatch(token)) continue;
      // Strip variant for lookup
      final parts = token.split('-');
      final key = '${parts[0]}-${parts[1].padLeft(3, '0')}';
      if (ttsLookup.containsKey(key)) {
        codeCounts[key] = (codeCounts[key] ?? 0) + 1;
      } else {
        unmatched[token] = (unmatched[token] ?? 0) + 1;
      }
    }

    RiftCard? legend;
    final runeMap = <String, int>{};
    final battlefields = <DeckCard>[];
    final mainDeck = <String, int>{};
    final sideboard = <String, int>{};
    final errors = <String>[];
    final warnings = <String>[];

    // Categorize cards
    int mainCount = 0;
    for (final e in codeCounts.entries) {
      final card = ttsLookup[e.key]!;
      final qty = e.value;
      if (card.type == 'Legend') {
        legend = card;
      } else if (card.type == 'Battlefield' && battlefields.length < 3) {
        battlefields.add(DeckCard(id: card.id, name: card.name, imageUrl: card.imageUrl));
      } else if (card.type == 'Rune') {
        final domain = card.domains.isNotEmpty ? card.domains.first : null;
        if (domain != null) runeMap[domain] = (runeMap[domain] ?? 0) + qty;
      } else {
        // Main deck, overflow to sideboard
        if (mainCount + qty <= 40) {
          mainDeck[card.id] = (mainDeck[card.id] ?? 0) + qty;
          mainCount += qty;
        } else {
          final toMain = 40 - mainCount;
          if (toMain > 0) { mainDeck[card.id] = (mainDeck[card.id] ?? 0) + toMain; mainCount += toMain; }
          final toSide = qty - toMain;
          if (toSide > 0) sideboard[card.id] = (sideboard[card.id] ?? 0) + toSide;
        }
      }
    }

    for (final e in unmatched.entries) {
      warnings.add('Code not found: "${e.key}" (×${e.value})');
    }
    if (codeCounts.isEmpty) errors.add('No valid TTS codes found');

    return (legend: legend, runeMap: runeMap, battlefields: battlefields, mainDeck: mainDeck, sideboard: sideboard, errors: errors, warnings: warnings);
  }

  /// Parse text format → import result
  ({RiftCard? legend, Map<String, int> runeMap, List<DeckCard> battlefields, Map<String, int> mainDeck, Map<String, int> sideboard, List<String> errors, List<String> warnings})
  _parseText(String text) {
    final lookup = CardService.getLookup();
    final nameMap = <String, RiftCard>{};
    for (final card in _allCards) { final key = card.name.toLowerCase(); if (!nameMap.containsKey(key) || card.isStandard) nameMap[key] = card; }
    const domains = ['fury', 'order', 'mind', 'chaos', 'body', 'calm'];
    RiftCard? legend;
    final runeMap = <String, int>{};
    final battlefields = <DeckCard>[];
    final mainDeck = <String, int>{};
    final sideboard = <String, int>{};
    final warnings = <String>[];
    String section = 'main';

    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Section headers
      if (trimmed.startsWith('//') || trimmed.startsWith('#') || trimmed.endsWith(':')) {
        final s = trimmed.replaceFirst(RegExp(r'^[/#]+\s*'), '').replaceFirst(RegExp(r':$'), '').toLowerCase().trim();
        if (s.contains('legend') || s.contains('champion')) { section = 'legend'; }
        else if (s.contains('rune')) { section = 'rune'; }
        else if (s.contains('battlefield')) { section = 'battlefield'; }
        else if (s.contains('side')) { section = 'side'; }
        else if (s.contains('main') || s.contains('deck')) { section = 'main'; }
        continue;
      }
      final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(trimmed);
      if (match == null) continue;
      final qty = int.tryParse(match.group(1)!) ?? 0;
      final cardName = match.group(2)!.trim();
      if (qty == 0) continue;

      switch (section) {
        case 'legend':
          final c = _fuzzyResolve(cardName, nameMap, lookup);
          if (c != null && c.isLegend) { legend = c; }
          else { warnings.add('Legend not found: "$cardName"'); }
        case 'rune':
          final d = cardName.toLowerCase().replaceAll(' rune', '');
          if (domains.contains(d)) { runeMap[d[0].toUpperCase() + d.substring(1)] = qty; }
          else { warnings.add('Unknown rune: "$cardName"'); }
        case 'battlefield':
          final c = _fuzzyResolve(cardName, nameMap, lookup);
          if (c != null && battlefields.length < 3) { battlefields.add(DeckCard(id: c.id, name: c.name, imageUrl: c.imageUrl)); }
          else if (c == null) { warnings.add('Card not found: "$cardName"'); }
        case 'side':
          final c = _fuzzyResolve(cardName, nameMap, lookup);
          if (c != null) { sideboard[c.id] = (sideboard[c.id] ?? 0) + qty; }
          else { warnings.add('Card not found: "$cardName"'); }
        default:
          final c = _fuzzyResolve(cardName, nameMap, lookup);
          if (c != null) { mainDeck[c.id] = (mainDeck[c.id] ?? 0) + qty; }
          else { warnings.add('Card not found: "$cardName"'); }
      }
    }

    final errors = <String>[];
    if (mainDeck.isEmpty && legend == null && battlefields.isEmpty) errors.add('No cards found in text');

    return (legend: legend, runeMap: runeMap, battlefields: battlefields, mainDeck: mainDeck, sideboard: sideboard, errors: errors, warnings: warnings);
  }

  void _applyImport({
    required RiftCard? legend,
    required Map<String, int> runeMap,
    required List<DeckCard> battlefields,
    required Map<String, int> mainDeck,
    required Map<String, int> sideboard,
  }) {
    final deck = _deck;
    var updated = deck;
    if (legend != null) {
      updated = updated.copyWith(legendId: legend.id, legendName: legend.name, legendImageUrl: legend.imageUrl, domains: List.from(legend.domains));
    }
    if (runeMap.isNotEmpty && updated.domains.length >= 2) {
      updated = updated.copyWith(runeCount1: runeMap[updated.domains[0]] ?? 6, runeCount2: runeMap[updated.domains[1]] ?? 6);
    }
    if (battlefields.isNotEmpty) updated = updated.copyWith(battlefields: battlefields);
    if (mainDeck.isNotEmpty || sideboard.isNotEmpty) {
      updated = updated.copyWith(
        mainDeck: mainDeck.isNotEmpty ? mainDeck : null,
        sideboard: sideboard.isNotEmpty ? sideboard : null,
      );
    }
    _updateDeck(updated);
  }

  void _showImportDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    String? previewFormat;
    RiftCard? previewLegend;
    Map<String, int> previewRunes = {};
    List<DeckCard> previewBf = [];
    Map<String, int> previewMain = {};
    Map<String, int> previewSide = {};
    List<String> previewErrors = [];
    List<String> previewWarnings = [];
    bool showPreview = false;

    showRiftrSheet(context: ctx, builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setLocal) {
        void doPreview() {
          final text = ctrl.text.trim();
          if (text.isEmpty) return;
          final isTts = _isTtsFormat(text);
          previewFormat = isTts ? 'TTS' : 'Text';
          final result = isTts ? _parseTts(text) : _parseText(text);
          previewLegend = result.legend;
          previewRunes = result.runeMap;
          previewBf = result.battlefields;
          previewMain = result.mainDeck;
          previewSide = result.sideboard;
          previewErrors = result.errors;
          previewWarnings = result.warnings;
          setLocal(() => showPreview = true);
        }

        final mainCount = previewMain.values.fold(0, (s, v) => s + v);
        final sideCount = previewSide.values.fold(0, (s, v) => s + v);
        final runeTotal = previewRunes.values.fold(0, (s, v) => s + v);

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(showPreview ? 'IMPORT PREVIEW' : 'IMPORT DECK',
              style: AppTextStyles.h2.copyWith(color: AppColors.amber400, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.lg),
            if (!showPreview) ...[
              Text('Paste a deck list or TTS codes:', style: AppTextStyles.bodySecondary),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: ctrl, maxLines: 8,
                autocorrect: false,
                enableSuggestions: false,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'OGN-036-1 OGN-052-1 ...\nor\n// Legend\n1 Annie, Dark Child',
                  hintStyle: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
                  filled: true, fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.rounded), borderSide: BorderSide.none))),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () async { final data = await Clipboard.getData(Clipboard.kTextPlain); if (data?.text != null) setLocal(() => ctrl.text = data!.text!); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppRadius.mdBR),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.paste, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Paste from clipboard', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ] else ...[
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: previewFormat == 'TTS' ? AppColors.mind.withValues(alpha: 0.2) : AppColors.order.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text(previewFormat!, style: AppTextStyles.small.copyWith(
                    color: previewFormat == 'TTS' ? AppColors.mind : AppColors.order, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppRadius.baseBR),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Legend: ${previewLegend?.displayName ?? 'None'}', style: AppTextStyles.bodySmall),
                  Text('Main Deck: $mainCount cards', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('Battlefields: ${previewBf.length}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('Runes: $runeTotal', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  if (sideCount > 0) Text('Sideboard: $sideCount cards', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
              if (previewErrors.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final e in previewErrors)
                  Padding(padding: const EdgeInsets.only(bottom: 2),
                    child: Row(children: [Icon(Icons.error, color: AppColors.loss, size: 14), SizedBox(width: AppSpacing.xs),
                      Flexible(child: Text(e, style: AppTextStyles.caption.copyWith(color: AppColors.loss)))])),
              ],
              if (previewWarnings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final w in previewWarnings)
                  Padding(padding: const EdgeInsets.only(bottom: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.warning_amber, color: AppColors.amber400, size: 14)),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(child: Text(w, style: AppTextStyles.caption.copyWith(color: AppColors.amber400)))])),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            if (!showPreview)
              Row(children: [
                Expanded(child: RiftrButton(label: 'Cancel',
                  onPressed: () => Navigator.pop(sheetCtx), style: RiftrButtonStyle.secondary)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RiftrButton(label: 'Preview',
                  onPressed: ctrl.text.trim().isNotEmpty ? doPreview : null)),
              ])
            else
              Row(children: [
                Expanded(child: RiftrButton(label: 'Back',
                  onPressed: () => setLocal(() => showPreview = false), style: RiftrButtonStyle.secondary)),
                const SizedBox(width: AppSpacing.md),
                if (previewErrors.isEmpty)
                  Expanded(child: RiftrButton(label: 'Import', icon: Icons.download,
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _applyImport(legend: previewLegend, runeMap: previewRunes, battlefields: previewBf, mainDeck: previewMain, sideboard: previewSide);
                      if (mounted) RiftrToast.success(context, 'Deck imported');
                    }))
                else
                  Expanded(child: RiftrButton(label: 'Cancel',
                    onPressed: () => Navigator.pop(sheetCtx), style: RiftrButtonStyle.secondary)),
              ]),
          ]),
        );
      },
    ));
  }

  RiftCard? _fuzzyResolve(String name, Map<String, RiftCard> nameMap, Map<String, RiftCard> lookup) {
    final exact = lookup[name]; if (exact != null) return exact;
    final lower = name.toLowerCase(); final byName = nameMap[lower]; if (byName != null) return byName;
    final clean = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();
    for (final e in nameMap.entries) { if (e.key.replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim() == clean) return e.value; }
    for (final e in nameMap.entries) { if ((e.key.contains(lower) || lower.contains(e.key)) && (e.key.length > 3 || lower.length > 3)) return e.value; }
    return null;
  }
}


/// Pulsing FAB that glows when [pulse] is true.
class _PulsingFab extends StatefulWidget {
  final bool pulse;
  final VoidCallback onTap;
  const _PulsingFab({required this.pulse, required this.onTap});

  @override
  State<_PulsingFab> createState() => _PulsingFabState();
}

class _PulsingFabState extends State<_PulsingFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween(begin: 0.5, end: 0.9).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingFab old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.pulse ? _scale.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber500,
              ),
              // FAB icon stays pure white for theme-independent contrast.
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing Shop FAB with storefront icon — navigates to Market with missing cards.
class _ShopFab extends StatefulWidget {
  final bool pulse;
  const _ShopFab({required this.pulse});

  @override
  State<_ShopFab> createState() => _ShopFabState();
}

class _ShopFabState extends State<_ShopFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween(begin: 0.4, end: 0.8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ShopFab old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.pulse ? _scale.value : 1.0,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber500,
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber600.withValues(alpha: widget.pulse ? _glow.value : 0.4),
                  blurRadius: widget.pulse ? 20 : 12,
                  spreadRadius: widget.pulse ? 3 : 1,
                ),
              ],
            ),
            // FAB icon stays pure white for theme-independent contrast.
            child: Icon(Icons.storefront, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }
}

/// Sort-button pill that visually matches RiftrPill (32dp pill-shape in 44dp
/// touch-target, same colors, same padding) but adds icon + optional trailing
/// icon slots. Used in the Decks tab so the sort button sits flush with the
/// tab pills in the same row.
class _SortPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData? trailingIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _SortPill({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? AppColors.background : AppColors.textSecondary;
    final bg = isActive ? AppColors.amber500 : AppColors.surfaceLight;
    return TapScale(
      onTap: onTap,
      child: SizedBox(
        height: 44, // Apple HIG touch-target (mirrors RiftrPill)
        child: Align(
          alignment: Alignment.center,
          child: Container(
            height: 32, // Visual pill height (mirrors RiftrPill)
            padding: AppSpacing.chipPadding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.pillBR,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon, color: fg, size: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small overlay chip showing a deck's estimated value.
///
/// The price is the sum of `CardPriceData.standardPrice × qty` across the
/// deck — a Cardmarket-aggregated TREND/MEDIAN per cardId, NOT what Smart
/// Cart will charge. Smart Cart adds shipping and uses the cheapest
/// available real listing; the gap can be substantial for foil decks
/// where listings are scarce / commanded a premium.
///
/// Long-press surfaces a Tooltip explaining the semantic so a buyer
/// doesn't read this badge as the actual buy price.
class _DeckPriceBadge extends StatelessWidget {
  final double price;
  const _DeckPriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Estimated value · Cardmarket median '
          '· excludes shipping & listing premium',
      preferBelow: false,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        // Tilde prefix = "approximate" hint that this is an estimate, not
        // an exact buy price. Subtle but readable in 10sp tiny-bold.
        child: Text('~€${price.toStringAsFixed(0)}',
            style: AppTextStyles.tiny.copyWith(
                color: AppColors.amber400, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
