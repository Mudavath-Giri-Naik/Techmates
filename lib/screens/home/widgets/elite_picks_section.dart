import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../services/bookmark_service.dart';
import '../home_theme.dart';

/// Section 4 — Elite Picks with pulsing badge, bookmark toggle, tags.
class ElitePicksSection extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const ElitePicksSection({super.key, required this.items});

  @override
  State<ElitePicksSection> createState() => _ElitePicksSectionState();
}

class _ElitePicksSectionState extends State<ElitePicksSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  final _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Elite Picks',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.onSurface(context),
                ),
              ),
              // ★ FEATURED badge with pulse
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final scale = 1.0 + 0.08 * _pulseCtrl.value;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: HomeTheme.primaryContainer(context), // Light background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('★',
                              style: TextStyle(
                                  color: HomeTheme.onPrimaryContainer(context), fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            'FEATURED',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HomeTheme.onPrimaryContainer(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cards
          ...widget.items.asMap().entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildEliteCard(entry.value, context, entry.key),
                  ))
              ,
        ],
      ),
    );
  }

  Widget _buildEliteCard(Map<String, dynamic> item, BuildContext context, int index) {
    final opportunityId = (item['opportunity_id'] ?? '').toString();
    final company = (item['company'] as String?) ?? '';
    final title = (item['title'] as String?) ?? '';
    final stipend = item['stipend'];
    final deadlineStr = (item['deadline'] ?? '').toString();
    final deadline = DateTime.tryParse(deadlineStr);
    final empType = (item['emp_type'] as String?) ?? '';
    final duration = (item['duration'] as String?) ?? '';
    final rawTags = item['tags'];
    final isBookmarked = _bookmarkService.isBookmarked(opportunityId);

    // Dynamic background color based on index
    final List<Color> bgColors = [
      HomeTheme.accentBlue,
      HomeTheme.accentGreen,
      HomeTheme.accentOrange,
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
    ];
    final Color baseColor = bgColors[index % bgColors.length];
    final Color dynamicBgColor = baseColor.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08);

    // Format stipend
    String stipendText = 'Stipend N/A';
    if (stipend != null && stipend is num && stipend > 0) {
      try {
        stipendText =
            '₹${NumberFormat('#,##,###').format(stipend)} / month';
      } catch (_) {
        stipendText = '₹$stipend / month';
      }
    }

    // Format deadline
    String deadlineText = '';
    if (deadline != null) {
      try {
        deadlineText = 'Closes ${DateFormat('MMM d').format(deadline)}';
      } catch (_) {
        deadlineText = 'Closes $deadlineStr';
      }
    }

    // Build tags list
    final tagsList = <String>[];
    if (empType.isNotEmpty) tagsList.add(empType);
    if (duration.isNotEmpty) tagsList.add(duration);
    if (rawTags != null && rawTags is List) {
      for (final t in rawTags.take(2)) {
        final s = t?.toString() ?? '';
        if (s.isNotEmpty) tagsList.add(s);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dynamicBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: company avatar + text + bookmark
          Row(
            children: [
              // Company initial avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeTheme.primaryContainer(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    company.isNotEmpty ? company[0].toUpperCase() : '?',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HomeTheme.onPrimaryContainer(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: HomeTheme.onSurfaceVariant(context),
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.onSurface(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Bookmark button
              GestureDetector(
                onTap: () {
                  _bookmarkService.toggleBookmarkById(opportunityId);
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isBookmarked
                        ? HomeTheme.primaryContainer(context)
                        : HomeTheme.surfaceContainer(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: isBookmarked
                        ? HomeTheme.primary(context)
                        : HomeTheme.onSurfaceVariant(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tags row
          if (tagsList.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tagsList.map((tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HomeTheme.surfaceContainer(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: HomeTheme.onSurfaceVariant(context),
                  ),
                ),
              )).toList(),
            ),
          const SizedBox(height: 12),
          // Footer: stipend + deadline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stipendText,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.accentGreen,
                ),
              ),
              if (deadlineText.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 13, color: HomeTheme.onSurfaceVariant(context)),
                    const SizedBox(width: 4),
                    Text(
                      deadlineText,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: HomeTheme.onSurfaceVariant(context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
