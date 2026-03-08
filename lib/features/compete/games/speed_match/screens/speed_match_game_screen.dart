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

class _SpeedMatchGameScreenState extends State<SpeedMatchGameScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _scorePopCtrl;
  late Animation<double> _scorePopAnim;
  late AnimationController _ruleFlipCtrl;
  late Animation<double> _ruleFlipAnim;
  late AnimationController _ruleFlipScaleCtrl;
  late Animation<double> _ruleFlipScaleAnim;

  bool get _isDuel => _n.duelId != null;

  @override
  void initState() {
    super.initState();
    _engine = _n.engine!;
    _n.addListener(_onNotify);

    _scorePopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scorePopAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _scorePopCtrl, curve: Curves.easeOutBack),
    );

    _ruleFlipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ruleFlipAnim = CurvedAnimation(
      parent: _ruleFlipCtrl,
      curve: Curves.easeOutCubic,
    );

    _ruleFlipScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ruleFlipScaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ruleFlipScaleCtrl, curve: Curves.easeOutCubic),
    );

    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _scoreSyncTimer?.cancel();
    _scorePopCtrl.dispose();
    _ruleFlipCtrl.dispose();
    _ruleFlipScaleCtrl.dispose();
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
    _ruleFlipCtrl.forward(from: 0);
    _ruleFlipScaleCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
    setState(() {});

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _engine.applyRuleFlip();
      _ruleFlipCtrl.reverse().then((_) {
        if (mounted) {
          setState(() {
            _ruleFlipPaused = false;
            _showRuleFlipOverlay = false;
          });
        }
      });
    });
  }

  void _onAnswer(bool tappedYes) {
    if (_isFirstCard || _ruleFlipPaused || !_gameStarted) return;

    final result = _engine.answer(tappedYes);
    _lastAnswerCorrect = result.isCorrect;

    if (result.isCorrect) {
      HapticFeedback.selectionClick();
      _scorePopCtrl.forward(from: 0);
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SpeedMatchScorecardScreen(notifier: _n),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgBase = const Color(0xFFF5F7FB);
    final isUrgent = _secondsRemaining <= 10;
    final bgColor = isUrgent
        ? Color.alphaBlend(const Color(0xFFFFECEE), bgBase)
        : bgBase;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: bgColor,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  TimerBarWidget(
                    progress: _secondsRemaining / 60.0,
                    secondsRemaining: _secondsRemaining,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _TimerChip(
                          seconds: _secondsRemaining,
                          isUrgent: isUrgent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScoreDisplay(
                          score: _engine.score,
                          popAnim: _scorePopAnim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusStrip(
                    streak: _engine.streak,
                    dotsToShow: _engine.dotsToShow,
                    multiplier: _engine.multiplier,
                  ),
                  if (_isDuel) ...[
                    const SizedBox(height: 12),
                    PlayerVsWidget(
                      player1Profile: _n.myProfile,
                      player2Profile: _n.opponentProfile,
                      player1Score: _engine.score,
                      player2Score: _n.opponentLiveScore,
                      currentUserId: _n.userId!,
                    ),
                  ],
                  const SizedBox(height: 18),
                  AnimatedOpacity(
                    opacity: _isFirstCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const _FocusBanner(
                      title: 'Opening Symbol',
                      subtitle: 'Memorize it before the match starts.',
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_engine.currentSymbol != null)
                            Flexible(
                              flex: 3,
                              child: SymbolCardWidget(
                                key: ValueKey(_engine.totalCards),
                                symbol: _engine.currentSymbol!,
                                lastAnswerCorrect: _lastAnswerCorrect,
                              ),
                            ),
                          const SizedBox(height: 12),
                          AnimatedOpacity(
                            opacity: !_isFirstCard ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: _InstructionCard(
                              text: _engine.ruleFlipped
                                  ? 'Tap YES when the current symbol is different from the previous one.'
                                  : 'Tap YES when the current symbol matches the previous one.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: (!_isFirstCard && _gameStarted) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AnswerButton(
                            label: 'NO',
                            hint: 'Different pattern',
                            icon: Icons.close_rounded,
                            isNegative: true,
                            onTap: () => _onAnswer(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnswerButton(
                            label: 'YES',
                            hint: 'Same pattern',
                            icon: Icons.check_rounded,
                            isNegative: false,
                            onTap: () => _onAnswer(true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showRuleFlipOverlay)
            FadeTransition(
              opacity: _ruleFlipAnim,
              child: ScaleTransition(
                scale: _ruleFlipScaleAnim,
                child: const _RuleFlipOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final int seconds;
  final bool isUrgent;

  const _TimerChip({
    required this.seconds,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isUrgent
        ? const Color(0xFFE46677)
        : const Color(0xFF3478F6);
    final bg = isUrgent
        ? const Color(0xFFFFF3F4)
        : const Color(0xFFFCFDFF);
    final border = isUrgent
        ? const Color(0xFFF0C9CF)
        : const Color(0xFFD7E0EC);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniIconBadge(
                icon: isUrgent ? Icons.timer_rounded : Icons.timer_outlined,
                iconColor: accent,
                bgColor: accent.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 8),
              const Text(
                'TIME LEFT',
                style: TextStyle(
                  color: Color(0xFF728096),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '0:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Color(0xFF162033),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final int score;
  final Animation<double> popAnim;

  const _ScoreDisplay({
    required this.score,
    required this.popAnim,
  });

  String _fmt(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E0EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniIconBadge(
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFF245FD9),
                bgColor: const Color(0xFFEAF2FF),
              ),
              const SizedBox(width: 8),
              const Text(
                'SCORE',
                style: TextStyle(
                  color: Color(0xFF728096),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ScaleTransition(
            scale: popAnim,
            child: Text(
              _fmt(score),
              style: const TextStyle(
                color: Color(0xFF162033),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final int streak;
  final int dotsToShow;
  final int multiplier;

  const _StatusStrip({
    required this.streak,
    required this.dotsToShow,
    required this.multiplier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E0EC)),
      ),
      child: Row(
        children: [
          const Text(
            'STREAK',
            style: TextStyle(
              color: Color(0xFF728096),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          StreakDotsWidget(filledCount: dotsToShow),
          const SizedBox(width: 12),
          Text(
            streak.toString(),
            style: const TextStyle(
              color: Color(0xFF162033),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          AnimatedMultiplierBadge(multiplier: multiplier),
        ],
      ),
    );
  }
}

class _FocusBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FocusBanner({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D7A5)),
      ),
      child: Row(
        children: [
          _MiniIconBadge(
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFFAD7A18),
            bgColor: const Color(0xFFFDF0CD),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E5A18),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9B7A3A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String text;

  const _InstructionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E0EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniIconBadge(
            icon: Icons.compare_arrows_rounded,
            iconColor: const Color(0xFF3478F6),
            bgColor: const Color(0xFFEAF2FF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF5F6E86),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _MiniIconBadge({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: iconColor),
    );
  }
}

class _AnswerButton extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isNegative;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.hint,
    required this.icon,
    required this.isNegative,
    required this.onTap,
  });

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isNegative
        ? const Color(0xFFFFF4F5)
        : const Color(0xFFF2FBF6);
    final border = widget.isNegative
        ? const Color(0xFFF0C9CF)
        : const Color(0xFFBFE4CD);
    final iconBg = widget.isNegative
        ? const Color(0xFFFFE4E8)
        : const Color(0xFFDDF5E7);
    final fg = widget.isNegative
        ? const Color(0xFFC44D63)
        : const Color(0xFF1B8C58);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: Ink(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.hint,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleFlipOverlay extends StatelessWidget {
  const _RuleFlipOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB).withValues(alpha: 0.97),
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD7E0EC)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFBFD2FB)),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  color: Color(0xFF245FD9),
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rule Flip',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF162033),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'YES now means different.\nNO now means same.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F6E86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
