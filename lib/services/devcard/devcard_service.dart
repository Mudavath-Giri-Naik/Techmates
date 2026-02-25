import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/devcard/devcard_model.dart';
import 'devcard_analyzer.dart';
import 'github_service.dart';

class DevCardService {
  static const Duration _cacheValidity = Duration(hours: 24);

  static Future<DevCardModel?> getDevCard(
      String userId, String githubUrl) async {
    try {
      final cached = await Supabase.instance.client
          .from('devcard_cache')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (cached != null) {
        final fetchedAt = DateTime.parse(cached['last_fetched_at'] as String);
        if (DateTime.now().difference(fetchedAt) < _cacheValidity) {
          return DevCardModel.fromJson(
              cached['analyzed_data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('DevCard cache read error: $e');
    }

    final username = GitHubService.extractUsername(githubUrl);
    return refreshDevCard(userId, username);
  }

  static Future<DevCardModel> refreshDevCard(
      String userId, String githubUsername) async {
    final rawData = await GitHubService.fetchDevCardData(githubUsername);
    final model = DevCardAnalyzer.analyze(rawData, userId);

    int fetchCount = 1;
    try {
      final existing = await Supabase.instance.client
          .from('devcard_cache')
          .select('fetch_count')
          .eq('user_id', userId)
          .maybeSingle();
      if (existing != null) {
        fetchCount = (existing['fetch_count'] as int? ?? 0) + 1;
      }
    } catch (_) {}

    try {
      await Supabase.instance.client.from('devcard_cache').upsert(
        {
          'user_id': userId,
          'github_username': githubUsername,
          'raw_data': rawData,
          'analyzed_data': model.toJson(),
          'last_fetched_at': DateTime.now().toUtc().toIso8601String(),
          'fetch_count': fetchCount,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('DevCard cache write error: $e');
    }

    return model;
  }

  /// Load another user's DevCard from cache only (no refresh).
  static Future<DevCardModel?> getOtherUserDevCard(String userId) async {
    try {
      final cached = await Supabase.instance.client
          .from('devcard_cache')
          .select('analyzed_data, last_fetched_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (cached != null) {
        return DevCardModel.fromJson(
            cached['analyzed_data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('DevCard other-user cache read error: $e');
    }
    return null;
  }
}
