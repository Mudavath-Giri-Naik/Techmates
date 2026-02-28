import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../utils/college_email_validator.dart';
import 'profile_service.dart';
import 'user_role_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  AuthService() {
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      debugPrint("[AUTH] Auth state change: $event");
      if (session != null) {
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          unawaited(_onLoginSuccess(session.user));
          unawaited(UserRoleService().fetchAndCacheRole(session.user.id));
        }
      } else {
        if (event == AuthChangeEvent.signedOut) {
          unawaited(UserRoleService().clear());
        }
      }
    });
  }

  Future<void> _onLoginSuccess(User user) async {
    try {
      final metadata = user.userMetadata ?? {};
      await _client.from('profiles').upsert(
        {
          'id': user.id,
          'email': user.email,
          'name': metadata['full_name'] ?? metadata['name'] ?? '',
          'avatar_url': metadata['avatar_url'] ??
              metadata['picture'] ??
              metadata['custom_avatar_url'],
          'role': 'student',
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
        ignoreDuplicates: false,
      );
      // Keep local cache warm.
      final profile = await ProfileService().refreshProfileNow(user.id);
      if (profile == null) {
        debugPrint('[AUTH] Login sync done, profile not found in DB');
      }
    } catch (e) {
      debugPrint('[AUTH] Failed to sync profile on login: $e');
    }
  }

  // =============================
  // STRICT VALIDATION (The Guard)
  // =============================
  Future<void> ensureSessionValid() async {
    debugPrint('[AUTH] ensureSessionValid started');
    try {
      await _ensureSessionValidInternal().timeout(const Duration(seconds: 5));
      debugPrint('[AUTH] ensureSessionValid done');
    } on TimeoutException {
      debugPrint('[AUTH] ensureSessionValid TIMED OUT');
    }
  }

  Future<void> _ensureSessionValidInternal() async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    if (session == null || user == null) {
      throw "No active session. Please login.";
    }

    final profile = await _client
        .from('profiles')
        .select('is_active')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null || profile['is_active'] == false) {
      await signOut();
      throw "Your account has been deactivated. Contact admin.";
    }

    if (user.emailConfirmedAt == null) {
      await signOut();
      throw "Email not verified. Please check your inbox and verify your email.";
    }

    if (!CollegeEmailValidator.isValid(user.email!)) {
      await signOut();
      throw "Invalid allowed domain. Use college email only.";
    }
  }

  // =============================
  // Google Login
  // =============================
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://signin-callback/',
    );
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // =============================
  // Signup
  // =============================
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (!CollegeEmailValidator.isValid(email)) {
      throw "Use college email only";
    }
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'student'},
      emailRedirectTo: 'io.supabase.flutter://signin-callback/',
    );
  }

  // =============================
  // Login
  // =============================
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await ensureSessionValid();
    if (_client.auth.currentUser != null) {
      await _onLoginSuccess(_client.auth.currentUser!);
    }
  }

  // =============================
  // Operations
  // =============================
  Future<void> sendPasswordOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<void> verifyPasswordOtp(String email, String otp) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: otp,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateCustomAvatar(String? url) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'custom_avatar_url': url}),
    );
  }

  Future<void> updateUserAvatar(String? url) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'avatar_url': url}),
    );
  }

  // =============================
  // State
  // =============================
  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  bool get isLoggedIn {
    final cachedSession = session;
    debugPrint('[AUTH] Session from cache: ${cachedSession == null ? 'null' : 'exists'}');
    final loggedIn = cachedSession != null;
    debugPrint('[AUTH] isLoggedIn: $loggedIn');
    return loggedIn;
  }
  String get role => user?.userMetadata?['role'] ?? 'student';
  bool get isAdmin => role == 'admin';

  Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    await _client.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
