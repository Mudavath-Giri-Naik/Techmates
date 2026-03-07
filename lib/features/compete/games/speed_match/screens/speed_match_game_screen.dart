import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/speed_match_engine.dart';
import '../speed_match_notifier.dart';
import '../speed_match_service.dart';
import '../widgets/multiplier_badge_widget.dart';
import '../widgets/player_vs_widget.dart';
import '../widgets/streak_dots_widget.dart';
import '../widgets/symbol_card_widget.dart';
import '../widgets/timer_bar_widget.dart';
import 'speed_match_scorecard_screen.dart';

/// Core 60-second gameplay screen.
class SpeedMatchGameScreen extends StatefulWidget {
  final SpeedMatchNotifier notifier;

  const SpeedMatchGameScreen({super.key, required this.notifier});

  @override
  State<SpeedMatchGameScreen> createState() => _SpeedMatchGameScreenState();
}

class _SpeedMatchGameScreenState extends State<SpeedMatchGameScreen> {
  SpeedMatchNotifier get _n => widget.notifier;

  late SpeedMatchEngine _engine;
  Timer? _gameTimer;
  Timer? _scoreSyncTimer;
  int _secondsRemaining = 60;
  bool? _lastAnswerCorrect;
  bool _showRuleFlipOverlay = false;
  bool _ruleFlipPaused = false;
  bool _isFirstCard = true;
  bool _gameStarted = false;
  int _syncCounter = 0;

  bool get _isDuel => _n.duelId != null;

  @override
  void initState() {
    super.initState();
    _engine = _n.engine!;
    _n.addListener(_onNotify);
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _scoreSyncTimer?.cancel();
    _n.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    if (mounted) setState(() {});
  }

  void _startGame() {
    _engine.startNewCard();
    _isFirstCard = true;
    setState(() {});

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _engine.startNewCard();
      _isFirstCard = false;
      _gameStarted = true;
      _startTimers();
      setState(() {});
    });
  }

  void _startTimers() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);

      if (_secondsRemaining == 30 &&
          _engine.phase.index >= 5 &&
          !_engine.ruleFlipped) {
        _triggerRuleFlip();
      }

      if (_secondsRemaining <= 10 && _secondsRemaining > 0) {
        HapticFeedback.lightImpact();
      }

      if (_secondsRemaining <= 0) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _endGame();
      }
    });

    if (_isDuel) {
      _scoreSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        SpeedMatchService().syncDuelScore(_n.duelId!, _engine.score);
      });
    }
  }

  void _triggerRuleFlip() {
    _ruleFlipPaused = true;
    _showRuleFlipOverlay = true;
    HapticFeedback.heavyImpact();
    setState(() {});

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _engine.applyRuleFlip();
      _ruleFlipPaused = false;
      _showRuleFlipOverlay = false;
      setState(() {});
    });
  }

  void _onAnswer(bool tappedYes) {
    if (_isFirstCard || _ruleFlipPaused || !_gameStarted) return;

    final result = _engine.answer(tappedYes);
    _lastAnswerCorrect = result.isCorrect;

    if (result.isCorrect) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }

    if (_isDuel && result.isCorrect) {
      _syncCounter++;
      if (_syncCounter % 5 == 0) {
        SpeedMatchService().syncDuelScore(_n.duelId!, _engine.score);
      }
    }

    _engine.startNewCard();
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _lastAnswerCorrect = null);
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _scoreSyncTimer?.cancel();
    _n.completeGame(_engine).then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SpeedMatchScorecardScreen(notifier: _n),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isUrgent = _secondsRemaining <= 10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: mq.padding.top),

              // Timer bar
              TimerBarWidget(
                progress: _secondsRemaining / 60.0,
                secondsRemaining: _secondsRemaining,
              ),

              // Top info row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    // Timer chip
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUrgent
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFBAE6FD),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 15,
                              color: isUrgent
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Text(
                            '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: isUrgent
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          _formatScore(_engine.score),
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Streak + multiplier
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StreakDotsWidget(filledCount: _engine.dotsToShow),
                    const SizedBox(width: 8),
                    AnimatedMultiplierBadge(multiplier: _engine.multiplier),
                  ],
                ),
              ),

              // Duel live scores
              if (_isDuel)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: PlayerVsWidget(
                    player1Profile: _n.myProfile,
                    player2Profile: _n.opponentProfile,
                    player1Score: _engine.score,
                    player2Score: _n.opponentLiveScore,
                    currentUserId: _n.userId!,
                  ),
                ),

              const Spacer(),

              // Symbol card
              if (_engine.currentSymbol != null)
                Column(
                  children: [
                    if (_isFirstCard)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Get Ready...',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SymbolCardWidget(
                      key: ValueKey(_engine.totalCards),
                      symbol: _engine.currentSymbol!,
                      lastAnswerCorrect: _lastAnswerCorrect,
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Question
              if (!_isFirstCard)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _engine.ruleFlipped
                        ? 'Does this symbol DIFFER from the previous?'
                        : 'Does this symbol match the previous?',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // YES / NO
              if (!_isFirstCard && _gameStarted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _answerBtn(
                          label: 'NO',
                          icon: Icons.close_rounded,
                          bg: const Color(0xFFFEF2F2),
                          border: const Color(0xFFFECACA),
                          fg: const Color(0xFFEF4444),
                          onTap: () => _onAnswer(false),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _answerBtn(
                          label: 'YES',
                          icon: Icons.check_rounded,
                          bg: const Color(0xFFECFDF5),
                          border: const Color(0xFFA7F3D0),
                          fg: const Color(0xFF10B981),
                          onTap: () => _onAnswer(true),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: mq.padding.bottom + 20),
            ],
          ),

          // Rule Flip Overlay
          if (_showRuleFlipOverlay)
            AnimatedOpacity(
              opacity: _showRuleFlipOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: const Color(0xFFFAFAFC).withOpacity(0.97),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(
                              color: const Color(0xFFFDE68A), width: 1.5),
                        ),
                        child: const Center(
                          child: Text('⚡', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'RULE FLIP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'SAME → NO  ·  DIFFERENT → YES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _answerBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScore(int s) {
    if (s >= 1000) {
      return '${(s / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return s.toString();
  }
}
