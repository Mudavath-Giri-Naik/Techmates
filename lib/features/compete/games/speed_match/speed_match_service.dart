import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_client.dart';
import 'models/user_game_level_model.dart';
import 'models/duel_session_model.dart';

/// All Supabase calls for Speed Match. Singleton.
class SpeedMatchService {
  SpeedMatchService._();
  static final SpeedMatchService _instance = SpeedMatchService._();
  factory SpeedMatchService() => _instance;

  SupabaseClient get _sb => Supabase.instance.client;
  String get _uid => _sb.auth.currentUser!.id;

  /// Cached arena UUID for the speed domain.
  String? _cachedSpeedArenaId;

  /// Look up (and cache) the arena UUID for the speed domain.
  Future<String> getSpeedArenaId() async {
    if (_cachedSpeedArenaId != null) return _cachedSpeedArenaId!;
    final row = await _sb
        .from('arenas')
        .select('id')
        .eq('domain_id', await _getSpeedDomainId())
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (row != null) {
      _cachedSpeedArenaId = row['id'] as String;
    } else {
      // Fallback: fetch any speed arena even if inactive
      final fallback = await _sb
          .from('arenas')
          .select('id')
          .eq('domain_id', await _getSpeedDomainId())
          .limit(1)
          .maybeSingle();
      _cachedSpeedArenaId = fallback?['id'] as String?;
    }
    debugPrint('SPEED_MATCH: resolved arena_id=$_cachedSpeedArenaId');
    return _cachedSpeedArenaId ?? '';
  }

  Future<int> _getSpeedDomainId() async {
    final row = await _sb
        .from('domains')
        .select('id')
        .eq('key', 'speed')
        .single();
    return row['id'] as int;
  }

  /// Dedicated client for realtime channels (connects to Supabase Cloud).
  SupabaseClient get _rtClient => SupabaseClientManager.realtimeInstance;

  // ── User Game Level ──────────────────────────────────

  /// Fetch (or create) the user's level record, applying weekly reset if needed.
  Future<UserGameLevel> fetchUserGameLevel() async {
    print('SPEED_MATCH: fetchUserGameLevel for uid=$_uid');
    final row = await _sb
        .from('user_game_levels')
        .select()
        .eq('user_id', _uid)
        .eq('game_type', 'speed_match')
        .maybeSingle();

    if (row == null) {
      print('SPEED_MATCH: no user_game_levels row, returning empty');
      return UserGameLevel.empty(_uid);
    }

    var level = UserGameLevel.fromMap(row);
    print('SPEED_MATCH: fetched level=${level.currentLevel} plays=${level.totalPlays}');

    // Weekly reset check
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart =
        DateTime(currentMonday.year, currentMonday.month, currentMonday.day);

    if (level.weekResetAt == null || level.weekResetAt!.isBefore(mondayStart)) {
      print('SPEED_MATCH: weekly reset triggered');
      await _sb.from('user_game_levels').upsert({
        'user_id': _uid,
        'game_type': 'speed_match',
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

  // ── Best Scores ──────────────────────────────────────

  Future<int> fetchAllTimeBestScore() async {
    try {
      final arenaId = await getSpeedArenaId();
      if (arenaId.isEmpty) return 0;
      final row = await _sb
          .from('game_sessions')
          .select('raw_score')
          .eq('player_id', _uid)
          .eq('arena_id', arenaId)
          .order('raw_score', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row?['raw_score'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('SPEED_MATCH: fetchAllTimeBestScore error: $e');
      return 0;
    }
  }

  Future<int> fetchBestCorrectAnswers() async {
    try {
      final arenaId = await getSpeedArenaId();
      if (arenaId.isEmpty) return 0;
      // game_sessions doesn't store metadata, so best correct = highest level_reached
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
      debugPrint('SPEED_MATCH: fetchBestCorrectAnswers error: $e');
      return 0;
    }
  }

  // ── Duel RPCs ────────────────────────────────────────

  Future<Map<String, dynamic>> createInviteDuel(int playerLevel) async {
    print('SPEED_MATCH: calling create_invite_duel level=$playerLevel');
    final result = await _sb.rpc('create_invite_duel', params: {
      'p_game_type': 'speed_match',
      'p_user_level': playerLevel,
    });
    print('SPEED_MATCH: create_invite_duel raw result=$result (type=${result.runtimeType})');

    // RPC may return a single Map or a List with one Map
    final Map<String, dynamic> row;
    if (result is List && result.isNotEmpty) {
      row = result.first as Map<String, dynamic>;
    } else if (result is Map<String, dynamic>) {
      row = result;
    } else {
      throw Exception('Unexpected create_invite_duel response: $result');
    }
    print('SPEED_MATCH: invite created duel_id=${row['duel_id']} code=${row['invite_code']}');
    return row;
  }

  Future<Map<String, dynamic>> joinInviteDuel(String inviteCode) async {
    final code = inviteCode.toUpperCase().trim();
    print('SPEED_MATCH: 🔄 calling join_invite_duel RPC code=$code');
    final result = await _sb.rpc('join_invite_duel', params: {
      'p_invite_code': code,
    });
    print('SPEED_MATCH: ✅ join_invite_duel result=$result (type=${result.runtimeType})');

    final Map<String, dynamic> row;
    if (result is List && result.isNotEmpty) {
      row = result.first as Map<String, dynamic>;
    } else if (result is Map<String, dynamic>) {
      row = result;
    } else {
      throw Exception('Unexpected join_invite_duel response: $result');
    }
    print('SPEED_MATCH: ✅ joined duel_id=${row['duel_id']} player1=${row['player1_id']}');
    return row;
  }

  Future<void> setDuelReady(String duelId) async {
    print('SPEED_MATCH: calling set_duel_ready duelId=$duelId');
    await _sb.rpc('set_duel_ready', params: {'p_duel_id': duelId});
    print('SPEED_MATCH: set_duel_ready complete');
  }

  Future<void> syncDuelScore(String duelId, int score) async {
    await _sb
        .rpc('sync_duel_score', params: {'p_duel_id': duelId, 'p_score': score});
  }

  Future<void> completeDuel(String duelId, int finalScore) async {
    print('SPEED_MATCH: calling complete_duel duelId=$duelId score=$finalScore');
    await _sb.rpc('complete_duel', params: {
      'p_duel_id': duelId,
      'p_final_score': finalScore,
    });
    print('SPEED_MATCH: complete_duel done');
  }

  // ── Matchmaking Queue ────────────────────────────────

  Future<void> insertMatchmakingQueue(int level, int elo) async {
    print('SPEED_MATCH: inserting into matchmaking_queue level=$level elo=$elo uid=$_uid');
    await _sb.from('matchmaking_queue').insert({
      'user_id': _uid,
      'game_type': 'speed_match',
      'user_level': level,
      'user_elo': elo,
    });
    print('SPEED_MATCH: matchmaking queue insert done');
  }

  Future<void> cancelMatchmaking(String userId, String gameType) async {
    print('SPEED_MATCH: cancelling matchmaking userId=$userId gameType=$gameType');
    await _sb
        .from('matchmaking_queue')
        .delete()
        .eq('user_id', userId)
        .eq('game_type', gameType);
    print('SPEED_MATCH: matchmaking cancelled');
  }

  // ── Process Game + Update Stats ──────────────────────

  Future<void> processAndUpdateStats({
    required int rawScore,
    required int level,
    required Map<String, dynamic> metadata,
    required UserGameLevel currentStats,
    bool levelUp = false,
    bool isDuel = false,
    String? opponentId,
    bool? won,
  }) async {
    final arenaId = await getSpeedArenaId();
    if (arenaId.isEmpty) {
      print('SPEED_MATCH: ❌ no arena_id found for speed domain, skipping RPC');
      return;
    }

    final int totalCards = (metadata['cards_seen'] as num?)?.toInt() ?? 0;
    final int correctCount = (metadata['correct_answers'] as num?)?.toInt() ?? 0;
    final double accuracy = totalCards > 0 ? (correctCount / totalCards * 100) : 0;
    final int mistakes = totalCards - correctCount;
    final int avgResponseMs = (metadata['avg_response_ms'] as num?)?.toInt() ?? 0;
    final double timeTakenSec = (totalCards * avgResponseMs) / 1000.0;

    print('SPEED_MATCH: calling process_game_session RPC');
    print('SPEED_MATCH:   arena_id=$arenaId, mode=${isDuel ? "dual" : "solo"}');
    print('SPEED_MATCH:   level=$level, accuracy=$accuracy, mistakes=$mistakes, time=${timeTakenSec}s');
    print('SPEED_MATCH:   override_score=$rawScore (actual game score)');

    try {
      final result = await _sb.rpc('process_game_session', params: {
        'p_player_id': _uid,
        'p_arena_id': arenaId,
        'p_mode': isDuel ? 'dual' : 'solo',
        'p_level_reached': level,
        'p_accuracy': accuracy,
        'p_mistakes': mistakes,
        'p_time_taken_sec': timeTakenSec,
        'p_opponent_id': opponentId,
        'p_won': won,
        'p_override_score': rawScore,
      });
      print('SPEED_MATCH: ✅ process_game_session result=$result');
    } catch (e) {
      print('SPEED_MATCH: ❌ process_game_session RPC error: $e');
      rethrow;
    }

    // Also update the local user_game_levels for level tracking
    final newBest = max(currentStats.bestScoreAtLevel, rawScore);
    final newTotal = currentStats.totalPlays + 1;
    final newWeek = currentStats.totalPlaysThisWeek + 1;

    final upsertData = <String, dynamic>{
      'user_id': _uid,
      'game_type': 'speed_match',
      'best_score_at_level': newBest,
      'total_plays': newTotal,
      'total_plays_this_week': newWeek,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (levelUp) {
      upsertData['current_level'] = level + 1;
      print('SPEED_MATCH: level up to ${level + 1}!');
    }
    await _sb.from('user_game_levels').upsert(upsertData);
    print('SPEED_MATCH: ✅ stats updated best=$newBest totalPlays=$newTotal');
  }

  // ── Fetch Duel Session ───────────────────────────────

  Future<DuelSession?> fetchDuelSession(String duelId) async {
    print('SPEED_MATCH: fetching duel session id=$duelId');
    final row = await _sb
        .from('duel_sessions')
        .select()
        .eq('id', duelId)
        .maybeSingle();
    if (row == null) {
      print('SPEED_MATCH: duel session not found');
      return null;
    }
    final duel = DuelSession.fromMap(row);
    print('SPEED_MATCH: duel fetched status=${duel.status} p1=${duel.player1Id} p2=${duel.player2Id}');
    return duel;
  }

  // ── Class Rankings ───────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchClassRankings(String collegeId) async {
    final todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .toIso8601String();
    try {
      final arenaId = await getSpeedArenaId();
      if (arenaId.isEmpty) return [];
      final data = await _sb
          .from('game_sessions')
          .select('player_id, raw_score, profiles!game_sessions_player_id_fkey!inner(full_name, college_id)')
          .eq('arena_id', arenaId)
          .eq('profiles.college_id', collegeId)
          .gte('played_at', todayStart)
          .order('raw_score', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('⚠️ [SpeedMatchService] fetchClassRankings error: $e');
      return [];
    }
  }

  // ── Fetch Profile ────────────────────────────────────

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final row = await _sb
          .from('profiles')
          .select('id, full_name, username, avatar_url, college_id, branch, year, colleges!profiles_college_id_fkey(short_name)')
          .eq('id', userId)
          .single();
      return row;
    } catch (e) {
      debugPrint('⚠️ [SpeedMatchService] fetchProfile error: $e');
      return null;
    }
  }

  /// Cancel a duel (update status to 'cancelled' instead of deleting).
  Future<void> cancelDuel(String duelId) async {
    print('SPEED_MATCH: cancelling duel id=$duelId');
    try {
      await _sb.from('duel_sessions').update({'status': 'cancelled'}).eq('id', duelId);
    } catch (e) {
      debugPrint('⚠️ [SpeedMatchService] cancelDuel error: $e');
    }
  }

  /// Realtime channel — subscribe to ALL changes on a specific duel session.
  RealtimeChannel subscribeToDuel(
      String duelId, void Function(Map<String, dynamic> newRecord) onUpdate) {
    print('SPEED_MATCH: subscribing to duel realtime duelId=$duelId');
    final channel = _rtClient.channel('duel_$duelId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'duel_sessions',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, column: 'id', value: duelId),
      callback: (payload) {
        print('SPEED_MATCH: realtime duel event=${payload.eventType} for duelId=$duelId');
        final record = payload.newRecord;
        if (record.isNotEmpty) {
          print('SPEED_MATCH: realtime duel data status=${record['status']} '
              'p1_ready=${record['player1_ready']} p2_ready=${record['player2_ready']} '
              'p2_id=${record['player2_id']} start_at=${record['duel_start_at']}');
          onUpdate(record);
        }
      },
    ).subscribe((status, [error]) {
      print('SPEED_MATCH: duel channel status=$status error=$error');
    });
    return channel;
  }

  /// Realtime channel — subscribe for matched duel (auto-match).
  /// Listens for both INSERT (new duel created by matchmaker) and UPDATE
  /// (existing duel that got matched).
  RealtimeChannel subscribeToMatchmaking(
      String userId, void Function(Map<String, dynamic> record) onMatch) {
    print('SPEED_MATCH: subscribing to matchmaking realtime for userId=$userId');
    final channel = _rtClient.channel('matching_$userId');

    void _handlePayload(PostgresChangePayload payload) {
      final record = payload.newRecord;
      print('SPEED_MATCH: matchmaking event=${payload.eventType} '
          'table=${payload.table} record=$record');
      if (record.isEmpty) return;

      final p1 = record['player1_id']?.toString();
      final p2 = record['player2_id']?.toString();
      final status = record['status']?.toString();
      final gameType = record['game_type']?.toString();

      print('SPEED_MATCH: matchmaking check p1=$p1 p2=$p2 status=$status gameType=$gameType me=$userId');

      if ((p1 == userId || p2 == userId) && gameType == 'speed_match') {
        // Accept 'matched', 'waiting' (with both players), or any status where
        // both players are present
        if (p1 != null && p2 != null) {
          print('SPEED_MATCH: ✅ match found! duel_id=${record['id']}');
          onMatch(record);
        }
      }
    }

    // Listen for INSERT events — when matchmaker creates a new duel
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'duel_sessions',
      callback: _handlePayload,
    );

    // Also listen for UPDATE events — when someone joins an existing duel
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'duel_sessions',
      callback: _handlePayload,
    );

    channel.subscribe((status, [error]) {
      print('SPEED_MATCH: matchmaking channel status=$status error=$error');
    });
    return channel;
  }
}
