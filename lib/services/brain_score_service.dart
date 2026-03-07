import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/brain_score.dart';
import '../models/domain_score.dart';
import '../models/user_ranks.dart';

/// Service for brain score, ranks, domains, and streak data.
class BrainScoreService {
  static final BrainScoreService _instance = BrainScoreService._();
  factory BrainScoreService() => _instance;
  BrainScoreService._();

  final _sb = SupabaseClientManager.instance;

  // ── Brain Score ─────────────────────────────────────────────────────

  Future<BrainScore?> fetchBrainScore(String userId) async {
    try {
      final data = await _sb
          .from('user_brain_score')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return BrainScore.fromJson(data);
    } catch (e) {
      debugPrint('❌ [BrainScoreService] fetchBrainScore: $e');
      return null;
    }
  }

  // ── Ranks ───────────────────────────────────────────────────────────

  Future<UserRanks?> fetchUserRanks(String userId) async {
    try {
      final data = await _sb
          .from('user_ranks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserRanks.fromJson(data);
    } catch (e) {
      debugPrint('❌ [BrainScoreService] fetchUserRanks: $e');
      return null;
    }
  }

  // ── Domain Scores ───────────────────────────────────────────────────

  Future<List<DomainScore>> fetchDomainScores(
      String userId, String? collegeId) async {
    try {
      var query = _sb
          .from('domain_percentile_cache')
          .select('*, domains!domain_id(name, domain_key)')
          .eq('user_id', userId);
      if (collegeId != null) {
        query = query.eq('college_id', collegeId);
      }
      final data = await query;
      return (data as List)
          .map((e) => DomainScore.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [BrainScoreService] fetchDomainScores: $e');
      return [];
    }
  }

  // ── Streak ──────────────────────────────────────────────────────────

  /// Returns {streakDays, longestStreak, weekActivity (7 bool: Mon→Sun)}.
  Future<Map<String, dynamic>> fetchStreakData(String userId) async {
    try {
      final data = await _sb
          .from('user_activity')
          .select('activity_date, is_active')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('activity_date', ascending: false)
          .limit(90);

      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < (data as List).length; i++) {
        final dateStr = data[i]['activity_date'] as String;
        final d = DateTime.parse(dateStr);
        final expected = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        if (d.year == expected.year &&
            d.month == expected.month &&
            d.day == expected.day) {
          streak++;
        } else {
          break;
        }
      }

      // Week activity: last 7 days starting from Monday
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final activeDates = (data as List)
          .map((e) => DateTime.parse(e['activity_date'] as String))
          .toSet();
      final weekActivity = List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        return activeDates.any((d) =>
            d.year == day.year && d.month == day.month && d.day == day.day);
      });

      // Longest streak from profiles table
      final profile = await _sb
          .from('profiles')
          .select('longest_streak')
          .eq('id', userId)
          .maybeSingle();

      return {
        'streakDays': streak,
        'longestStreak': (profile?['longest_streak'] as num?)?.toInt() ?? streak,
        'weekActivity': weekActivity,
      };
    } catch (e) {
      debugPrint('❌ [BrainScoreService] fetchStreakData: $e');
      return {
        'streakDays': 0,
        'longestStreak': 0,
        'weekActivity': List.filled(7, false),
      };
    }
  }

  // ── Zero Day check ──────────────────────────────────────────────────

  Future<bool> isZeroDay(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final data = await _sb
          .from('user_activity')
          .select('is_active')
          .eq('user_id', userId)
          .eq('activity_date', today)
          .maybeSingle();
      return data == null || data['is_active'] == false;
    } catch (e) {
      return true;
    }
  }
}
