import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../speed_match/models/user_game_level_model.dart';
import 'memory_service.dart';
import 'models/memory_game_result_model.dart';

enum MemoryPhase {
  initial,
  loadingInfo,
  ready,
  submitting,
  complete,
}

class MemoryNotifier extends ChangeNotifier {
  final MemoryService _service = MemoryService();

  MemoryPhase _phase = MemoryPhase.initial;
  MemoryPhase get phase => _phase;

  UserGameLevel _userLevel = const UserGameLevel(userId: '', gameType: 'memory');
  UserGameLevel get userLevel => _userLevel;

  int _allTimeBest = 0;
  int get allTimeBest => _allTimeBest;

  int _bestLevelReached = 0;
  int get bestLevelReached => _bestLevelReached;

  String? _userId;
  String? get userId => _userId;

  String? _collegeId;
  String? get collegeId => _collegeId;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  MemoryGameResult? _gameResult;
  MemoryGameResult? get gameResult => _gameResult;

  String? _error;
  String? get error => _error;

  void _setPhase(MemoryPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  Future<void> loadInfo() async {
    _setPhase(MemoryPhase.loadingInfo);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      _userId = user.id;

      final results = await Future.wait([
        _service.fetchUserGameLevel(),
        _service.fetchAllTimeBestScore(),
        _service.fetchBestLevelReached(),
        _service.fetchProfile(user.id),
      ]);

      _userLevel = results[0] as UserGameLevel;
      _allTimeBest = results[1] as int;
      _bestLevelReached = results[2] as int;
      _profile = results[3] as Map<String, dynamic>?;
      _collegeId = _profile?['college_id'] as String?;
      _error = null;
    } catch (e) {
      _error = 'Failed to load Memory arena';
      debugPrint('MEMORY: loadInfo error: $e');
    }

    _setPhase(MemoryPhase.ready);
  }

  Future<void> completeGame({
    required double rawScore,
    required double accuracy,
    required int levelReached,
    required int timeTakenMs,
    required int mistakes,
  }) async {
    if (_userId == null) {
      await loadInfo();
      if (_userId == null) return;
    }

    _setPhase(MemoryPhase.submitting);

    try {
      final submission = await _service.processAndUpdateStats(
        rawScore: rawScore,
        accuracy: accuracy,
        levelReached: levelReached,
        timeTakenMs: timeTakenMs,
        mistakes: mistakes,
        currentStats: _userLevel,
      );

      final nextLevel = max(_userLevel.currentLevel, levelReached);
      final nextBest = max(_userLevel.bestScoreAtLevel, submission.score);
      _userLevel = UserGameLevel(
        userId: _userLevel.userId.isEmpty ? _userId! : _userLevel.userId,
        gameType: 'memory',
        currentLevel: nextLevel,
        bestScoreAtLevel: nextBest,
        totalPlays: _userLevel.totalPlays + 1,
        totalPlaysThisWeek: _userLevel.totalPlaysThisWeek + 1,
        weekResetAt: _userLevel.weekResetAt,
        updatedAt: DateTime.now(),
      );
      _allTimeBest = max(_allTimeBest, submission.score);
      _bestLevelReached = max(_bestLevelReached, levelReached);
      _gameResult = MemoryGameResult(
        score: submission.score,
        accuracy: accuracy,
        levelReached: levelReached,
        timeTakenMs: timeTakenMs,
        mistakes: mistakes,
        brainScore: submission.brainScore,
      );
      _error = null;
      _setPhase(MemoryPhase.complete);
    } catch (e) {
      _error = 'Unable to save your Memory score';
      debugPrint('MEMORY: completeGame error: $e');
      _setPhase(MemoryPhase.ready);
    }
  }

  void reset() {
    _phase = MemoryPhase.initial;
    _gameResult = null;
    _error = null;
    notifyListeners();
  }
}
