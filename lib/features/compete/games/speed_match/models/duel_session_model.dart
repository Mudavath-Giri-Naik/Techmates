/// Data class for the `duel_sessions` table.
class DuelSession {
  final String id;
  final String player1Id;
  final String? player2Id;
  final String gameType;
  final String status;
  final String? inviteCode;
  final int playerLevel;
  final bool player1Ready;
  final bool player2Ready;
  final DateTime? duelStartAt;
  final int player1Score;
  final int player2Score;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DuelSession({
    required this.id,
    required this.player1Id,
    this.player2Id,
    required this.gameType,
    required this.status,
    this.inviteCode,
    this.playerLevel = 1,
    this.player1Ready = false,
    this.player2Ready = false,
    this.duelStartAt,
    this.player1Score = 0,
    this.player2Score = 0,
    this.winnerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DuelSession.fromMap(Map<String, dynamic> map) {
    return DuelSession(
      id: map['id'] as String,
      player1Id: map['player1_id'] as String,
      player2Id: map['player2_id'] as String?,
      gameType: map['game_type'] as String? ?? 'speed_match',
      status: map['status'] as String? ?? 'pending',
      inviteCode: map['invite_code'] as String?,
      playerLevel: (map['player_level'] as num?)?.toInt() ?? 1,
      player1Ready: map['player1_ready'] as bool? ?? false,
      player2Ready: map['player2_ready'] as bool? ?? false,
      duelStartAt: map['duel_start_at'] != null
          ? DateTime.tryParse(map['duel_start_at'].toString())
          : null,
      player1Score: (map['player1_score'] as num?)?.toInt() ?? 0,
      player2Score: (map['player2_score'] as num?)?.toInt() ?? 0,
      winnerId: map['winner_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// The game seed derived from duel_start_at for fairness.
  int get gameSeed =>
      duelStartAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

  bool get isBothReady => player1Ready && player2Ready;

  bool get isComplete => status == 'complete';

  /// Returns the opponent's ID given the current user.
  String? opponentId(String currentUserId) {
    if (currentUserId == player1Id) return player2Id;
    if (currentUserId == player2Id) return player1Id;
    return null;
  }

  /// Returns the current user's score.
  int myScore(String currentUserId) {
    if (currentUserId == player1Id) return player1Score;
    return player2Score;
  }

  /// Returns the opponent's score.
  int opponentScore(String currentUserId) {
    if (currentUserId == player1Id) return player2Score;
    return player1Score;
  }
}
