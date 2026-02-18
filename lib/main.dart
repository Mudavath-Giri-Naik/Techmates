import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/supabase_client.dart';
import 'services/auth_service.dart';
import 'services/user_role_service.dart'; // Import Role Service
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart'; 
import 'screens/splash_screen.dart'; 
import 'screens/opportunity_detail_screen.dart';



@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? error;

  try {
    // Load env file
    await dotenv.load(fileName: ".env");
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await SupabaseClientManager.initialize();

    // Initialize Role Service (Load from cache)
    await UserRoleService().init();

    // Check strict session rules on startup
    final auth = AuthService();
    if (auth.isLoggedIn) {
      try {
        await auth.ensureSessionValid();
      } catch (e) {
        // If invalid (e.g. unverified email), force logout
        debugPrint("Session invalid on startup: $e");
        await auth.signOut();
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

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
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
