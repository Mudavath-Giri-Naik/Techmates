import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';

class DashboardService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  void _logAppUpdate(String message, {Map<String, dynamic>? context}) {
    final ctx = context != null ? ' | ctx=$context' : '';
    debugPrint('[APP_UPDATE][WRITE] $message$ctx');
  }

  // ---------------------------------------------------------------------------
  // COUNTS
  // ---------------------------------------------------------------------------

  Future<int> getTotalUsers() async {
    try {
      // Debug: Print raw response to check RLS
      final rawResponse = await _client.from('user_roles').select('*');
      print("🔍 [DEBUG] RAW user_roles response length: ${rawResponse.length}");
      if (rawResponse.isNotEmpty) {
        print("🔍 [DEBUG] First row: ${rawResponse.first}");
      } else {
        print("⚠️ [DEBUG] user_roles returns EMPTY list (Check RLS!)");
      }

      // Correct count query
      final countResponse = await _client
          .from('user_roles')
          .count(CountOption.exact);
      
      print("📊 [DEBUG] Total Users Count: $countResponse");
      return countResponse;
    } catch (e) {
      print("❌ [DEBUG] Error fetching Total Users: $e");
      return 0;
    }
  }

  Future<int> getAdminCount() async {
    try {
      final count = await _client
          .from('user_roles')
          .count(CountOption.exact)
          .eq('role', 'admin');
      print("📊 [DEBUG] Admin Count: $count");
      return count;
    } catch (e) {
      print("❌ [DEBUG] Error fetching Admin Count: $e");
      return 0;
    }
  }

  Future<int> getStudentCount() async {
    try {
      final count = await _client
          .from('user_roles')
          .count(CountOption.exact)
          .eq('role', 'student');
      print("📊 [DEBUG] Student Count: $count");
      return count;
    } catch (e) {
      print("❌ [DEBUG] Error fetching Student Count: $e");
      return 0;
    }
  }

  Future<int> getSuperAdminCount() async {
    try {
      final count = await _client
          .from('user_roles')
          .count(CountOption.exact)
          .eq('role', 'super_admin');
      print("📊 [DEBUG] Super Admin Count: $count");
      return count;
    } catch (e) {
      print("❌ [DEBUG] Error fetching Super Admin Count: $e");
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // LISTS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client
          .from('user_roles')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching All Users: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      final response = await _client
          .from('user_roles')
          .select('*')
          .eq('role', 'admin')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching Admins: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS (Legacy/Other Stats)
  // ---------------------------------------------------------------------------
  // Keeping this for compatibility with existing UI that might call it, 
  // or I will update UI to use specific methods.
  // The user requested "Create DashboardService... example structure", implies replacing.
  // But DashboardSummaryGrid calls fetchDashboardStats(). I should refactor that widget.
  // For now, I'll provide a helper that aggregates these for the existing widget if needed,
  // OR I will update the widget. I will update the widget.

  // Logs & Opps helper (since user didn't specify these in the request but they are in the dashboard)
  Future<int> getOpportunityCount() async {
     try {
       return await _client.from('opportunities').count(CountOption.exact);
     } catch (e) { return 0; }
  }

  Future<int> getInternshipCount() async {
     try { return await _client.from('opportunities').count(CountOption.exact).eq('type', 'internship'); } catch (e) { return 0; }
  }

  Future<int> getHackathonCount() async {
     try { return await _client.from('opportunities').count(CountOption.exact).eq('type', 'hackathon'); } catch (e) { return 0; }
  }

  Future<int> getEventCount() async {
     try { return await _client.from('opportunities').count(CountOption.exact).eq('type', 'event'); } catch (e) { return 0; }
  }

  Future<int> getInactiveUserCount() async {
     try { return await _client.from('profiles').count(CountOption.exact).eq('is_active', false); } catch (e) { return 0; }
  }

  Future<int> getRoleChangesCount() async {
     try { return await _client.from('user_role_logs').count(CountOption.exact); } catch (e) { return 0; }
  }
  
  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
   Future<void> updateUserRole({
    required String userId,
    required String email,
    required String oldRole,
    required String newRole,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw "Not authenticated";

      await _client.from('user_roles').upsert({
        'user_id': userId,
        'email': email,
        'role': newRole,
      });

      await _client.from('profiles').update({
        'role': newRole,
      }).eq('id', userId);

      await _client.from('user_role_logs').insert({
        'target_user': userId,
        'old_role': oldRole,
        'new_role': newRole,
        'changed_by': currentUser.id,
      });

    } catch (e) {
      throw "Failed to update user role: $e";
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _client.from('profiles').update({
        'is_active': isActive,
      }).eq('id', userId);
    } catch (e) {
      throw "Failed to update user status: $e";
    }
  }

  // Logs Fetches (Preserving previous functionality)
  Future<List<Map<String, dynamic>>> fetchRoleLogs() async {
    try {
       final response = await _client.from('user_role_logs').select('*, target:profiles!target_user(name, email), actor:profiles!changed_by(name, email)').order('created_at', ascending: false).limit(50);
       return List<Map<String, dynamic>>.from(response);
    } catch (e) {
       return [];
    }
  }

   Future<List<Map<String, dynamic>>> fetchOpportunityLogs() async {
    try {
       final response = await _client.from('opportunity_logs').select('*, opportunity:opportunities(title), actor:profiles!performed_by(name, email)').order('created_at', ascending: false).limit(50);
       return List<Map<String, dynamic>>.from(response);
    } catch (e) {
       return [];
    }
  }
  
  Future<String> fetchMinVersion() async {
    try {
      debugPrint('[APP_UPDATE][READ] Fetching min_version from app_update...');
      final response = await _client
          .from('app_update')
          .select('min_version')
          .limit(1)
          .single();
      debugPrint('[APP_UPDATE][READ] Raw row: $response');

      final minVersion = response['min_version'] as String;
      debugPrint('[APP_UPDATE][READ] Parsed min_version: $minVersion');
      return minVersion;
    } catch (e, st) {
      debugPrint('[APP_UPDATE][READ][ERROR] Failed to fetch min_version: $e');
      debugPrint('[APP_UPDATE][READ][STACK] $st');
      debugPrint('[APP_UPDATE][READ] Falling back to 1.0.0');
      return '1.0.0';
    }
  }

  Future<void> updateMinVersion(String version) async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    final accessToken = session?.accessToken;

    final tokenPreview = accessToken == null
        ? 'null'
        : '${accessToken.substring(0, accessToken.length > 10 ? 10 : accessToken.length)}... (len=${accessToken.length})';

    final payload = {'id': 1, 'min_version': version};

    _logAppUpdate(
      'Starting updateMinVersion',
      context: {
        'userId': user?.id,
        'hasSession': session != null,
        'hasAccessToken': accessToken != null,
        'accessTokenPreview': tokenPreview,
        'version': version,
        'payload': payload,
      },
    );

    try {
      final newVersion = version;
      debugPrint("🔵 [UPDATE] Attempting to update min_version to: $newVersion");
      debugPrint("🔵 [UPDATE] Logged in UID: ${_client.auth.currentUser?.id}");

      final response = await _client
          .from('app_update')
          .update({'min_version': newVersion})
          .eq('id', 1);

      _logAppUpdate('Upsert succeeded', context: {'response': response});
    } on PostgrestException catch (e, st) {
      _logAppUpdate('PostgrestException during upsert', context: {
        'code': e.code,
        'message': e.message,
        'details': e.details,
        'hint': e.hint,
      });
      debugPrint('[APP_UPDATE][WRITE][STACK] $st');
      throw Exception('Postgrest error ${e.code}: ${e.message}');
    } catch (e, st) {
      _logAppUpdate('Unexpected error during upsert', context: {
        'error': e.toString(),
      });
      debugPrint('[APP_UPDATE][WRITE][STACK] $st');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers({
    String? searchQuery,
    String? roleFilter,
    bool? statusFilter,
    int page = 0,
    int limit = 50,
  }) async {
    try {
      print("🔍 [DEBUG] fetchUsers params: Search='$searchQuery', Role='$roleFilter'");
      
      // 1. Fetch User Roles (Source of Truth for existence and role)
      var rolesQuery = _client.from('user_roles').select('*');
      
      if (roleFilter != null && roleFilter != 'all') {
        rolesQuery = rolesQuery.eq('role', roleFilter);
      }
      
      final rolesData = await rolesQuery.order('created_at', ascending: false);
      final List<Map<String, dynamic>> rolesList = List<Map<String, dynamic>>.from(rolesData);
      
      print("🔍 [DEBUG] fetchUsers fetched ${rolesList.length} roles from user_roles");

      if (rolesList.isEmpty) return [];

      // 2. Fetch Profiles for names/status
      final userIds = rolesList.map((e) => e['user_id']).toList();
      final profilesResponse = await _client
          .from('profiles')
          .select('id, name, email, is_active')
          .filter('id', 'in', userIds);
          
      print("🔍 [DEBUG] fetchUsers profiles fetched: ${(profilesResponse as List).length}");
      
      final List<Map<String, dynamic>> profilesList = List<Map<String, dynamic>>.from(profilesResponse);
      final profilesMap = {for (var p in profilesList) p['id']: p};

      // 3. Merge and Filter (Search/Status)
      final List<Map<String, dynamic>> mergedList = [];
      
      for (var roleItem in rolesList) {
        final uid = roleItem['user_id'];
        final profile = profilesMap[uid];
        
        final name = profile?['name'] ?? 'Unknown';
        final email = roleItem['email'] ?? profile?['email']; // user_roles has email usually
        final isActive = profile?['is_active'] ?? true;
        final role = roleItem['role'];

        // Apply Search Filter (in memory)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final matchesName = name.toLowerCase().contains(query);
          final matchesEmail = email.toLowerCase().contains(query);
          if (!matchesName && !matchesEmail) continue;
        }

        // Apply Status Filter (in memory)
        if (statusFilter != null) {
          if (isActive != statusFilter) continue;
        }

        mergedList.add({
          'id': uid,
          'user_id': uid,
          'name': name,
          'email': email,
          'role': role,
          'is_active': isActive,
          'created_at': roleItem['created_at'],
        });
      }

      // Pagination in memory (since we filtered in memory)
      final startIndex = page * limit;
      if (startIndex >= mergedList.length) return [];
      final endIndex = (startIndex + limit) < mergedList.length ? (startIndex + limit) : mergedList.length;
      
      return mergedList.sublist(startIndex, endIndex);

    } catch (e) {
      print("❌ [DEBUG] Error fetching/merging users: $e");
      return [];
    }
  }
}
