import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback when the memory game finishes.
typedef GameCompleteCallback = Future<void> Function({
  required double rawScore,
  required double accuracy,
  required int levelReached,
  required int timeTakenMs,
  required int mistakes,
});

/// Grid-based memory game widget.
///
/// Flow:
/// 1. Show highlighted cells for a preview period
/// 2. Hide them; user taps to recall
/// 3. Score and advance levels
class MemoryGameWidget extends StatefulWidget {
  final GameCompleteCallback onGameComplete;

  const MemoryGameWidget({super.key, required this.onGameComplete});

  @override
  State<MemoryGameWidget> createState() => _MemoryGameWidgetState();
}

enum _GamePhase { ready, preview, play, levelComplete, finished }

class _MemoryGameWidgetState extends State<MemoryGameWidget> {
  // Game state
  _GamePhase _phase = _GamePhase.ready;
  int _level = 1;
  int _gridSize = 3; // starts 3x3
  int _highlightCount = 3;
  List<int> _highlightedCells = [];
  Set<int> _userTaps = {};
  int _totalCorrect = 0;
  int _totalMistakes = 0;
  int _totalCells = 0;
  int _maxLevel = 0;
  DateTime? _levelStartTime;
  double _totalTimeSec = 0;
  int _lives = 3;

  // Preview countdown
  int _previewCountdown = 3;
  Timer? _previewTimer;

  final _random = Random();

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  // ── Grid parameters per level ──
  void _configureLevel() {
    if (_level <= 2) {
      _gridSize = 3;
      _highlightCount = _level + 2; // 3, 4
    } else if (_level <= 4) {
      _gridSize = 4;
      _highlightCount = _level + 2; // 5, 6
    } else if (_level <= 6) {
      _gridSize = 4;
      _highlightCount = _level + 3; // 8, 9
    } else {
      _gridSize = 5;
      _highlightCount = min(_level + 4, _gridSize * _gridSize - 2);
    }
  }

  void _startLevel() {
    _configureLevel();

    final totalCellCount = _gridSize * _gridSize;
    // Generate unique random cells to highlight
    final cells = <int>{};
    while (cells.length < _highlightCount) {
      cells.add(_random.nextInt(totalCellCount));
    }
    _highlightedCells = cells.toList();
    _userTaps = {};

    setState(() => _phase = _GamePhase.preview);

    _previewCountdown = 3;
    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_previewCountdown <= 1) {
        timer.cancel();
        _levelStartTime = DateTime.now();
        if (mounted) setState(() => _phase = _GamePhase.play);
      } else {
        if (mounted) setState(() => _previewCountdown--);
      }
    });
  }

  void _onCellTap(int index) {
    if (_phase != _GamePhase.play) return;
    if (_userTaps.contains(index)) return; // already tapped

    HapticFeedback.lightImpact();

    setState(() {
      _userTaps.add(index);
    });

    if (_highlightedCells.contains(index)) {
      _totalCorrect++;
      _totalCells++;

      // Check if all targets found
      final found =
          _userTaps.where((i) => _highlightedCells.contains(i)).length;
      if (found == _highlightedCells.length) {
        _onLevelComplete();
      }
    } else {
      _totalMistakes++;
      _totalCells++;
      _lives--;

      if (_lives <= 0) {
        _onGameFinished();
      }
    }
  }

  void _onLevelComplete() {
    final elapsed = DateTime.now().difference(_levelStartTime!).inMilliseconds;
    _totalTimeSec += elapsed / 1000.0;
    _maxLevel = _level;

    setState(() => _phase = _GamePhase.levelComplete);

    // Auto advance after short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _level++;
      _startLevel();
    });
  }

  void _onGameFinished() {
    if (_levelStartTime != null) {
      final elapsed =
          DateTime.now().difference(_levelStartTime!).inMilliseconds;
      _totalTimeSec += elapsed / 1000.0;
    }
    _maxLevel = max(_maxLevel, _level);

    setState(() => _phase = _GamePhase.finished);

    // Calculate scores
    final accuracy =
        _totalCells > 0 ? (_totalCorrect / _totalCells) * 100.0 : 0.0;
    final timePenalty = (_totalTimeSec > 30) ? (_totalTimeSec - 30) * 0.5 : 0.0;
    final rawScore = (_maxLevel * 100.0) +
        (accuracy * 10.0) -
        (_totalMistakes * 20.0) -
        timePenalty;

    // Delay slightly for UX, then callback
    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onGameComplete(
        rawScore: rawScore < 0 ? 0 : rawScore,
        accuracy: double.parse(accuracy.toStringAsFixed(1)),
        levelReached: _maxLevel,
        timeTakenMs: (_totalTimeSec * 1000).round(),
        mistakes: _totalMistakes,
      );
    });
  }

  void _resetGame() {
    setState(() {
      _phase = _GamePhase.ready;
      _level = 1;
      _totalCorrect = 0;
      _totalMistakes = 0;
      _totalCells = 0;
      _maxLevel = 0;
      _totalTimeSec = 0;
      _lives = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // ── Status bar ──
          _buildStatusBar(cs, theme),
          const SizedBox(height: 20),

          // ── Game area ──
          Expanded(
            child: _phase == _GamePhase.ready
                ? _buildReadyState(cs, theme)
                : _phase == _GamePhase.finished
                    ? _buildFinishedBrief(cs, theme)
                    : _buildGrid(cs, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(ColorScheme cs, ThemeData theme) {
    return Row(
      children: [
        // Level
        _StatChip(
          label: 'Level',
          value: '$_level',
          color: cs.primary,
          theme: theme,
        ),
        const SizedBox(width: 10),
        // Lives
        _StatChip(
          label: 'Lives',
          value: '♥' * _lives,
          color: cs.error,
          theme: theme,
        ),
        const Spacer(),
        // Phase indicator
        if (_phase == _GamePhase.preview)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: cs.tertiaryContainer.withOpacity(0.7),
            ),
            child: Text(
              'Memorize  $_previewCountdown',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_phase == _GamePhase.play)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: cs.primaryContainer.withOpacity(0.7),
            ),
            child: Text(
              'Tap the cells',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_phase == _GamePhase.levelComplete)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.green.withOpacity(0.15),
            ),
            child: Text(
              '✓ Correct',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReadyState(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_view_rounded,
              size: 56, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            'Memory Arena',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Memorize the highlighted cells\nand tap them from memory',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '3 lives  •  Increasing difficulty',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _startLevel,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedBrief(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 56, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Processing…',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs, ThemeData theme) {
    final totalCells = _gridSize * _gridSize;
    final isPreview = _phase == _GamePhase.preview;
    final isLevelComplete = _phase == _GamePhase.levelComplete;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final isTarget = _highlightedCells.contains(index);
            final isTapped = _userTaps.contains(index);

            Color cellColor;
            if (isPreview || isLevelComplete) {
              cellColor = isTarget
                  ? cs.primary.withOpacity(0.8)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04));
            } else {
              // Play phase
              if (isTapped && isTarget) {
                cellColor = Colors.green.withOpacity(0.6);
              } else if (isTapped && !isTarget) {
                cellColor = cs.error.withOpacity(0.5);
              } else {
                cellColor = isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04);
              }
            }

            return GestureDetector(
              onTap: () => _onCellTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cellColor,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Small stat chip for the status bar.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
