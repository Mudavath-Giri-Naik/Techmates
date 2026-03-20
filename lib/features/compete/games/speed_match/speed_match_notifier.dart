import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_client.dart';
import 'engine/speed_match_engine.dart';
import 'models/duel_session_model.dart';
import 'models/game_result_model.dart';
import 'models/user_game_level_model.dart';
import 'speed_match_service.dart';

/// All possible phases of the Speed Match flow.
enum SpeedMatchPhase {
  initial,
  loadingInfo,
  infoLoaded,
  modeSelect,
  solo,
  creatingRoom,
  waiting,
  searching,
  joiningRoom,
  preGame,
  countdown,
  playing,
  complete,
}

/// Centralized state for the entire Speed Match feature.
///
/// A single instance is shared across all screens via constructor injection.
/// Uses Supabase realtime subscriptions (WebSocket connects directly to
/// Supabase Cloud, bypassing the Cloudflare proxy).
class SpeedMatchNotifier extends ChangeNotifier {
  final SpeedMatchService _service = SpeedMatchService();

  // ── Phase ──
  SpeedMatchPhase _phase = SpeedMatchPhase.initial;
  SpeedMatchPhase get phase => _phase;

  void _setPhase(SpeedMatchPhase p) {
    print('SPEED_MATCH: phase change ${_phase.name} → ${p.name}');
    _phase = p;
    notifyListeners();
  }

  // ── User Data ──
  UserGameLevel _userLevel = UserGameLevel.empty('');
  UserGameLevel get userLevel => _userLevel;

  int _allTimeBest = 0;
  int get allTimeBest => _allTimeBest;

  int _bestCorrectAnswers = 0;
  int get bestCorrectAnswers => _bestCorrectAnswers;

  String? _userId;
  String? get userId => _userId;

  String? _collegeId;
  String? get collegeId => _collegeId;

  // ── Duel Data ──
  DuelSession? _duelSession;
  DuelSession? get duelSession => _duelSession;

  String? _inviteCode;
  String? get inviteCode => _inviteCode;

  String? _duelId;
  String? get duelId => _duelId;

  Map<String, dynamic>? _opponentProfile;
  Map<String, dynamic>? get opponentProfile => _opponentProfile;

  Map<String, dynamic>? _myProfile;
  Map<String, dynamic>? get myProfile => _myProfile;

  int _opponentLevel = 1;
  int get opponentLevel => _opponentLevel;

  int _opponentLiveScore = 0;
  int get opponentLiveScore => _opponentLiveScore;

  bool _myReady = false;
  bool get myReady => _myReady;

  bool _opponentReady = false;
  bool get opponentReady => _opponentReady;

  // ── Engine ──
  SpeedMatchEngine? _engine;
  SpeedMatchEngine? get engine => _engine;

  // ── Game Result ──
  GameResult? _gameResult;
  GameResult? get gameResult => _gameResult;

  // ── Realtime ──
  RealtimeChannel? _realtimeChannel;

  // ── Match Poll Timer (repeating while searching) ──
  Timer? _matchPollTimer;

  // ── Error ──
  String? _error;
  String? get error => _error;

  bool get isDuel =>
      _phase == SpeedMatchPhase.creatingRoom ||
      _phase == SpeedMatchPhase.waiting ||
      _phase == SpeedMatchPhase.searching ||
      _phase == SpeedMatchPhase.joiningRoom ||
      _phase == SpeedMatchPhase.preGame ||
      _duelId != null;

  // ────────────────────────────────────────────────────
  //  PHASE TRANSITIONS
  // ────────────────────────────────────────────────────

  /// Load info screen data.
  Future<void> loadInfo() async {
    _setPhase(SpeedMatchPhase.loadingInfo);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'Not logged in';
        print('SPEED_MATCH: ❌ not logged in');
        _setPhase(SpeedMatchPhase.initial);
        return;
      }
      _userId = user.id;
      print('SPEED_MATCH: loading info for user=$_userId');

      final results = await Future.wait([
        _service.fetchUserGameLevel(),
        _service.fetchAllTimeBestScore(),
        _service.fetchBestCorrectAnswers(),
        _service.fetchProfile(user.id),
      ]);

      _userLevel = results[0] as UserGameLevel;
      _allTimeBest = results[1] as int;
      _bestCorrectAnswers = results[2] as int;
      _myProfile = results[3] as Map<String, dynamic>?;
      _collegeId = _myProfile?['college_id'] as String?;
      _error = null;
      print('SPEED_MATCH: info loaded level=${_userLevel.currentLevel} best=$_allTimeBest');
      _setPhase(SpeedMatchPhase.infoLoaded);
    } catch (e) {
      print('SPEED_MATCH: ❌ loadInfo error: $e');
      _error = 'Failed to load game info';
      _setPhase(SpeedMatchPhase.infoLoaded);
    }
  }

  void showModeSelect() => _setPhase(SpeedMatchPhase.modeSelect);

  // ── Solo ──

  void startSolo() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    print('SPEED_MATCH: starting solo level=${_userLevel.currentLevel} seed=$seed');
    _engine = SpeedMatchEngine(
        level: _userLevel.currentLevel, gameSeed: seed);
    _duelId = null;
    _duelSession = null;
    _setPhase(SpeedMatchPhase.countdown);
  }

  // ── Duel: Challenge a Friend ──

  Future<void> createInviteDuel() async {
    _setPhase(SpeedMatchPhase.creatingRoom);
    try {
      final result =
          await _service.createInviteDuel(_userLevel.currentLevel);
      _duelId = result['duel_id']?.toString();
      _inviteCode = result['invite_code']?.toString();
      print('SPEED_MATCH: invite created duelId=$_duelId code=$_inviteCode');

      if (_duelId == null || _inviteCode == null) {
        throw Exception('Missing duel_id or invite_code in RPC response');
      }

      _subscribeToUpdates(_duelId!);
      _setPhase(SpeedMatchPhase.waiting);
    } catch (e) {
      print('SPEED_MATCH: ❌ createInviteDuel error: $e');
      _error = 'Failed to create room: $e';
      _setPhase(SpeedMatchPhase.modeSelect);
    }
  }

  // ── Duel: Auto Match ──

  Future<void> startAutoMatch() async {
    _setPhase(SpeedMatchPhase.searching);
    try {
      debugPrint('🚀 [DUEL AUTO-MATCH] Starting auto match for userId=$_userId level=${_userLevel.currentLevel}');

      // STEP 1: Subscribe to realtime FIRST (catches matches created by the other player's trigger)
      debugPrint('⏳ [DUEL AUTO-MATCH] Step 1: Subscribing to matchmaking realtime channel...');
      _realtimeChannel = _service.subscribeToMatchmaking(
        _userId!,
        (record) {
          debugPrint('✅ [DUEL AUTO-MATCH] Realtime match found! duel_id=${record['id']} status=${record['status']} p1=${record['player1_id']} p2=${record['player2_id']}');
          if (_phase != SpeedMatchPhase.searching) {
            debugPrint('🔄 [DUEL AUTO-MATCH] Already matched (instant path), ignoring realtime duplicate');
            return;
          }
          final id = record['id']?.toString();
          if (id == null) {
            debugPrint('❌ [DUEL AUTO-MATCH] ERROR: matched duel has no id field!');
            return;
          }
          _duelId = id;
          _duelSession = DuelSession.fromMap(record);
          debugPrint('✅ [DUEL AUTO-MATCH] DuelSession built: status=${_duelSession!.status} p1=${_duelSession!.player1Id} p2=${_duelSession!.player2Id}');
          _loadOpponentAndGoPreGame();
        },
      );
      debugPrint('✅ [DUEL AUTO-MATCH] Step 1 done: realtime channel subscribed');

      // STEP 2: Call the fast RPC — instantly returns a match if opponent already waiting
      debugPrint('⏳ [DUEL AUTO-MATCH] Step 2: Calling find_or_create_match RPC...');
      final instantMatch = await _service.findOrCreateMatch(_userLevel.currentLevel, 1000);

      if (instantMatch != null) {
        // ⚡ INSTANT MATCH — no realtime wait needed!
        debugPrint('⚡ [DUEL AUTO-MATCH] Instant match! Navigating immediately...');
        final id = instantMatch['duel_id']?.toString();
        if (id == null) {
          debugPrint('❌ [DUEL AUTO-MATCH] Instant match missing duel_id!');
          return;
        }
        _duelId = id;
        // Fetch full duel session for complete data
        final duel = await _service.fetchDuelSession(id);
        _duelSession = duel;
        _loadOpponentAndGoPreGame();
        return; // Done! No need for fallback poll
      }

      debugPrint('✅ [DUEL AUTO-MATCH] Step 2 done: queued. Waiting for opponent via realtime...');

      // STEP 3: Repeating poll every 2s — catches opponents who join AFTER us
      // (handles case where realtime event is missed or User B joins later)
      debugPrint('⏳ [DUEL AUTO-MATCH] Step 3: Starting 2s repeating poll...');
      _startMatchPollTimer();

    } catch (e) {
      debugPrint('❌ [DUEL AUTO-MATCH] FATAL ERROR in startAutoMatch: $e');
      _error = 'Failed to join queue: $e';
      _setPhase(SpeedMatchPhase.modeSelect);
    }
  }

  void _startMatchPollTimer() {
    _matchPollTimer?.cancel();
    _matchPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_phase != SpeedMatchPhase.searching || _userId == null) {
        debugPrint('🔄 [DUEL POLL] Stopping poll (phase=$_phase)');
        timer.cancel();
        _matchPollTimer = null;
        return;
      }
      debugPrint('🔍 [DUEL POLL] Tick: checking for a match...');
      try {
        final existing = await Supabase.instance.client
            .from('duel_sessions')
            .select()
            .or('player1_id.eq.$_userId,player2_id.eq.$_userId')
            .eq('game_type', 'speed_match')
            .inFilter('status', ['waiting', 'matched'])
            .not('player2_id', 'is', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (existing != null && _phase == SpeedMatchPhase.searching) {
          debugPrint('✅ [DUEL POLL] Match found! duel_id=${existing['id']} — navigating to pregame');
          timer.cancel();
          _matchPollTimer = null;
          _duelId = existing['id']?.toString();
          _duelSession = DuelSession.fromMap(existing);
          _loadOpponentAndGoPreGame();
        } else {
          debugPrint('⏳ [DUEL POLL] No match yet, will retry in 2s...');
        }
      } catch (e) {
        debugPrint('❌ [DUEL POLL] Poll error: $e');
      }
    });
  }

  Future<void> cancelAutoMatch() async {
    debugPrint('🔄 [DUEL AUTO-MATCH] Cancelling auto match');
    _matchPollTimer?.cancel();
    _matchPollTimer = null;
    if (_userId != null) {
      await _service.cancelMatchmaking(_userId!, 'speed_match');
    }
    _removeRealtimeChannel();
    _setPhase(SpeedMatchPhase.modeSelect);
  }

  // ── Duel: Join via Code ──

  void showJoinRoom() => _setPhase(SpeedMatchPhase.joiningRoom);

  Future<void> joinWithCode(String code) async {
    print('SPEED_MATCH: 🔄 joining with code=$code');
    _error = null;
    try {
      final result = await _service.joinInviteDuel(code);
      _duelId = result['duel_id']?.toString();
      final player1Id = result['player1_id']?.toString();
      final playerLevel = (result['player_level'] as num?)?.toInt() ?? 1;

      print('SPEED_MATCH: ✅ RPC succeeded duelId=$_duelId player1Id=$player1Id level=$playerLevel');

      if (_duelId == null || player1Id == null) {
        throw Exception('Missing duel_id or player1_id in join response');
      }

      // Fetch the full duel session so pregame has all data
      final duel = await _service.fetchDuelSession(_duelId!);
      if (duel != null) {
        _duelSession = duel;
        print('SPEED_MATCH: ✅ duelSession loaded status=${duel.status} p1=${duel.player1Id} p2=${duel.player2Id}');
      } else {
        print('SPEED_MATCH: ⚠️ fetchDuelSession returned null, building minimal duelSession');
      }

      // Load opponent profile (player1 is the host)
      _opponentProfile = await _service.fetchProfile(player1Id);
      _opponentLevel = playerLevel;
      if (_opponentProfile != null) {
        print('SPEED_MATCH: ✅ opponent profile: name=${_opponentProfile!['full_name']} avatar=${_opponentProfile!['avatar_url']}');
      } else {
        print('SPEED_MATCH: ❌ opponent profile is null');
      }

      // Ensure myProfile is loaded
      if (_myProfile == null && _userId != null) {
        print('SPEED_MATCH: 🔄 loading myProfile...');
        _myProfile = await _service.fetchProfile(_userId!);
        print('SPEED_MATCH: ${_myProfile != null ? '✅' : '❌'} myProfile: name=${_myProfile?['full_name']}');
      }

      _subscribeToUpdates(_duelId!);
      print('SPEED_MATCH: ✅ joinWithCode complete, transitioning to preGame');
      _setPhase(SpeedMatchPhase.preGame);
    } catch (e) {
      print('SPEED_MATCH: ❌ joinWithCode error: $e');
      _error = 'Invalid or expired code';
      notifyListeners();
    }
  }

  // ── Pre-Game: Ready ──

  Future<void> setReady() async {
    if (_duelId == null) {
      debugPrint('❌ [PREGAME] Cannot set ready: _duelId is null');
      return;
    }
    debugPrint('⏳ [PREGAME] Setting ready for duelId=$_duelId...');
    try {
      await _service.setDuelReady(_duelId!);
      _myReady = true;
      debugPrint('✅ [PREGAME] Successfully set myself as READY');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [PREGAME] setReady RPC error: $e');
    }
  }

  // ── Start Playing ──

  void startPlaying() {
    print('SPEED_MATCH: starting gameplay!');
    _setPhase(SpeedMatchPhase.playing);
  }

  // ── Complete Game ──

  Future<void> completeGame(SpeedMatchEngine engine) async {
    print('SPEED_MATCH: 🏁 game complete score=${engine.score} cards=${engine.totalCards}');
    _engine = engine;

    // Set duelWon immediately from live score so it's correct even if later fetches fail
    final bool isDuel = _duelId != null;
    final bool initialDuelWon = isDuel && engine.score > _opponentLiveScore;
    print('SPEED_MATCH: isDuel=$isDuel myScore=${engine.score} oppLiveScore=$_opponentLiveScore → duelWon=$initialDuelWon');

    _gameResult = GameResult(
      score: engine.score,
      totalCards: engine.totalCards,
      correctCount: engine.correctCount,
      accuracy: engine.accuracy,
      maxStreak: engine.maxStreak,
      avgResponseMs: engine.avgResponseMs,
      bestResponseMs: engine.bestResponseMs,
      level: _userLevel.currentLevel,
      isDuel: isDuel,
      opponentId: _duelSession?.opponentId(_userId!),
      duelWon: isDuel ? initialDuelWon : null,
      opponentScore: _opponentLiveScore,
    );

    // Upload duel score
    if (isDuel) {
      try {
        await _service.completeDuel(_duelId!, engine.score);
        print('SPEED_MATCH: ✅ completeDuel done');
      } catch (e) {
        print('SPEED_MATCH: ❌ completeDuel error: $e');
      }
    }

    // Save stats (separate try so it doesn't block duelWon)
    try {
      final bool isLevelUp = !isDuel &&
          engine.score >= (200 + _userLevel.currentLevel * 50);

      await _service.processAndUpdateStats(
        rawScore: engine.score,
        level: _userLevel.currentLevel,
        metadata: _gameResult!.toMetadata(),
        currentStats: _userLevel,
        levelUp: isLevelUp,
        isDuel: isDuel,
        opponentId: _duelSession?.opponentId(_userId!),
        won: isDuel ? initialDuelWon : null,
      );
      print('SPEED_MATCH: ✅ processAndUpdateStats done');
    } catch (e) {
      print('SPEED_MATCH: ❌ processAndUpdateStats error: $e');
    }

    // Re-fetch duel to get final opponent score (separate try)
    if (isDuel) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        final duel = await _service.fetchDuelSession(_duelId!);
        if (duel != null) {
          _duelSession = duel;
          final finalOppScore = duel.opponentScore(_userId!);
          final finalWon = engine.score > finalOppScore;
          _opponentLiveScore = finalOppScore;
          _gameResult = GameResult(
            score: engine.score,
            totalCards: engine.totalCards,
            correctCount: engine.correctCount,
            accuracy: engine.accuracy,
            maxStreak: engine.maxStreak,
            avgResponseMs: engine.avgResponseMs,
            bestResponseMs: engine.bestResponseMs,
            level: _userLevel.currentLevel,
            isDuel: true,
            opponentId: duel.opponentId(_userId!),
            duelWon: finalWon,
            opponentScore: finalOppScore,
          );
          print('SPEED_MATCH: ✅ final duel result myScore=${engine.score} oppScore=$finalOppScore → duelWon=$finalWon');
        } else {
          print('SPEED_MATCH: ⚠️ fetchDuelSession returned null, keeping initial result');
        }
      } catch (e) {
        print('SPEED_MATCH: ❌ fetchDuelSession error: $e (keeping initial duelWon=$initialDuelWon)');
      }
    }

    _removeRealtimeChannel();
    _setPhase(SpeedMatchPhase.complete);
  }

  // ── Cancel / Reset ──

  Future<void> cancelDuel() async {
    print('SPEED_MATCH: cancelling duel $_duelId');
    if (_duelId != null) {
      await _service.cancelDuel(_duelId!);
    }
    _removeRealtimeChannel();
    _duelId = null;
    _duelSession = null;
    _inviteCode = null;
    _opponentProfile = null;
    _myReady = false;
    _opponentReady = false;
    _setPhase(SpeedMatchPhase.modeSelect);
  }

  void resetToInfo() {
    print('SPEED_MATCH: resetting to info screen');
    _removeRealtimeChannel();
    _duelId = null;
    _duelSession = null;
    _inviteCode = null;
    _opponentProfile = null;
    _myReady = false;
    _opponentReady = false;
    _engine = null;
    _gameResult = null;
    _opponentLiveScore = 0;
    _error = null;
    loadInfo();
  }

  // ────────────────────────────────────────────────────
  //  REALTIME
  // ────────────────────────────────────────────────────

  void _subscribeToUpdates(String duelId) {
    print('SPEED_MATCH: subscribing to duel updates duelId=$duelId');
    _removeRealtimeChannel();
    _realtimeChannel = _service.subscribeToDuel(duelId, _handleDuelUpdate);
  }

  void _handleDuelUpdate(Map<String, dynamic> record) {
    debugPrint('📡 [PREGAME RT] Realtime duel update received!');
    debugPrint('   → status=${record['status']}');
    debugPrint('   → p1_ready=${record['player1_ready']}');
    debugPrint('   → p2_ready=${record['player2_ready']}');
    debugPrint('   → duel_start_at=${record['duel_start_at']}');
    debugPrint('   → current_phase=$_phase');

    _duelSession = DuelSession.fromMap(record);
    final duel = _duelSession!;

    // ── Duel cancelled by opponent ──
    if (duel.status == 'cancelled') {
      debugPrint('❌ [PREGAME] Duel was cancelled by opponent');
      _removeRealtimeChannel();
      _duelId = null;
      _duelSession = null;
      _inviteCode = null;
      _opponentProfile = null;
      _myReady = false;
      _opponentReady = false;
      _error = 'Match was cancelled';
      _setPhase(SpeedMatchPhase.modeSelect);
      return;
    }

    // ── Opponent joined (for invite host) ──
    if (duel.player2Id != null &&
        duel.player2Id!.isNotEmpty &&
        _phase == SpeedMatchPhase.waiting) {
      debugPrint('✅ [PREGAME] Opponent joined! p2=${duel.player2Id}');
      _loadOpponentAndGoPreGame();
      return;
    }

    // ── Ready states ──
    final amP1 = _userId == duel.player1Id;
    _myReady = amP1 ? duel.player1Ready : duel.player2Ready;
    _opponentReady = amP1 ? duel.player2Ready : duel.player1Ready;
    debugPrint('✅ [PREGAME] Ready states updated: myReady=$_myReady oppReady=$_opponentReady');

    // ── Live score during game ──
    if (_phase == SpeedMatchPhase.playing) {
      _opponentLiveScore = duel.opponentScore(_userId!);
    }

    // ── duel_start_at set → engine with shared seed → countdown ──
    if (duel.duelStartAt != null && _phase == SpeedMatchPhase.preGame) {
      final gameSeed = duel.gameSeed;
      final playLevel = duel.playerLevel;
      debugPrint('🚀 [PREGAME] duel_start_at is SET -> $gameSeed! Transitioning to countdown! 🎮');
      _engine = SpeedMatchEngine(level: playLevel, gameSeed: gameSeed);
      _setPhase(SpeedMatchPhase.countdown);
      return;
    }

    if (duel.isBothReady && duel.duelStartAt == null && _phase == SpeedMatchPhase.preGame) {
      debugPrint('⚠️ [PREGAME] BOTH players are ready (true), BUT duel_start_at is still NULL!');
      debugPrint('⚠️ [PREGAME] This means the database trigger/function failed to set the start time.');
    } else if (!duel.isBothReady && duel.duelStartAt == null && _phase == SpeedMatchPhase.preGame) {
       debugPrint('⏳ [PREGAME] Waiting for the other player to click ready...');
    }

    notifyListeners();
  }

  Future<void> _loadOpponentAndGoPreGame() async {
    if (_duelSession == null || _userId == null) {
      print('SPEED_MATCH: ❌ _loadOpponentAndGoPreGame: duelSession or userId is null');
      return;
    }
    final oppId = _duelSession!.opponentId(_userId!);
    print('SPEED_MATCH: 🔄 loading opponent profile oppId=$oppId');

    if (oppId == null || oppId.isEmpty) {
      print('SPEED_MATCH: ❌ opponent ID is null/empty');
      return;
    }

    // Fetch opponent profile
    _opponentProfile = await _service.fetchProfile(oppId);
    if (_opponentProfile != null) {
      print('SPEED_MATCH: ✅ opponent profile loaded:'
          ' name=${_opponentProfile!['full_name']}'
          ' avatar=${_opponentProfile!['avatar_url']}'
          ' branch=${_opponentProfile!['branch']}'
          ' year=${_opponentProfile!['year']}'
          ' college=${_opponentProfile!['colleges']?['short_name']}');
    } else {
      print('SPEED_MATCH: ❌ opponent profile returned null for oppId=$oppId');
    }

    // Also ensure myProfile is loaded
    if (_myProfile == null && _userId != null) {
      print('SPEED_MATCH: 🔄 myProfile is null, re-fetching...');
      _myProfile = await _service.fetchProfile(_userId!);
      if (_myProfile != null) {
        print('SPEED_MATCH: ✅ my profile loaded:'
            ' name=${_myProfile!['full_name']}'
            ' avatar=${_myProfile!['avatar_url']}'
            ' branch=${_myProfile!['branch']}'
            ' year=${_myProfile!['year']}');
      } else {
        print('SPEED_MATCH: ❌ my profile returned null');
      }
    } else {
      print('SPEED_MATCH: ✅ myProfile already loaded: name=${_myProfile?['full_name']}');
    }

    // Fetch opponent level
    try {
      final row = await Supabase.instance.client
          .from('user_game_levels')
          .select('current_level')
          .eq('user_id', oppId)
          .eq('game_type', 'speed_match')
          .maybeSingle();
      _opponentLevel = (row?['current_level'] as num?)?.toInt() ?? 1;
      print('SPEED_MATCH: ✅ opponent level=$_opponentLevel');
    } catch (e) {
      print('SPEED_MATCH: ⚠️ fetch opponent level error: $e');
      _opponentLevel = 1;
    }

    // Always switch to duel-specific channel (replaces matchmaking channel)
    if (_duelId != null) {
      _subscribeToUpdates(_duelId!);
    }

    // Set phase and notify — this triggers UI rebuild with all profile data ready
    print('SPEED_MATCH: ✅ all profile data loaded, transitioning to preGame');
    _setPhase(SpeedMatchPhase.preGame);
  }

  void _removeRealtimeChannel() {
    _matchPollTimer?.cancel();
    _matchPollTimer = null;
    if (_realtimeChannel != null) {
      print('SPEED_MATCH: removing realtime channel');
      SupabaseClientManager.realtimeInstance.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  @override
  void dispose() {
    _removeRealtimeChannel();
    super.dispose();
  }
}
