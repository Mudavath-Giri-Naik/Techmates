import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/supabase_client.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/user_role_service.dart';
import 'services/app_update_service.dart';
import 'services/opportunity_store.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_form_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/opportunity_detail_screen.dart';
import 'core/theme_notifier.dart';
import 'models/user_profile.dart';



@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background message: ${message.messageId}");
}

// FIX 11: main() does only local/instant init. Supabase init is non-blocking.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make status bar icons dark on light backgrounds globally
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  String? error;

  try {
    // ── Local-only init (no network, instant) ──
    final packageInfo = await PackageInfo.fromPlatform();
    debugPrint("🚀 Techmates App Version: ${packageInfo.version}");
    debugPrint("📦 Build Number: ${packageInfo.buildNumber}");

    await ThemeNotifier.instance.init();
    await dotenv.load(fileName: ".env");

    // Firebase init (local — reads google-services.json)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Supabase must be awaited — MyApp.initState accesses Supabase.instance
    // immediately. The 5s timeout in SupabaseClientManager prevents hanging.
    await SupabaseClientManager.initialize();

    // If Supabase failed to initialize, don't proceed to MyApp
    if (!SupabaseClientManager.isInitialized) {
      error = 'Supabase failed to initialize. Check your internet connection and .env file.';
    }

    // Load cached role from SharedPreferences (local only)
    if (error == null) {
      try {
        await UserRoleService().init();
      } catch (e) {
        debugPrint('[INIT] Role cache init failed - proceeding anyway: $e');
      }
    }

  } catch (e) {
    error = e.toString();
    debugPrint('Initialization failed: $e');
  }

  if (error != null) {
    runApp(ErrorApp(message: "Failed to initialize App.\n\nError: $error\n\nPlease check your .env file."));
  } else {
    runApp(const MyApp());
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Auth state subscription — handles routing after Google/email login
  late final Stream<AuthState> _authStream =
      SupabaseClientManager.instance.auth.onAuthStateChange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenAuthState();

    // CHANGED: Schedule deferred startup tasks AFTER first frame renders.
    // This ensures splash is visible before any network work begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDeferredStartupTasks();
    });
  }

  // CHANGED: All network-dependent startup work moved here.
  // Runs fire-and-forget after the first frame so UI is never blocked.
  void _runDeferredStartupTasks() {
    final auth = AuthService();

    // 1. Try to refresh the session in background (since autoRefreshToken is off)
    unawaited(Future(() async {
      try {
        if (auth.session != null) {
          debugPrint("🔄 [Deferred] Refreshing session token...");
          await SupabaseClientManager.instance.auth
              .refreshSession()
              .timeout(const Duration(seconds: 5));
          debugPrint("✅ [Deferred] Session refreshed.");
        }
      } on TimeoutException {
        debugPrint("⚠️ [Deferred] Session refresh timed out (offline?).");
      } catch (e) {
        debugPrint("⚠️ [Deferred] Session refresh failed: $e");
      }
    }));

    // 2. Validate session in background
    if (auth.isLoggedIn) {
      unawaited(Future(() async {
        try {
          await auth.ensureSessionValid();
        } catch (e) {
          debugPrint("❌ [Deferred] Session invalid: $e");
          await auth.signOut();
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false,
          );
        }
      }));

      // 3. Fetch fresh role in background
      unawaited(Future(() async {
        try {
          final userId = auth.user!.id;
          await UserRoleService().fetchAndCacheRole(userId)
              .timeout(const Duration(seconds: 5));
        } on TimeoutException {
          debugPrint("⚠️ [Deferred] Role fetch timed out.");
        } catch (e) {
          debugPrint("⚠️ [Deferred] Role fetch failed: $e");
        }
      }));
    }

    // 4. Eager fetch opportunities — removed, splash_screen already does this

    // 5. Check for app update in background (needs context, delayed slightly)
    unawaited(Future.delayed(const Duration(seconds: 2), () {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        AppUpdateService().checkForUpdate(ctx);
      }
    }));
  }

  void _listenAuthState() {
    _authStream.listen((data) async {
      if (data.event != AuthChangeEvent.signedIn) return;
      final user = data.session?.user;
      if (user == null) return;

      debugPrint('🧭 [App] signedIn → running routing for ${user.email}');

      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      // FIX 12: Check cache first — navigate immediately if available
      final cachedRole = UserRoleService().role;
      final cachedProfile = await ProfileService().getProfileCached(user.id);

      if (cachedRole.isNotEmpty && cachedProfile != null) {
        debugPrint('🧭 [App] Cache hit — navigating immediately');
        _navigateForUser(user, cachedRole, cachedProfile);

        // Refresh in background (fire-and-forget)
        unawaited(Future.wait([
          UserRoleService().refreshRoleNow(user.id)
              .timeout(const Duration(seconds: 8), onTimeout: () => ''),
          ProfileService().refreshProfileNow(user.id)
              .timeout(const Duration(seconds: 8), onTimeout: () => null),
        ]));
        return;
      }

      // No cache — FIX 2: fetch role + profile in parallel (max 5s)
      debugPrint('🧭 [App] No cache — fetching role + profile in parallel');
      String role = 'student';
      UserProfile? profile;
      try {
        final results = await Future.wait([
          UserRoleService().refreshRoleNow(user.id)
              .timeout(const Duration(seconds: 5), onTimeout: () => 'student'),
          ProfileService().refreshProfileNow(user.id)
              .timeout(const Duration(seconds: 5), onTimeout: () => null),
        ]);
        role = results[0] as String? ?? 'student';
        profile = results[1] as UserProfile?;
      } catch (e) {
        debugPrint('⚠️ [App] Parallel fetch failed: $e');
        role = UserRoleService().role;
      }

      _navigateForUser(user, role, profile);
    });
  }

  void _navigateForUser(User user, String role, UserProfile? profile) {
    debugPrint('🧭 [App] Role = $role');

    if (role == 'admin' || role == 'super_admin') {
      debugPrint('🧭 [App] Admin → MainScreen');
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (r) => false,
      );
      return;
    }

    final onboardingDone = profile?.onboardingCompleted ?? false;
    debugPrint('🧭 [App] profile=${profile == null ? "null" : "exists"}, onboarding_completed=$onboardingDone');

    if (onboardingDone) {
      debugPrint('🧭 [App] onboarding done → MainScreen');
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (r) => false,
      );
    } else {
      debugPrint('🧭 [App] onboarding NOT done → OnboardingFormScreen');
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OnboardingFormScreen(
            userId: user.id,
            initialName: profile?.name ??
                (user.userMetadata?['full_name'] as String?) ??
                '',
          ),
        ),
        (r) => false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // CHANGED: AuthService is now a singleton, so no duplicate listener created.
      final auth = AuthService();

      if (auth.isLoggedIn) {
        try {
          debugPrint("🔄 [LIFECYCLE] App resumed. Revalidating session...");
          // CHANGED: Added timeout to prevent hanging on resume with no internet
          await auth.ensureSessionValid()
              .timeout(const Duration(seconds: 5));
        } on TimeoutException {
          debugPrint("⚠️ [LIFECYCLE] Session validation timed out on resume.");
        } catch (e) {
          debugPrint("❌ [LIFECYCLE] Session invalid on resume: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeNotifier.instance,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Techmates Auth',
          scrollBehavior: const SmoothScrollBehavior(),
          themeMode: ThemeNotifier.instance.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0),
              brightness: Brightness.light,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
              },
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: const Color(0xFF1565C0),
              selectionColor: const Color(0xFF1565C0).withOpacity(0.4),
              selectionHandleColor: const Color(0xFF1565C0),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0),
              brightness: Brightness.dark,
              surface: Colors.black,
            ),
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.black,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
              },
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: const Color(0xFF90CAF9),
              selectionColor: const Color(0xFF1565C0).withOpacity(0.4),
              selectionHandleColor: const Color(0xFF90CAF9),
            ),
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/opportunity_detail': (context) {
               final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
               return OpportunityDetailScreen(
                 opportunityId: args['opportunityId'],
                 type: args['type'],
               );
            },
            '/edit_profile': (context) => const EditProfileScreen(),
          },
        );
      }
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Global smooth scroll — iOS-style bouncing on all platforms
// ─────────────────────────────────────────────────────
class SmoothScrollBehavior extends ScrollBehavior {
  const SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }
}

// ─────────────────────────────────────────────────────
// No-animation page transitions — instant screen switches
// ─────────────────────────────────────────────────────
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
