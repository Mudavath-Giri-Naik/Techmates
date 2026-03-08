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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E0EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _playerChip(
              name: p1Name,
              profile: player1Profile,
              score: player1Score,
              leading: p1Leading,
              alignEnd: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFF7A879C),
                  ),
                ),
                const SizedBox(height: 8),
                _scoreBar(player1Score, player2Score),
              ],
            ),
          ),
          Expanded(
            child: _playerChip(
              name: p2Name,
              profile: player2Profile,
              score: player2Score,
              leading: !p1Leading,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerChip({
    required String name,
    required Map<String, dynamic>? profile,
    required int score,
    required bool leading,
    required bool alignEnd,
  }) {
    final avatarUrl = profile?['avatar_url'] as String?;
    final accent = leading ? const Color(0xFF3478F6) : const Color(0xFF8C99AC);

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          _avatar(name, avatarUrl, accent, leading),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF162033),
                  fontSize: 12,
                  fontWeight: leading ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: score),
                duration: const Duration(milliseconds: 400),
                builder: (_, value, child) => Text(
                  _formatScore(value),
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 8),
          _avatar(name, avatarUrl, accent, leading),
        ],
      ],
    );
  }

  Widget _avatar(String name, String? avatarUrl, Color accent, bool leading) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: leading ? accent : const Color(0xFFD7E0EC),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => _initials(name),
              )
            : _initials(name),
      ),
    );
  }

  Widget _scoreBar(int s1, int s2) {
    final total = s1 + s2;
    final ratio = total == 0 ? 0.5 : s1 / total;

    return SizedBox(
      width: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 8,
          child: Row(
            children: [
              Expanded(
                flex: (ratio * 100).round(),
                child: Container(color: const Color(0xFF3478F6)),
              ),
              Expanded(
                flex: ((1 - ratio) * 100).round(),
                child: Container(color: const Color(0xFFD7E0EC)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials(String name) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF5F6E86),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _firstName(String? name) {
    if (name == null || name.isEmpty) return '???';
    return name.split(' ').first;
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return score.toString();
  }
}
