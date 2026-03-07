/// User's master brain score from `user_brain_score` table.
class BrainScore {
  final String userId;
  final int brainScore;
  final double normalizedScore;
  final int breadthBonus;
  final double streakMultiplier;

  const BrainScore({
    required this.userId,
    required this.brainScore,
    this.normalizedScore = 0,
    this.breadthBonus = 0,
    this.streakMultiplier = 1.0,
  });

  factory BrainScore.fromJson(Map<String, dynamic> json) {
    return BrainScore(
      userId: json['user_id'] as String,
      brainScore: (json['brain_score'] as num?)?.toInt() ?? 0,
      normalizedScore: (json['normalized_score'] as num?)?.toDouble() ?? 0,
      breadthBonus: (json['breadth_bonus'] as num?)?.toInt() ?? 0,
      streakMultiplier: (json['streak_multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static const empty = BrainScore(userId: '', brainScore: 0);
}
