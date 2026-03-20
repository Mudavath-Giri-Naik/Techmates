import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_client.dart';
import '../speed_match/models/user_game_level_model.dart';
import '../speed_match/models/duel_session_model.dart';

class MemorySubmissionResult {
  final String? sessionId;
  final int score;
  final int? brainScore;

  const MemorySubmissionResult({
    required this.sessionId,
    required this.score,
    required this.brainScore,
  });
}

/// Supabase bridge for the Memory arena.
class MemoryService {
  MemoryService._();
  static final MemoryService _instance = MemoryService._();
  factory MemoryService() => _instance;

  SupabaseClient get _sb => Supabase.instance.client;
  String get _uid => _sb.auth.currentUser!.id;

  /// Dedicated client for realtime channels.
  SupabaseClient get _rtClient => SupabaseClientManager.realtimeInstance;

  String? _cachedMemoryArenaId;

  Future<String> getMemoryArenaId() async {
    if (_cachedMemoryArenaId != null) return _cachedMemoryArenaId!;

    final domainId = await _getMemoryDomainId();
    final activeArena = await _sb
        .from('arenas')
        .select('id')
        .eq('domain_id', domainId)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (activeArena != null) {
      _cachedMemoryArenaId = activeArena['id'] as String;
    } else {
      final fallbackArena = await _sb
          .from('arenas')
          .select('id')
          .eq('domain_id', domainId)
          .limit(1)
          .maybeSingle();
      _cachedMemoryArenaId = fallbackArena?['id'] as String?;
    }

    debugPrint('🧠 MEMORY: resolved arena_id=$_cachedMemoryArenaId');
    return _cachedMemoryArenaId ?? '';
  }

  Future<int> _getMemoryDomainId() async {
    final row = await _sb.from('domains').select('id').eq('key', 'memory').single();
    return row['id'] as int;
  }

  // ── User Game Level ──────────────────────────────────

  Future<UserGameLevel> fetchUserGameLevel() async {
    debugPrint('🧠 MEMORY: fetchUserGameLevel for uid=$_uid');
    final row = await _sb
        .from('user_game_levels')
        .select()
        .eq('user_id', _uid)
        .eq('game_type', 'memory')
        .maybeSingle();

    if (row == null) {
      return UserGameLevel(userId: _uid, gameType: 'memory');
    }

    var level = UserGameLevel.fromMap(row);

    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart =
        DateTime(currentMonday.year, currentMonday.month, currentMonday.day);

    if (level.weekResetAt == null || level.weekResetAt!.isBefore(mondayStart)) {
      await _sb.from('user_game_levels').upsert({
        'user_id': _uid,
        'game_type': 'memory',
        'total_plays_this_week': 0,
        'week_reset_at': mondayStart.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      level = UserGameLevel(
        userId: level.userId,
        gameType: level.gameType,
        currentLevel: level.currentLevel,
        bestScoreAtLevel: level.bestScoreAtLevel,
        totalPlays: level.totalPlays,
        totalPlaysThisWeek: 0,
        weekResetAt: mondayStart,
        updatedAt: DateTime.now(),
      );
    }

    return level;
  }

  // ── Best Scores ──────────────────────────────────

  Future<int> fetchAllTimeBestScore() async {
    try {
      final arenaId = await getMemoryArenaId();
      if (arenaId.isEmpty) return 0;

      final row = await _sb
          .from('game_sessions')
          .select('raw_score')
          .eq('player_id', _uid)
          .eq('arena_id', arenaId)
          .order('raw_score', ascending: false)
          .limit(1)
          .maybeSingle();

      return (row?['raw_score'] as num?)?.round() ?? 0;
    } catch (e) {
      debugPrint('❌ MEMORY: fetchAllTimeBestScore error: $e');
      return 0;
    }
  }

  Future<int> fetchBestLevelReached() async {
    try {
      final arenaId = await getMemoryArenaId();
      if (arenaId.isEmpty) return 0;

      final row = await _sb
          .from('game_sessions')
          .select('level_reached')
          .eq('player_id', _uid)
          .eq('arena_id', arenaId)
          .order('level_reached', ascending: false)
          .limit(1)
          .maybeSingle();

      return (row?['level_reached'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('❌ MEMORY: fetchBestLevelReached error: $e');
      return 0;
    }
  }

  // ── Rankings ──────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchClassRankings(String collegeId) async {
    try {
      final todayStart =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
              .toIso8601String();
      final arenaId = await getMemoryArenaId();
      if (arenaId.isEmpty) return [];

      final data = await _sb
          .from('game_sessions')
          .select(
            'player_id, raw_score, profiles!game_sessions_player_id_fkey!inner(full_name, college_id)',
          )
          .eq('arena_id', arenaId)
          .eq('profiles.college_id', collegeId)
          .gte('played_at', todayStart)
          .order('raw_score', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ MEMORY: fetchClassRankings error: $e');
      return [];
    }
  }

  // ── Profile ──────────────────────────────────

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final row = await _sb
          .from('profiles')
          .select(
            'id, full_name, username, avatar_url, college_id, branch, year, colleges!profiles_college_id_fkey(short_name)',
          )
          .eq('id', userId)
          .single();
      return row;
    } catch (e) {
      debugPrint('❌ MEMORY: fetchProfile error: $e');
      return null;
    }
  }

  // ── Solo: Process & Save ──────────────────────────────────

  Future<MemorySubmissionResult> processAndUpdateStats({
    required double rawScore,
    required double accuracy,
    required int levelReached,
    required int timeTakenMs,
    required int mistakes,
    required UserGameLevel currentStats,
  }) async {
    final arenaId = await getMemoryArenaId();
    if (arenaId.isEmpty) {
      throw Exception('Memory arena not configured');
    }

    final savedScore = rawScore.round();
    final timeTakenSec = timeTakenMs / 1000.0;

    debugPrint('🧠 MEMORY: calling process_game_session');
    debugPrint(
      '🧠 MEMORY: arena_id=$arenaId level=$levelReached accuracy=$accuracy mistakes=$mistakes time=${timeTakenSec}s score=$savedScore',
    );

    final dynamic rpcResult = await _sb.rpc('process_game_session', params: {
      'p_player_id': _uid,
      'p_arena_id': arenaId,
      'p_mode': 'solo',
      'p_level_reached': levelReached,
      'p_accuracy': accuracy,
      'p_mistakes': mistakes,
      'p_time_taken_sec': timeTakenSec,
      'p_override_score': savedScore,
    });

    final resultMap = _unwrapRpcMap(rpcResult);
    final sessionId = resultMap?['session_id']?.toString();
    final brainScore = (resultMap?['brain_score'] as num?)?.round();

    final newBest = max(currentStats.bestScoreAtLevel, savedScore);
    final newTotal = currentStats.totalPlays + 1;
    final newWeek = currentStats.totalPlaysThisWeek + 1;
    final newLevel = max(currentStats.currentLevel, levelReached);

    await _sb.from('user_game_levels').upsert({
      'user_id': _uid,
      'game_type': 'memory',
      'current_level': newLevel,
      'best_score_at_level': newBest,
      'total_plays': newTotal,
      'total_plays_this_week': newWeek,
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint(
      '✅ MEMORY: stats updated score=$savedScore best=$newBest plays=$newTotal level=$newLevel',
    );

    return MemorySubmissionResult(
      sessionId: sessionId,
      score: savedScore,
      brainScore: brainScore,
    );
  }

  // ══════════════════════════════════════════════════════
  //  DUEL METHODS
  // ══════════════════════════════════════════════════════

  /// Atomic RPC: instantly matches if opponent is waiting, otherwise queues self.
  Future<Map<String, dynamic>?> findOrCreateMatch(int level, int elo) async {
    debugPrint('🧠🚀 [MEMORY MATCHMAKING] Calling find_or_create_match RPC: uid=$_uid level=$level elo=$elo');
    try {
      final result = await _sb.rpc('find_or_create_match', params: {
        'p_user_id': _uid,
        'p_game_type': 'memory',
        'p_level': level,
        'p_elo': elo,
      });
      debugPrint('✅ [MEMORY MATCHMAKING] RPC result: $result');

      final Map<String, dynamic> row;
      if (result is List && result.isNotEmpty) {
        row = result.first as Map<String, dynamic>;
      } else if (result is Map<String, dynamic>) {
        row = result;
      } else {
        debugPrint('❌ [MEMORY MATCHMAKING] Unexpected RPC response type: ${result.runtimeType}');
        return null;
      }

      final matchedInstantly = row['matched_instantly'] as bool? ?? false;
      final duelId = row['duel_id']?.toString();

      if (matchedInstantly && duelId != null) {
        debugPrint('⚡ [MEMORY MATCHMAKING] INSTANT MATCH! duel_id=$duelId');
        return row;
      } else {
        debugPrint('⏳ [MEMORY MATCHMAKING] Queued. Waiting for realtime event...');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [MEMORY MATCHMAKING] find_or_create_match RPC FAILED: $e');
      debugPrint('❌ [MEMORY MATCHMAKING] Falling back to direct queue insert...');
      try {
        await _sb.from('matchmaking_queue').upsert({
          'user_id': _uid,
          'game_type': 'memory',
          'user_level': level,
          'user_elo': elo,
        }, onConflict: 'user_id, game_type');
        debugPrint('✅ [MEMORY MATCHMAKING] Fallback queue insert succeeded');
      } catch (e2) {
        debugPrint('❌ [MEMORY MATCHMAKING] Fallback insert also FAILED: $e2');
        rethrow;
      }
      return null;
    }
  }

  Future<void> cancelMatchmaking(String userId, String gameType) async {
    debugPrint('🧠🔄 [MEMORY MATCHMAKING] Cancelling queue for userId=$userId');
    try {
      await _sb
          .from('matchmaking_queue')
          .delete()
          .eq('user_id', userId)
          .eq('game_type', gameType);
      debugPrint('✅ [MEMORY MATCHMAKING] Queue entry deleted');
    } catch (e) {
      debugPrint('❌ [MEMORY MATCHMAKING] Cancel failed: $e');
    }
  }

  Future<void> setDuelReady(String duelId) async {
    debugPrint('🧠 MEMORY: calling set_duel_ready duelId=$duelId');
    await _sb.rpc('set_duel_ready', params: {'p_duel_id': duelId});
    debugPrint('✅ MEMORY: set_duel_ready complete');
  }

  Future<void> syncDuelScore(String duelId, int score) async {
    debugPrint('🧠 MEMORY: syncDuelScore duelId=$duelId score=$score');
    await _sb
        .rpc('sync_duel_score', params: {'p_duel_id': duelId, 'p_score': score});
  }

  Future<void> completeDuel(String duelId, int finalScore) async {
    debugPrint('🧠 MEMORY: calling complete_duel duelId=$duelId score=$finalScore');
    await _sb.rpc('complete_duel', params: {
      'p_duel_id': duelId,
      'p_final_score': finalScore,
    });
    debugPrint('✅ MEMORY: complete_duel done');
  }

  Future<DuelSession?> fetchDuelSession(String duelId) async {
    debugPrint('🧠 MEMORY: fetchDuelSession duelId=$duelId');
    try {
      final row = await _sb
          .from('duel_sessions')
          .select()
          .eq('id', duelId)
          .maybeSingle();
      if (row == null) return null;
      return DuelSession.fromMap(row);
    } catch (e) {
      debugPrint('❌ MEMORY: fetchDuelSession error: $e');
      return null;
    }
  }

  Future<void> cancelDuel(String duelId) async {
    debugPrint('🧠 MEMORY: cancelling duel id=$duelId');
    try {
      await _sb.from('duel_sessions').update({'status': 'cancelled'}).eq('id', duelId);
    } catch (e) {
      debugPrint('❌ MEMORY: cancelDuel error: $e');
    }
  }

  // ── Realtime ──────────────────────────────────

  RealtimeChannel subscribeToDuel(
      String duelId, void Function(Map<String, dynamic> newRecord) onUpdate) {
    debugPrint('🧠 MEMORY: subscribing to duel realtime duelId=$duelId');
    final channel = _rtClient.channel('memory_duel_$duelId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'duel_sessions',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, column: 'id', value: duelId),
      callback: (payload) {
        debugPrint('🧠 MEMORY: realtime duel event=${payload.eventType} for duelId=$duelId');
        final record = payload.newRecord;
        if (record.isNotEmpty) {
          debugPrint('🧠 MEMORY: realtime data status=${record['status']} '
              'p1_ready=${record['player1_ready']} p2_ready=${record['player2_ready']} '
              'p2_id=${record['player2_id']} start_at=${record['duel_start_at']}');
          onUpdate(record);
        }
      },
    ).subscribe((status, [error]) {
      debugPrint('🧠 MEMORY: duel channel status=$status error=$error');
    });
    return channel;
  }

  RealtimeChannel subscribeToMatchmaking(
      String userId, void Function(Map<String, dynamic> record) onMatch) {
    // ─── CRITICAL: Always refresh auth token on the realtime client ───
    final session = _sb.auth.currentSession;
    if (session != null) {
      _rtClient.realtime.setAuth(session.accessToken);
      debugPrint('✅ [MEMORY MATCHMAKING RT] Auth token synced to realtime client');
    } else {
      debugPrint('❌ [MEMORY MATCHMAKING RT] WARNING: No session! Realtime will use anon key → RLS will block events!');
    }

    debugPrint('🧠🚀 [MEMORY MATCHMAKING RT] Subscribing to realtime for userId=$userId');
    final channel = _rtClient.channel('memory_matching_$userId');

    void handlePayload(PostgresChangePayload payload) {
      final record = payload.newRecord;
      debugPrint('📡 [MEMORY MATCHMAKING RT] Event received! type=${payload.eventType} table=${payload.table}');
      debugPrint('📡 [MEMORY MATCHMAKING RT] Record: id=${record['id']} p1=${record['player1_id']} p2=${record['player2_id']} status=${record['status']} game=${record['game_type']}');

      if (record.isEmpty) {
        debugPrint('❌ [MEMORY MATCHMAKING RT] Record is EMPTY! Check Supabase Realtime settings → Full table replication must be enabled!');
        return;
      }

      final p1 = record['player1_id']?.toString();
      final p2 = record['player2_id']?.toString();
      final status = record['status']?.toString();
      final gameType = record['game_type']?.toString();

      debugPrint('🔍 [MEMORY MATCHMAKING RT] Checking: p1=$p1 p2=$p2 status=$status gameType=$gameType me=$userId');

      if (gameType != 'memory') {
        debugPrint('⏭️ [MEMORY MATCHMAKING RT] Skipping: gameType=$gameType is not memory');
        return;
      }

      if (p1 != userId && p2 != userId) {
        debugPrint('⏭️ [MEMORY MATCHMAKING RT] Skipping: neither p1 nor p2 matches me ($userId)');
        return;
      }

      if (p1 == null || p2 == null) {
        debugPrint('⏭️ [MEMORY MATCHMAKING RT] Waiting: player2 not yet assigned (p2 is null). Waiting for next update...');
        return;
      }

      debugPrint('✅ [MEMORY MATCHMAKING RT] MATCH FOUND! duel_id=${record['id']} status=$status');
      onMatch(record);
    }

    // Listen for INSERT events — when matchmaker creates a new duel
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'duel_sessions',
      callback: handlePayload,
    );

    // Also listen for UPDATE events — when someone joins an existing duel
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'duel_sessions',
      callback: handlePayload,
    );

    channel.subscribe((status, [error]) {
      if (error != null) {
        debugPrint('❌ [MEMORY MATCHMAKING RT] Channel subscribe error: $error');
      } else {
        debugPrint('✅ [MEMORY MATCHMAKING RT] Channel status: $status');
      }
    });
    debugPrint('✅ [MEMORY MATCHMAKING RT] Channel registered (waiting for Supabase confirmation...)');
    return channel;
  }

  // ── Helpers ──────────────────────────────────

  Map<String, dynamic>? _unwrapRpcMap(dynamic result) {
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    if (result is List && result.isNotEmpty && result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    return null;
  }
}
