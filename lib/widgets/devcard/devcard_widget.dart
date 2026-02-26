import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';
import 'header_section.dart';
import 'stats_section.dart';
import 'languages_section.dart';
import 'streak_section.dart';
import 'commits_section.dart';
import 'projects_section.dart';

class DevCardWidget extends StatelessWidget {
  final DevCardModel devCard;
  final bool isDark;
  final String? userName;
  final String? college;
  final String? branch;
  final String? year;
  final VoidCallback? onReport;
  final VoidCallback? onShare;

  const DevCardWidget({
    super.key,
    required this.devCard,
    required this.isDark,
    this.userName,
    this.college,
    this.branch,
    this.year,
    this.onReport,
    this.onShare,
  });

  Color get _cardBg => isDark ? const Color(0xFF0D1120) : Colors.white;
  Color get _text2 => isDark ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);
  Color get _borderCol => isDark ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cardBg,
      child: Column(
        children: [
          // Section 1 — Header
          HeaderSection(
            devCard: devCard,
            isDark: isDark,
            userName: userName,
            college: college,
            branch: branch,
            year: year,
          ),
          _divider(),

          // Section 2 — Stats
          StatsSection(devCard: devCard, isDark: isDark),
          _divider(),

          // Section 3 — Languages
          LanguagesSection(
              languages: devCard.topLanguages,
              projects: devCard.projects,
              isDark: isDark),
          _divider(),

          // Section 4 — Streak & Calendar
          StreakSection(devCard: devCard, isDark: isDark),
          _divider(),

          // Section 5 — Recent Commits
          CommitsSection(
              commits: devCard.recentCommits,
              frameworks: devCard.topFrameworks.map((f) => f.name).toList(),
              projects: devCard.projects,
              isDark: isDark),
          _divider(),

          // Section 6 — Projects
          ProjectsSection(devCard: devCard, isDark: isDark, onReport: onReport),
          _divider(),

          // Section 7 — Footer
          _footer(),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: _borderCol);
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _cardBg,
      child: Row(
        children: [
          // Brand
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'DIC',
                        style: TextStyle(
                            color: const Color(0xFF00D4FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace')),
                    TextSpan(
                        text: ' · IN',
                        style: TextStyle(
                            color: _text2,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace')),
                  ]),
                ),
                const SizedBox(height: 2),
                Text(
                  '${devCard.userId.substring(0, 8)} · ${_formatDate(devCard.lastFetchedAt)}',
                  style: TextStyle(
                      color: _text2, fontSize: 8, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          // Report button
          if (onReport != null)
            OutlinedButton(
              onPressed: onReport,
              style: OutlinedButton.styleFrom(
                foregroundColor: _text2,
                side: BorderSide(color: _borderCol),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Report'),
            ),
          const SizedBox(width: 8),
          // Share button
          if (onShare != null)
            ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.north_east, size: 12),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF0D1120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
