class LeaderboardEntry {
  final String userId;
  final String fullName;
  final String? username;
  final String? avatarUrl;
  final int brainScore;
  final int rank;
  final int rankDelta;
  final String? topDomain;
  final int? totalSessions;
  final int streakDays;
  final bool isCurrentUser;
  final String? branch;
  final int? year;

  LeaderboardEntry({
    required this.userId,
    required this.fullName,
    this.username,
    this.avatarUrl,
    required this.brainScore,
    required this.rank,
    required this.rankDelta,
    this.topDomain,
    this.totalSessions,
    required this.streakDays,
    required this.isCurrentUser,
    this.branch,
    this.year,
  });
}
