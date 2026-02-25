import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class DevRankBadge extends StatelessWidget {
  final DevScoreBreakdown breakdown;

  const DevRankBadge({super.key, required this.breakdown});

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _parseHex(breakdown.rankColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${breakdown.rankEmoji} ${breakdown.rank}',
            style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${breakdown.total}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
