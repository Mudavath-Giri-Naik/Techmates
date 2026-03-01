import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../utils/college_email_validator.dart';
import 'user_role_service.dart';

class AuthService {
  // Singleton — only one listener ever registered
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final SupabaseClient _client = SupabaseClientManager.instance;

  AuthService._internal() {
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
      debugPrint('[AUTH] Login profile upsert done');
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
  // Google Login (Native — no browser needed)
  // =============================
  Future<void> signInWithGoogle() async {
    debugPrint('[AUTH] Starting native Google Sign-In...');

    // Use Google Play Services to show native account chooser
    final googleSignIn = GoogleSignIn(
      serverClientId: '968736212482-cdfo509mfoai7b9cceauqn4m9uabemdo.apps.googleusercontent.com',
    );

    // Always sign out first to force the account chooser to appear
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('[AUTH] Google Sign-In cancelled by user');
      throw 'Google Sign-In was cancelled.';
    }

    debugPrint('[AUTH] Google user: ${googleUser.email}');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      debugPrint('[AUTH] Failed to get ID token from Google');
      throw 'Failed to get ID token from Google.';
    }

    debugPrint('[AUTH] Got Google ID token, authenticating with Supabase...');

    // Authenticate with Supabase using the Google ID token
    // This goes through the proxy (api.girinaik.in) — no browser redirect needed
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    debugPrint('[AUTH] Supabase auth response: ${response.user?.email ?? 'null'}');
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
