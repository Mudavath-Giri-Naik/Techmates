import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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
  bool _isPasswordVisible = false;

  Future<void> _handleSignup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _auth.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF2563EB),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please login.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('SocketException') || errorMsg.contains('host lookup')) {
          errorMsg = "Network error. Please check your internet connection.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border, width: 0.8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _ink),
                ),
              ),
              const SizedBox(height: 28),

              // ── Brand ──
              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                    children: [
                      TextSpan(text: 'Tech', style: TextStyle(color: _red)),
                      TextSpan(text: 'mates', style: TextStyle(color: _blue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Heading ──
              const Text(
                "Create account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Join the student community for opportunities",
                style: TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 28),

              // ── Email field ──
              _label("College Email"),
              const SizedBox(height: 6),
              _field(
                controller: _emailController,
                hint: "you@college.edu.in",
                icon: Icons.school_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // ── Password field ──
              _label("Password"),
              const SizedBox(height: 6),
              _field(
                controller: _passwordController,
                hint: "min. 6 characters",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 28),

              // ── Create Account button ──
              GestureDetector(
                onTap: _isLoading ? null : _handleSignup,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text(
                            "Create Account",
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
              const SizedBox(height: 24),

              // ── Info box ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _blue.withOpacity(0.2), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: _blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Use your college email for better curation and verification.",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _blue.withOpacity(0.8),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Sign in link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _blue,
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
