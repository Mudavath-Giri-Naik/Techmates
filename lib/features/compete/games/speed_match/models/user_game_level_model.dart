/// Data class for the `user_game_levels` table.
class UserGameLevel {
  final String userId;
  final String gameType;
  final int currentLevel;
  final int bestScoreAtLevel;
  final int totalPlays;
  final int totalPlaysThisWeek;
  final DateTime? weekResetAt;
  final DateTime? updatedAt;

  const UserGameLevel({
    required this.userId,
    required this.gameType,
    this.currentLevel = 1,
    this.bestScoreAtLevel = 0,
    this.totalPlays = 0,
    this.totalPlaysThisWeek = 0,
    this.weekResetAt,
    this.updatedAt,
  });

  factory UserGameLevel.fromMap(Map<String, dynamic> map) {
    return UserGameLevel(
      userId: map['user_id'] as String,
      gameType: map['game_type'] as String,
      currentLevel: (map['current_level'] as num?)?.toInt() ?? 1,
      bestScoreAtLevel: (map['best_score_at_level'] as num?)?.toInt() ?? 0,
      totalPlays: (map['total_plays'] as num?)?.toInt() ?? 0,
      totalPlaysThisWeek: (map['total_plays_this_week'] as num?)?.toInt() ?? 0,
      weekResetAt: map['week_reset_at'] != null
          ? DateTime.tryParse(map['week_reset_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Default record for a new player.
  factory UserGameLevel.empty(String userId) {
    return UserGameLevel(userId: userId, gameType: 'speed_match');
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'game_type': gameType,
        'current_level': currentLevel,
        'best_score_at_level': bestScoreAtLevel,
        'total_plays': totalPlays,
        'total_plays_this_week': totalPlaysThisWeek,
        if (weekResetAt != null)
          'week_reset_at': weekResetAt!.toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}
