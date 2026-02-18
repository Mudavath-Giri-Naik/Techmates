import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AdminService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  Future<void> createOpportunity({
    required String type, // 'internship', 'hackathon', 'event'
    required String title,
    required String organization,
    required Map<String, dynamic> additionalData, // Details
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw "User not logged in";

      // Prepare RPC parameters
      final Map<String, dynamic> params = {
         'p_type': type,
         'p_title': title,
         'p_company': organization, // Using organization as company/organiser
         'p_organiser': organization, // Set both, RPC uses based on logic or we map conditionally
         
         // Common optional fields mapping
         'p_description': additionalData['description'],
         'p_link': additionalData['link'] ?? additionalData['apply_link'],
         'p_location': additionalData['location'],
         'p_deadline': additionalData['deadline'],
         'p_start_date': additionalData['start_date'],
         'p_end_date': additionalData['end_date'],
         'p_apply_deadline': additionalData['apply_deadline'],
         
         // Internship specifics
         'p_stipend': additionalData['stipend'],
         'p_emp_type': additionalData['employment_type'] ?? additionalData['emp_type'],
         'p_tags': additionalData['tags'], // Ensure this is List<String> or null
         'p_eligibility': additionalData['eligibility'], // Ensure List<String> or null
         
         // Hackathon specifics
         'p_team_size': additionalData['team_size'],
         'p_rounds': additionalData['rounds'], // JSON or String? RPC likely expects JSONB or Text
         'p_prizes': additionalData['prizes'], // JSON/Text
         
         // Event specifics
         'p_venue': additionalData['venue'],
         'p_entry_fee': additionalData['entry_fee'],
      };

      // Clean up params: The RPC example expects null for unused fields.
      // Dart map values dealing with 'dynamic' might need explicit nulls if missing?
      // Actually Supabase Dart sends null for missing keys if we construct it well, 
      // but let's be explicit to match the user's "Unused fields must be null" instruction if needed.
      // However, sending { key: null } is different from missing key. 
      // The RPC definition in Postgres usually defaults to null if parameter not provided?
      // User EXAMPLE explicitly lists nulls. Let's follow the example structure for safety.

      final Map<String, dynamic> rpcParams = {
        'p_type': type,
        'p_title': title,
        'p_description': additionalData['description'],
        'p_source': additionalData['source'],
        'p_link': additionalData['link'] ?? additionalData['apply_link'],
      };

      if (type == 'internship') {
        rpcParams.addAll({
          'p_company': organization,
          'p_organiser': null,
          'p_location': additionalData['location'],
          'p_deadline': additionalData['deadline'],
          'p_stipend': additionalData['stipend'],
          'p_emp_type': additionalData['employment_type'],
          'p_duration': additionalData['duration'],
          'p_tags': additionalData['tags'],
          'p_eligibility': additionalData['eligibility'],
          'p_is_elite': additionalData['is_elite'],
          // Nulls for hackathon/event
          'p_team_size': null,
          'p_rounds': null,
          'p_prizes': null,
          'p_start_date': null,
          'p_end_date': null,
          'p_venue': null,
          'p_entry_fee': null,
          'p_apply_deadline': null,
        });
      } else if (type == 'hackathon') {
        rpcParams.addAll({
          'p_company': organization,
          'p_organiser': null,
          'p_location': additionalData['location'],
          'p_deadline': additionalData['deadline'],
          'p_team_size': additionalData['team_size'],
          'p_rounds': additionalData['rounds'],
          'p_prizes': additionalData['prizes'],
          'p_start_date': additionalData['start_date'],
          'p_end_date': additionalData['end_date'],
          'p_eligibility': additionalData['eligibility'],
          // Nulls for internship/event
          'p_stipend': null,
          'p_emp_type': null,
          'p_duration': null,
          'p_tags': null,
          'p_venue': null,
          'p_entry_fee': null,
          'p_apply_deadline': null,
        });
      } else if (type == 'event') {
        rpcParams.addAll({
          'p_organiser': organization,
          'p_company': null,
          'p_location': additionalData['location'],
          'p_venue': additionalData['venue'],
          'p_entry_fee': additionalData['entry_fee'],
          'p_apply_deadline': additionalData['apply_deadline'],
          'p_start_date': additionalData['start_date'],
          'p_end_date': additionalData['end_date'],
          // Nulls for internship/hackathon
          'p_deadline': null,
          'p_stipend': null,
          'p_emp_type': null,
          'p_duration': null,
          'p_tags': null,
          'p_eligibility': null,
          'p_team_size': null,
          'p_rounds': null,
          'p_prizes': null,
        });
      }

      try {
        await _client.rpc('insert_opportunity_with_details', params: rpcParams);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('p_is_elite') || msg.contains('is_elite')) {
          final fallbackParams = Map<String, dynamic>.from(rpcParams);
          fallbackParams.remove('p_is_elite');
          await _client.rpc('insert_opportunity_with_details', params: fallbackParams);
        } else {
          rethrow;
        }
      }

    } catch (e) {
      throw "Failed to create opportunity: $e";
    }
  }

  Future<void> updateOpportunity({
    required String id,
    required String type,
    required String title,
    required String organization,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      // 1. Update Parent
      await _client.from('opportunities').update({
        'title': title,
        'source': additionalData['source'],
      }).eq('id', id);

      // 2. Update Child
      final String childTable = _getChildTableName(type);
      // Ensure we don't try to update opportunity_id in child
      final childUpdateData = Map<String, dynamic>.from(additionalData);
      childUpdateData.remove('opportunity_id'); 
      childUpdateData.remove('source'); // source lives on parent table only
      
      await _client.from(childTable).update(childUpdateData).eq('opportunity_id', id);

    } catch (e) {
      throw "Failed to update opportunity: $e";
    }
  }

  String _getChildTableName(String type) {
    switch (type) {
      case 'internship':
        return 'internship_details';
      case 'hackathon':
        return 'hackathon_details';
      case 'event':
        return 'event_details';
      default:
        throw "Unknown type: $type";
    }
  }

  // Opportunity Management
  Future<void> deleteOpportunity(String id) async {
    try {
      // Child should cascade delete usually? Or manual.
      // Assuming cascade set in DB. If not, delete child first.
      await _client.from('opportunities').delete().eq('id', id);
    } catch (e) {
      throw "Failed to delete opportunity: $e";
    }
  }

  // User Management
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await _client
          .from('user_roles')
          .select('user_id, role');
          
      final rolesData = response as List<dynamic>;
      final Map<String, String> roleMap = {};
      for (var r in rolesData) {
        roleMap[r['user_id']] = r['role'];
      }
      
      // Fetch profiles
      final profilesResponse = await _client.from('profiles').select('*');
      final profilesData = profilesResponse as List<dynamic>;
      
      final List<Map<String, dynamic>> result = [];
      for (var p in profilesData) {
        final uid = p['id'];
        result.add({
          'id': uid,
          'name': p['full_name'] ?? p['name'] ?? 'Unknown',
          'email': p['email'] ?? '',
          'role': roleMap[uid] ?? 'student',
        });
      }
      
      return result;

    } catch (e) {
      throw "Failed to fetch users: $e";
    }
  }

  Future<void> updateUserRole(String userId, String email, String newRole) async {
    print("🔐 Current User ID: ${_client.auth.currentUser?.id}");
    print("🔐 Current User Email: ${_client.auth.currentUser?.email}");
    print("🔐 Current Session: ${_client.auth.currentSession}");
    print("🔐 Target User ID: $userId");
    print("🔐 New Role: $newRole");

    if (_client.auth.currentUser == null) {
      print("❌ No active session!");
      throw "No active session";
    }

    if (!['student', 'admin', 'super_admin'].contains(newRole)) {
      print("❌ Invalid role value: $newRole");
      throw "Invalid role value";
    }

    try {
      // Use update explicitly as requested
      final response = await _client
          .from('user_roles')
          .update({'role': newRole})
          .eq('user_id', userId)
          .select(); // Select to get response data for debugging

      print("✅ Update Response: $response");
      
    } catch (e, stack) {
      print("❌ Role Update Error: $e");
      print("❌ Stack: $stack");
      rethrow;
    }
  }

  // Logs
  Future<List<Map<String, dynamic>>> fetchLogs() async {
    try {
      final response = await _client
          .from('opportunity_logs')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
       // If table doesn't exist or RLS blocks
       return []; 
    }
  }
}
