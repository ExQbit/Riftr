import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/shipping_rates.dart';
import '../widgets/drag_to_dismiss.dart';
import '../theme/app_components.dart';
import '../theme/app_theme.dart';
import '../theme/riftr_theme.dart';
import '../widgets/gold_header.dart';
import '../widgets/card_image.dart';
import '../widgets/riftr_search_bar.dart';
import '../widgets/qty_stepper_row.dart';
import '../widgets/riftr_drag_handle.dart';
import '../widgets/market/checkout_sheet.dart';
import '../widgets/market/condition_badge.dart';
import 'admin_disputes_screen.dart';
import 'legal_screen.dart';
import '../widgets/market/dac7_status_banner.dart';
import '../widgets/market/seller_reclassification_sheet.dart';
import '../services/auth_service.dart';
import '../services/demo_service.dart';
import '../services/match_service.dart';
import '../services/firestore_deck_service.dart';
import '../services/firestore_collection_service.dart';
import '../services/public_deck_service.dart';
import '../services/firestore_service.dart';
import '../services/listing_service.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import '../models/market/listing_model.dart';
import '../services/follow_service.dart';
import '../services/profile_service.dart';
import '../services/seller_service.dart';
import '../services/social_helpers.dart';
import '../models/match_model.dart';
import '../models/market/seller_profile.dart';
import '../models/profile_model.dart';
import '../services/card_service.dart';
import '../widgets/riftr_toast.dart';
import '../models/public_deck_model.dart';

class SocialScreen extends StatefulWidget {
  final VoidCallback? onGoToPublicDecks;
  final void Function(PublicDeckData deck)? onViewPublicDeck;
  const SocialScreen({super.key, this.onGoToPublicDecks, this.onViewPublicDeck});

  @override
  State<SocialScreen> createState() => SocialScreenState();
}

// Public state so main.dart can call navigateToAuthor


class SocialScreenState extends State<SocialScreen> {
  // View state: 'home' | 'editProfile' | 'author'
  String _view = 'home';
  String? _selectedAuthorId;
  String? _selectedAuthorName;

  // Edit profile controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  // Address fields editable from Edit Profile (2026-05-01).
  // Single source of truth = UserProfile; on save we also mirror to
  // SellerProfile.address so the DSA imprint stays in sync.
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _avatarController = TextEditingController();
  String? _selectedCountry;

  // Name change uniqueness check
  Timer? _nameDebounce;
  String _nameStatus = ''; // '', 'checking', 'available', 'taken', 'short'
  String? _originalName; // name when edit started, to detect changes

  // Player search
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  // Privacy toggles (for edit profile)
  bool _privacyWinRate = true;
  bool _privacyCollection = true;
  bool _privacyMatchCount = true;

  // Collection expanded state
  bool _collectionExpanded = false;

  bool get _isDemo => DemoService.instance.isActive;

  /// Called from main.dart to navigate to an author profile
  void navigateToAuthor(String authorId, String authorName) {
    setState(() {
      _selectedAuthorId = authorId;
      _selectedAuthorName = authorName;
      _view = 'author';
    });
  }

  // Admin-Claim Cache. Async-evaluated in initState; null waehrend
  // Token-Read laeuft, true/false danach. Phase 6.5 Admin-Tools sind nur
  // fuer Admin-User sichtbar (Custom-Claim `admin: true`).
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    PublicDeckService.instance.addListener(_refresh);
    FollowService.instance.addListener(_refresh);
    ProfileService.instance.addListener(_refresh);
    MatchService.instance.addListener(_refresh);
    FirestoreDeckService.instance.addListener(_refresh);
    FirestoreCollectionService.instance.addListener(_refresh);
    ListingService.instance.addListener(_refresh);
    CartService.instance.addListener(_refresh);
    // DAC7-Banner + Switch-to-commercial-Button reagieren auf
    // sellerProfile-Aenderungen (z.B. nach Reclass-Sheet).
    SellerService.instance.addListener(_refresh);
    // Fetch profiles for followed users
    _fetchFollowingProfiles();
    // Async admin-claim evaluation
    _checkAdminClaim();
  }

  Future<void> _checkAdminClaim() async {
    if (_isDemo) return;
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;
      final tokenResult = await user.getIdTokenResult();
      final isAdmin = tokenResult.claims?['admin'] == true;
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (e) {
      // Token-Read fail: assume not-admin, no UI shown.
      if (mounted) setState(() => _isAdmin = false);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
    _fetchFollowingProfiles();
  }

  void _fetchFollowingProfiles() {
    if (_isDemo) return;
    final following = FollowService.instance.myFollowing;
    if (following.isNotEmpty) {
      ProfileService.instance.fetchProfiles(following);
    }
  }

  /// Resolve the avatar URL for any other user shown in Social Tab lists
  /// (followed-users, search results, etc).
  ///
  /// Preference order — matches the Author-Profile-Page behavior where
  /// the main-legend image takes priority over a user-set avatar URL:
  /// 1. **Legend image from user's most recent public deck** (auto-avatar).
  ///    Uses PublicDeckService (already loaded, no extra fetch). This is a
  ///    lighter approximation of SocialHelpers.mainLegend() which needs
  ///    match history — too expensive for list views.
  /// 2. Explicit `avatarUrl` from playerProfiles mirror (search results).
  /// 3. Cached full profile avatarUrl from `users/{uid}/data/profile`.
  /// 4. On-demand fetch + placeholder; widget refreshes via ProfileService
  ///    listener when cache populates.
  String? _avatarForUser(String uid, {String? mirrorAvatar}) {
    // Auto-avatar: legend image from user's public decks
    final authorDecks = PublicDeckService.instance.decksByAuthor(uid);
    if (authorDecks.isNotEmpty) {
      final legendImg = authorDecks.first.legendImageUrl;
      if (legendImg != null && legendImg.isNotEmpty) return legendImg;
    }
    // User-set avatar (mirror first, then full profile cache)
    if (mirrorAvatar != null && mirrorAvatar.isNotEmpty) return mirrorAvatar;
    final cached = ProfileService.instance.getCachedProfile(uid);
    if (cached?.avatarUrl != null && cached!.avatarUrl!.isNotEmpty) {
      return cached.avatarUrl;
    }
    // On-demand fetch for legacy users (mirror didn't have avatarUrl yet).
    // Idempotent — ProfileService._fetched de-dups.
    if (!_isDemo) ProfileService.instance.fetchProfiles([uid]);
    return null;
  }

  void _onNameChanged(String value) {
    _nameDebounce?.cancel();
    final trimmed = value.trim();
    // No change from original → no check needed
    if (trimmed == _originalName) {
      setState(() => _nameStatus = '');
      return;
    }
    if (trimmed.length < 3) {
      setState(() => _nameStatus = 'short');
      return;
    }
    setState(() => _nameStatus = 'checking');
    _nameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final snap = await FirestoreService.instance
            .globalCollection('playerProfiles')
            .where('displayNameLower', isEqualTo: trimmed.toLowerCase())
            .limit(1)
            .get();
        final uid = AuthService.instance.uid;
        final taken = snap.docs.any((d) => d.id != uid);
        if (mounted) setState(() => _nameStatus = taken ? 'taken' : 'available');
      } catch (_) {
        if (mounted) setState(() => _nameStatus = 'available');
      }
    });
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _nameController.dispose();
    _bioController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _avatarController.dispose();
    _searchController.dispose();
    PublicDeckService.instance.removeListener(_refresh);
    FollowService.instance.removeListener(_refresh);
    ProfileService.instance.removeListener(_refresh);
    MatchService.instance.removeListener(_refresh);
    FirestoreDeckService.instance.removeListener(_refresh);
    FirestoreCollectionService.instance.removeListener(_refresh);
    ListingService.instance.removeListener(_refresh);
    CartService.instance.removeListener(_refresh);
    SellerService.instance.removeListener(_refresh);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      'editProfile' => _buildEditProfile(),
      'author' => _buildAuthorProfile(),
      _ => _buildHome(),
    };
  }

  // ───── HOME VIEW ─────

  Widget _buildHome() {
    final user = AuthService.instance.currentUser;
    final profile = ProfileService.instance.ownProfile;
    final name = _isDemo
        ? 'Demo User'
        : (profile?.displayName ?? user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous');

    // Computed data
    final matches = _isDemo ? <dynamic>[] : MatchService.instance.matches;
    final decks = _isDemo ? <dynamic>[] : FirestoreDeckService.instance.decks;
    final legend = SocialHelpers.mainLegend(
      matches.cast(), decks.cast());
    final wr = SocialHelpers.winRate(matches.cast());
    final cards = _isDemo ? <String, int>{} : FirestoreCollectionService.instance.cards;
    final foilCards = _isDemo ? <String, int>{} : FirestoreCollectionService.instance.foils;
    final bySet = SocialHelpers.collectionBySet(cards, foilCards);
    final collectionPct = SocialHelpers.totalCollectionPercent(bySet);
    final checkItems = SocialHelpers.checklist(
      matchCount: matches.length,
      uniqueOwned: _isDemo ? 0 : FirestoreCollectionService.instance.uniqueOwned,
      deckCount: decks.length,
    );
    final showCheck = SocialHelpers.showChecklist(checkItems);
    final sellerProfile = _isDemo ? null : SellerService.instance.profile;
    final badgeList = SocialHelpers.badges(
      memberSince: profile?.createdAt ?? user?.metadata.creationTime,
      collectionBySet: bySet,
      sellerProfile: sellerProfile,
    );
    final followingCount = FollowService.instance.myFollowing.length;

    final followerCount = _isDemo ? 0 : FollowService.instance.getFollowerCount(AuthService.instance.uid ?? '');

    // Location string
    final locationParts = <String>[];
    if (profile?.city != null && profile!.city!.isNotEmpty) locationParts.add(profile.city!);
    if (profile?.country != null && profile!.country!.isNotEmpty) locationParts.add(profile.country!);
    final memberSince = user?.metadata.creationTime;
    final sinceLabel = memberSince != null
        ? 'Since ${_monthName(memberSince.month)} ${memberSince.year}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(children: [
        const GoldOrnamentHeader(title: 'UNITE THE LEGENDS'),

        // ── Profile Card ──
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: RiftrCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(children: [

              // Avatar (Legend artwork or placeholder)
              _buildLegendAvatar(legend.imageUrl, name, 96),
              const SizedBox(height: AppSpacing.md),

              // Username
              Text(name, style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
              const SizedBox(height: 2),

              // Main Legend or "New summoner"
              Text(
                legend.name != null ? '${legend.name} main' : 'New summoner',
                style: AppTextStyles.bodySmall.copyWith(
                  color: legend.name != null ? AppColors.amber400 : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              // Location + Member since
              if (locationParts.isNotEmpty || sinceLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  [if (locationParts.isNotEmpty) locationParts.join(', '), if (sinceLabel != null) sinceLabel].join(' · '),
                  style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.base),

              // Stats Grid (3 cards) — social-relevant metrics
              Row(children: [
                ..._buildStatsSlots(
                  matchCount: matches.length,
                  winRate: wr,
                  followerCount: followerCount,
                  sellerProfile: sellerProfile,
                  collectionPct: collectionPct,
                  deckCount: decks.length,
                ),
              ]),

              // Get Started Checklist
              if (showCheck) ...[
                const SizedBox(height: AppSpacing.base),
                _buildChecklist(checkItems),
              ],

              // Collection Progress Bars
              if (bySet.isNotEmpty && !showCheck) ...[
                const SizedBox(height: AppSpacing.base),
                _buildCollectionBars(bySet),
              ],

              // Badges
              if (badgeList.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                _buildBadges(badgeList),
              ],

              const SizedBox(height: AppSpacing.base),

              // DAC7 / PStTG status banner — prominent for sellers near
              // or at the threshold. Renders nothing for users without a
              // seller profile or commercial sellers (exempt).
              if (!_isDemo && SellerService.instance.profile != null) ...[
                Dac7StatusBanner(
                  seller: SellerService.instance.profile!,
                ),
                const SizedBox(height: AppSpacing.base),
              ],

              // Theme toggle — hidden for now, infrastructure kept for later
              // TODO: Re-enable when Fire & Gold theme is ready

              // Buttons
              Row(children: [
                Expanded(child: RiftrButton(
                  label: 'Edit Profile',
                  onPressed: () {
                    final p = ProfileService.instance.ownProfile;
                    _nameController.text = p?.displayName ?? user?.displayName ?? '';
                    _bioController.text = p?.bio ?? '';
                    _avatarController.text = p?.avatarUrl ?? '';
                    _selectedCountry = p?.country;
                    _streetController.text = p?.street ?? '';
                    _cityController.text = p?.city ?? '';
                    _zipController.text = p?.zip ?? '';
                    _privacyWinRate = p?.isWinRateVisible ?? true;
                    _privacyCollection = p?.isCollectionVisible ?? true;
                    _privacyMatchCount = p?.isMatchCountVisible ?? true;
                    _originalName = _nameController.text.trim();
                    _nameStatus = '';
                    setState(() => _view = 'editProfile');
                  },
                  style: RiftrButtonStyle.secondary,
                  icon: Icons.edit,
                )),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RiftrButton(
                  label: _isDemo ? 'Exit Demo' : 'Logout',
                  onPressed: () => _handleLogout(context, _isDemo),
                  style: RiftrButtonStyle.danger,
                  icon: _isDemo ? Icons.exit_to_app : Icons.logout,
                )),
              ]),

              // Switch to commercial: nur sichtbar wenn ein SellerProfile
              // existiert und der User aktuell als privat eingestuft ist.
              // Self-Reclassification (BACKLOG Ticket 4) — keine stille
              // Re-Klassifizierung durch Riftr (§ 308 Nr. 4 BGB).
              if (!_isDemo &&
                  SellerService.instance.profile != null &&
                  SellerService.instance.profile!.isCommercialSeller ==
                      false) ...[
                const SizedBox(height: AppSpacing.sm),
                RiftrButton(
                  label: 'Switch to commercial seller',
                  icon: Icons.business_outlined,
                  style: RiftrButtonStyle.secondary,
                  onPressed: () async {
                    final ok = await SellerReclassificationSheet.show(
                        context);
                    if (ok == true && mounted) setState(() {});
                  },
                ),
              ],

              // Rechtliches: AGB / Widerrufsbelehrung / Datenschutz.
              // Pflicht-Einstieg fuer Anlage 1 zu Art. 246a § 1 Abs. 2 EGBGB
              // (Widerrufsbelehrung muss eindeutig auffindbar sein).
              const SizedBox(height: AppSpacing.sm),
              RiftrButton(
                label: 'Legal',
                icon: Icons.gavel_outlined,
                style: RiftrButtonStyle.secondary,
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => const LegalScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                },
              ),

              // Admin-only: Mediation-Tools-Button (Phase 6.5).
              // Sichtbar nur fuer User mit Firebase-Auth-Custom-Claim
              // `admin: true`. _isAdmin wird async in initState evaluated.
              if (_isAdmin == true) ...[
                const SizedBox(height: AppSpacing.sm),
                RiftrButton(
                  label: 'Admin: Open Disputes',
                  icon: Icons.gavel,
                  style: RiftrButtonStyle.secondary,
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => const AdminDisputesScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 200),
                      ),
                    );
                  },
                ),
              ],
            ]),
          ),
        ),

        // ── Player Search ──
        if (!_isDemo) _buildSearchSection(),

        // ── Following Section ──
        if (followingCount > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.favorite, color: AppColors.amber400, size: 16),
              const SizedBox(width: 6),
              Text('FOLLOWING ($followingCount)', style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ]),
          ),
          ...FollowService.instance.myFollowing.map((followedId) {
            final fProfile = ProfileService.instance.getCachedProfile(followedId);
            final demoDecks = _isDemo ? DemoService.instance.publicDecks.where((d) => d.authorId == followedId).toList() : <dynamic>[];
            final displayName = _isDemo
                ? (demoDecks.isNotEmpty ? demoDecks.first.authorName : 'Unknown')
                : (fProfile?.displayName ?? 'Unknown');
            final deckCount = _isDemo ? demoDecks.length : PublicDeckService.instance.decksByAuthor(followedId).length;
            final followers = FollowService.instance.getFollowerCount(followedId);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: RiftrCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                onTap: () => setState(() {
                  _selectedAuthorId = followedId;
                  _selectedAuthorName = displayName;
                  _view = 'author';
                }),
                child: Row(children: [
                  // Auto-avatar: legend-image from user's public decks with
                  // user-set avatarUrl as fallback. Matches Author-Profile-Page.
                  _buildLegendAvatar(_avatarForUser(followedId, mirrorAvatar: fProfile?.avatarUrl), displayName, 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(displayName, style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('$deckCount decks · $followers followers', style: AppTextStyles.tiny.copyWith(
                      color: AppColors.textMuted)),
                  ])),
                  Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                ]),
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: AppSpacing.xxxl),
          RiftrEmptyState(
            icon: Icons.people,
            title: 'Discover Players',
            subtitle: 'Browse Public Decks to find and follow other players',
            buttonLabel: 'Browse Public Decks',
            onButtonPressed: widget.onGoToPublicDecks,
          ),
        ],
      ]),
    );
  }

  // ── Home Sub-Widgets ──────────────────────────────

  Widget _buildLegendAvatar(String? imageUrl, String name, double size) {
    final placeholder = Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(Icons.person, size: size * 0.4, color: AppColors.amber400),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.amber500, width: 2.5),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            // Image.network with errorBuilder → same person-icon placeholder
            // if the URL 404s / blocks / times out. Avoids the generic
            // CardImage text-fallback that would render the card name.
            ? Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              )
            : placeholder,
      ),
    );
  }

  Widget _statCard(String value, String label, {Color? valueColor, IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.mdBR,
        ),
        child: Column(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(value, style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppColors.textPrimary,
            )),
            if (icon != null) ...[
              const SizedBox(width: 3),
              Icon(icon, size: 14, color: valueColor ?? AppColors.textPrimary),
            ],
          ]),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.micro.copyWith(
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  /// Build the 3 stat slots based on user context.
  List<Widget> _buildStatsSlots({
    required int matchCount,
    required double winRate,
    required int followerCount,
    required SellerProfile? sellerProfile,
    required double collectionPct,
    required int deckCount,
  }) {
    final hasSeller = sellerProfile != null && sellerProfile.reviewCount > 0;
    final ratingStr = hasSeller
        ? sellerProfile.rating.toStringAsFixed(1)
        : null;

    if (matchCount > 0 && hasSeller) {
      // Matches | Win Rate | Rating
      return [
        _statCard('$matchCount', 'matches'),
        const SizedBox(width: AppSpacing.sm),
        _statCard('${winRate.round()}%', 'win rate',
            valueColor: SocialHelpers.winRateColor(winRate)),
        const SizedBox(width: AppSpacing.sm),
        _statCard(ratingStr!, 'rating', valueColor: AppColors.amber400, icon: Icons.star),
      ];
    }
    if (matchCount > 0) {
      // Matches | Win Rate | Followers
      return [
        _statCard('$matchCount', 'matches'),
        const SizedBox(width: AppSpacing.sm),
        _statCard('${winRate.round()}%', 'win rate',
            valueColor: SocialHelpers.winRateColor(winRate)),
        const SizedBox(width: AppSpacing.sm),
        _statCard('$followerCount', 'followers'),
      ];
    }
    if (hasSeller) {
      // Cards | Rating | Followers
      return [
        _statCard('${collectionPct.round()}%', 'collection'),
        const SizedBox(width: AppSpacing.sm),
        _statCard(ratingStr!, 'rating', valueColor: AppColors.amber400, icon: Icons.star),
        const SizedBox(width: AppSpacing.sm),
        _statCard('$followerCount', 'followers'),
      ];
    }
    // Day-1: Matches | Collection | Decks
    return [
      _statCard('$matchCount', 'matches'),
      const SizedBox(width: AppSpacing.sm),
      _statCard('${collectionPct.round()}%', 'collection'),
      const SizedBox(width: AppSpacing.sm),
      _statCard('$deckCount', 'decks'),
    ];
  }

  Widget _buildChecklist(List<({String label, bool done})> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.baseBR,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GET STARTED', style: AppTextStyles.sectionLabel.copyWith(
          color: AppColors.amber400)),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.done ? AppColors.amber500 : Colors.transparent,
                border: Border.all(
                  color: item.done ? AppColors.amber500 : AppColors.textMuted,
                  width: 1.5),
              ),
              child: item.done
                  ? Icon(Icons.check, size: 12, color: AppColors.background)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              item.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: item.done ? AppColors.textMuted : AppColors.textPrimary,
                decoration: item.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildCollectionBars(
      Map<String, ({int owned, int total, double percent})> bySet) {
    final order = ['OGN', 'SFD', 'OGS', 'UNL'];
    final sorted = order.where((s) => bySet.containsKey(s)).toList();
    final totalPct = SocialHelpers.totalCollectionPercent(bySet);

    return GestureDetector(
      onTap: () => setState(() => _collectionExpanded = !_collectionExpanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.baseBR,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row (always visible)
          Row(children: [
            Text('COLLECTION', style: AppTextStyles.sectionLabel.copyWith(
              color: AppColors.textSecondary)),
            const Spacer(),
            Text('${totalPct.round()}%', style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(width: AppSpacing.xs),
            AnimatedRotation(
              turns: _collectionExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down,
                size: 18, color: AppColors.textMuted),
            ),
          ]),
          // Expandable set bars
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(children: sorted.map((setId) {
                final data = bySet[setId]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(children: [
                    SizedBox(width: 32, child: Text(setId,
                      style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w700))),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.xsBR,
                        child: LinearProgressIndicator(
                          value: (data.percent / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(AppColors.amber500),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(width: 36, child: Text('${data.percent.round()}%',
                      style: AppTextStyles.tiny.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.right)),
                  ]),
                );
              }).toList()),
            ),
            crossFadeState: _collectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ]),
      ),
    );
  }


  Widget _buildBadges(List<({String label, Color bgColor, Color textColor})> badges) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: badges.map((b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: b.bgColor,
          borderRadius: AppRadius.pillBR,
        ),
        child: Text(b.label, style: AppTextStyles.tiny.copyWith(
          color: b.textColor, fontWeight: FontWeight.w700)),
      )).toList(),
    );
  }

  String _monthName(int month) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][month];

  // ── Player Search ──────────────────────────────────

  Timer? _searchDebounce;

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.length < 2) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    _searching = true;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    try {
      final snap = await FirestoreService.instance
          .globalCollection('playerProfiles')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      if (!mounted) return;
      final uid = AuthService.instance.uid;
      final results = snap.docs
          .where((doc) => doc.id != uid) // exclude self
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();

      setState(() { _searchResults = results; _searching = false; });
    } catch (e) {
      if (mounted) setState(() { _searchResults = []; _searching = false; });
    }
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(children: [
        // Search bar
        RiftrSearchBar(
          controller: _searchController,
          hintText: 'Search players...',
          onChanged: _onSearchChanged,
          onClear: () => _onSearchChanged(''),
        ),

        // Results
        if (_searching)
          Padding(
            padding: EdgeInsets.all(AppSpacing.base),
            child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber400)),
          )
        else if (_searchController.text.length >= 2 && _searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Text('No players found', style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
          )
        else
          ...List.generate(_searchResults.length, (i) {
            final r = _searchResults[i];
            final rUid = r['uid'] as String;
            final rName = r['displayName'] as String? ?? 'Unknown';
            final rCity = r['city'] as String?;
            final rCountry = r['country'] as String?;
            final locationStr = [if (rCity != null) rCity, if (rCountry != null) rCountry].join(', ');
            final isFollowing = FollowService.instance.isFollowing(rUid);

            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: RiftrCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                onTap: () => setState(() {
                  _selectedAuthorId = rUid;
                  _selectedAuthorName = rName;
                  _view = 'author';
                }),
                child: Row(children: [
                  // Auto-avatar: legend-image from user's public decks with
                  // user-set avatarUrl as fallback. Matches Author-Profile-Page.
                  _buildLegendAvatar(_avatarForUser(rUid, mirrorAvatar: r['avatarUrl'] as String?), rName, 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rName, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800)),
                    if (locationStr.isNotEmpty)
                      Text(locationStr, style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted)),
                  ])),
                  // 44dp touch-target (Apple HIG); visual pill stays compact.
                  SizedBox(
                    height: 44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (isFollowing) {
                          await FollowService.instance.unfollow(rUid);
                        } else {
                          await FollowService.instance.follow(rUid);
                        }
                        if (mounted) setState(() {});
                      },
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: isFollowing ? AppColors.surfaceLight : AppColors.amber500,
                            borderRadius: AppRadius.pillBR,
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: AppTextStyles.tiny.copyWith(
                              color: isFollowing ? AppColors.textMuted : AppColors.background,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }),
      ]),
    );
  }

  // ───── EDIT PROFILE VIEW ─────

  Widget _buildEditProfile() {
    return DragToDismiss(
      onDismissed: () => setState(() => _view = 'home'),
      backgroundColor: AppColors.background,
      child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxxl, top: AppSpacing.base),
      child: Column(children: [
        // Drag handle
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
          child: Center(child: Text('Edit Profile', style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w900))),
        ),

        // Avatar preview
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          child: _buildAvatar(
            _avatarController.text.isNotEmpty ? _avatarController.text : null,
            (_nameController.text.isNotEmpty ? _nameController.text[0] : '?').toUpperCase(),
            80,
          ),
        ),

        // Fields
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Column(children: [
            // Avatar URL
            _buildField('Avatar URL', _avatarController, hintText: 'Paste image URL'),
            const SizedBox(height: AppSpacing.base),
            // Display Name (1x changeable, then locked)
            _buildNameField(),
            const SizedBox(height: AppSpacing.base),
            // Bio
            _buildField('Bio', _bioController, maxLength: 150, maxLines: 3),
            const SizedBox(height: AppSpacing.base),
            // Country
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Country', style: AppTextStyles.bodySmallSecondary.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.baseBR,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    hint: Text('Select country', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                    style: AppTextStyles.body,
                    items: ShippingRates.countries.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text('${_countryFlag(e.key)} ${e.value}')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCountry = v),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            // Address (used for shipping + DSA-imprint at commercial sellers).
            // 2026-05-01: BACKLOG Ticket — mirror to sellerProfile.address
            // on save, so the public imprint stays in sync.
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Address',
                style: AppTextStyles.bodySmallSecondary
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildField('Street', _streetController, hintText: 'Street'),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: _buildField('City', _cityController,
                      hintText: 'City'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildField('ZIP', _zipController, hintText: 'ZIP'),
                ),
              ]),
              if (SellerService.instance.profile?.isCommercialSeller ==
                  true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your address is publicly visible in the seller imprint '
                  '(§ 5 DDG / Art. 30 DSA).',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ]),
            const SizedBox(height: AppSpacing.lg),
            // Privacy toggles
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Privacy', style: AppTextStyles.bodySmallSecondary.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              _privacyToggle('Show Win Rate', _privacyWinRate, (v) => setState(() => _privacyWinRate = v)),
              _privacyToggle('Show Collection Progress', _privacyCollection, (v) => setState(() => _privacyCollection = v)),
              _privacyToggle('Show Match Count', _privacyMatchCount, (v) => setState(() => _privacyMatchCount = v)),
            ]),
            const SizedBox(height: AppSpacing.lg),
            // Save button
            RiftrButton(
              label: 'Save',
              onPressed: _saveProfile,
            ),
          ]),
        ),
      ]),
    ));
  }

  Widget _buildNameField() {
    final profile = ProfileService.instance.ownProfile;
    final canChange = (profile?.nameChangesLeft ?? 1) > 0;
    final nameChanged = _nameController.text.trim() != _originalName;

    if (!canChange) {
      // Locked — read-only with hint
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Display Name', style: AppTextStyles.bodySmallSecondary.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.baseBR,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Expanded(child: Text(_nameController.text,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
            Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
          ]),
        ),
        const SizedBox(height: 4),
        Text('Contact support to change your name',
          style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
      ]);
    }

    // Editable with uniqueness check
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Display Name', style: AppTextStyles.bodySmallSecondary.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('1 change remaining',
          style: AppTextStyles.small.copyWith(color: AppColors.amber400)),
      ]),
      const SizedBox(height: 6),
      TextField(
        autocorrect: false,
        enableSuggestions: false,
        controller: _nameController,
        maxLength: 20,
        onChanged: _onNameChanged,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]'))],
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
          suffixIcon: !nameChanged ? null : switch (_nameStatus) {
            'checking' => Padding(
              padding: EdgeInsets.all(AppSpacing.base),
              child: SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted))),
            'available' => Icon(Icons.check_circle, color: AppColors.success, size: 20),
            'taken' => Icon(Icons.cancel, color: AppColors.error, size: 20),
            _ => null,
          },
          border: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide(color: AppColors.amber400, width: 1.5)),
        ),
      ),
      const SizedBox(height: 4),
      if (nameChanged && _nameStatus == 'taken')
        Text('Already taken', style: AppTextStyles.small.copyWith(color: AppColors.error))
      else if (nameChanged && _nameStatus == 'short')
        Text('Min 3 characters', style: AppTextStyles.small.copyWith(color: AppColors.error))
      else if (nameChanged && _nameStatus == 'available')
        Text('Available', style: AppTextStyles.small.copyWith(color: AppColors.success))
      else
        const SizedBox(height: AppSpacing.base),
    ]);
  }

  Widget _buildField(String label, TextEditingController controller, {
    int? maxLength, int maxLines = 1, String? hintText,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: AppTextStyles.bodySmallSecondary.copyWith(fontWeight: FontWeight.bold)),
        if (maxLength != null) ...[
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, _a, _b) => Text('${controller.text.length}/$maxLength',
              style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
          ),
        ],
      ]),
      const SizedBox(height: 6),
      TextField(
        autocorrect: false,
        enableSuggestions: false,
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.textMuted),
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
          border: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: AppRadius.baseBR, borderSide: BorderSide(color: AppColors.amber400)),
        ),
        onChanged: maxLength == null && label == 'Avatar URL' ? (_) => setState(() {}) : null,
      ),
    ]);
  }

  /// Quick-buy bottom sheet for a FOR SALE listing — stays in Social Tab.
  void _showListingQuickBuy(MarketListing listing) {
    final buyerCountry = ProfileService.instance.ownProfile?.country;
    final maxQty = listing.availableQty;
    var selectedQty = 1;
    showRiftrSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final unitPrice = listing.price;
          // Bundle = qty × unit-price. Drives both the per-tier card-cap
          // upgrade (count) AND Cardmarket's >€25 tracked-required rule.
          final bundleValue = unitPrice * selectedQty;
          final shipping = buyerCountry != null && listing.sellerCountry != null
              ? (ShippingRates.quoteForBundle(
                      listing.sellerCountry!,
                      buyerCountry,
                      cardCount: selectedQty,
                      insuredOnly: listing.insuredOnly,
                      forceTracked:
                          ShippingRates.requiresTracking(bundleValue: bundleValue),
                      bundleValue: bundleValue,
                    )?.price ??
                  1.80)
              : 1.80;
          final totalPrice = bundleValue + shipping;
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: CardImage(
                    imageUrl: listing.imageUrl,
                    fallbackText: listing.cardName,
                    width: 140,
                    height: 196,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                // Name
                Text(listing.cardName, style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                // Set + Condition + Language
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ConditionBadge(condition: listing.condition),
                  const SizedBox(width: 6),
                  Text(listing.language == 'CN' ? '🇨🇳' : '🇬🇧', style: AppTextStyles.bodyLarge),
                  if (maxQty > 1) ...[
                    const SizedBox(width: 6),
                    Text('×$maxQty available',
                      style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  ],
                ]),
                const SizedBox(height: AppSpacing.md),
                // Price
                Text('€${unitPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                // Seller info
                Text('${listing.sellerName} · ${listing.sellerCountry != null ? _countryFlag(listing.sellerCountry!) : ''}',
                  style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
                // Quantity selector (only when seller has >1).
                // Uses shared QtyStepperRow with showTrashAtOne: false —
                // quick-buy never deletes, just clamps at minimum 1.
                if (maxQty > 1) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: QtyStepperRow(
                      quantity: selectedQty,
                      showTrashAtOne: false,
                      onDecrement: selectedQty > 1
                          ? () => setSheetState(() => selectedQty--)
                          : null,
                      onIncrement: selectedQty < maxQty
                          ? () => setSheetState(() => selectedQty++)
                          : null,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                // Buy now → opens CheckoutSheet (Card-Preview pattern push)
                RiftrButton(
                  label: 'Buy now · €${totalPrice.toStringAsFixed(2)}',
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        transitionDuration: const Duration(milliseconds: 200),
                        reverseTransitionDuration:
                            const Duration(milliseconds: 150),
                        pageBuilder: (c, anim, secondaryAnim) => CheckoutSheet(
                            listing: listing, initialQuantity: selectedQty),
                        transitionsBuilder: (c, anim, secondaryAnim, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // Add to cart
                RiftrButton(
                  label: selectedQty > 1 ? 'Add $selectedQty to cart' : 'Add to cart',
                  style: RiftrButtonStyle.secondary,
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await CartService.instance.addItem(
                      CartItem.fromListing(listing, quantity: selectedQty),
                    );
                    if (mounted) {
                      if (ok) {
                        RiftrToast.cart(context, 'Added to cart');
                      } else {
                        RiftrToast.error(context, 'Not available');
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _privacyToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.amber400,
        ),
      ]),
    );
  }

  static String _countryFlag(String code) =>
      code.toUpperCase().codeUnits.map((c) => String.fromCharCode(0x1F1E6 - 0x41 + c)).join();

  Future<void> _saveProfile() async {
    final existing = ProfileService.instance.ownProfile;
    final newName = _nameController.text.trim();
    final nameChanged = newName != _originalName;

    // Block save if name changed but not available
    if (nameChanged && _nameStatus != 'available') {
      RiftrToast.error(context, 'Please choose an available name');
      return;
    }

    // Set createdAt once (from Firebase Auth creation time, or now as fallback)
    final createdAt = existing?.createdAt ??
        AuthService.instance.currentUser?.metadata.creationTime ??
        DateTime.now();

    // Decrement nameChangesLeft if name was changed
    final currentChanges = existing?.nameChangesLeft ?? 1;
    final newChangesLeft = nameChanged ? (currentChanges - 1).clamp(0, 99) : currentChanges;

    final newStreet = _streetController.text.trim();
    final newCity = _cityController.text.trim();
    final newZip = _zipController.text.trim();

    final profile = (existing ?? const UserProfile()).copyWith(
      displayName: newName,
      bio: _bioController.text.trim(),
      avatarUrl: _avatarController.text.trim().isEmpty ? null : _avatarController.text.trim(),
      country: _selectedCountry,
      street: newStreet.isEmpty ? null : newStreet,
      city: newCity.isEmpty ? null : newCity,
      zip: newZip.isEmpty ? null : newZip,
      nameChangesLeft: newChangesLeft,
      showWinRate: _privacyWinRate,
      showCollectionProgress: _privacyCollection,
      showMatchCount: _privacyMatchCount,
      createdAt: createdAt,
    );
    if (!_isDemo) {
      await ProfileService.instance.updateProfile(profile);

      // Mirror address to sellerProfile.address if the user is already a
      // seller — keeps DSA imprint in sync without forcing the user to
      // re-do seller onboarding (BACKLOG Pre-Launch Legal Track).
      final seller = SellerService.instance.profile;
      if (seller != null &&
          newStreet.isNotEmpty &&
          newCity.isNotEmpty &&
          newZip.isNotEmpty &&
          _selectedCountry != null) {
        final newAddress = SellerAddress(
          name: seller.address?.name ?? newName,
          street: newStreet,
          city: newCity,
          zip: newZip,
          country: _selectedCountry!,
        );
        await SellerService.instance.saveProfile(
          displayName: seller.displayName ?? newName,
          email: seller.email ?? '',
          address: newAddress,
          isCommercialSeller: seller.isCommercialSeller,
          vatId: seller.vatId,
          legalEntityName: seller.legalEntityName,
        );
      }
    }
    if (mounted) {
      setState(() => _view = 'home');
      RiftrToast.success(context, 'Profile updated!');
    }
  }

  // ───── AUTHOR PROFILE VIEW ─────

  // Cache for author data (loaded once per navigation)
  Map<String, dynamic>? _authorData;
  String? _authorDataId;

  Future<void> _loadAuthorData(String authorId) async {
    if (_authorDataId == authorId && _authorData != null) return;
    _authorDataId = authorId;
    _collectionExpanded = false; // Reset for each author

    final data = <String, dynamic>{};

    // Matches (for win rate + main legend)
    try {
      final matchSnap = await FirestoreService.instance
          .otherUserCollection(authorId, 'matches')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();
      data['matches'] = matchSnap.docs
          .map((d) => MatchData.fromFirestore(d))
          .toList();
    } catch (_) {
      data['matches'] = <MatchData>[];
    }

    // Collection
    try {
      final colDoc = await FirestoreService.instance
          .otherUserDoc(authorId, 'data', 'collection')
          .get();
      if (colDoc.exists) {
        final d = colDoc.data() ?? {};
        final cardsRaw = d['cards'] as Map<String, dynamic>? ?? {};
        final foilsMap = <String, int>{};
        final cardsMap = <String, int>{};
        for (final entry in cardsRaw.entries) {
          if (entry.value is Map) {
            final m = entry.value as Map;
            cardsMap[entry.key] = (m['qty'] as int?) ?? 0;
            foilsMap[entry.key] = (m['foil_qty'] as int?) ?? 0;
          } else if (entry.value is int) {
            cardsMap[entry.key] = entry.value as int;
          }
        }
        data['cards'] = cardsMap;
        data['foils'] = foilsMap;
      }
    } catch (_) {}

    // Seller profile (Public-Stats only, via playerProfiles-Mirror).
    // VORHER las das direkt aus `users/{uid}/data/sellerProfile` was
    // PII (email, address, totalRevenue, strikes, suspended, stripeAccountId)
    // mit-exposiert hat. Jetzt nur via Mirror — rating/reviewCount/totalSales/
    // memberSince. SellerProfile.fromMap ist null-tolerant, fehlende Felder
    // bleiben null/default. CF syncht automatisch bei Review/Sale-Aenderungen.
    try {
      final mirrorDoc = await FirestoreService.instance
          .globalCollection('playerProfiles')
          .doc(authorId)
          .get();
      if (mirrorDoc.exists) {
        data['sellerProfile'] = SellerProfile.fromMap(mirrorDoc.data() ?? {});
      }
    } catch (_) {}

    if (mounted) setState(() => _authorData = data);
  }

  Widget _buildAuthorProfile() {
    final authorId = _selectedAuthorId;
    if (authorId == null) return const SizedBox.shrink();

    // Trigger async load
    _loadAuthorData(authorId);

    final profile = ProfileService.instance.getCachedProfile(authorId);
    final displayName = profile?.displayName ?? _selectedAuthorName ?? 'Unknown';
    final bio = profile?.bio;
    final uid = AuthService.instance.uid;
    final isOwn = uid == authorId;
    final isFollowing = FollowService.instance.isFollowing(authorId);
    final followerCount = FollowService.instance.getFollowerCount(authorId);
    final authorDecks = PublicDeckService.instance.decksByAuthor(authorId);

    // Author data (async loaded)
    final authorMatches = (_authorData?['matches'] as List<MatchData>?) ?? [];
    final authorCards = (_authorData?['cards'] as Map<String, int>?) ?? {};
    final authorFoils = (_authorData?['foils'] as Map<String, int>?) ?? {};
    final authorSeller = _authorData?['sellerProfile'] as SellerProfile?;
    final legend = SocialHelpers.mainLegend(authorMatches, []);
    final wr = SocialHelpers.winRate(authorMatches);
    final authorBySet = SocialHelpers.collectionBySet(authorCards, authorFoils);
    final authorCollPct = SocialHelpers.totalCollectionPercent(authorBySet);
    final authorBadges = SocialHelpers.badges(
      memberSince: profile?.createdAt,
      collectionBySet: authorBySet,
      sellerProfile: authorSeller,
    );

    // Privacy checks
    final showWr = profile?.isWinRateVisible ?? true;
    final showColl = profile?.isCollectionVisible ?? true;
    final showMatch = profile?.isMatchCountVisible ?? true;

    // Location
    final locParts = <String>[];
    if (profile?.city != null && profile!.city!.isNotEmpty) locParts.add(profile.city!);
    if (profile?.country != null && profile!.country!.isNotEmpty) locParts.add(profile.country!);

    return DragToDismiss(
      onDismissed: () {
        _authorData = null;
        _authorDataId = null;
        setState(() => _view = 'home');
      },
      backgroundColor: AppColors.background,
      child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxxl, top: AppSpacing.base),
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
        ),

        // Author card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: RiftrCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(children: [
              _buildLegendAvatar(legend.imageUrl ?? profile?.avatarUrl, displayName, 96),
              const SizedBox(height: AppSpacing.md),
              Text(displayName, style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(
                legend.name != null ? '${legend.name} main' : 'New summoner',
                style: AppTextStyles.bodySmall.copyWith(
                  color: legend.name != null ? AppColors.amber400 : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (locParts.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(locParts.join(', '),
                  style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
              ],
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(bio, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],

              // Follow button or "You" badge
              if (isOwn) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.amber600, borderRadius: BorderRadius.circular(AppRadius.rounded)),
                  child: Text('You', style: AppTextStyles.small.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                RiftrButton(
                  label: isFollowing ? 'Unfollow' : 'Follow',
                  onPressed: () {
                    if (isFollowing) {
                      FollowService.instance.unfollow(authorId);
                    } else {
                      FollowService.instance.follow(authorId);
                    }
                  },
                  style: isFollowing ? RiftrButtonStyle.secondary : RiftrButtonStyle.primary,
                  icon: isFollowing ? Icons.favorite : Icons.favorite_border,
                  fullWidth: false,
                ),
              ],

              const SizedBox(height: AppSpacing.base),

              // Stats grid (respecting privacy)
              Row(children: [
                ..._buildStatsSlots(
                  matchCount: showMatch ? authorMatches.length : 0,
                  winRate: showWr ? wr : 0,
                  followerCount: followerCount,
                  sellerProfile: authorSeller,
                  collectionPct: authorCollPct,
                  deckCount: authorDecks.length,
                ),
              ]),

              // Collection bars (if privacy allows)
              if (showColl && authorBySet.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                _buildCollectionBars(authorBySet),
              ],

              // Badges
              if (authorBadges.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.base),
                _buildBadges(authorBadges),
              ],
            ]),
          ),
        ),

        // Author's deck cards
        if (authorDecks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.layers, color: AppColors.amber400, size: 16),
              const SizedBox(width: 6),
              Text('DECKS (${authorDecks.length})', style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ]),
          ),
          ...authorDecks.map((deck) => _buildAuthorDeckCard(deck)),
        ] else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('No published decks', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ),

        // FOR SALE section (seller's active listings)
        if (!_isDemo) ...[
          Builder(builder: (_) {
            final sellerListings = ListingService.instance.allActive
                .where((l) => l.sellerId == authorId)
                .toList();
            if (sellerListings.isEmpty) return const SizedBox.shrink();
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.sm),
                child: Row(children: [
                  Icon(Icons.storefront, color: AppColors.amber400, size: 16),
                  const SizedBox(width: 6),
                  Text('FOR SALE (${sellerListings.length})', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ]),
              ),
              ...sellerListings.map((listing) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: RiftrCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () => _showListingQuickBuy(listing),
                  child: Row(children: [
                    SizedBox(
                      width: 40,
                      height: 56,
                      child: Transform.scale(
                        scale: 1.25,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.rounded),
                          child: CardImage(
                            imageUrl: listing.imageUrl,
                            fallbackText: listing.cardName,
                            width: 40,
                            height: 56,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(listing.cardName,
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        ConditionBadge(condition: listing.condition),
                        const SizedBox(width: 6),
                        Text(listing.language == 'CN' ? '🇨🇳' : '🇬🇧',
                          style: AppTextStyles.bodySmall),
                        if (listing.availableQty > 1) ...[
                          const SizedBox(width: 6),
                          Text('×${listing.availableQty}',
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        ],
                      ]),
                    ])),
                    Text('€${listing.price.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(width: AppSpacing.sm),
                    // 44dp touch-target; visual circle stays compact at 32dp.
                    SizedBox(
                      width: 44, height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final ok = await CartService.instance.addItem(CartItem.fromListing(listing));
                          if (mounted) {
                            if (ok) {
                              RiftrToast.cart(context, 'Added to cart');
                            } else {
                              RiftrToast.error(context, 'Not available');
                            }
                          }
                        },
                        child: Center(
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.amber500),
                            ),
                            child: Icon(Icons.shopping_cart_outlined, size: 14, color: AppColors.amber500),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              )),
            ]);
          }),
        ],
      ]),
    ));
  }

  Widget _buildAuthorDeckCard(dynamic deck) {
    final isOwn = _isDemo ? (deck.authorId == 'demo') : (AuthService.instance.uid == deck.authorId);
    final dateStr = deck.publishedAt != null
        ? '${(deck.publishedAt as DateTime).day.toString().padLeft(2, '0')}.${(deck.publishedAt as DateTime).month.toString().padLeft(2, '0')}.${(deck.publishedAt as DateTime).year}'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: RiftrCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () {
          if (deck is PublicDeckData) {
            widget.onViewPublicDeck?.call(deck);
          }
        },
        child: Stack(children: [
          Row(children: [
            // Legend image
            ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(width: 64, height: 96,
              child: deck.legendImageUrl != null
                  ? CardImage(imageUrl: deck.legendImageUrl, fallbackText: deck.legendName ?? '', fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Center(child: Icon(Icons.person, color: AppColors.slate600))))),
            const SizedBox(width: 6),
            // Domain runes
            Column(mainAxisAlignment: MainAxisAlignment.center, children: (deck.domains as List).isNotEmpty
                ? (deck.domains as List).take(2).map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RuneIcon(domain: d as String, size: 32))).toList()
                : [_emptyDomainCircle(), const SizedBox(height: AppSpacing.xs), _emptyDomainCircle()]),
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deck.name, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              if (deck.description != null && (deck.description as String).isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 1),
                  child: Text(deck.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))),
              const SizedBox(height: 2),
              // Author + date
              Row(children: [
                Text('by ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                Flexible(child: Text(
                  isOwn ? 'You' : (deck.authorName ?? 'Unknown'),
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.amber400),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (dateStr != null) ...[
                  const SizedBox(width: 6),
                  Text(dateStr, style: AppTextStyles.small,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ]),
              const SizedBox(height: AppSpacing.xs),
              // Set badges
              Builder(builder: (_) {
                final lookup = CardService.getLookup();
                final sets = <String>{};
                for (final id in (deck.mainDeck as Map).keys) {
                  final c = lookup[id];
                  if (c?.setId != null) sets.add(c!.setId!);
                }
                for (final id in (deck.sideboard as Map).keys) {
                  final c = lookup[id];
                  if (c?.setId != null) sets.add(c!.setId!);
                }
                if (sets.isEmpty) return const SizedBox.shrink();
                return Wrap(spacing: 4, runSpacing: 4, children: [
                  ...sets.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.rounded),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Text(s, style: AppTextStyles.small.copyWith(color: AppColors.amber400, fontWeight: FontWeight.bold)),
                  )),
                ]);
              }),
            ])),
          ]),
          // Copy count — top-right
          Positioned(top: 0, right: 0, child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${deck.viewCount}', style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(width: 3),
            Icon(Icons.file_download_outlined, size: 16, color: AppColors.textMuted),
          ])),
          // Copy button — bottom-right
          if (!isOwn) Positioned(bottom: 0, right: 0, child: GestureDetector(
            onTap: () async {
              if (_isDemo) {
                DemoService.instance.incrementViewCount(deck.name);
                DemoService.instance.createDeck((deck as PublicDeckData).toDeckData().copyWith(name: '${deck.name} (Copy)'));
              } else {
                if (deck.id != null) PublicDeckService.instance.incrementViewCount(deck.id!);
                FirestoreDeckService.instance.suppressNextBadge = true;
                await PublicDeckService.instance.copyToMyDecks(deck);
              }
              if (mounted) {
                RiftrToast.success(context, 'Deck copied!');
              }
            },
            // 44×44 touch-target (Apple HIG) — centered 22dp icon.
            child: SizedBox(
              width: 44, height: 44,
              child: Center(child: Icon(Icons.copy, color: AppColors.textMuted, size: 22)),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _emptyDomainCircle() => Container(width: 32, height: 32, decoration: BoxDecoration(
    shape: BoxShape.circle, color: AppColors.surfaceLight,
    border: Border.all(color: AppColors.border, style: BorderStyle.solid)));

  // ───── FAB ─────


  // ───── SHARED WIDGETS ─────

  Widget _buildAvatar(String? avatarUrl, String initial, double size) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(child: SizedBox(width: size, height: size,
        child: Image.network(avatarUrl, fit: BoxFit.cover,
          errorBuilder: (_, _a, _b) => _buildInitialAvatar(initial, size))));
    }
    return _buildInitialAvatar(initial, size);
  }

  Widget _buildInitialAvatar(String initial, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.amber600, AppColors.amber400],
        ),
      ),
      child: Center(child: Text(initial, style: AppTextStyles.body.copyWith(
        fontSize: size * 0.44, fontWeight: FontWeight.w900))),
    );
  }

  void _handleLogout(BuildContext context, bool isDemo) async {
    final confirmed = await showRiftrSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemo ? 'EXIT DEMO' : 'LOGOUT',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isDemo ? 'Exit demo mode?' : 'Are you sure you want to logout?',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: RiftrButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(ctx, false),
                  style: RiftrButtonStyle.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RiftrButton(
                  label: isDemo ? 'Exit' : 'Logout',
                  onPressed: () => Navigator.pop(ctx, true),
                  style: RiftrButtonStyle.danger,
                  icon: isDemo ? Icons.exit_to_app : Icons.logout,
                ),
              ),
            ]),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    if (isDemo) {
      DemoService.instance.deactivate();
    } else {
      MatchService.instance.stopListening();
      FirestoreDeckService.instance.stopListening();
      FirestoreCollectionService.instance.stopListening();
      PublicDeckService.instance.stopListening();
      FollowService.instance.stopListening();
      ProfileService.instance.stopListening();
      await AuthService.instance.signOut();
    }
  }
}
