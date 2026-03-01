import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_theme.dart';

/// Section 3 — "⚡ Closing Soon" deadline watchlist.
class ClosingSoonSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback? onSeeAll;

  const ClosingSoonSection({
    super.key,
    required this.items,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚡ Closing Soon',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: HomeTheme.onSurface(context),
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeTheme.primary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal scroll
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _buildDeadlineCard(context, items[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineCard(BuildContext context, Map<String, dynamic> item) {
    final type = (item['type'] as String?) ?? 'event';
    final title = (item['title'] as String?) ?? 'Untitled';
    final company = (item['company'] as String?) ?? '';
    final deadlineStr = (item['deadline'] ?? '').toString();
    final deadline = DateTime.tryParse(deadlineStr);

    // Calculate days using date-only comparison (ignore time)
    int daysLeft = 0;
    if (deadline != null) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final deadlineDate =
          DateTime(deadline.year, deadline.month, deadline.day);
      daysLeft = deadlineDate.difference(todayDate).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }
    final isUrgent = daysLeft <= 3;

    // Type chip colors
    final chipBg = HomeTheme.typeChipBg(context, type);
    final chipText = HomeTheme.typeChipText(context, type);
    final chipLabel = type.toUpperCase();

    // Countdown colors
    final countdownCols = HomeTheme.countdownColors(context, daysLeft);
    final countdownBg = countdownCols.bg;
    final countdownText = countdownCols.text;

    return Container(
      width: 180,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : HomeTheme.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              chipLabel,
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: chipText,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HomeTheme.onSurface(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Company
          Text(
            company,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: HomeTheme.onSurfaceVariant(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Countdown chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: countdownBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 11, color: countdownText),
                const SizedBox(width: 4),
                Text(
                  daysLeft == 0 ? 'Today' : '$daysLeft days left',
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: countdownText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
