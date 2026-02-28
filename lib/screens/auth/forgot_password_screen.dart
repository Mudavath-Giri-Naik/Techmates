import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  Color _ink(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  Color _blue(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color _red(BuildContext context) => Theme.of(context).colorScheme.error;
  Color _border(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;
  Color _fieldBg(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;

  final _emailController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleReset() async {
    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordOtp(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to email.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                    border: Border.all(color: _border(context), width: 0.8),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _ink(context)),
                ),
              ),
              const SizedBox(height: 32),

              // ── Heading ──
              Text(
                "Forgot password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Enter your email to receive a reset link",
                style: TextStyle(fontSize: 13, color: _muted(context)),
              ),
              const SizedBox(height: 32),

              _label(context, "Email Address"),
              const SizedBox(height: 6),
              _field(
                context: context,
                controller: _emailController,
                hint: "you@example.com",
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: _isLoading ? null : _handleReset,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _blue(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text(
                            "Send Reset Link",
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
            ],
          ),
        ),
      ),
    );
  }

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
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: _ink(context), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: _muted(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
