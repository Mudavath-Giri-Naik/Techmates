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
        vsync: this, duration: const Duration(milliseconds: 300));
    _scorePopAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _scorePopCtrl, curve: Curves.elasticOut),
    );

    _ruleFlipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _ruleFlipAnim = CurvedAnimation(
        parent: _ruleFlipCtrl, curve: Curves.easeOutCubic);

    _ruleFlipScaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _ruleFlipScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
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
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SpeedMatchScorecardScreen(notifier: _n),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUrgent = _secondsRemaining <= 10;

    // Urgency tint bleeds into background at 10s
    final bgColor = isUrgent
        ? Color.alphaBlend(
            cs.errorContainer.withOpacity(0.12), cs.surface)
        : cs.surface;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: bgColor,
            child: Column(
              children: [
                SizedBox(height: mq.padding.top),

                // ── Timer Bar ──
                TimerBarWidget(
                  progress: _secondsRemaining / 60.0,
                  secondsRemaining: _secondsRemaining,
                ),

                const SizedBox(height: 14),

                // ── HUD Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Timer chip
                      _TimerChip(
                        seconds: _secondsRemaining,
                        isUrgent: isUrgent,
                        cs: cs,
                        isDark: isDark,
                      ),
                      const Spacer(),
                      // Score
                      _ScoreDisplay(
                        score: _engine.score,
                        popAnim: _scorePopAnim,
                        cs: cs,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Streak + Multiplier ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      StreakDotsWidget(filledCount: _engine.dotsToShow),
                      const SizedBox(width: 8),
                      AnimatedMultiplierBadge(
                          multiplier: _engine.multiplier),
                    ],
                  ),
                ),

                // ── Duel Scores ──
                if (_isDuel)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
                    child: PlayerVsWidget(
                      player1Profile: _n.myProfile,
                      player2Profile: _n.opponentProfile,
                      player1Score: _engine.score,
                      player2Score: _n.opponentLiveScore,
                      currentUserId: _n.userId!,
                    ),
                  ),

                const Spacer(),

                // ── Symbol Card ──
                if (_engine.currentSymbol != null)
                  Column(
                    children: [
                      // "Get Ready" label
                      AnimatedOpacity(
                        opacity: _isFirstCard ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Get Ready…',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
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

                const SizedBox(height: 20),

                // ── Question label ──
                AnimatedOpacity(
                  opacity: !_isFirstCard ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _engine.ruleFlipped
                            ? 'Does this symbol DIFFER from the previous?'
                            : 'Does this symbol match the previous?',
                        key: ValueKey(_engine.ruleFlipped),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Answer Buttons ──
                AnimatedOpacity(
                  opacity: (!_isFirstCard && _gameStarted) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AnswerButton(
                            label: 'NO',
                            icon: Icons.close_rounded,
                            isNegative: true,
                            cs: cs,
                            isDark: isDark,
                            onTap: () => _onAnswer(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnswerButton(
                            label: 'YES',
                            icon: Icons.check_rounded,
                            isNegative: false,
                            cs: cs,
                            isDark: isDark,
                            onTap: () => _onAnswer(true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: mq.padding.bottom + 24),
              ],
            ),
          ),

          // ── Rule Flip Overlay ──
          if (_showRuleFlipOverlay)
            FadeTransition(
              opacity: _ruleFlipAnim,
              child: ScaleTransition(
                scale: _ruleFlipScaleAnim,
                child: _RuleFlipOverlay(cs: cs, isDark: isDark),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  final int seconds;
  final bool isUrgent;
  final ColorScheme cs;
  final bool isDark;

  const _TimerChip({
    required this.seconds,
    required this.isUrgent,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isUrgent
        ? cs.errorContainer
        : (isDark ? cs.surfaceContainer : cs.surfaceContainerLow);
    final fg = isUrgent ? cs.onErrorContainer : cs.primary;
    final border = isUrgent
        ? cs.error.withOpacity(0.35)
        : cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.timer_rounded : Icons.timer_outlined,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            '0:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
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
  final ColorScheme cs;

  const _ScoreDisplay({
    required this.score,
    required this.popAnim,
    required this.cs,
  });

  String _fmt(int s) {
    if (s >= 1000) {
      return '${(s / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return s.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'SCORE',
          style: TextStyle(
            color: cs.onSurfaceVariant.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 1),
        ScaleTransition(
          scale: popAnim,
          child: Text(
            _fmt(score),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isNegative;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.isNegative,
    required this.cs,
    required this.isDark,
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
        ? widget.cs.errorContainer
        : widget.cs.tertiaryContainer;
    final fg = widget.isNegative
        ? widget.cs.onErrorContainer
        : widget.cs.onTertiaryContainer;
    final border = widget.isNegative
        ? widget.cs.error.withOpacity(0.3)
        : widget.cs.tertiary.withOpacity(0.3);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 68,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: fg.withOpacity(0.12),
              highlightColor: fg.withOpacity(0.06),
              onTap: null, // handled by GestureDetector
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: fg, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleFlipOverlay extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;

  const _RuleFlipOverlay({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surface.withOpacity(0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.tertiaryContainer,
                border: Border.all(
                  color: cs.tertiary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'RULE FLIP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: cs.tertiary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: cs.outlineVariant
                        .withOpacity(isDark ? 0.25 : 0.5)),
              ),
              child: Text(
                'SAME → NO  ·  DIFFERENT → YES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}