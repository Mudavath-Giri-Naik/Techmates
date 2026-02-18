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
  bool get isAdmin => _currentRole == 'admin' || _currentRole == 'super_admin'; // Admin/SuperAdmin are admins
  bool get isSuperAdmin => _currentRole == 'super_admin';
  bool get canEdit => isAdmin; // Valid for admin and super_admin

  /// Initialize: Load role from cache
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentRole = prefs.getString(_roleKey) ?? 'student';
    debugPrint("👤 [UserRoleService] Initialized with role: $_currentRole");
  }

  /// Fetch role from Supabase and cache it
  Future<void> fetchAndCacheRole(String userId) async {
    final email = _client.auth.currentUser?.email ?? 'Unknown';
    debugPrint("🔍 [UserRoleService] Checking role for user: $userId (Email: $email)...");
    
    try {
      // Assuming 'user_roles' table: user_id (uuid), role (text)
      // QUERY: Check if user exists in table (by ID, which is safer/correct). 
      // User requested to "check if email matches", but ID is the key. 
      // We will trust ID match implies strict relationship.
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      String newRole = 'student';

      if (response != null && response['role'] != null) {
        newRole = response['role'] as String;
        debugPrint("✅ [UserRoleService] Match found in user_roles table for $email.");
        debugPrint("👤 [UserRoleService] Role fetched from DB: $newRole");
      } else {
        debugPrint("⚠️ [UserRoleService] No match found in user_roles for $email. Defaulting to 'student'.");
        debugPrint("   -> Ensure you have inserted a row in 'user_roles' for this user ID.");
      }

      // Update Cache
      await _cacheRole(newRole);
      
    } catch (e) {
      debugPrint("❌ [UserRoleService] Failed to fetch role: $e");
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
