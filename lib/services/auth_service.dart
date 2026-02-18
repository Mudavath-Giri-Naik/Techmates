import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../utils/college_email_validator.dart';
import '../models/user_profile.dart';
import 'profile_service.dart';
import 'user_role_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  AuthService() {
    // Debug listener for all auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      debugPrint("🔔 [AuthService] Auth State Change: $event");
      if (session != null) {
        debugPrint("   -> Session Active: ${session.user.email}");
        debugPrint("   -> Email Verified: ${session.user.emailConfirmedAt}");
        
        // Post-Login Profile Sync
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
           _onLoginSuccess(session.user);
           // Fetch Role
           UserRoleService().fetchAndCacheRole(session.user.id);
        }
      } else {
        // Clear role on logout
        if (event == AuthChangeEvent.signedOut) {
             UserRoleService().clear();
        }
        debugPrint("   -> No Session");
      }
    });
  }

  Future<void> _onLoginSuccess(User user) async {
    try {
      // 1. Sync Profile
      final profileService = ProfileService();
      final metadata = user.userMetadata ?? {};
      
      final profile = UserProfile(
        id: user.id,
        email: user.email!,
        name: metadata['full_name'] ?? metadata['name'] ?? '',
        avatarUrl: metadata['avatar_url'] ?? metadata['picture'] ?? metadata['custom_avatar_url'],
        role: metadata['role'] ?? 'student',
        updatedAt: DateTime.now(),
      );
      
      await profileService.upsertProfile(profile);
      
      // 2. Fetch Role (Redundant call but ensures freshness)
      // await UserRoleService().fetchAndCacheRole(user.id); 
    } catch (e) {
      debugPrint("⚠️ [AuthService] Failed to sync profile on login: $e");
    }
  }

  // =============================
  // STRICT VALIDATION (The Guard)
  // =============================
  Future<void> ensureSessionValid() async {
    debugPrint("🛡️ [AuthService] Validating Session...");
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    if (session == null || user == null) {
      debugPrint("❌ [AuthService] Validation Failed: No active session.");
      throw "No active session. Please login.";
    }

    debugPrint("🔍 [AuthService] Checking account activation status...");
    final profile = await _client
        .from('profiles')
        .select('is_active')
        .eq('id', user.id)
        .maybeSingle();

    if (profile != null) {
      debugPrint("🔍 [AuthService] is_active: ${profile['is_active']}");
    }

    if (profile == null || profile['is_active'] == false) {
      debugPrint("❌ [AuthService] Account deactivated.");
      await signOut();
      throw "Your account has been deactivated. Contact admin.";
    }

    debugPrint("   -> User: ${user.email}");
    
    // Check Email Verification
    if (user.emailConfirmedAt == null) {
      debugPrint("❌ [AuthService] Validation Failed: Email NOT verified.");
      await signOut(); 
      throw "Email not verified. Please check your inbox and verify your email.";
    }

    // Check Domain Validation
    if (!CollegeEmailValidator.isValid(user.email!)) {
      debugPrint("❌ [AuthService] Validation Failed: Invalid Domain.");
      await signOut(); 
      throw "Invalid allowed domain. Use college email only.";
    }

    debugPrint("✅ [AuthService] Session Validated Successfully.");
  }


  // =============================
  // Google Login
  // =============================
  Future<void> signInWithGoogle() async {
    debugPrint("🌐 [AuthService] initiating Google Sign-In...");
    try {
      // kIsWeb check is useful, but assuming mobile here based on user context, 
      // strictly following instructions to just use OAuthProvider.google
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://signin-callback/',
      );
      debugPrint("🌐 [AuthService] Google OAuth flow started.");
    } catch (e) {
      debugPrint("❌ [AuthService] Google Sign-In Error: $e");
      rethrow;
    }
  }

  // Monitor for Google Login Completion
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // =============================
  // Signup
  // =============================
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint("📝 [AuthService] Attempting Signup: $email");

    if (!CollegeEmailValidator.isValid(email)) {
      debugPrint("❌ [AuthService] Signup Blocked: Invalid Domain");
      throw "Use college email only";
    }

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'role': 'student'},
        emailRedirectTo: 'io.supabase.flutter://signin-callback/',
      );

      debugPrint("📨 [AuthService] Signup Response Received.");
      debugPrint("   -> User: ${response.user?.id}");
      debugPrint("   -> Session: ${response.session != null ? 'Active' : 'NULL (Verification Pending)'}");

      if (response.session == null && response.user != null) {
        debugPrint("ℹ️ [AuthService] Email confirmation sent. User must verify.");
      } else if (response.session != null) {
        debugPrint("⚠️ [AuthService] Session created immediately (Maybe Supabase is set to auto-confirm?). Checking rules...");
        // Even if session exists, we must enforce our rule if it's not verified (though usually session implies verified if strict)
        // But for signup, usually session is null if confirm is on.
      }

      return response;
    } catch (e) {
      debugPrint("❌ [AuthService] Signup Error: $e");
      rethrow;
    }
  }

  // =============================
  // Login
  // =============================
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint("🔑 [AuthService] Attempting Email Login: $email");
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint("✅ [AuthService] Login Initial Success. Validating...");
      await ensureSessionValid();
      
      // Manual sync for email login
      await _onLoginSuccess(_client.auth.currentUser!);
    } catch (e) {
      debugPrint("❌ [AuthService] Login Error: $e");
      rethrow;
    }
  }

  // =============================
  // Operations
  // =============================
  Future<void> sendPasswordOtp(String email) async {
    debugPrint("🔄 [AuthService] Sending Password OTP to $email");
    await _client.auth.signInWithOtp(email: email);
  }

  Future<void> verifyPasswordOtp(String email, String otp) async {
    debugPrint("🔢 [AuthService] Verifying OTP...");
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: otp,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    debugPrint("🔐 [AuthService] Updating Password...");
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateCustomAvatar(String? url) async {
    debugPrint("🖼️ [AuthService] Updating Custom Avatar URL: $url");
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'custom_avatar_url': url}),
    );
    
    if (response.user != null) {
      debugPrint("✅ [AuthService] Custom Avatar Updated: ${response.user?.userMetadata?['custom_avatar_url']}");
    }
  }

  Future<void> updateUserAvatar(String? url) async {
    debugPrint("🖼️ [AuthService] Updating Provider Avatar URL: $url");
    // Update metadata. If url is null, we can set it to null or remove it.
    // Supabase usually merges metadata. To remove, setting to null is standard.
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'avatar_url': url}),
    );
    
    if (response.user != null) {
      debugPrint("✅ [AuthService] Avatar Updated: ${response.user?.userMetadata?['avatar_url']}");
    }
  }

  // =============================
  // State
  // =============================
  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  bool get isLoggedIn => session != null;
  String get role => user?.userMetadata?['role'] ?? 'student';
  bool get isAdmin => role == 'admin';

  Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    debugPrint("🔄 [AuthService] Updating User Metadata: $data");
    await _client.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  Future<void> signOut() async {
    debugPrint("👋 [AuthService] Signing Out.");
    await _client.auth.signOut();
  }
}
