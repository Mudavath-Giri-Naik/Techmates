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
    final p1Name = player1Profile?['full_name'] as String? ?? 'Player 1';
    final p2Name = player2Profile?['full_name'] as String? ?? 'Player 2';
    
    final p1Details = _formatDetails(player1Profile);
    final p2Details = _formatDetails(player2Profile);

    final p1Leading = player1Score >= player2Score;
    final p2Leading = player2Score >= player1Score;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── PLAYER 1 (Left) ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _avatar(p1Name, player1Profile?['avatar_url'] as String?),
                    const SizedBox(width: 10),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: player1Score),
                      duration: const Duration(milliseconds: 300),
                      builder: (_, value, child) => Text(
                        _formatScore(value),
                        style: TextStyle(
                          color: p1Leading ? const Color(0xFF162033) : const Color(0xFF728096),
                          fontSize: p1Leading ? 24 : 20,
                          fontWeight: p1Leading ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p1Name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF162033),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (p1Details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    p1Details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF728096),
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // ── VS Divider ──
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
            child: Text(
              'VS',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          
          // ── PLAYER 2 (Right) ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: player2Score),
                      duration: const Duration(milliseconds: 300),
                      builder: (_, value, child) => Text(
                        _formatScore(value),
                        style: TextStyle(
                          color: p2Leading ? const Color(0xFF162033) : const Color(0xFF728096),
                          fontSize: p2Leading ? 24 : 20,
                          fontWeight: p2Leading ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _avatar(p2Name, player2Profile?['avatar_url'] as String?),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p2Name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF162033),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (p2Details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    p2Details,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF728096),
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetails(Map<String, dynamic>? profile) {
    if (profile == null) return '';
    final branch = profile['branch'];
    final year = profile['year'];
    
    // Handle the joined colleges table structure
    final colObj = profile['colleges'];
    String? colName;
    if (colObj != null && colObj is Map) {
      colName = colObj['short_name'] as String?;
    } else if (profile['college_id'] != null) {
      // In case the join didn't happen, we don't have the name, so we just skip it
      colName = null; 
    }

    final parts = <String>[];
    if (colName != null && colName.isNotEmpty) parts.add(colName);
    if (branch != null && branch.toString().isNotEmpty) parts.add(branch.toString());
    if (year != null && year.toString().isNotEmpty) parts.add('Year $year');

    return parts.join(' • ');
  }

  Widget _avatar(String name, String? avatarUrl) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7E0EC), width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(name),
              )
            : _initials(name),
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _firstName(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.split(' ').first;
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return score.toString();
  }
}
