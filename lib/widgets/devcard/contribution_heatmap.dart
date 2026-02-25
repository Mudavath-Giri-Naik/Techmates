import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class ContributionHeatmap extends StatelessWidget {
  final List<ContributionDay> days;

  const ContributionHeatmap({super.key, required this.days});

  static const _levelColors = [
    Color(0xFF161B22), // 0
    Color(0xFF0E4429), // 1
    Color(0xFF006D32), // 2
    Color(0xFF26A641), // 3
    Color(0xFF39D353), // 4
  ];

  @override
  Widget build(BuildContext context) {
    // Pad to multiple of 7
    final padded = List<ContributionDay>.from(days);
    while (padded.length % 7 != 0) {
      padded.insert(0, ContributionDay(date: '', count: 0, level: 0));
    }
    final weekCount = padded.length ~/ 7;
    final totalContribs = days.fold<int>(0, (s, d) => s + d.count);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTRIBUTIONS',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalContribs contributions this year',
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weekCount, (w) {
                return Column(
                  children: List.generate(7, (d) {
                    final idx = w * 7 + d;
                    final level =
                        idx < padded.length ? padded[idx].level : 0;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: _levelColors[level.clamp(0, 4)],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less',
                  style: TextStyle(color: Color(0xFF8B949E), fontSize: 10)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _levelColors[i],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
              const SizedBox(width: 4),
              const Text('More',
                  style: TextStyle(color: Color(0xFF8B949E), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
