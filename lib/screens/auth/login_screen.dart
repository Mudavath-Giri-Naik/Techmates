import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../welcome_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _ink = Color(0xFF0D0D1A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _red = Color(0xFFEF4444);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _fieldBg = Color(0xFFF9FAFB);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isRedirecting = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    // If already signed in (e.g. app resumed after Google OAuth), redirect immediately
    if (_auth.isLoggedIn) {
      _isRedirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuthEvent());
    }

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
    if (mounted) setState(() => _isRedirecting = true);

    try {
      await _auth.ensureSessionValid();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedirecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (mounted) _showLoginHelpDialog();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLoginHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: _red),
            SizedBox(width: 8),
            Text("Login failed", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _ink)),
          ],
        ),
        content: const Text(
          "Invalid credentials. If you signed up with Google, please continue with Google or use Forgot Password.",
          style: TextStyle(fontSize: 13, color: _muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleGoogleLogin();
            },
            child: const Text("Use Google", style: TextStyle(color: _blue)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Forgot Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('SocketException') || errorMsg.contains('host lookup')) {
        errorMsg = "Network error. Please check your internet connection.";
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show full-screen loader while redirecting (e.g. after Google OAuth return)
    if (_isRedirecting) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // ── Logo + Brand ──
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 48,
                      width: 48,
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1),
                        children: [
                          TextSpan(text: 'Tech', style: TextStyle(color: _red)),
                          TextSpan(text: 'mates', style: TextStyle(color: _blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Welcome text ──
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Sign in to explore opportunities",
                style: TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 28),

              // ── Email field ──
              _label("Email"),
              const SizedBox(height: 6),
              _field(
                controller: _emailController,
                hint: "you@example.com",
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // ── Password field ──
              _label("Password"),
              const SizedBox(height: 6),
              _field(
                controller: _passwordController,
                hint: "••••••••",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              // ── Forgot password ──
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _blue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Sign In button ──
              GestureDetector(
                onTap: _isLoading ? null : _handleEmailLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Divider ──
              Row(
                children: [
                  Expanded(child: Container(height: 0.6, color: _border)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text("or", style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(child: Container(height: 0.6, color: _border)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Google button ──
              GestureDetector(
                onTap: _isLoading ? null : _handleGoogleLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 16,
                        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: _blue),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Continue with Google",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Sign up link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _muted,
        letterSpacing: 1,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: _muted),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  child: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: _muted,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
