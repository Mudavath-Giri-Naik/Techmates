import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      final response = await _auth.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent! Please check your inbox and verify before logging in.')),
          );
          Navigator.pop(context); // Go back to login
        } else {
           // Session exists (maybe auto-confirm?). check verified?
           // If strict, we might still want to say "check email".
           // But if session is valid, we could technically log in?
           // The user says: "If session == null, treat it as email verification pending... DO NOT navigate."
           // If session != null, we might be good? Or we should check verified.
           // Let's assume response.session != null means we are good, BUT
           // AuthService will block login if not verified anyway.
           // So if we try to access home, we need validation.
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Created! Please Login.')),
          );
          Navigator.pop(context);
        }
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'College Email',
                hintText: 'example@mvgrce.edu.in',
              ),
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
            else
              ElevatedButton(
                onPressed: _handleSignup,
                child: const Text('Sign Up'),
              ),
          ],
        ),
      ),
    );
  }
}
