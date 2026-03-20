import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/devcard/devcard_model.dart';
import 'devcard_analyzer.dart';
import 'github_service.dart';

class DevCardService {
  static const Duration _cacheValidity = Duration(hours: 24);

  static Future<DevCardModel?> getDevCard(
    String userId,
    String githubUrl,
  ) async {
    debugPrint('🚀 [DEVCARD SERVICE] getDevCard called for userId: $userId');
    try {
      debugPrint('⏳ [DEVCARD SERVICE] Checking devcard_cache...');
      final cached = await Supabase.instance.client
          .from('devcard_cache')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Cache select timed out');
            },
          );

      if (cached != null) {
        debugPrint('✅ [DEVCARD SERVICE] Found cached devcard!');
        final fetchedAt = DateTime.parse(cached['last_fetched_at'] as String);
        if (DateTime.now().difference(fetchedAt) < _cacheValidity) {
          debugPrint(
            '✅ [DEVCARD SERVICE] Cache is valid, returning cached data.',
          );
          return DevCardModel.fromJson(
            cached['analyzed_data'] as Map<String, dynamic>,
          );
        } else {
          debugPrint('❌ [DEVCARD SERVICE] Cache is expired. Refreshing.');
        }
      } else {
        debugPrint('❌ [DEVCARD SERVICE] No cached devcard found.');
      }
    } catch (e) {
      debugPrint('❌ [DEVCARD SERVICE ERROR] Cache read error: $e');
    }

    final username = GitHubService.extractUsername(githubUrl);
    debugPrint(
      '🚀 [DEVCARD SERVICE] Extracted username: $username. Calling refreshDevCard...',
    );
    return refreshDevCard(userId, username);
  }

  static Future<DevCardModel> refreshDevCard(
    String userId,
    String githubUsername,
  ) async {
    debugPrint('⏳ [DEVCARD SERVICE] Fetching fresh data from Edge Function...');
    final rawData = await GitHubService.fetchDevCardData(githubUsername);
    debugPrint(
      '✅ [DEVCARD SERVICE] Edge function returned raw data. Analyzing...',
    );
    final model = DevCardAnalyzer.analyze(rawData, userId);
    debugPrint('✅ [DEVCARD SERVICE] Analysis complete. Updating cache...');

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
      await Supabase.instance.client.from('devcard_cache').upsert({
        'user_id': userId,
        'github_username': githubUsername,
        'raw_data': rawData,
        'analyzed_data': model.toJson(),
        'last_fetched_at': DateTime.now().toUtc().toIso8601String(),
        'fetch_count': fetchCount,
      }, onConflict: 'user_id');
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
          cached['analyzed_data'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('DevCard other-user cache read error: $e');
    }
    return null;
  }
}
