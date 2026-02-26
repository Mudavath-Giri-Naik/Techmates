import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';

class StatsSection extends StatelessWidget {
  final DevCardModel devCard;
  final bool isDark;

  const StatsSection({super.key, required this.devCard, required this.isDark});

  Color get _cardBg => isDark ? const Color(0xFF0D1120) : Colors.white;
  Color get _boxBg => isDark ? const Color(0xFF141E2F) : const Color(0xFFF9FAFB);
  Color get _text1 => isDark ? const Color(0xFFEDF2FF) : const Color(0xFF1A1A2E);
  Color get _text2 => isDark ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final stats = [
      _S('${devCard.totalCommitsLastYear}', 'Commits', const Color(0xFF00D4FF)),
      _S('${devCard.totalPublicRepos}', 'Repos', const Color(0xFF8B5CF6)),
      _S('${devCard.topLanguages.length}', 'Languages', const Color(0xFF22C55E)),
      _S('${devCard.topFrameworks.length}', 'Tech', const Color(0xFFF59E0B)),
      _S('${devCard.currentStreak}d', 'Streak', const Color(0xFFF43F5E)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: stats
                .map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _statBox(s),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _statBox(_S s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _boxBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(s.value,
              style: TextStyle(
                  color: _text1,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(s.label,
              style: TextStyle(
                  color: _text2,
                  fontSize: 8,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _S {
  final String value, label;
  final Color color;
  const _S(this.value, this.label, this.color);
}
