import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../speed_match/models/user_game_level_model.dart';

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

    debugPrint('MEMORY: resolved arena_id=$_cachedMemoryArenaId');
    return _cachedMemoryArenaId ?? '';
  }

  Future<int> _getMemoryDomainId() async {
    final row = await _sb.from('domains').select('id').eq('key', 'memory').single();
    return row['id'] as int;
  }

  Future<UserGameLevel> fetchUserGameLevel() async {
    debugPrint('MEMORY: fetchUserGameLevel for uid=$_uid');
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
      debugPrint('MEMORY: fetchAllTimeBestScore error: $e');
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
      debugPrint('MEMORY: fetchBestLevelReached error: $e');
      return 0;
    }
  }

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
      debugPrint('MEMORY: fetchClassRankings error: $e');
      return [];
    }
  }

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
      debugPrint('MEMORY: fetchProfile error: $e');
      return null;
    }
  }

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

    debugPrint('MEMORY: calling process_game_session');
    debugPrint(
      'MEMORY: arena_id=$arenaId level=$levelReached accuracy=$accuracy mistakes=$mistakes time=${timeTakenSec}s score=$savedScore',
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
      'MEMORY: stats updated score=$savedScore best=$newBest plays=$newTotal level=$newLevel',
    );

    return MemorySubmissionResult(
      sessionId: sessionId,
      score: savedScore,
      brainScore: brainScore,
    );
  }

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
