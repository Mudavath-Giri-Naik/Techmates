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



@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background message: ${message.messageId}");
}

// CHANGED: main() now only does local/essential init. All network calls are deferred.
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
    final packageInfo = await PackageInfo.fromPlatform();
    debugPrint("🚀 Techmates App Version: ${packageInfo.version}");
    debugPrint("📦 Build Number: ${packageInfo.buildNumber}");

    // Load env file (local asset)
    await dotenv.load(fileName: ".env");
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // CHANGED: Supabase init now uses autoRefreshToken: false (see supabase_client.dart)
    // so this will NOT make any network calls and completes instantly.
    await SupabaseClientManager.initialize();

    // Initialize Role Service (Load from SharedPreferences cache — local only)
    try {
      await UserRoleService().init();
    } catch (e) {
      debugPrint('[INIT] Role cache init failed - proceeding anyway: $e');
    }

    // REMOVED: ensureSessionValid() was here — it made a network DB query
    // before runApp(), blocking the entire UI from appearing.
    // Now deferred to _runDeferredStartupTasks() below.

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

    // 4. Eager fetch opportunities in background
    unawaited(OpportunityStore.instance.fetchAll());

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

      // Always wait a beat so the navigator is ready after login screen
      await Future.delayed(const Duration(milliseconds: 100));

      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      // 1. Fetch fresh role (with timeout)
      try {
        await UserRoleService().refreshRoleNow(user.id)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        debugPrint('⚠️ [App] Role fetch timed out, using cached.');
      } catch (e) {
        debugPrint('⚠️ [App] Role fetch failed: $e');
      }
      final role = UserRoleService().role;
      debugPrint('🧭 [App] Role = $role');

      // 2. Admin → MainScreen (full bottom navigation)
      if (role == 'admin' || role == 'super_admin') {
        debugPrint('🧭 [App] Admin → MainScreen');
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (r) => false,
        );
        return;
      }

      // 3. Student → check onboarding_completed (with timeout — already in ProfileService)
      final profile = await ProfileService()
          .refreshProfileNow(user.id)
          .timeout(const Duration(seconds: 5));
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
    });
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Techmates Auth',
      scrollBehavior: const SmoothScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
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
          cursorColor: Colors.deepPurple,
          selectionColor: Colors.deepPurple.withOpacity(0.4),
          selectionHandleColor: Colors.deepPurple,
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
