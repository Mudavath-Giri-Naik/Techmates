/// Captures final game statistics for the scorecard.
class GameResult {
  final int score;
  final int totalCards;
  final int correctCount;
  final double accuracy;
  final int maxStreak;
  final int avgResponseMs;
  final int bestResponseMs;
  final int level;
  final bool isDuel;
  final String? opponentId;
  final bool? duelWon;
  final int? opponentScore;

  const GameResult({
    required this.score,
    required this.totalCards,
    required this.correctCount,
    required this.accuracy,
    required this.maxStreak,
    required this.avgResponseMs,
    this.bestResponseMs = 0,
    required this.level,
    this.isDuel = false,
    this.opponentId,
    this.duelWon,
    this.opponentScore,
  });

  int get wrongCount => totalCards - correctCount;

  Map<String, dynamic> toMetadata() => {
        'level': level,
        'cards_seen': totalCards,
        'correct_answers': correctCount,
        'accuracy': accuracy,
        'max_streak': maxStreak,
        'avg_response_ms': avgResponseMs,
        'duel_opponent_id': opponentId,
        'duel_won': duelWon,
      };
}
