import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class UserRoleService {
  // Singleton
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  final SupabaseClient _client = SupabaseClientManager.instance;
  static const String _roleKey = 'user_role';

  String _currentRole = 'student'; // Default safe role

  String get role => _currentRole;

  bool get isStudent => _currentRole == 'student';
  bool get isAdmin => _currentRole == 'admin' || _currentRole == 'super_admin';
  bool get isSuperAdmin => _currentRole == 'super_admin';
  bool get canEdit => isAdmin;

  /// Initialize: Load role from cache
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentRole = prefs.getString(_roleKey) ?? 'student';
    debugPrint('[ROLE] Cache hit: $_currentRole');
  }

  /// Cache-first role read. Returns immediately from cache, then refreshes in background.
  Future<void> fetchAndCacheRole(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRole = prefs.getString(_roleKey);

    if (cachedRole != null && cachedRole.isNotEmpty) {
      _currentRole = cachedRole;
      debugPrint('[ROLE] Cache hit: $_currentRole');
    } else {
      debugPrint('[ROLE] Cache miss - fetching from network');
    }

    unawaited(
      _refreshRoleFromNetwork(userId, fallbackRole: _currentRole)
          .then((_) {}),
    );
  }

  /// Explicit network refresh for pull-to-refresh actions.
  Future<String> refreshRoleNow(String userId) async {
    return _refreshRoleFromNetwork(userId, fallbackRole: _currentRole);
  }

  Future<String> _refreshRoleFromNetwork(
    String userId, {
    required String fallbackRole,
  }) async {
    final email = _client.auth.currentUser?.email ?? 'Unknown';
    debugPrint("🔍 [UserRoleService] Checking role for user: $userId (Email: $email)...");

    try {
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      String newRole = 'student';
      if (response != null && response['role'] != null) {
        newRole = response['role'] as String;
      }

      await _cacheRole(newRole);
      debugPrint('[ROLE] Network fetch success: $newRole');
      return newRole;
    } on TimeoutException {
      debugPrint('[ROLE] Network fetch FAILED/TIMEOUT - using cache');
      return fallbackRole;
    } catch (e) {
      debugPrint("❌ [UserRoleService] Failed to fetch role: $e");
      debugPrint('[ROLE] Network fetch FAILED/TIMEOUT - using cache');
      return fallbackRole;
    }
  }

  Future<void> _cacheRole(String role) async {
    _currentRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    debugPrint("💾 [UserRoleService] Role cached: $role");
  }

  /// Clear role on logout
  Future<void> clear() async {
    _currentRole = 'student';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    debugPrint("🧹 [UserRoleService] Role cleared.");
  }
}
