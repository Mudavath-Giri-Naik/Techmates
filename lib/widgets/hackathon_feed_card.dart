import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hackathon_details_model.dart';
import '../models/opportunity_feed_item.dart';
import 'internship_feed_card.dart';

class HackathonFeedCard extends StatelessWidget {
  final OpportunityFeedItem opportunity;

  const HackathonFeedCard({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final hackathon = opportunity.hackathon;
    if (hackathon == null) {
      return const SizedBox.shrink();
    }

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    const lightBg = Color(0xFFF5F2EB);
    const lightText = Color(0xFF111110);
    const lightMuted = Color(0xFF666666);
    const lightSubtle = Color(0xFFAAAAAA);
    const lightBorder = Color(0x1F000000);
    const lightPillBg = Color(0x0F000000);
    const lightPillText = Color(0xFF222222);
    const lightTopBar = Color(0xFF111110);
    const lightApplyBg = Color(0xFF111110);
    const lightApplyFg = Colors.white;
    const lightSaveFg = Color(0xFF555555);

    const darkBg = Color(0xFF111110);
    const darkText = Color(0xFFF0EDE6);
    const darkMuted = Color(0x66FFFFFF);
    const darkSubtle = Color(0x4DFFFFFF);
    const darkBorder = Color(0x1AFFFFFF);
    const darkPillBg = Color(0x12FFFFFF);
    const darkPillText = Color(0xFFE8E8E0);
    const darkTopBar = Color(0xFF1E1E1C);
    const darkApplyBg = Color(0xFFF0EDE6);
    const darkApplyFg = Color(0xFF111110);
    const darkSaveFg = Color(0x80FFFFFF);

    final colors = (
      bg: isDark ? darkBg : lightBg,
      text: isDark ? darkText : lightText,
      muted: isDark ? darkMuted : lightMuted,
      subtle: isDark ? darkSubtle : lightSubtle,
      border: isDark ? darkBorder : lightBorder,
      pillBg: isDark ? darkPillBg : lightPillBg,
      pillText: isDark ? darkPillText : lightPillText,
      topBar: isDark ? darkTopBar : lightTopBar,
      applyBg: isDark ? darkApplyBg : lightApplyBg,
      applyFg: isDark ? darkApplyFg : lightApplyFg,
      saveFg: isDark ? darkSaveFg : lightSaveFg,
    );

    final orgName = _orgName(hackathon);
    final location = _location(hackathon);
    final prize = _prize(hackathon);
    final daysLeft = _daysLeft(hackathon.deadline);
    final deadlineShort = DateFormat('MMM d').format(hackathon.deadline);
    final venueShort = _venueShort(location);
    final postedAtFormatted = DateFormat(
      'MMM d, yyyy',
    ).format(opportunity.createdAt);
    final applyLink =
        opportunity.applyLink ?? opportunity.postLink ?? hackathon.link;
    final rank = (hackathon.typeSerialNo ?? 1).toString();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.zero,
      ).copyWith(color: colors.bg),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                lineColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.055),
                spacing: 30,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(
                isDark: isDark,
                rank: rank,
                isElite: opportunity.isElite,
                isOpen: daysLeft > 0,
                topBarColor: colors.topBar,
              ),
              _buildBody(
                isDark: isDark,
                orgName: orgName,
                location: location,
                prize: prize,
                textColor: colors.text,
                mutedColor: colors.muted,
                borderColor: colors.border,
                pillBgColor: colors.pillBg,
                pillTextColor: colors.pillText,
              ),
              _buildStatsRow(
                isDark: isDark,
                isOpen: daysLeft > 0,
                deadlineShort: deadlineShort,
                daysLeft: daysLeft,
                venueShort: venueShort,
                borderColor: colors.border,
                subtleColor: colors.subtle,
                textColor: colors.text,
              ),
              _buildBottomRow(
                context: context,
                isDark: isDark,
                daysLeft: daysLeft,
                postedAtFormatted: postedAtFormatted,
                applyLink: applyLink,
                borderColor: colors.border,
                subtleColor: colors.subtle,
                textColor: colors.text,
                saveColor: colors.saveFg,
                applyBgColor: colors.applyBg,
                applyFgColor: colors.applyFg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _orgName(HackathonDetailsModel hackathon) {
    if (hackathon.company.trim().isNotEmpty) {
      return hackathon.company;
    }
    return opportunity.posterName ?? opportunity.posterUsername ?? 'TechMates';
  }

  String _location(HackathonDetailsModel hackathon) {
    final location = hackathon.location.trim();
    return location.isNotEmpty ? location : 'India';
  }

  String _prize(HackathonDetailsModel hackathon) {
    final prizes = hackathon.prizes.trim();
    return prizes.isNotEmpty ? prizes : '-';
  }

  int _daysLeft(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = deadlineDate.difference(today).inDays;
    return diff > 0 ? diff : 0;
  }

  String _venueShort(String location) {
    final parts = location
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final firstWord = parts.isNotEmpty ? parts.first : location;
    if (firstWord.length <= 10) {
      return firstWord;
    }
    return firstWord.substring(0, 10);
  }

  Widget _buildTopBar({
    required bool isDark,
    required String rank,
    required bool isElite,
    required bool isOpen,
    required Color topBarColor,
  }) {
    return Container(
      height: 44,
      color: topBarColor,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'HACKATHON',
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  letterSpacing: 2.0,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#$rank',
                style: GoogleFonts.archivoBlack(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          _buildTopRightPill(isElite: isElite, isOpen: isOpen, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildTopRightPill({
    required bool isElite,
    required bool isOpen,
    required bool isDark,
  }) {
    if (isElite) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 9, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'ELITE',
              style: GoogleFonts.dmMono(
                fontSize: 8,
                letterSpacing: 1.4,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: GoogleFonts.dmMono(
          fontSize: 8,
          letterSpacing: 1.2,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required String orgName,
    required String location,
    required String prize,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color pillBgColor,
    required Color pillTextColor,
  }) {
    final title = opportunity.title;
    final titleLength = title.length;
    final titleSize = titleLength > 28
        ? 26.0
        : titleLength > 18
        ? 30.0
        : 34.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildOrgBlock(
                  orgName: orgName,
                  location: location,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              _buildPrizePill(
                prize: prize,
                borderColor: borderColor,
                pillBgColor: pillBgColor,
                pillTextColor: pillTextColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.archivoBlack(
              fontSize: titleSize,
              height: 1.0,
              letterSpacing: -0.01,
              color: textColor,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOrgBlock({
    required String orgName,
    required String location,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          orgName,
          style: GoogleFonts.archivoBlack(
            fontSize: 11,
            letterSpacing: 0.04,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 11, color: mutedColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                location,
                style: GoogleFonts.archivo(
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  color: mutedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrizePill({
    required String prize,
    required Color borderColor,
    required Color pillBgColor,
    required Color pillTextColor,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: pillBgColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 11, color: pillTextColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                prize,
                style: GoogleFonts.archivo(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: pillTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required bool isDark,
    required bool isOpen,
    required String deadlineShort,
    required int daysLeft,
    required String venueShort,
    required Color borderColor,
    required Color subtleColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _statBlock(
                label: 'DEADLINE',
                value: deadlineShort,
                subtleColor: subtleColor,
                textColor: textColor,
                isFirst: true,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: borderColor),
            Expanded(
              child: _statBlock(
                label: 'STATUS',
                value: isOpen ? 'Open' : 'Closed',
                subtleColor: subtleColor,
                textColor: textColor,
                valueColor: isOpen
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: borderColor),
            Expanded(
              child: _statBlock(
                label: isOpen ? 'DAYS LEFT' : 'VENUE',
                value: isOpen ? daysLeft.toString() : venueShort,
                subtleColor: subtleColor,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock({
    required String label,
    required String value,
    required Color subtleColor,
    required Color textColor,
    Color? valueColor,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isFirst ? 0 : 14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmMono(
              fontSize: 7.5,
              letterSpacing: 1.6,
              color: subtleColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.archivoBlack(
              fontSize: 13,
              height: 1.1,
              color: valueColor ?? textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow({
    required BuildContext context,
    required bool isDark,
    required int daysLeft,
    required String postedAtFormatted,
    required String applyLink,
    required Color borderColor,
    required Color subtleColor,
    required Color textColor,
    required Color saveColor,
    required Color applyBgColor,
    required Color applyFgColor,
  }) {
    final isClosed = daysLeft <= 0;
    final hasApplyLink = applyLink.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POSTED',
                style: GoogleFonts.dmMono(
                  fontSize: 7.5,
                  letterSpacing: 1.6,
                  color: subtleColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                postedAtFormatted,
                style: GoogleFonts.archivoBlack(fontSize: 14, color: textColor),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bookmark_border,
                    size: 15,
                    color: saveColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isClosed || !hasApplyLink
                    ? null
                    : () async {
                        final uri = Uri.tryParse(applyLink);
                        if (uri != null) {
                          await launchUrl(uri);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isClosed
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06))
                        : applyBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isClosed ? 'Closed' : 'Apply Now',
                        style: GoogleFonts.archivoBlack(
                          fontSize: 12,
                          letterSpacing: 0.04,
                          color: isClosed
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.25))
                              : applyFgColor,
                        ),
                      ),
                      if (!isClosed) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.north_east, size: 13, color: applyFgColor),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
