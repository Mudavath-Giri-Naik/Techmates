import 'dart:math';

import 'scoring_calculator.dart';
import 'symbol_generator.dart';

/// Result of answering a single card.
class AnswerResult {
  final bool isCorrect;
  final int points;
  final int newMultiplier;

  const AnswerResult._({
    required this.isCorrect,
    this.points = 0,
    this.newMultiplier = 1,
  });

  factory AnswerResult.correct({required int points, required int newMultiplier}) =>
      AnswerResult._(isCorrect: true, points: points, newMultiplier: newMultiplier);

  factory AnswerResult.wrong() =>
      AnswerResult._(isCorrect: false, points: 0, newMultiplier: 1);
}

/// Pure game logic — zero Flutter/UI imports.
class SpeedMatchEngine {
  final int level;
  final int gameSeed;

  int score = 0;
  int streak = 0;
  int multiplier = 1;
  int totalCards = 0;
  int correctCount = 0;
  int maxStreak = 0;
  final List<int> responseTimes = [];
  bool ruleFlipped = false;

  GeneratedSymbol? currentSymbol;
  GeneratedSymbol? previousSymbol;

  DateTime? _cardShownAt;
  late final SymbolGenerator _generator;

  GamePhase get phase => SymbolGenerator.phaseFor(level);

  SpeedMatchEngine({required this.level, required this.gameSeed}) {
    _generator = SymbolGenerator(gameSeed: gameSeed, phase: phase);
  }

  /// Show the next symbol card.
  void startNewCard() {
    _cardShownAt = DateTime.now();
    previousSymbol = currentSymbol;
    currentSymbol = _generator.next(previousSymbol);
    totalCards++;
  }

  /// Process the player's YES / NO answer.
  AnswerResult answer(bool tappedYes) {
    final responseMs =
        DateTime.now().difference(_cardShownAt!).inMilliseconds;
    responseTimes.add(responseMs);

    final actuallyMatches = _doesMatch();
    // For rule flip: correct answer is inverted.
    final correctAnswer = ruleFlipped ? !actuallyMatches : actuallyMatches;
    final isCorrect = tappedYes == correctAnswer;

    if (isCorrect) {
      streak++;
      maxStreak = max(maxStreak, streak);
      correctCount++;
      multiplier = _multiplierFor(streak);
      final points = ScoringCalculator.calculate(responseMs, multiplier);
      score += points;
      return AnswerResult.correct(points: points, newMultiplier: multiplier);
    } else {
      streak = 0;
      multiplier = 1;
      return AnswerResult.wrong();
    }
  }

  /// Activate rule flip (levels 76+).
  void applyRuleFlip() {
    ruleFlipped = true;
    streak = 0;
    multiplier = 1;
  }

  int get avgResponseMs => responseTimes.isEmpty
      ? 0
      : responseTimes.reduce((a, b) => a + b) ~/ responseTimes.length;

  int get bestResponseMs => responseTimes.isEmpty
      ? 0
      : responseTimes.reduce(min);

  double get accuracy =>
      totalCards == 0 ? 0.0 : correctCount / totalCards;

  /// Number of correct answers needed for next multiplier tier.
  int get streakTarget {
    if (multiplier < 2) return 3;
    if (multiplier < 4) return 6;
    if (multiplier < 8) return 10;
    return 10; // already at max
  }

  /// Progress within the current multiplier tier (0-based index into dots).
  int get streakProgress {
    if (streak >= 10) return streak - 10; // at ×8, keep counting
    if (streak >= 6) return streak - 6;   // working toward ×8
    if (streak >= 3) return streak - 3;   // working toward ×4
    return streak;                         // working toward ×2
  }

  /// Number of dots to fill (max 4 per tier, wraps).
  int get dotsToShow {
    if (multiplier >= 8) return 4; // full
    if (multiplier >= 4) return min(streak - 6, 4);
    if (multiplier >= 2) return min(streak - 3, 3);
    return min(streak, 3);
  }

  // ── Private ──

  int _multiplierFor(int s) {
    if (s >= 10) return 8;
    if (s >= 6) return 4;
    if (s >= 3) return 2;
    return 1;
  }

  bool _doesMatch() {
    if (previousSymbol == null || currentSymbol == null) return false;
    return currentSymbol!.matches(previousSymbol!);
  }
}
