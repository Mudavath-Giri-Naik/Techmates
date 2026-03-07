import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

/// Service for the Compete feature. Singleton.
///
/// DB column reference:
///   game_sessions:     id, user_id, arena_id, college_id, raw_score, accuracy,
///                      difficulty_level, time_taken_ms, mistakes, rating_before,
///                      rating_after, rating_delta, is_counted
///   user_arena_stats:  rating, percentile, total_sessions, avg_accuracy,
///                      best_raw_score, best_level_reached, avg_raw_score
///   user_tpi:          final_tpi, final_tpi_1000, campus_rank, campus_percentile,
///                      ability_score, consistency_score, growth_score,
///                      total_campus_players
///   arena_percentile_cache: percentile, arena_rank
class CompeteService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final CompeteService _instance = CompeteService._internal();
  factory CompeteService() => _instance;
  CompeteService._internal();

  // ── Arenas ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchArenas() async {
    try {
      final response = await _client
          .from('arenas')
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .timeout(kDefaultQueryTimeout);
      debugPrint('✅ [Compete] ${response.length} arenas');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [Compete] fetchArenas: $e');
      return [];
    }
  }

  // ── User Arena Stats ────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchUserArenaStats(String userId) async {
    try {
      final response = await _client
          .from('user_arena_stats')
          .select()
          .eq('user_id', userId)
          .timeout(kDefaultQueryTimeout);
      debugPrint('✅ [Compete] ${response.length} arena stats');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [Compete] fetchUserArenaStats: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchUserArenaStat(
      String userId, String arenaId) async {
    try {
      final response = await _client
          .from('user_arena_stats')
          .select()
          .eq('user_id', userId)
          .eq('arena_id', arenaId)
          .maybeSingle()
          .timeout(kDefaultQueryTimeout);
      debugPrint('✅ [Compete] Arena stat: $response');
      return response;
    } catch (e) {
      debugPrint('❌ [Compete] fetchUserArenaStat: $e');
      return null;
    }
  }

  // ── Game Session Submission ─────────────────────────

  /// Full pipeline:
  /// 1. Insert game_sessions row → get session id
  /// 2. Compute player percentile (where does this score rank vs others?)
  /// 3. Call process_game_session RPC with session_id + percentile
  Future<String?> submitGameSession({
    required String userId,
    required String arenaId,
    required String collegeId,
    required double rawScore,
    required double accuracy,
    required int levelReached,
    int timeTakenMs = 0,
    int mistakes = 0,
  }) async {
    try {
      // Step 1: Insert game session, get back the id
      debugPrint('🎮 [Compete] Inserting game_session...');
      final inserted = await _client.from('game_sessions').insert({
        'user_id': userId,
        'arena_id': arenaId,
        'college_id': collegeId,
        'raw_score': rawScore,
        'accuracy': accuracy,
        'difficulty_level': levelReached,
        'time_taken_ms': timeTakenMs,
        'mistakes': mistakes,
      }).select('id').single().timeout(const Duration(seconds: 10));

      final sessionId = inserted['id'] as String;
      debugPrint('✅ [Compete] Session inserted: $sessionId');      // Step 2: Call the master RPC
      debugPrint('🎮 [Compete] Calling process_game_session RPC...');
      await _client.rpc('process_game_session', params: {
        'p_session_id': sessionId,
        'p_user_id': userId,
        'p_arena_id': arenaId,
        'p_college_id': collegeId,
        'p_raw_score': rawScore,
        'p_accuracy': accuracy,
        'p_level': levelReached,
      }).timeout(const Duration(seconds: 15));

      debugPrint('✅ [Compete] RPC complete');
      return sessionId;
    } catch (e) {
      debugPrint('❌ [Compete] submitGameSession: $e');
      return null;
    }
  }

  // ── Session Fetch ─────────────────────────────────────────
  
  Future<Map<String, dynamic>?> fetchGameSession(String sessionId) async {
    try {
      final response = await _client
          .from('game_sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle()
          .timeout(kDefaultQueryTimeout);
      return response;
    } catch (e) {
      debugPrint('❌ [Compete] fetchGameSession: $e');
      return null;
    }
  }

  // ── User TPI ────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchUserTpi(String userId) async {
    try {
      final response = await _client
          .from('user_tpi')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(kDefaultQueryTimeout);
      debugPrint('✅ [Compete] TPI: $response');
      return response;
    } catch (e) {
      debugPrint('❌ [Compete] fetchUserTpi: $e');
      return null;
    }
  }

  // ── Leaderboard ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLeaderboard(
      String? collegeId, {int limit = 50}) async {
    try {
      if (collegeId == null || collegeId.isEmpty) return [];

      // Query user_tpi for this college, sorted by final_tpi
      final tpiEntries = await _client
          .from('user_tpi')
          .select()
          .eq('college_id', collegeId)
          .order('final_tpi', ascending: false)
          .limit(limit)
          .timeout(kDefaultQueryTimeout);

      if (tpiEntries.isEmpty) return [];

      // Get profile info for these users
      final userIds = tpiEntries
          .map((e) => e['user_id']?.toString())
          .whereType<String>()
          .toList();

      final profiles = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds)
          .timeout(kDefaultQueryTimeout);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        profileMap[p['id'] as String] = p;
      }

      // Merge
      final result = <Map<String, dynamic>>[];
      for (final entry in tpiEntries) {
        final uid = entry['user_id']?.toString();
        if (uid != null) {
          result.add({...entry, 'profiles': profileMap[uid]});
        }
      }

      debugPrint('✅ [Compete] Leaderboard: ${result.length} entries');
      return result;
    } catch (e) {
      debugPrint('❌ [Compete] fetchLeaderboard: $e');
      return [];
    }
  }

  // ── Arena Leaderboard ───────────────────────────────

  Future<List<Map<String, dynamic>>> fetchArenaLeaderboard(
      String arenaId, {int limit = 50}) async {
    try {
      final stats = await _client
          .from('user_arena_stats')
          .select()
          .eq('arena_id', arenaId)
          .order('rating', ascending: false)
          .limit(limit)
          .timeout(kDefaultQueryTimeout);

      if (stats.isEmpty) return [];

      final userIds = stats
          .map((e) => e['user_id']?.toString())
          .whereType<String>()
          .toList();

      final profiles = await _client
          .from('profiles')
          .select('id, full_name, avatar_url, college, branch, year')
          .inFilter('id', userIds)
          .timeout(kDefaultQueryTimeout);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        profileMap[p['id'] as String] = p;
      }

      final result = <Map<String, dynamic>>[];
      for (final entry in stats) {
        final uid = entry['user_id']?.toString();
        if (uid != null) {
          result.add({...entry, 'profiles': profileMap[uid]});
        }
      }

      debugPrint('✅ [Compete] Arena leaderboard: ${result.length} entries');
      return result;
    } catch (e) {
      debugPrint('❌ [Compete] fetchArenaLeaderboard: $e');
      return [];
    }
  }
}
