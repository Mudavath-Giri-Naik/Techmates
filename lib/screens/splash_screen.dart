import 'dart:async';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'main_screen.dart';
import 'onboarding/onboarding_form_screen.dart';
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

  late Animation<double> _gridOpacity;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _brandFade;
  late Animation<Offset> _brandSlide;
  late Animation<double> _lineFade;
  late Animation<double> _lineWidth;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _dotsFade;

  bool _didNavigate = false;
  bool _navigationInProgress = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();

    _gridController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _gridOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.30, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack)),
    );

    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)),
    );
    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic)),
    );

    _lineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.35, 0.55, curve: Curves.easeOut)),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic)),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.50, 0.80, curve: Curves.easeOut)),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic)),
    );

    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.70, 0.95, curve: Curves.easeOut)),
    );

    _gridController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });

    unawaited(OpportunityStore.instance.fetchAll());
    unawaited(_runSplashFlow());
  }

  Future<void> _runSplashFlow() async {
    _stopwatch.start();
    debugPrint('[SPLASH] Started');
    debugPrint('[SPLASH] Timer started');

    await Future.any([
      _splashLogic(),
      Future.delayed(const Duration(seconds: 3), () async {
        if (_didNavigate || !mounted) return;
        debugPrint('[SPLASH] 3s hard cap triggered - forcing navigation');
        await _forceNavigateFromCache();
      }),
    ]);
  }

  Future<void> _splashLogic() async {
    final auth = AuthService();
    final loggedIn = auth.isLoggedIn;
    debugPrint('[SPLASH] Local session check: $loggedIn');

    if (!loggedIn) {
      _navigateTo(const LoginScreen(), 'LoginScreen');
      return;
    }

    final user = auth.user;
    if (user == null) {
      _navigateTo(const LoginScreen(), 'LoginScreen');
      return;
    }
    final userId = user.id;
    final cachedRole = UserRoleService().role;
    final cachedOnboarding = await ProfileService().getOnboardingCached(userId) ?? false;

    debugPrint('[SPLASH] Cached role: $cachedRole');
    debugPrint('[SPLASH] Cached onboarding: $cachedOnboarding');

    if (cachedRole == 'admin' || cachedRole == 'super_admin') {
      _navigateTo(const MainScreen(), 'MainScreen');
      _runBackgroundRefresh(userId);
      return;
    }

    if (cachedOnboarding) {
      _navigateTo(const MainScreen(), 'MainScreen');
    } else {
      _navigateTo(
        OnboardingFormScreen(
          userId: userId,
          initialName: user.userMetadata?['full_name'] as String? ?? '',
        ),
        'OnboardingFormScreen',
      );
    }
    _runBackgroundRefresh(userId);
  }

  Future<void> _forceNavigateFromCache() async {
    final auth = AuthService();
    if (!auth.isLoggedIn) {
      _navigateTo(const LoginScreen(), 'LoginScreen');
      return;
    }

    final userId = auth.user?.id;
    final cachedRole = UserRoleService().role;
    final cachedOnboarding =
        userId == null ? false : (await ProfileService().getOnboardingCached(userId) ?? false);
    debugPrint('[SPLASH] Cached role: $cachedRole');
    debugPrint('[SPLASH] Cached onboarding: $cachedOnboarding');

    if (cachedRole == 'admin' || cachedRole == 'super_admin' || cachedOnboarding) {
      _navigateTo(const MainScreen(), 'MainScreen');
    } else if (userId != null) {
      final user = auth.user;
      _navigateTo(
        OnboardingFormScreen(
          userId: userId,
          initialName: user?.userMetadata?['full_name'] as String? ?? '',
        ),
        'OnboardingFormScreen',
      );
    } else {
      _navigateTo(const LoginScreen(), 'LoginScreen');
    }
  }

  void _runBackgroundRefresh(String userId) {
    unawaited(UserRoleService().fetchAndCacheRole(userId));
    unawaited(ProfileService().fetchProfile(userId).then((_) {}));
    unawaited(Future<void>(() async {
      await Future.delayed(const Duration(milliseconds: 250));
      await AppUpdateService().checkForUpdate(context);
    }));
  }

  void _navigateTo(Widget page, String screenName) {
    if (!mounted || _didNavigate || _navigationInProgress) return;
    _navigationInProgress = true;
    debugPrint('[SPLASH] Navigating to: $screenName');
    debugPrint('[SPLASH] Total splash time: ${_stopwatch.elapsedMilliseconds}ms');
    debugPrint('[SPLASH] Done');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryNavigate(page, 0);
    });
  }

  void _tryNavigate(Widget page, int attempt) {
    if (!mounted || _didNavigate) return;
    try {
      Navigator.pushReplacement(context, FadePageRoute(page: page));
      _didNavigate = true;
    } catch (e) {
      debugPrint('[SPLASH] Navigation attempt ${attempt + 1} failed: $e');
      if (attempt >= 3) {
        _navigationInProgress = false;
        return;
      }
      Future.delayed(const Duration(milliseconds: 80), () {
        _tryNavigate(page, attempt + 1);
      });
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
          Center(
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
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
                                  color: _muted.withValues(alpha: 0.9),
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
                                    color: _muted.withValues(alpha: 0.9),
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 28;
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }

    final accentPaint = Paint()
      ..color = const Color(0xFFD1D5DB).withValues(alpha: 0.4)
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
                color: widget.color.withValues(alpha: _opacities[i].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

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
