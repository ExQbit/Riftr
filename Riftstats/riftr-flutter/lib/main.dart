import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'services/firestore_deck_service.dart';
import 'services/firestore_collection_service.dart';
import 'services/demo_service.dart';
import 'services/public_deck_service.dart';
import 'services/meta_deck_service.dart';
import 'services/notification_inbox_service.dart';
import 'services/follow_service.dart';
import 'services/profile_service.dart';
import 'screens/login_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/decks_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/social_screen.dart';
import 'screens/market_screen.dart';
import 'services/market_service.dart';
import 'services/listing_service.dart';
import 'services/seller_service.dart';
import 'services/card_service.dart';
import 'services/order_service.dart';
import 'services/wallet_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';
import 'services/cart_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background message handler (required by FCM).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // No action needed — FCM auto-displays notification in background
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  Stripe.publishableKey = 'pk_test_51T8RW7IF9chIKwTY1iXCxHqtIGfPlCRIs4k0INBevmznbBTmEiKmXoUcKBVBJdSrmUPa1ZsVIIRIWfUTW3I16WWu007iPI7MWl';
  Stripe.merchantIdentifier = 'merchant.app.getriftr';
  Stripe.urlScheme = 'riftr';

  // Lock to portrait (matching landscape guard behavior)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge: app renders behind system bars (status bar + nav bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  runApp(const RiftrApp());
}

class RiftrApp extends StatelessWidget {
  const RiftrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riftr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

/// Shows LoginScreen or AppShell based on auth state + demo mode
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    DemoService.instance.addListener(_onDemoChanged);
  }

  void _onDemoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DemoService.instance.removeListener(_onDemoChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Demo mode bypasses auth
    if (DemoService.instance.isActive) {
      return const AppShell();
    }

    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.amber400)),
          );
        }
        // Suppress brief auth state during registration (create → signOut)
        if (snapshot.hasData && !AuthService.instance.isRegistering) {
          return const _OnboardingGate();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Routes users to onboarding or app based on profile state.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    ProfileService.instance.listen();
    ProfileService.instance.addListener(_onProfileChanged);
    _loadPrefs();
  }

  @override
  void dispose() {
    ProfileService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait for profile load + prefs
    if (!ProfileService.instance.hasLoaded || _hasSeenOnboarding == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.amber400)),
      );
    }

    final profile = ProfileService.instance.ownProfile;
    final hasUsername = profile?.displayName != null && profile!.displayName!.isNotEmpty;
    final hasCountry = profile?.country != null && profile!.country!.isNotEmpty;

    // Existing user with complete profile → App
    if (hasUsername && hasCountry) {
      return const AppShell();
    }

    // New user (never seen onboarding) → full 6 screens
    if (!_hasSeenOnboarding!) {
      return const OnboardingScreen();
    }

    // Returning user without username → just setup screen
    return const SetupScreen();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Exposed for FABs in child screens to sync their position with NavBar slide.
  static final navSlideNotifier = ValueNotifier<double>(1.0);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  int? _returnToTabIndex; // Auto-return after cross-tab navigation (e.g. Social → Decks → back)
  bool _hideNav = false;
  bool _navCollapsed = false;
  DateTime _lastNavToggle = DateTime(2000);
  final Set<int> _badgeTabs = {}; // Tab indices with unread events
  late final AnimationController _navSlideController; // 1.0 = visible, 0.0 = hidden below


  final _socialKey = GlobalKey<SocialScreenState>();
  final _decksKey = GlobalKey<DecksScreenState>();
  final _cardsKey = GlobalKey<CardsScreenState>();
  final _collectionKey = GlobalKey<CollectionScreenState>();
  final _statsKey = GlobalKey<StatsScreenState>();
  final _marketKey = GlobalKey<MarketScreenState>();

  late final List<Widget> _screens = [
    TrackerScreen(onFullscreenChanged: _setNavHidden, onGoToDecks: () => setState(() { _currentIndex = 4; _badgeTabs.remove(4); })),
    CardsScreen(key: _cardsKey),
    CollectionScreen(key: _collectionKey),
    MarketScreen(key: _marketKey, onFullscreenChanged: _setNavHidden, onNavigateToAuthor: _navigateToAuthor),
    DecksScreen(
      key: _decksKey,
      onFullscreenChanged: _setNavHidden,
      onNavigateToAuthor: _navigateToAuthor,
      onShowMissingInMarket: _showMissingInMarket,
      onDeckViewerClosed: () {
        if (_returnToTabIndex != null) {
          setState(() {
            _currentIndex = _returnToTabIndex!;
            _returnToTabIndex = null;
          });
        }
      },
    ),
    StatsScreen(key: _statsKey, onGoToTracker: () => setState(() { _currentIndex = 0; _badgeTabs.remove(0); })),
    SocialScreen(key: _socialKey, onGoToPublicDecks: () {
      setState(() { _currentIndex = 4; _badgeTabs.remove(4); });
      _decksKey.currentState?.showPublicDecks();
    }, onViewPublicDeck: (deck) {
      setState(() {
        if (_currentIndex != 4) _returnToTabIndex = _currentIndex;
        _currentIndex = 4;
        _badgeTabs.remove(4);
      });
      _decksKey.currentState?.viewPublicDeck(deck);
    }),
  ];

  // ─── Badge Listeners ───
  int _prevPurchaseCount = -1;
  int _prevSaleCount = -1;
  int _prevCollectionCount = -1;
  int _prevDeckCount = -1;
  int _prevMatchCount = -1;
  int _prevFollowerCount = -1;
  int _prevFollowedDeckCount = -1;
  bool _badgeWarmupDone = false; // Skip badge triggers during initial Firestore sync

  void _setupBadgeListeners() {
    // Market badges: new orders (purchases or sales)
    OrderService.instance.addListener(_onOrdersChanged);
    // Collection badges: new cards added
    FirestoreCollectionService.instance.addListener(_onCollectionChanged);
    // Deck badges: new decks
    FirestoreDeckService.instance.addListener(_onDecksChanged);
    // Stats badges: new matches
    MatchService.instance.addListener(_onMatchesChanged);
    // Social badges: new followers
    FollowService.instance.addListener(_onFollowsChanged);
    // Social badges: followee shared a new deck
    PublicDeckService.instance.addListener(_onFollowedDecksChanged);
  }

  void _onOrdersChanged() {
    final purchaseCount = OrderService.instance.purchases.length;
    final saleCount = OrderService.instance.sales.length;
    // Only badge if counts increased AND warmup is done (cache→server sync can cause false positives)
    if (_badgeWarmupDone && _prevPurchaseCount >= 0 && purchaseCount > _prevPurchaseCount && _currentIndex != 3) {
      setState(() => _badgeTabs.add(3)); // Market tab
    }
    if (_badgeWarmupDone && _prevSaleCount >= 0 && saleCount > _prevSaleCount && _currentIndex != 3) {
      setState(() => _badgeTabs.add(3)); // Market tab
    }
    _prevPurchaseCount = purchaseCount;
    _prevSaleCount = saleCount;
  }

  void _onCollectionChanged() {
    final count = FirestoreCollectionService.instance.cards.values
        .fold<int>(0, (sum, qty) => sum + qty);
    if (_badgeWarmupDone && _prevCollectionCount >= 0 && count > _prevCollectionCount && _currentIndex != 2) {
      setState(() => _badgeTabs.add(2)); // Collect tab
    }
    _prevCollectionCount = count;
  }

  void _onDecksChanged() {
    final count = FirestoreDeckService.instance.decks.length;
    if (_badgeWarmupDone && _prevDeckCount >= 0 && count > _prevDeckCount && _currentIndex != 4) {
      if (FirestoreDeckService.instance.suppressNextBadge) {
        FirestoreDeckService.instance.suppressNextBadge = false;
      } else {
        setState(() => _badgeTabs.add(4)); // Decks tab
      }
    }
    _prevDeckCount = count;
  }

  void _onMatchesChanged() {
    final count = MatchService.instance.matches.length;
    if (_badgeWarmupDone && _prevMatchCount >= 0 && count > _prevMatchCount && _currentIndex != 5) {
      setState(() => _badgeTabs.add(5)); // Stats tab
    }
    _prevMatchCount = count;
  }

  void _onFollowsChanged() {
    final uid = AuthService.instance.uid ?? '';
    final count = FollowService.instance.getFollowerCount(uid);
    if (_badgeWarmupDone && _prevFollowerCount >= 0 && count > _prevFollowerCount && _currentIndex != 6) {
      setState(() => _badgeTabs.add(6)); // Social tab
    }
    _prevFollowerCount = count;
  }

  void _onFollowedDecksChanged() {
    final following = FollowService.instance.myFollowing;
    if (following.isEmpty) return;
    final count = PublicDeckService.instance.decks
        .where((d) => following.contains(d.authorId))
        .length;
    if (_badgeWarmupDone && _prevFollowedDeckCount >= 0 && count > _prevFollowedDeckCount && _currentIndex != 6) {
      setState(() => _badgeTabs.add(6)); // Social tab
    }
    _prevFollowedDeckCount = count;
  }

  void _navigateToAuthor(String authorId, String authorName) {
    setState(() { _currentIndex = 6; _badgeTabs.remove(6); }); // Social tab
    _socialKey.currentState?.navigateToAuthor(authorId, authorName);
  }

  void _showMissingInMarket(Map<String, int> missingCards) {
    _marketKey.currentState?.showMissingCards(missingCards);
    _setNavHidden(false); // Close deck fullscreen overlay
    setState(() { _currentIndex = 3; _badgeTabs.remove(3); }); // Market tab
  }


  void _setNavHidden(bool hide) {
    if (_hideNav == hide) return;
    _hideNav = hide;
    if (hide) {
      _navSlideController.animateTo(0.0, curve: Curves.easeOut);
    } else {
      _navCollapsed = false;
      _navSlideController.animateTo(1.0, curve: Curves.easeOut);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _navSlideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0, // start visible
    );
    _navSlideController.addListener(() {
      AppShell.navSlideNotifier.value = _navSlideController.value;
    });
    if (!DemoService.instance.isActive) {
      MatchService.instance.listen();
      FirestoreDeckService.instance.listen();
      FirestoreCollectionService.instance.listen();
      PublicDeckService.instance.listen();
      FollowService.instance.listen();
      ProfileService.instance.listen();
      SellerService.instance.listen();
      OrderService.instance.listen();
      WalletService.instance.listen();
      MetaDeckService.instance.listen();

      // Notification Inbox — Firestore-based dots (no navigation)
      NotificationInboxService.instance.listen();
      NotificationInboxService.instance.addListener(_onNotificationInboxChanged);

      // FCM Push — banner display only, no deep linking
      PushNotificationService.instance.initialize().catchError((e) {
        debugPrint('PushNotificationService init error: $e');
      });
      _setupBadgeListeners();
      // Allow Firestore cache + server sync to settle before reacting to count changes.
      // Without this, cache→server delta triggers false badges on every start.
      Future.delayed(const Duration(seconds: 5), () { if (mounted) _badgeWarmupDone = true; });
    }
    _initMarket();
  }

  /// Firestore-based notification inbox — updates dots only, NO navigation.
  void _onNotificationInboxChanged() {
    final inbox = NotificationInboxService.instance;
    setState(() {
      // Market Tab + sub-tab dots
      if (inbox.unseenOrderCount > 0) {
        _badgeTabs.add(3);
        MarketScreen.hasUnreadOrders = true;
        MarketScreen.hasUnreadSales = inbox.unseen.any((n) => n.type == 'order' && n.role == 'seller');
        MarketScreen.hasUnreadPurchases = inbox.unseen.any((n) => n.type == 'order' && n.role == 'buyer');
      } else {
        _badgeTabs.remove(3);
        MarketScreen.hasUnreadOrders = false;
        MarketScreen.hasUnreadSales = false;
        MarketScreen.hasUnreadPurchases = false;
      }
      // Decks Tab dot
      if (inbox.unseenMetaCount > 0) {
        _badgeTabs.add(4);
        DecksScreen.hasUnreadMeta = true;
      } else {
        _badgeTabs.remove(4);
        DecksScreen.hasUnreadMeta = false;
      }
      // Cards Tab dot
      if (inbox.unseenCardsCount > 0) {
        _badgeTabs.add(1);
        CardsScreen.hasUnreadCards = true;
      } else {
        _badgeTabs.remove(1);
        CardsScreen.hasUnreadCards = false;
      }
    });
  }


  void _initMarket() async {
    final cards = await CardService.loadCards();
    if (cards.isEmpty) return;

    final collection = DemoService.instance.isActive
        ? DemoService.instance.collection
        : FirestoreCollectionService.instance.cards;

    final costBasis = DemoService.instance.isActive
        ? null
        : FirestoreCollectionService.instance.costBasis;

    // Always use real Firestore prices (falls back to mock if no data)
    final foilCollection = DemoService.instance.isActive
        ? null
        : FirestoreCollectionService.instance.foils;
    await MarketService.instance.initializeFromFirestore(
      cards, collection, foilCollection: foilCollection, costBasis: costBasis,
    );

    if (!DemoService.instance.isActive) {
      // Move non-foil entries for foil-only cards (promos, rare+) to foil map
      final migrated = FirestoreCollectionService.instance.migrateVariantEntries();
      if (migrated > 0) debugPrint('Variant migration: $migrated cards');

      // Repair cost basis lot prices (avg1 → trend, 2026-03-14)
      final repaired = FirestoreCollectionService.instance.repairCostBasis();
      if (repaired > 0) debugPrint('Cost basis repaired: $repaired cards');

      // Sync cost basis qty with actual collection qty (fix orphaned/missing lots)
      final synced = FirestoreCollectionService.instance.syncCostBasisWithCollection();
      if (synced > 0) debugPrint('Cost basis synced: $synced cards');
    }

    // Recalculate portfolio when collection changes (new cards added, etc.)
    if (!DemoService.instance.isActive) {
      FirestoreCollectionService.instance.addListener(() {
        final svc = FirestoreCollectionService.instance;
        // Repair any cost basis lots that used fallback prices
        svc.repairCostBasis();
        MarketService.instance.recalculatePortfolio(
          svc.cards,
          foilCollection: svc.foils,
          costBasis: svc.costBasis,
        );
      });

      // Collection may have arrived during initializeFromFirestore await —
      // recalculate once now to catch any missed updates
      final svc = FirestoreCollectionService.instance;
      if (svc.cards.isNotEmpty || svc.foils.isNotEmpty) {
        MarketService.instance.recalculatePortfolio(
          svc.cards,
          foilCollection: svc.foils,
          costBasis: svc.costBasis,
        );
      }
    }

    // Start listening for marketplace listings
    ListingService.instance.listen();

    // Load cart from disk + sync with Firestore reservations
    if (!DemoService.instance.isActive) {
      await CartService.instance.loadFromDisk();
      CartService.instance.syncWithFirestore();
      CartService.instance.addListener(() { if (mounted) setState(() {}); });
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navSlideController.dispose();
    if (!DemoService.instance.isActive) {
      OrderService.instance.removeListener(_onOrdersChanged);
      FirestoreCollectionService.instance.removeListener(_onCollectionChanged);
      FirestoreDeckService.instance.removeListener(_onDecksChanged);
      MatchService.instance.removeListener(_onMatchesChanged);
      FollowService.instance.removeListener(_onFollowsChanged);
      PublicDeckService.instance.removeListener(_onFollowedDecksChanged);
      MatchService.instance.stopListening();
      FirestoreDeckService.instance.stopListening();
      FirestoreCollectionService.instance.stopListening();
      PublicDeckService.instance.stopListening();
      FollowService.instance.stopListening();
      ListingService.instance.stopListening();
      ProfileService.instance.stopListening();
      SellerService.instance.stopListening();
      OrderService.instance.stopListening();
      WalletService.instance.stopListening();
    }
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return;
    if (notification.metrics.maxScrollExtent <= 0) return;

    // Debounce: ignore toggles within 200ms of each other
    final now = DateTime.now();
    if (now.difference(_lastNavToggle).inMilliseconds < 200) return;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final pixels = notification.metrics.pixels;

      if (delta > 5 && !_navCollapsed && pixels > 0) {
        _navCollapsed = true;
        _lastNavToggle = now;
        _navSlideController.animateTo(0.0, curve: Curves.easeOut);
      } else if (delta < -5 && _navCollapsed) {
        _navCollapsed = false;
        _lastNavToggle = now;
        _navSlideController.animateTo(1.0, curve: Curves.easeOut);
      }
    }

    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0 && _navCollapsed) {
        _navCollapsed = false;
        _navSlideController.animateTo(1.0, curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!_hideNav) _handleScrollNotification(notification);
                return false;
              },
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _navSlideController,
              builder: (context, child) {
                final t = _navSlideController.value; // 1.0 = visible, 0.0 = hidden
                return Transform.translate(
                  offset: Offset(0, (1 - t) * 104), // navHeight ~80 + margin 24
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildFloatingNav(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Market NavBar icon — normal storefront + pulsing cart badge when cart has items.
  Widget _buildMarketIcon(bool isActive) {
    final hasCartItems = CartService.instance.totalItems > 0;

    return SizedBox(
      width: 42, height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Normal storefront icon
          Icon(
            Icons.storefront,
            size: 42,
            color: isActive ? AppColors.amber100 : AppColors.textMuted,
          ),
          // Pulsing cart badge bottom-left (only when cart has items)
          if (hasCartItems)
            Positioned(
              bottom: -1, left: -1,
              child: _PulsingCartBadge(count: CartService.instance.totalItems),
            ),
        ],
      ),
    );
  }

  Widget _badgeIcon(Widget icon, int tabIndex) {
    if (!_badgeTabs.contains(tabIndex)) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -2,
          right: -4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.amber400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber400.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _tabs = [
    (icon: Icons.sports_esports, label: 'Tracker'),
    (icon: Icons.style, label: 'Cards'),
    (icon: Icons.collections_bookmark, label: 'Collect'),
    (icon: Icons.storefront, label: 'Market'),
    (icon: Icons.layers, label: 'Decks'),
    (icon: Icons.bar_chart, label: 'Stats'),
    (icon: Icons.people, label: 'Social'),
  ];

  Widget _buildFloatingNav() {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth - 32.0;
    const bump = 12.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: navWidth,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: CustomPaint(
          painter: _NavBarPainter(
            color: AppColors.surface.withValues(alpha: 0.8),
            borderColor: AppColors.amber400.withValues(alpha: 0.1),
            shadowColor: Colors.black.withValues(alpha: 0.5),
            bump: bump,
          ),
          child: ClipPath(
            clipper: _NavBarClipper(bump: bump),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_tabs.length, (i) {
                    final isActive = _currentIndex == i;
                    final isMarket = i == 3;
                    return Expanded(
                      flex: isMarket ? 5 : 4,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (_navCollapsed) {
                            _navCollapsed = false;
                            _navSlideController.animateTo(1.0, curve: Curves.easeOut);
                          }
                          setState(() {
                            _currentIndex = i;
                            _returnToTabIndex = null;
                            if (i != 1 && i != 3) _badgeTabs.remove(i);
                          });
                          switch (i) {
                            case 1:
                              _cardsKey.currentState?.resetScroll();
                              NotificationInboxService.instance.markAllSeenByType('new_cards');
                            case 2: _collectionKey.currentState?.resetScroll();
                            case 3: _marketKey.currentState?.resetScroll();
                            case 4:
                              _decksKey.currentState?.resetScroll();
                              if (_decksKey.currentState?.isFullscreen == true) {
                                _setNavHidden(true);
                              }
                            case 5: _statsKey.currentState?.resetScroll();
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: AppSpacing.xs),
                          child: isMarket
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: 0.86,
                                  child: Transform.translate(
                                    offset: const Offset(0, -3),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _badgeIcon(_buildMarketIcon(isActive), i),
                                        Text('Market',
                                          style: AppTextStyles.small.copyWith(
                                            color: isActive ? AppColors.amber100 : AppColors.textMuted,
                                            fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _badgeIcon(
                                      Icon(_tabs[i].icon, size: 30,
                                        color: isActive ? AppColors.amber100 : AppColors.textMuted),
                                      i),
                                    const SizedBox(height: 2),
                                    Text(_tabs[i].label,
                                      style: AppTextStyles.tiny.copyWith(
                                        color: isActive ? AppColors.amber100 : AppColors.textMuted,
                                        fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pulsing cart badge placeholder — old painters removed.
/// Draws the navbar shape: pill with a smooth upward bump in the center.
class _NavBarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double bump;

  _NavBarPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
    required this.bump,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildNavPath(size, bump);
    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()..color = shadowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter old) =>
      old.bump != bump || old.color != color || old.borderColor != borderColor;
}

class _NavBarClipper extends CustomClipper<Path> {
  final double bump;
  _NavBarClipper({required this.bump});

  @override
  Path getClip(Size size) => _buildNavPath(size, bump);

  @override
  bool shouldReclip(covariant _NavBarClipper old) => old.bump != bump;
}

Path _buildNavPath(Size size, double bump) {
  final r = size.height / 2;
  final cx = size.width / 2;
  const bumpHalf = 32.0;

  if (bump < 0.5) {
    return Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(r)));
  }

  final path = Path();
  path.moveTo(r, 0);
  path.lineTo(cx - bumpHalf - 12, 0);
  path.cubicTo(cx - bumpHalf, 0, cx - bumpHalf * 0.5, -bump, cx, -bump);
  path.cubicTo(cx + bumpHalf * 0.5, -bump, cx + bumpHalf, 0, cx + bumpHalf + 12, 0);
  path.lineTo(size.width - r, 0);
  path.arcToPoint(Offset(size.width - r, size.height), radius: Radius.circular(r), clockwise: true);
  path.lineTo(r, size.height);
  path.arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: true);
  path.close();
  return path;
}

/// Small pulsing cart badge for the NavBar Market icon.
/// Uses CartService.pulse (shared ValueNotifier) so all cart badges sync.
class _PulsingCartBadge extends StatelessWidget {
  final int count;
  const _PulsingCartBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: CartService.pulse,
      builder: (context, t, child) {
        final scale = 1.0 + 0.15 * t; // 1.0 → 1.15
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.amber400,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.shopping_cart, size: 10, color: AppColors.textPrimary),
            ),
          ),
        );
      },
    );
  }
}
