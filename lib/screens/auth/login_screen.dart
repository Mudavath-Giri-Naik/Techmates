import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';
import 'set_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isRedirecting = false; // To prevent double nav

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authStateChanges.listen((data) {
      final event = data.event;
      debugPrint("🔔 [LoginScreen] Auth Event: $event");
      
      if (event == AuthChangeEvent.signedIn) {
        _handleAuthEvent();
      } else if (event == AuthChangeEvent.passwordRecovery) {
        _handlePasswordRecovery();
      }
    });
  }

  Future<void> _handlePasswordRecovery() async {
    debugPrint("🔄 [LoginScreen] Password Recovery Detected. Navigating...");
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthEvent() async {
    if (_isRedirecting) return;
    _isRedirecting = true; // Block multiple calls

    try {
      // Logic to validate session when we detect a sign-in event
      // This covers Google Login (which fires this event async)
      // and Email Login (which fires this too).
      
      debugPrint("🔔 [LoginScreen] SignedIn Event detected. Validating...");
      await _auth.ensureSessionValid();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("❌ [LoginScreen] Validation failed after sign-in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      _isRedirecting = false; // Reset to allow retry
    }
  }



  Future<void> _handleEmailLogin() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    try {
      await _auth.signInWithEmail(
        email: email,
        password: password,
      );
      // Success? The listener will handle navigation.
      
    } on AuthException catch (e) {
      if (mounted) {
        // Show UX Friendly Dialog on Login Failure
        _showLoginHelpDialog();
        debugPrint("❌ [LoginScreen] AuthException: ${e.message}");
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      _isRedirecting = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showLoginHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login failed"),
        content: const Text(
          "Invalid credentials.\n\n"
          "If you signed up with Google, please continue with Google or use Forgot Password to set a password."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleGoogleLogin();
            },
            child: const Text("Continue with Google"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: const Text("Forgot Password"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    // We don't set _isLoading = true here effectively because it's a redirect flow
    // But we can show a spinner.
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithGoogle();
      // We DO NOT navigate here. We wait for the listener.
      // If web/mobile redirect happens, the app will pause/resume.
      // On resume, URL is parsed -> Session set -> SIGNED_IN fires -> listener -> navigation.
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In Failed: $e')));
    } finally {
      // Always reset loading state because the auth flow continues externally (browser)
      // If we don't reset, returning to the app without login leaves the UI stuck.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _handleEmailLogin,
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _handleGoogleLogin,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
            ],
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              ),
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
