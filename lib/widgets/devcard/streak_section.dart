import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';

class StreakSection extends StatelessWidget {
  final DevCardModel devCard;
  final bool isDark;

  const StreakSection(
      {super.key, required this.devCard, required this.isDark});

  Color get _cardBg => isDark ? const Color(0xFF0D1120) : Colors.white;
  Color get _boxBg => isDark ? const Color(0xFF141E2F) : const Color(0xFFF9FAFB);
  Color get _text1 => isDark ? const Color(0xFFEDF2FF) : const Color(0xFF1A1A2E);
  Color get _text2 => isDark ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);
  Color get _borderCol => isDark ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);

  static const _calColors = [
    Color(0xFF161B22), // 0
    Color(0xFF0E4429), // 1
    Color(0xFF006D32), // 2
    Color(0xFF26A641), // 3
    Color(0xFF39D353), // 4
  ];
  static const _calColorsLight = [
    Color(0xFFEBEDF0),
    Color(0xFF9BE9A8),
    Color(0xFF40C463),
    Color(0xFF30A14E),
    Color(0xFF216E39),
  ];

  @override
  Widget build(BuildContext context) {
    // Use all available heatmap data (full year)
    final allDays = List<ContributionDay>.from(devCard.heatmapData);
    // Pad to full weeks (multiple of 7)
    while (allDays.length % 7 != 0) {
      allDays.insert(0, ContributionDay(date: '', count: 0, level: 0));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-year scrollable calendar (7 rows × ~52 columns)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Start scrolled to the right (most recent)
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildWeeks(allDays),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(List<ContributionDay> days) {
    final colors = isDark ? _calColors : _calColorsLight;
    final weeks = <List<ContributionDay>>[];
    for (int i = 0; i < days.length; i += 7) {
      final end = (i + 7 > days.length) ? days.length : i + 7;
      weeks.add(days.sublist(i, end));
    }
    return weeks.map((week) {
      return Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Column(
          children: week.map((day) {
            final lvl = day.level.clamp(0, 4);
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: colors[lvl],
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}
