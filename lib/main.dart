import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'core/supabase_client.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? error;

  try {
    // Load env file
    await dotenv.load(fileName: ".env");
    await SupabaseClientManager.initialize();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We can safely create AuthService here because we only run MyApp if init succeeded.
    final auth = AuthService();

    return MaterialApp(
      title: 'Techmates Auth',
      theme: ThemeData(
        // Enforce light mode to prevent "White Text on White Background" issues
        // if the system is in Dark Mode but the app is hardcoded to light backgrounds.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Explicitly style text selection controls
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.deepPurple,
          selectionColor: Colors.deepPurple.withOpacity(0.4),
          selectionHandleColor: Colors.deepPurple,
        ),
      ),
      // Simple routing based on auth state
      home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
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
