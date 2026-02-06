import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  /// Fetch current user's profile
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint("❌ [ProfileService] Fetch Error: $e");
      return null;
    }
  }

  /// Upsert profile (Create if first login, update if exists)
  Future<void> upsertProfile(UserProfile profile) async {
    try {
      debugPrint("🔄 [ProfileService] Upserting profile for ${profile.email}");
      await _client.from('profiles').upsert(
        profile.toJson(),
        onConflict: 'id',
      );
      debugPrint("✅ [ProfileService] Profile upserted successfully.");
    } catch (e) {
      debugPrint("❌ [ProfileService] Upsert Error: $e");
      // Don't rethrow as we don't want to break login if profile creation fails?
      // Actually, user said if login fails do nothing, but if it succeeds we try.
    }
  }

  /// Update specific profile fields
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      debugPrint("📝 [ProfileService] Updating profile: $data");
      await _client
          .from('profiles')
          .update(data)
          .eq('id', userId);
      debugPrint("✅ [ProfileService] Profile updated successfully.");
    } catch (e) {
      debugPrint("❌ [ProfileService] Update Error: $e");
      rethrow;
    }
  }
}
