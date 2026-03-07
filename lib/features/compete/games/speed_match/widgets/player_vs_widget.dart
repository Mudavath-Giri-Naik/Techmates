import 'package:flutter/material.dart';

/// Duel header: two player avatars with live scores.
class PlayerVsWidget extends StatelessWidget {
  final Map<String, dynamic>? player1Profile;
  final Map<String, dynamic>? player2Profile;
  final int player1Score;
  final int player2Score;
  final String currentUserId;

  const PlayerVsWidget({
    super.key,
    this.player1Profile,
    this.player2Profile,
    this.player1Score = 0,
    this.player2Score = 0,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final p1Name = _firstName(player1Profile?['full_name'] as String?);
    final p2Name = _firstName(player2Profile?['full_name'] as String?);
    final p1Leading = player1Score >= player2Score;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Player 1
          _playerChip(p1Name, player1Profile, player1Score, p1Leading),
          const Spacer(),
          // Score bar
          _scoreBar(player1Score, player2Score),
          const Spacer(),
          // Player 2
          _playerChip(p2Name, player2Profile, player2Score, !p1Leading),
        ],
      ),
    );
  }

  Widget _playerChip(
      String name, Map<String, dynamic>? profile, int score, bool leading) {
    final avatarUrl = profile?['avatar_url'] as String?;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: leading
                  ? const Color(0xFF00B4D8)
                  : Colors.white.withOpacity(0.3),
              width: leading ? 2 : 1,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(name))
                : _initials(name),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: leading ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: score),
              duration: const Duration(milliseconds: 400),
              builder: (_, val, __) => Text(
                _formatScore(val),
                style: TextStyle(
                  color: leading
                      ? const Color(0xFF00B4D8)
                      : Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scoreBar(int s1, int s2) {
    final total = s1 + s2;
    final ratio = total == 0 ? 0.5 : s1 / total;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratio * 100).round(),
                    child: Container(color: const Color(0xFF00B4D8)),
                  ),
                  Expanded(
                    flex: ((1 - ratio) * 100).round(),
                    child: Container(
                        color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials(String name) {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _firstName(String? name) {
    if (name == null || name.isEmpty) return '???';
    return name.split(' ').first;
  }

  String _formatScore(int s) {
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(1)}k';
    return s.toString();
  }
}
