import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_screen.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Color _ink(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  Color _blue(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color _red(BuildContext context) => Theme.of(context).colorScheme.error;
  Color _border(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;
  Color _fieldBg(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isRedirecting = false;
  bool _isPasswordVisible = false;
  bool _showEmailForm = false;

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
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedirecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: _red(context),
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
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: _red(context)),
            const SizedBox(width: 8),
            Text("Login failed", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _ink(context))),
          ],
        ),
        content: Text(
          "Invalid credentials. If you signed up with Google, please continue with Google or use Forgot Password.",
          style: TextStyle(fontSize: 13, color: _muted(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleGoogleLogin();
            },
            child: Text("Use Google", style: TextStyle(color: _blue(context))),
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
                color: _ink(context),
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
    if (_isRedirecting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(width: 36, height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue(context))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32, // -32 for vertical padding
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo + Brand ──────────────────────────────────────────
                    Center(child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png', 
                          height: 56, 
                          width: 56,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(text: const TextSpan(
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.2),
                        children: [
                          TextSpan(text: 'Tech', style: TextStyle(color: Color(0xFFF0190A))),
                          TextSpan(text: 'mates', style: TextStyle(color: Color(0xFF0B19D9))),
                        ],
                      )),
                    ])),
                    const SizedBox(height: 48),

                    // ── Welcome ───────────────────────────────────────────────
                    Center(
                      child: Text("Welcome back",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink(context), letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text("Sign in to explore opportunities",
                        style: TextStyle(fontSize: 14, color: _muted(context))),
                    ),
                    const SizedBox(height: 40),

                    // ── Continue with Google (primary) ────────────────────────
                    GestureDetector(
                      onTap: _isLoading ? null : _handleGoogleLogin,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _ink(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _ink(context).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text("Continue with Google",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Continue with Gmail (secondary — reveals email form) ──
                    if (!_showEmailForm) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() => _showEmailForm = true);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border(context), width: 1.5),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.email_outlined, size: 18, color: _ink(context)),
                            const SizedBox(width: 10),
                            Text("Continue with Email",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                color: _ink(context))),
                          ]),
                        ),
                      ),
                    ],

                    // ── Email form (only visible after tap) ───────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: _showEmailForm ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Row(children: [
                            Expanded(child: Container(height: 1, color: _border(context))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text("or sign in with email", style: TextStyle(fontSize: 12, color: _muted(context), fontWeight: FontWeight.w600))),
                            Expanded(child: Container(height: 1, color: _border(context))),
                          ]),
                          const SizedBox(height: 24),

                          _label(context, "Email"),
                          const SizedBox(height: 8),
                          _field(
                            context: context,
                            controller: _emailController,
                            hint: "you@example.com",
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          _label(context, "Password"),
                          const SizedBox(height: 8),
                          _field(
                            context: context,
                            controller: _passwordController,
                            hint: "••••••••",
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Padding(padding: const EdgeInsets.only(top: 12),
                                child: Text("Forgot password?",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _blue(context)))),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Sign In button
                          GestureDetector(
                            onTap: _isLoading ? null : _handleEmailLogin,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _blue(context),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _blue(context).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Center(
                                child: _isLoading
                                  ? const SizedBox(height: 18, width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text("Sign In",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ) : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Sign up link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account?",
                        style: TextStyle(fontSize: 13, color: _muted(context))),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text("Sign Up",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _red(context))),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _label(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _muted(context),
        letterSpacing: 1,
      ),
    );
  }

  Widget _field({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border(context), width: 0.8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: _ink(context), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: _muted(context)),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  child: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: _muted(context),
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
