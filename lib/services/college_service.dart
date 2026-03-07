import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class CollegeService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final CollegeService _instance = CollegeService._internal();
  factory CollegeService() => _instance;
  CollegeService._internal();

  /// Search colleges table by name using ilike.
  /// Returns up to 10 results with id, name, domain, code.
  Future<List<Map<String, dynamic>>> searchColleges(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final response = await _client
          .from('colleges')
          .select('id, name, domain, code')
          .ilike('name', '%${query.trim()}%')
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [CollegeService] searchColleges error: $e');
      return [];
    }
  }

  /// Look up a college by its email domain.
  /// Returns a map with 'id' and 'name' if found, null if not.
  Future<Map<String, dynamic>?> getCollegeIdByDomain(String domain) async {
    try {
      final response = await _client
          .from('colleges')
          .select('id, name, domain, is_verified')
          .eq('domain', domain.toLowerCase().trim())
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('❌ [CollegeService] getCollegeIdByDomain error: $e');
      return null;
    }
  }

  /// Handle an unknown college domain by calling the Supabase RPC
  /// `insert_unverified_college`. Returns the new college UUID.
  /// Also notifies super_admin users via FCM.
  Future<String?> handleUnknownDomain(String domain, String submittedName) async {
    try {
      final normalizedDomain = domain.toLowerCase().trim();

      // Call the RPC — returns the new college_id (UUID)
      final result = await _client.rpc('insert_unverified_college', params: {
        'p_domain': normalizedDomain,
        'p_submitted_name': submittedName,
      });

      final collegeId = result as String?;
      debugPrint('📝 [CollegeService] RPC insert_unverified_college → $collegeId');

      // Notify super_admin(s) about the new domain
      await _notifySuperAdmin(normalizedDomain, submittedName);

      return collegeId;
    } catch (e) {
      debugPrint('❌ [CollegeService] handleUnknownDomain error: $e');
      return null;
    }
  }

  /// Send FCM notification to super_admin users about a new domain.
  Future<void> _notifySuperAdmin(String domain, String submittedName) async {
    try {
      // Get only super_admin user IDs from user_roles
      final roleRows = await _client
          .from('user_roles')
          .select('user_id')
          .eq('role', 'super_admin');

      if (roleRows.isEmpty) {
        debugPrint('⚠️ [CollegeService] No super_admin found to notify.');
        return;
      }

      final userIds =
          (roleRows as List).map((r) => r['user_id'] as String).toList();

      // Fetch FCM tokens for those users
      final profiles = await _client
          .from('profiles')
          .select('id, fcm_token')
          .inFilter('id', userIds);

      for (final profile in profiles) {
        final token = profile['fcm_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _client.functions.invoke(
            'send-notification',
            body: {
              'token': token,
              'title': 'New College Domain',
              'body': 'domain: $domain, submitted as: $submittedName',
            },
          );
          debugPrint(
              '📩 [CollegeService] Superadmin notified: ${profile['id']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [CollegeService] _notifySuperAdmin error: $e');
    }
  }

  /// Save college email info to the user's profile.
  /// Sets college_verified = true only if collegeId is not null.
  Future<void> saveCollegeToProfile(
    String userId,
    String collegeEmail,
    String domain,
    String? collegeId,
    String? collegeName,
  ) async {
    try {
      final data = <String, dynamic>{
        'college_email': collegeEmail,
        'college_email_domain': domain.toLowerCase().trim(),
        'college_id': collegeId,
        'college_verified': collegeId != null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // college column has been removed from profiles table
      await _client.from('profiles').update(data).eq('id', userId);
      debugPrint(
          '✅ [CollegeService] Saved college to profile: $collegeEmail (verified: ${collegeId != null})');
    } catch (e) {
      debugPrint('❌ [CollegeService] saveCollegeToProfile error: $e');
      rethrow;
    }
  }

  /// Fetch all colleges from the `colleges_with_student_count` view.
  /// Used in the super_admin dashboard.
  Future<List<Map<String, dynamic>>> getAllColleges() async {
    try {
      final response = await _client
          .from('colleges_with_student_count')
          .select()
          .order('no_of_students', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [CollegeService] getAllColleges error: $e');
      return [];
    }
  }

  /// Update a college row in the `colleges` table by id.
  /// The database trigger will auto-sync changes to all linked profiles.
  Future<void> updateCollege(String collegeId, Map<String, dynamic> updates) async {
    try {
      await _client.from('colleges').update(updates).eq('id', collegeId);
      debugPrint('✅ [CollegeService] Updated college $collegeId');
    } catch (e) {
      debugPrint('❌ [CollegeService] updateCollege error: $e');
      rethrow;
    }
  }
}
