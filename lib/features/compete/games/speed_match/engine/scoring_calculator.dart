/// Pure scoring logic — zero Flutter imports.
class ScoringCalculator {
  const ScoringCalculator._();

  /// Points for a single correct answer.
  ///
  /// Base 100 + speed bonus, multiplied by streak multiplier.
  static int calculate(int responseMs, int multiplier) {
    const base = 100;
    final timeBonus = responseMs <= 300
        ? 50
        : responseMs <= 600
            ? 25
            : 0;
    return (base + timeBonus) * multiplier;
  }

  /// Score threshold to unlock the next level (solo only).
  static int levelUpThreshold(int currentLevel) => 200 + (currentLevel * 50);
}
