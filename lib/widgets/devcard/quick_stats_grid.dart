import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class QuickStatsGrid extends StatelessWidget {
  final DevCardModel devCard;

  const QuickStatsGrid({super.key, required this.devCard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _box('${devCard.totalPublicRepos}', 'repos'),
              const SizedBox(width: 8),
              _box('${devCard.totalCommitsLastYear}', 'commits this year'),
              const SizedBox(width: 8),
              _box(
                '${devCard.currentStreak}',
                'current streak',
                icon: Icons.local_fire_department_outlined,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _box(
                '${devCard.longestStreak}',
                'best streak',
                icon: Icons.emoji_events_outlined,
              ),
              const SizedBox(width: 8),
              _box('${devCard.totalStars}', 'total stars'),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box(String value, String label, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: const Color(0xFF8B949E)),
                  const SizedBox(width: 6),
                ],
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
