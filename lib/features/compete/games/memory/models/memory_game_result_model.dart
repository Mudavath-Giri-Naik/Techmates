class MemoryGameResult {
  final int score;
  final double accuracy;
  final int levelReached;
  final int timeTakenMs;
  final int mistakes;
  final int? brainScore;

  // Duel fields
  final bool isDuel;
  final bool? duelWon;
  final int? opponentScore;
  final String? opponentId;

  const MemoryGameResult({
    required this.score,
    required this.accuracy,
    required this.levelReached,
    required this.timeTakenMs,
    required this.mistakes,
    this.brainScore,
    this.isDuel = false,
    this.duelWon,
    this.opponentScore,
    this.opponentId,
  });

  String get formattedTime {
    final totalSeconds = (timeTakenMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
