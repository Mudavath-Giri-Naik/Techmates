import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _profileCachePrefix = 'profile_cache_';
  static const String _onboardingCachePrefix = 'profile_onboarding_cache_';

  String _profileKey(String userId) => '$_profileCachePrefix$userId';
  String _onboardingKey(String userId) => '$_onboardingCachePrefix$userId';

  Future<UserProfile?> getProfileCached(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  Future<bool?> getOnboardingCached(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_onboardingKey(userId))) {
      return prefs.getBool(_onboardingKey(userId));
    }
    final cachedProfile = await getProfileCached(userId);
    return cachedProfile?.onboardingCompleted;
  }

  /// Cache-first fetch: returns cached profile immediately, refreshes from network in background.
  Future<UserProfile?> fetchProfile(String userId) async {
    final cached = await getProfileCached(userId);
    if (cached != null) {
      debugPrint('[PROFILE] Cache hit');
    } else {
      debugPrint('[PROFILE] Cache miss - fetching from network');
    }
    unawaited(_refreshProfileFromNetwork(userId).then((_) {}));
    return cached;
  }

  /// Explicit network refresh for pull-to-refresh actions.
  Future<UserProfile?> refreshProfileNow(String userId) async {
    return _refreshProfileFromNetwork(userId);
  }

  Future<UserProfile?> _refreshProfileFromNetwork(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      if (response == null) {
        return null;
      }

      final profile = UserProfile.fromJson(response);
      await _cacheProfile(userId, profile);
      debugPrint('[PROFILE] Network fetch success - cache updated');
      return profile;
    } on TimeoutException {
      debugPrint('[PROFILE] Network fetch FAILED/TIMEOUT - using cache');
      return getProfileCached(userId);
    } catch (e) {
      debugPrint("❌ [ProfileService] Fetch Error: $e");
      debugPrint('[PROFILE] Network fetch FAILED/TIMEOUT - using cache');
      return getProfileCached(userId);
    }
  }

  Future<void> _cacheProfile(String userId, UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey(userId), jsonEncode(profile.toJson()));
    await prefs.setBool(_onboardingKey(userId), profile.onboardingCompleted);
  }

  /// Upsert profile (Create if first login, update if exists)
  Future<void> upsertProfile(UserProfile profile) async {
    try {
      debugPrint("🔄 [ProfileService] Upserting profile for ${profile.email}");
      await _client.from('profiles').upsert(
        profile.toJson(),
        onConflict: 'id',
      );
      await _cacheProfile(profile.id, profile);
      debugPrint("✅ [ProfileService] Profile upserted successfully.");
    } catch (e) {
      debugPrint("❌ [ProfileService] Upsert Error: $e");
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
      unawaited(_refreshProfileFromNetwork(userId).then((_) {}));
      debugPrint("✅ [ProfileService] Profile updated successfully.");
    } catch (e) {
      debugPrint("❌ [ProfileService] Update Error: $e");
      rethrow;
    }
  }
}
