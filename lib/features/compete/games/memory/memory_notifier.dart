import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../speed_match/models/user_game_level_model.dart';
import '../speed_match/models/duel_session_model.dart';
import 'memory_service.dart';
import 'models/memory_game_result_model.dart';

enum MemoryPhase {
  initial,
  loadingInfo,
  ready,        // Info loaded, show mode select
  modeSelect,   // Solo / Duel picker

  // Duel flow
  searching,    // Auto-match searching
  preGame,      // VS screen, ready buttons
  countdown,    // 3-2-1 countdown
  playing,      // Actually playing

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

  // Alias for consistency with duel screens  
  Map<String, dynamic>? get myProfile => _profile;

  MemoryGameResult? _gameResult;
  MemoryGameResult? get gameResult => _gameResult;

  String? _error;
  String? get error => _error;

  // â”€â”€ Duel Data â”€â”€
  DuelSession? _duelSession;
  DuelSession? get duelSession => _duelSession;

  String? _duelId;
  String? get duelId => _duelId;

  Map<String, dynamic>? _opponentProfile;
  Map<String, dynamic>? get opponentProfile => _opponentProfile;

  int _opponentLiveScore = 0;
  int get opponentLiveScore => _opponentLiveScore;

  bool _myReady = false;
  bool get myReady => _myReady;

  bool _opponentReady = false;
  bool get opponentReady => _opponentReady;

  bool get isDuel => _duelId != null;

  // â”€â”€ Realtime â”€â”€
  RealtimeChannel? _realtimeChannel;

  // â”€â”€ Match Poll Timer â”€â”€
  Timer? _matchPollTimer;

  void _setPhase(MemoryPhase phase) {
    debugPrint('ðŸ§  MEMORY: phase â†’ $phase');
    _phase = phase;
    notifyListeners();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  PHASE TRANSITIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> loadInfo() async {
    _setPhase(MemoryPhase.loadingInfo);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      _userId = user.id;
      debugPrint('ðŸ§  MEMORY: loading info for user=$_userId');

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
      debugPrint('âœ… MEMORY: info loaded level=${_userLevel.currentLevel} best=$_allTimeBest');
    } catch (e) {
      _error = 'Failed to load Memory arena';
      debugPrint('âŒ MEMORY: loadInfo error: $e');
    }

    _setPhase(MemoryPhase.ready);
  }

  void showModeSelect() => _setPhase(MemoryPhase.modeSelect);

  // â”€â”€ Solo â”€â”€

  void startSolo() {
    debugPrint('ðŸ§  MEMORY: starting solo');
    _duelId = null;
    _duelSession = null;
    _setPhase(MemoryPhase.playing);
  }

  // â”€â”€ Duel: Auto Match â”€â”€

  Future<void> startAutoMatch() async {
    // GUARD: make sure userId is loaded first
    if (_userId == null) {
      debugPrint('ðŸ§ âš ï¸ [MEMORY AUTO-MATCH] userId is null, loading info first...');
      await loadInfo();
      if (_userId == null) {
        debugPrint('âŒ [MEMORY AUTO-MATCH] STILL no userId after loadInfo, aborting!');
        _error = 'Not logged in';
        _setPhase(MemoryPhase.modeSelect);
        return;
      }
    }

    _setPhase(MemoryPhase.searching);
    try {
      debugPrint('ðŸ§ ðŸš€ [MEMORY AUTO-MATCH] Starting auto match for userId=$_userId level=${_userLevel.currentLevel}');

      // STEP 1: Subscribe to realtime FIRST (catches matches created by the other player's trigger)
      debugPrint('â³ [MEMORY AUTO-MATCH] Step 1: Subscribing to matchmaking realtime channel...');
      _realtimeChannel = _service.subscribeToMatchmaking(
        _userId!,
        (record) {
          debugPrint('âœ… [MEMORY AUTO-MATCH] Realtime match found! duel_id=${record['id']} status=${record['status']} p1=${record['player1_id']} p2=${record['player2_id']}');
          if (_phase != MemoryPhase.searching) {
            debugPrint('ðŸ”„ [MEMORY AUTO-MATCH] Already matched (instant path), ignoring realtime duplicate');
            return;
          }
          final id = record['id']?.toString();
          if (id == null) {
            debugPrint('âŒ [MEMORY AUTO-MATCH] ERROR: matched duel has no id field!');
            return;
          }
          _duelId = id;
          _duelSession = DuelSession.fromMap(record);
          debugPrint('âœ… [MEMORY AUTO-MATCH] DuelSession built: status=${_duelSession!.status} p1=${_duelSession!.player1Id} p2=${_duelSession!.player2Id}');
          _loadOpponentAndGoPreGame();
        },
      );
      debugPrint('âœ… [MEMORY AUTO-MATCH] Step 1 done: realtime channel subscribed');

      // STEP 2: Call the fast RPC â€” instantly returns a match if opponent already waiting
      debugPrint('â³ [MEMORY AUTO-MATCH] Step 2: Calling find_or_create_match RPC...');
      final instantMatch = await _service.findOrCreateMatch(
          _userLevel.currentLevel, 1000);

      if (instantMatch != null) {
        // âš¡ INSTANT MATCH â€” no realtime wait needed!
        debugPrint('âš¡ [MEMORY AUTO-MATCH] Instant match! Navigating immediately...');
        final id = instantMatch['duel_id']?.toString();
        if (id == null) {
          debugPrint('âŒ [MEMORY AUTO-MATCH] Instant match missing duel_id!');
          return;
        }
        _duelId = id;
        // Fetch full duel session for complete data
        final duel = await _service.fetchDuelSession(id);
        _duelSession = duel;
        _loadOpponentAndGoPreGame();
        return; // Done! No need for fallback poll
      }

      debugPrint('âœ… [MEMORY AUTO-MATCH] Step 2 done: queued. Waiting for opponent via realtime...');

      // STEP 3: Repeating poll every 2s â€” catches opponents who join AFTER us
      debugPrint('â³ [MEMORY AUTO-MATCH] Step 3: Starting 2s repeating poll...');
      _startMatchPollTimer();
    } catch (e) {
      debugPrint('âŒ [MEMORY AUTO-MATCH] FATAL ERROR in startAutoMatch: $e');
      _error = 'Failed to join queue: $e';
      _setPhase(MemoryPhase.modeSelect);
    }
  }

  void _startMatchPollTimer() {
    _matchPollTimer?.cancel();
    _matchPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_phase != MemoryPhase.searching || _userId == null) {
        debugPrint('ðŸ”„ [MEMORY POLL] Stopping poll (phase=$_phase)');
        timer.cancel();
        _matchPollTimer = null;
        return;
      }
      debugPrint('ðŸ” [MEMORY POLL] Tick: checking for a match...');
      try {
        // Keep-alive heartbeat AND active match scanning
        final instantMatch = await _service.findOrCreateMatch(_userLevel.currentLevel, 1000);
        if (instantMatch != null && _phase == MemoryPhase.searching) {
          debugPrint('âš¡ [MEMORY POLL] Match found via RPC! duel_id=${instantMatch['duel_id']}');
          timer.cancel();
          _matchPollTimer = null;
          final id = instantMatch['duel_id']?.toString();
          if (id != null) {
            _duelId = id;
            final duel = await _service.fetchDuelSession(id);
            _duelSession = duel;
            _loadOpponentAndGoPreGame();
          }
          return;
        }

        // Fallback check on duel_sessions directly
        final existing = await Supabase.instance.client
            .from('duel_sessions')
            .select()
            .or('player1_id.eq.$_userId,player2_id.eq.$_userId')
            .eq('game_type', 'memory')
            .inFilter('status', ['waiting', 'matched'])
            .not('player2_id', 'is', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (existing != null && _phase == MemoryPhase.searching) {
          debugPrint('âœ… [MEMORY POLL] Match found! duel_id=${existing['id']} â€” navigating to pregame');
          timer.cancel();
          _matchPollTimer = null;
          _duelId = existing['id']?.toString();
          _duelSession = DuelSession.fromMap(existing);
          _loadOpponentAndGoPreGame();
        } else {
          debugPrint('â³ [MEMORY POLL] No match yet, will retry in 2s...');
        }
      } catch (e) {
        debugPrint('âŒ [MEMORY POLL] Poll error: $e');
      }
    });
  }

  Future<void> cancelAutoMatch() async {
    debugPrint('ðŸ§ ðŸ”„ [MEMORY] Cancelling auto match');
    _matchPollTimer?.cancel();
    _matchPollTimer = null;
    if (_userId != null) {
      await _service.cancelMatchmaking(_userId!, 'memory');
    }
    _removeRealtimeChannel();
    _setPhase(MemoryPhase.modeSelect);
  }

  // â”€â”€ Pre-Game: Ready â”€â”€

  Future<void> setReady() async {
    if (_duelId == null) return;
    debugPrint('ðŸ§ â³ [MEMORY PREGAME] Setting ready for duelId=$_duelId...');
    try {
      await _service.setDuelReady(_duelId!);
      _myReady = true;
      debugPrint('âœ… [MEMORY PREGAME] Successfully set myself as READY');
      notifyListeners();
    } catch (e) {
      debugPrint('âŒ [MEMORY PREGAME] setReady error: $e');
    }
  }

  void startPlaying() {
    debugPrint('ðŸ§  MEMORY: starting gameplay!');
    _setPhase(MemoryPhase.playing);
  }

  // â”€â”€ Complete Game â”€â”€

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
    debugPrint('ðŸ§  MEMORY: ðŸ game complete score=$rawScore level=$levelReached isDuel=$isDuel');

    final bool duelMode = isDuel;
    final int savedScore = rawScore.round();

    try {
      // Upload duel score
      if (duelMode && _duelId != null) {
        try {
          await _service.completeDuel(_duelId!, savedScore);
          debugPrint('âœ… MEMORY: completeDuel done');
        } catch (e) {
          debugPrint('âŒ MEMORY: completeDuel error: $e');
        }
      }

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

      // Set initial duel result
      final bool initialDuelWon = duelMode && savedScore > _opponentLiveScore;

      _gameResult = MemoryGameResult(
        score: submission.score,
        accuracy: accuracy,
        levelReached: levelReached,
        timeTakenMs: timeTakenMs,
        mistakes: mistakes,
        brainScore: submission.brainScore,
        isDuel: duelMode,
        duelWon: duelMode ? initialDuelWon : null,
        opponentScore: duelMode ? _opponentLiveScore : null,
        opponentId: duelMode ? _duelSession?.opponentId(_userId!) : null,
      );

      // Re-fetch duel for final opponent score
      if (duelMode && _duelId != null) {
        try {
          await Future.delayed(const Duration(seconds: 2));
          final duel = await _service.fetchDuelSession(_duelId!);
          if (duel != null) {
            _duelSession = duel;
            final finalOppScore = duel.opponentScore(_userId!);
            final finalWon = savedScore > finalOppScore;
            _opponentLiveScore = finalOppScore;
            _gameResult = MemoryGameResult(
              score: submission.score,
              accuracy: accuracy,
              levelReached: levelReached,
              timeTakenMs: timeTakenMs,
              mistakes: mistakes,
              brainScore: submission.brainScore,
              isDuel: true,
              duelWon: finalWon,
              opponentScore: finalOppScore,
              opponentId: duel.opponentId(_userId!),
            );
            debugPrint('âœ… MEMORY: final duel result myScore=$savedScore oppScore=$finalOppScore â†’ duelWon=$finalWon');
          }
        } catch (e) {
          debugPrint('âŒ MEMORY: fetchDuelSession error: $e');
        }
      }

      _removeRealtimeChannel();
      _error = null;
      _setPhase(MemoryPhase.complete);
    } catch (e) {
      _error = 'Unable to save your Memory score';
      debugPrint('âŒ MEMORY: completeGame error: $e');
      _setPhase(MemoryPhase.ready);
    }
  }

  // â”€â”€ Cancel / Reset â”€â”€

  Future<void> cancelDuel() async {
    debugPrint('ðŸ§  MEMORY: cancelling duel $_duelId');
    if (_duelId != null) {
      await _service.cancelDuel(_duelId!);
    }
      _removeRealtimeChannel();
      _duelId = null;
      _duelSession = null;
      _opponentProfile = null;
      _myReady = false;
      _opponentReady = false;
      _setPhase(MemoryPhase.modeSelect);
  }


  void resetToInfo() {
    debugPrint('ðŸ§  MEMORY: resetting to info screen');
    _removeRealtimeChannel();
    _duelId = null;
    _duelSession = null;
    _opponentProfile = null;
    _myReady = false;
    _opponentReady = false;
    _gameResult = null;
    _opponentLiveScore = 0;
    _error = null;
    loadInfo();
  }

  void reset() {
    _phase = MemoryPhase.initial;
    _gameResult = null;
    _error = null;
    notifyListeners();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  REALTIME
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  void _subscribeToUpdates(String duelId) {
    debugPrint('ðŸ§  MEMORY: subscribing to duel updates duelId=$duelId');
    _removeRealtimeChannel();
    _realtimeChannel = _service.subscribeToDuel(duelId, _handleDuelUpdate);
  }

  void _handleDuelUpdate(Map<String, dynamic> record) {
    debugPrint('ðŸ“¡ [MEMORY PREGAME RT] Realtime duel update received!');
    debugPrint('   â†’ status=${record['status']}');
    debugPrint('   â†’ p1_ready=${record['player1_ready']}');
    debugPrint('   â†’ p2_ready=${record['player2_ready']}');
    debugPrint('   â†’ duel_start_at=${record['duel_start_at']}');
    debugPrint('   â†’ current_phase=$_phase');

    _duelSession = DuelSession.fromMap(record);
    final duel = _duelSession!;

    // â”€â”€ Duel cancelled by opponent â”€â”€
    if (duel.status == 'cancelled') {
      debugPrint('Match was cancelled by opponent');
      _removeRealtimeChannel();
      _duelId = null;
      _duelSession = null;
      _opponentProfile = null;
      _myReady = false;
      _opponentReady = false;
      _error = 'Match was cancelled';
      _setPhase(MemoryPhase.modeSelect);
      return;
    }

    // â”€â”€ Ready states â”€â”€
    final amP1 = _userId == duel.player1Id;
    _myReady = amP1 ? duel.player1Ready : duel.player2Ready;
    _opponentReady = amP1 ? duel.player2Ready : duel.player1Ready;
    debugPrint('âœ… [MEMORY PREGAME] Ready states: myReady=$_myReady oppReady=$_opponentReady');

    // â”€â”€ Live score during game â”€â”€
    if (_phase == MemoryPhase.playing) {
      _opponentLiveScore = duel.opponentScore(_userId!);
    }

    // â”€â”€ duel_start_at set â†’ countdown â”€â”€
    if (duel.duelStartAt != null && _phase == MemoryPhase.preGame) {
      debugPrint('ðŸš€ [MEMORY PREGAME] duel_start_at is SET â†’ countdown!');
      _setPhase(MemoryPhase.countdown);
      return;
    }

    if (duel.isBothReady && duel.duelStartAt == null && _phase == MemoryPhase.preGame) {
      debugPrint('âš ï¸ [MEMORY PREGAME] BOTH players ready BUT duel_start_at is still NULL!');
    } else if (!duel.isBothReady && duel.duelStartAt == null && _phase == MemoryPhase.preGame) {
      debugPrint('â³ [MEMORY PREGAME] Waiting for the other player to click ready...');
    }

    notifyListeners();
  }

  Future<void> _loadOpponentAndGoPreGame() async {
    if (_duelSession == null || _userId == null) {
      debugPrint('âŒ MEMORY: _loadOpponentAndGoPreGame: duelSession or userId is null');
      return;
    }
    final oppId = _duelSession!.opponentId(_userId!);
    debugPrint('ðŸ§ ðŸ”„ MEMORY: loading opponent profile oppId=$oppId');

    if (oppId == null || oppId.isEmpty) {
      debugPrint('âŒ MEMORY: opponent ID is null/empty');
      return;
    }

    _opponentProfile = await _service.fetchProfile(oppId);
    if (_opponentProfile != null) {
      debugPrint('âœ… MEMORY: opponent profile: name=${_opponentProfile!['full_name']}');
    } else {
      debugPrint('âŒ MEMORY: opponent profile is null');
    }

    // Ensure myProfile is loaded
    if (_profile == null && _userId != null) {
      _profile = await _service.fetchProfile(_userId!);
    }

    _subscribeToUpdates(_duelId!);
    _setPhase(MemoryPhase.preGame);
  }

  void _removeRealtimeChannel() {
    if (_realtimeChannel != null) {
      debugPrint('ðŸ§  MEMORY: removing realtime channel');
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }
}
