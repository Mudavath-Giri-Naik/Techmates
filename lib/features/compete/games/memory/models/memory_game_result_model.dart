class MemoryGameResult {
  final int score;
  final double accuracy;
  final int levelReached;
  final int timeTakenMs;
  final int mistakes;
  final int? brainScore;

  const MemoryGameResult({
    required this.score,
    required this.accuracy,
    required this.levelReached,
    required this.timeTakenMs,
    required this.mistakes,
    this.brainScore,
  });

  String get formattedTime {
    final totalSeconds = (timeTakenMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
