import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';
import '../services/app_update_service.dart';
import '../services/opportunity_store.dart';
import '../services/user_role_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const Color _ink = Color(0xFF0D0D1A);
  static const Color _red = Color(0xFFEF4444);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF9CA3AF);

  late AnimationController _gridController;
  late AnimationController _contentController;

  // Grid dots fade in
  late Animation<double> _gridOpacity;

  // Staggered content animations
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _brandFade;
  late Animation<Offset> _brandSlide;
  late Animation<double> _lineFade;
  late Animation<double> _lineWidth;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    // Grid animation — subtle pulse
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _gridOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // Content stagger controller
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    // Logo: fade + scale (0% → 30%)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.30, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack)),
    );

    // Brand name: fade + slide up (15% → 45%)
    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)),
    );
    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic)),
    );

    // Divider line: fade + expand width (35% → 60%)
    _lineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.35, 0.55, curve: Curves.easeOut)),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic)),
    );

    // Tagline: fade + slide up (50% → 80%)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.50, 0.80, curve: Curves.easeOut)),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic)),
    );

    // Bottom dots: fade in (70% → 95%)
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.70, 0.95, curve: Curves.easeOut)),
    );

    // Start animations
    _gridController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });

    // Eager fetch
    OpportunityStore.instance.fetchAll();

    // Navigate after splash
    Timer(const Duration(seconds: 3), () async {
      await AppUpdateService().checkForUpdate(context);
      if (mounted) _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    final auth = AuthService();
    if (auth.isLoggedIn) {
      await UserRoleService().fetchAndCacheRole(auth.user!.id);
      if (mounted) {
        Navigator.pushReplacement(context, FadePageRoute(page: const HomeScreen()));
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(context, FadePageRoute(page: const LoginScreen()));
      }
    }
  }

  @override
  void dispose() {
    _gridController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Animated dot grid background ──
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, child) {
              return Opacity(
                opacity: _gridOpacity.value,
                child: CustomPaint(
                  painter: _DotGridPainter(),
                  size: Size.infinite,
                ),
              );
            },
          ),

          // ── Main content ──
          Center(
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 56,
                          width: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand name
                    SlideTransition(
                      position: _brandSlide,
                      child: FadeTransition(
                        opacity: _brandFade,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                            children: [
                              TextSpan(text: 'Tech', style: TextStyle(color: _red)),
                              TextSpan(text: 'mates', style: TextStyle(color: _blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Animated divider line
                    FadeTransition(
                      opacity: _lineFade,
                      child: SizedBox(
                        width: 180,
                        child: Align(
                          alignment: Alignment.center,
                          child: AnimatedBuilder(
                            animation: _lineWidth,
                            builder: (context, _) {
                              return Container(
                                height: 1,
                                width: 180 * _lineWidth.value,
                                color: const Color(0xFFD1D5DB),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Column(
                            children: [
                              Text(
                                "A centralized opportunity",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _muted.withOpacity(0.9),
                                  letterSpacing: 0.2,
                                  height: 1.5,
                                ),
                              ),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _muted.withOpacity(0.9),
                                    letterSpacing: 0.2,
                                    height: 1.5,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "control system",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    TextSpan(text: " for "),
                                    TextSpan(
                                      text: "students",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _blue,
                                      ),
                                    ),
                                    TextSpan(text: "."),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Bottom loading dots
                    FadeTransition(
                      opacity: _dotsFade,
                      child: _LoadingDots(color: _muted),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────
// DOT GRID PAINTER
// ────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 28;
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }

    // Slightly larger dots at intersections of a wider grid
    final accentPaint = Paint()
      ..color = const Color(0xFFD1D5DB).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    const double wideSpacing = spacing * 4;
    for (double x = wideSpacing; x < size.width; x += wideSpacing) {
      for (double y = wideSpacing; y < size.height; y += wideSpacing) {
        canvas.drawCircle(Offset(x, y), 1.8, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ────────────────────────────────────
// ANIMATED LOADING DOTS
// ────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _opacities = _controllers.map((c) {
      return Tween<double>(begin: 0.2, end: 0.8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the dot animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _opacities[i],
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(_opacities[i].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// ────────────────────────────────────
// FADE PAGE ROUTE
// ────────────────────────────────────

class FadePageRoute extends PageRouteBuilder {
  final Widget page;
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}
