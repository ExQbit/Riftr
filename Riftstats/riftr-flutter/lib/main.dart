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
import 'models/public_deck_model.dart';
import 'services/market_service.dart';
import 'services/listing_service.dart';
import 'services/seller_service.dart';
import 'services/card_service.dart';
import 'services/order_service.dart';
import 'services/wallet_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';

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
  // merchantIdentifier only needed when Apple Pay is configured
  // Stripe.merchantIdentifier = 'merchant.app.getriftr';
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
          return const AppShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _hideNav = false;
  bool _navCollapsed = false;
  final Set<int> _badgeTabs = {}; // Tab indices with unread events
  late final AnimationController _navAnimController;
  late final Animation<double> _navAnimation;
  late final AnimationController _pulseController;
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
    MarketScreen(key: _marketKey, onFullscreenChanged: _setNavHidden),
    DecksScreen(
      key: _decksKey,
      onFullscreenChanged: _setNavHidden,
      onNavigateToAuthor: _navigateToAuthor,
      onShowMissingInMarket: _showMissingInMarket,
    ),
    StatsScreen(key: _statsKey, onGoToTracker: () => setState(() { _currentIndex = 0; _badgeTabs.remove(0); })),
    SocialScreen(key: _socialKey, onViewPublicDeck: _viewPublicDeck, onGoToPublicDecks: () {
      setState(() { _currentIndex = 4; _badgeTabs.remove(4); });
      _decksKey.currentState?.showPublicDecks();
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
    // Only badge if counts increased (not on first load)
    if (_prevPurchaseCount >= 0 && purchaseCount > _prevPurchaseCount && _currentIndex != 3) {
      setState(() => _badgeTabs.add(3)); // Market tab
    }
    if (_prevSaleCount >= 0 && saleCount > _prevSaleCount && _currentIndex != 3) {
      setState(() => _badgeTabs.add(3)); // Market tab
    }
    _prevPurchaseCount = purchaseCount;
    _prevSaleCount = saleCount;
  }

  void _onCollectionChanged() {
    final count = FirestoreCollectionService.instance.cards.values
        .fold<int>(0, (sum, qty) => sum + qty);
    if (_prevCollectionCount >= 0 && count > _prevCollectionCount && _currentIndex != 2) {
      setState(() => _badgeTabs.add(2)); // Collect tab
    }
    _prevCollectionCount = count;
  }

  void _onDecksChanged() {
    final count = FirestoreDeckService.instance.decks.length;
    if (_prevDeckCount >= 0 && count > _prevDeckCount && _currentIndex != 4) {
      setState(() => _badgeTabs.add(4)); // Decks tab
    }
    _prevDeckCount = count;
  }

  void _onMatchesChanged() {
    final count = MatchService.instance.matches.length;
    if (_prevMatchCount >= 0 && count > _prevMatchCount && _currentIndex != 5) {
      setState(() => _badgeTabs.add(5)); // Stats tab
    }
    _prevMatchCount = count;
  }

  void _onFollowsChanged() {
    final uid = AuthService.instance.uid ?? '';
    final count = FollowService.instance.getFollowerCount(uid);
    if (_prevFollowerCount >= 0 && count > _prevFollowerCount && _currentIndex != 6) {
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
    if (_prevFollowedDeckCount >= 0 && count > _prevFollowedDeckCount && _currentIndex != 6) {
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

  void _viewPublicDeck(PublicDeckData deck) {
    setState(() { _currentIndex = 4; _badgeTabs.remove(4); }); // Decks tab
    _decksKey.currentState?.viewPublicDeck(deck);
  }

  void _setNavHidden(bool hide) {
    if (_hideNav == hide) return;
    _hideNav = hide;
    if (hide) {
      // Slide nav down and out
      _navSlideController.animateTo(0.0, curve: Curves.easeInCubic);
      _pulseController.stop();
      _pulseController.value = 0;
    } else {
      // Reset to expanded, then slide back up
      _navCollapsed = false;
      _navAnimController.value = 1.0;
      _pulseController.stop();
      _pulseController.value = 0;
      _navSlideController.animateTo(1.0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0, // start expanded
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimController,
      curve: Curves.easeInOut,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _navSlideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
      value: 1.0, // start visible
    );
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
      PushNotificationService.instance.initialize().catchError((e) {
        debugPrint('PushNotificationService init error: $e');
      });
      _setupBadgeListeners();
    }
    _initMarket();
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
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    _pulseController.dispose();
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

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final pixels = notification.metrics.pixels;

      // Only collapse on intentional downward scroll (pixels > 0 = not in overscroll territory)
      if (delta > 2 && !_navCollapsed && pixels > 0) {
        _navCollapsed = true;
        _navAnimController.reverse();
        _pulseController.repeat(reverse: true);
      } else if (delta < -2 && _navCollapsed) {
        _navCollapsed = false;
        _navAnimController.forward();
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }

    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0 && _navCollapsed) {
        _navCollapsed = false;
        _navAnimController.forward();
        _pulseController.stop();
        _pulseController.value = 0;
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
                final slideValue = _navSlideController.value;
                if (slideValue <= 0.01) return const SizedBox.shrink();
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - slideValue)),
                  child: Opacity(
                    opacity: slideValue,
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
    return AnimatedBuilder(
      animation: Listenable.merge([_navAnimation, _pulseController]),
      builder: (context, _) {
        final t = _navAnimation.value; // 1.0 = expanded, 0.0 = collapsed
        final screenWidth = MediaQuery.of(context).size.width;
        final expandedWidth = screenWidth - 32.0;
        const collapsedWidth = 56.0;
        final currentWidth = collapsedWidth + (expandedWidth - collapsedWidth) * t;

        final labelOpacity = (t * 2).clamp(0.0, 1.0);
        final inactiveOpacity = ((t - 0.1) * 1.25).clamp(0.0, 1.0);

        final pulseVal = _pulseController.value;
        final borderAlpha = t < 0.3 ? 0.15 + pulseVal * 0.5 : 0.1;
        final glowAlpha = t < 0.3 ? pulseVal * 0.4 : 0.0;

        // Bump factor: how much the center bulges (0 when collapsed, full when expanded)
        final bump = 12.0 * t;

        return Align(
          alignment: Alignment.lerp(Alignment.bottomLeft, Alignment.bottomCenter, t)!,
          child: Container(
            width: currentWidth,
            margin: EdgeInsets.only(bottom: AppSpacing.base, left: AppSpacing.base, right: t > 0.5 ? AppSpacing.base : 0),
            child: CustomPaint(
              painter: _NavBarPainter(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderColor: AppColors.amber400.withValues(alpha: borderAlpha),
                shadowColor: Colors.black.withValues(alpha: 0.5),
                glowColor: glowAlpha > 0 ? AppColors.amber400.withValues(alpha: glowAlpha) : null,
                bump: bump,
              ),
              child: ClipPath(
                clipper: _NavBarClipper(bump: bump),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: t < 0.3
                        // Collapsed: only active icon, tap to expand
                        ? GestureDetector(
                            onTap: () {
                              _navCollapsed = false;
                              _navAnimController.forward();
                              _pulseController.stop();
                              _pulseController.value = 0;
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                final pulseVal = _pulseController.value;
                                final glowOpacity = 0.15 + pulseVal * 0.2;
                                final iconScale = 1.0 + pulseVal * 0.06;
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                    child: Transform.scale(
                                      scale: iconScale,
                                      child: Icon(
                                        _tabs[_currentIndex].icon,
                                        size: 30,
                                        color: AppColors.amber100,
                                        shadows: [
                                          Shadow(
                                            color: AppColors.amber400.withValues(alpha: glowOpacity),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        // Expanding / Expanded: all tabs
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_tabs.length, (i) {
                              final isActive = _currentIndex == i;
                              final isMarket = i == 3;
                              return Expanded(
                                flex: isMarket ? 5 : 4,
                                child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _currentIndex = i;
                                    _badgeTabs.remove(i);
                                  });
                                  switch (i) {
                                    case 1: _cardsKey.currentState?.resetScroll();
                                    case 2: _collectionKey.currentState?.resetScroll();
                                    case 3: _marketKey.currentState?.resetScroll();
                                    case 4:
                                      _decksKey.currentState?.resetScroll();
                                      // Hide nav if deck is open in fullscreen
                                      if (_decksKey.currentState?.isFullscreen == true) {
                                        _setNavHidden(true);
                                      }
                                    case 5: _statsKey.currentState?.resetScroll();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: AppSpacing.xs),
                                  child: Opacity(
                                    opacity: isActive ? 1.0 : (isMarket ? inactiveOpacity.clamp(0.7, 1.0) : inactiveOpacity),
                                    child: isMarket
                                      // Market: Align with heightFactor so 50px icon doesn't inflate Row height
                                      ? Align(
                                          alignment: Alignment.bottomCenter,
                                          heightFactor: 0.86,
                                          child: Transform.translate(
                                            offset: const Offset(0, -3),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _badgeIcon(
                                                  Icon(
                                                    _tabs[i].icon,
                                                    size: 42,
                                                    color: isActive
                                                        ? AppColors.amber100
                                                        : AppColors.textMuted,
                                                  ),
                                                  i,
                                                ),
                                                if (labelOpacity > 0.01) ...[
                                                  Opacity(
                                                    opacity: labelOpacity,
                                                    child: Text(
                                                      'Market',
                                                      style: AppTextStyles.small.copyWith(
                                                        color: isActive
                                                            ? AppColors.amber100
                                                            : AppColors.textMuted,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        )
                                      // Normal tabs: icon + label
                                      : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _badgeIcon(
                                          Icon(
                                            _tabs[i].icon,
                                            size: 30,
                                            color: isActive ? AppColors.amber100 : AppColors.textMuted,
                                          ),
                                          i,
                                        ),
                                        if (labelOpacity > 0.01) ...[
                                          const SizedBox(height: 2),
                                          Opacity(
                                            opacity: labelOpacity,
                                            child: Text(
                                              _tabs[i].label,
                                              style: AppTextStyles.tiny.copyWith(
                                                color: isActive ? AppColors.amber100 : AppColors.textMuted,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
      },
    );
  }
}

/// Draws the navbar shape: pill with a smooth upward bump in the center.
class _NavBarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final Color? glowColor;
  final double bump;

  _NavBarPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
    this.glowColor,
    required this.bump,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildNavPath(size, bump);

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Glow
    if (glowColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = glowColor!
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Fill
    canvas.drawPath(path, Paint()..color = color);

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter old) =>
      old.bump != bump || old.color != color || old.borderColor != borderColor;
}

/// Clips to the navbar shape so BackdropFilter works correctly.
class _NavBarClipper extends CustomClipper<Path> {
  final double bump;
  _NavBarClipper({required this.bump});

  @override
  Path getClip(Size size) => _buildNavPath(size, bump);

  @override
  bool shouldReclip(covariant _NavBarClipper old) => old.bump != bump;
}

/// Shared path: pill shape with tight center bump.
Path _buildNavPath(Size size, double bump) {
  final r = size.height / 2;
  final cx = size.width / 2;
  const bumpHalf = 32.0; // half-width of the bump — tight around center icon

  if (bump < 0.5) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(r),
      ));
  }

  final path = Path();
  path.moveTo(r, 0);

  // Top edge: flat → tight bump up → flat
  path.lineTo(cx - bumpHalf - 12, 0); // approach
  path.cubicTo(
    cx - bumpHalf, 0,          // control 1: start curving
    cx - bumpHalf * 0.5, -bump, // control 2: steep rise
    cx, -bump,                   // peak
  );
  path.cubicTo(
    cx + bumpHalf * 0.5, -bump, // control 1: steep descent
    cx + bumpHalf, 0,           // control 2: back to flat
    cx + bumpHalf + 12, 0,      // rejoin flat
  );
  path.lineTo(size.width - r, 0);

  // Right arc
  path.arcToPoint(
    Offset(size.width - r, size.height),
    radius: Radius.circular(r),
    clockwise: true,
  );

  // Bottom edge
  path.lineTo(r, size.height);

  // Left arc
  path.arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: true);
  path.close();
  return path;
}
