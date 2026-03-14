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
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    TrackerScreen(onFullscreenChanged: _setNavHidden, onGoToDecks: () => setState(() => _currentIndex = 4)),
    CardsScreen(key: _cardsKey),
    CollectionScreen(key: _collectionKey),
    MarketScreen(key: _marketKey, onFullscreenChanged: _setNavHidden),
    DecksScreen(
      key: _decksKey,
      onFullscreenChanged: _setNavHidden,
      onNavigateToAuthor: _navigateToAuthor,
    ),
    StatsScreen(key: _statsKey, onGoToTracker: () => setState(() => _currentIndex = 0)),
    SocialScreen(key: _socialKey, onViewPublicDeck: _viewPublicDeck, onGoToPublicDecks: () {
      setState(() => _currentIndex = 4);
      _decksKey.currentState?.showPublicDecks();
    }),
  ];

  void _navigateToAuthor(String authorId, String authorName) {
    setState(() => _currentIndex = 6); // Social tab
    _socialKey.currentState?.navigateToAuthor(authorId, authorName);
  }

  void _viewPublicDeck(PublicDeckData deck) {
    setState(() => _currentIndex = 4); // Decks tab
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
    }

    // Recalculate portfolio when collection changes (new cards added, etc.)
    if (!DemoService.instance.isActive) {
      FirestoreCollectionService.instance.addListener(() {
        final svc = FirestoreCollectionService.instance;
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
      MatchService.instance.stopListening();
      FirestoreDeckService.instance.stopListening();
      FirestoreCollectionService.instance.stopListening();
      PublicDeckService.instance.stopListening();
      FollowService.instance.stopListening();
      ListingService.instance.stopListening();
      ProfileService.instance.stopListening();
      SellerService.instance.stopListening();
      OrderService.instance.stopListening();
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
          AnimatedBuilder(
            animation: _navSlideController,
            builder: (context, child) {
              final slideValue = _navSlideController.value; // 1 = visible, 0 = hidden
              if (slideValue <= 0.01) return const SizedBox.shrink();
              return Positioned(
                bottom: -100 * (1 - slideValue), // slides 100px below screen
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: slideValue,
                  child: _buildFloatingNav(),
                ),
              );
            },
          ),
        ],
      ),
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
            margin: EdgeInsets.only(bottom: 16, left: 16, right: t > 0.5 ? 16 : 0),
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
                                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  setState(() => _currentIndex = i);
                                  switch (i) {
                                    case 1: _cardsKey.currentState?.resetScroll();
                                    case 2: _collectionKey.currentState?.resetScroll();
                                    case 3: _marketKey.currentState?.resetScroll();
                                    case 4: _decksKey.currentState?.resetScroll();
                                    case 5: _statsKey.currentState?.resetScroll();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                                                Icon(
                                                  _tabs[i].icon,
                                                  size: 42,
                                                  color: isActive
                                                      ? AppColors.amber100
                                                      : AppColors.textMuted,
                                                ),
                                                if (labelOpacity > 0.01) ...[
                                                  Opacity(
                                                    opacity: labelOpacity,
                                                    child: Text(
                                                      'Market',
                                                      style: TextStyle(
                                                        color: isActive
                                                            ? AppColors.amber100
                                                            : AppColors.textMuted,
                                                        fontSize: 11,
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
                                        Icon(
                                          _tabs[i].icon,
                                          size: 30,
                                          color: isActive ? AppColors.amber100 : AppColors.textMuted,
                                        ),
                                        if (labelOpacity > 0.01) ...[
                                          const SizedBox(height: 2),
                                          Opacity(
                                            opacity: labelOpacity,
                                            child: Text(
                                              _tabs[i].label,
                                              style: TextStyle(
                                                color: isActive ? AppColors.amber100 : AppColors.textMuted,
                                                fontSize: 10,
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
