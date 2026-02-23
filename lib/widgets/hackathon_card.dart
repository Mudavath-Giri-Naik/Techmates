import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hackathon_details_model.dart';
import 'package:intl/intl.dart';
import '../services/bookmark_service.dart';
import '../utils/opportunity_options_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Card Theme
// ─────────────────────────────────────────────────────────────
class _CardTheme {
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;
  final Color companyColor;
  final Color secondaryText;
  final Color mutedText;
  final Color accentColor;
  final Color accentBg;
  final Color pillBg;
  final Color pillBorder;
  final Color pillText;
  final Color buttonBg;
  final Color buttonText;
  final bool buttonOutlined;
  final Color bookmarkActive;
  final Color topBar;

  const _CardTheme({
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
    required this.companyColor,
    required this.secondaryText,
    required this.mutedText,
    required this.accentColor,
    required this.accentBg,
    required this.pillBg,
    required this.pillBorder,
    required this.pillText,
    required this.buttonBg,
    required this.buttonText,
    required this.buttonOutlined,
    required this.bookmarkActive,
    required this.topBar,
  });
}

// Theme 1 — White & Ink
const _t1 = _CardTheme(
  cardBg:        Color(0xFFFFFFFF),
  cardBorder:    Color(0xFFE4E7EC),
  titleColor:    Color(0xFF0D1117),
  companyColor:  Color(0xFF374151),
  secondaryText: Color(0xFF6B7280),
  mutedText:     Color(0xFFB0B7C3),
  accentColor:   Color(0xFF2563EB),
  accentBg:      Color(0xFFEFF6FF),
  pillBg:        Color(0xFFF9FAFB),
  pillBorder:    Color(0xFFE4E7EC),
  pillText:      Color(0xFF374151),
  buttonBg:      Color(0xFF0D1117),
  buttonText:    Color(0xFF0D1117),
  buttonOutlined: true,
  bookmarkActive: Color(0xFF2563EB),
  topBar:        Color(0xFF2563EB),
);

// Theme 2 — Parchment & Amber
const _t2 = _CardTheme(
  cardBg:        Color(0xFFFFFCF5),
  cardBorder:    Color(0xFFEADFC9),
  titleColor:    Color(0xFF1C1506),
  companyColor:  Color(0xFF4A3418),
  secondaryText: Color(0xFF7C5E3A),
  mutedText:     Color(0xFFBEA98A),
  accentColor:   Color(0xFFB45309),
  accentBg:      Color(0xFFFFF7ED),
  pillBg:        Color(0xFFFEF3C7),
  pillBorder:    Color(0xFFF6D87A),
  pillText:      Color(0xFF4A3418),
  buttonBg:      Color(0xFF1C1506),
  buttonText:    Color(0xFF1C1506),
  buttonOutlined: true,
  bookmarkActive: Color(0xFFB45309),
  topBar:        Color(0xFFD97706),
);

// Theme 3 — Slate & Teal (outlined button)
const _t3 = _CardTheme(
  cardBg:        Color(0xFFF7FAFA),
  cardBorder:    Color(0xFFCFE1E3),
  titleColor:    Color(0xFF0C2229),
  companyColor:  Color(0xFF2D5059),
  secondaryText: Color(0xFF4A7A85),
  mutedText:     Color(0xFF92B8BE),
  accentColor:   Color(0xFF0D9488),
  accentBg:      Color(0xFFF0FDFA),
  pillBg:        Color(0xFFE6F7F6),
  pillBorder:    Color(0xFFB2E0DC),
  pillText:      Color(0xFF0C3A36),
  buttonBg:      Color(0xFF0D9488),
  buttonText:    Color(0xFF0D9488),
  buttonOutlined: true,
  bookmarkActive: Color(0xFF0D9488),
  topBar:        Color(0xFF0D9488),
);

// Theme 4 — Lavender & Violet (outlined button)
const _t4 = _CardTheme(
  cardBg:        Color(0xFFFAF9FF),
  cardBorder:    Color(0xFFDDD6FE),
  titleColor:    Color(0xFF12093A),
  companyColor:  Color(0xFF3730A3),
  secondaryText: Color(0xFF5B51A8),
  mutedText:     Color(0xFFAEA8D3),
  accentColor:   Color(0xFF5B21B6),
  accentBg:      Color(0xFFF5F3FF),
  pillBg:        Color(0xFFEDE9FE),
  pillBorder:    Color(0xFFDDD6FE),
  pillText:      Color(0xFF2E1065),
  buttonBg:      Color(0xFF5B21B6),
  buttonText:    Color(0xFF5B21B6),
  buttonOutlined: true,
  bookmarkActive: Color(0xFF5B21B6),
  topBar:        Color(0xFF7C3AED),
);

const _themes = [_t1, _t2, _t3, _t4];

// ─────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────
class HackathonCard extends StatefulWidget {
  final HackathonDetailsModel hackathon;
  final int? serialNumber;
  final bool isHighlighted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HackathonCard({
    super.key,
    required this.hackathon,
    this.serialNumber,
    this.isHighlighted = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<HackathonCard> createState() => _HackathonCardState();
}

class _HackathonCardState extends State<HackathonCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isSaved = false;

  _CardTheme get _theme {
    final idx = (widget.serialNumber ?? widget.hackathon.typeSerialNo ?? 0) % 4;
    return _themes[idx];
  }

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    setState(() {
      _isSaved = _bookmarkService.isBookmarked(widget.hackathon.opportunityId);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.hackathon);
    _checkBookmarkStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? "Saved to bookmarks" : "Removed from bookmarks"),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 200,
        ),
      );
    }
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(widget.hackathon.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isSaved = _bookmarkService.isBookmarked(widget.hackathon.opportunityId);
    final t = _theme;

    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      widget.hackathon.deadline.year,
      widget.hackathon.deadline.month,
      widget.hackathon.deadline.day,
    );
    final daysLeft = deadline.difference(today).inDays;

    final String timeLeftText;
    final Color  timeLeftColor;
    final Color  timeLeftBg;

    if (daysLeft < 0) {
      timeLeftText  = "Closed";
      timeLeftColor = const Color(0xFF9CA3AF);
      timeLeftBg    = const Color(0xFFF3F4F6);
    } else if (daysLeft == 0) {
      timeLeftText  = "Ends Today";
      timeLeftColor = const Color(0xFFDC2626);
      timeLeftBg    = const Color(0xFFFEF2F2);
    } else if (daysLeft <= 5) {
      timeLeftText  = "$daysLeft days left";
      timeLeftColor = const Color(0xFFDC2626);
      timeLeftBg    = const Color(0xFFFEF2F2);
    } else if (daysLeft <= 15) {
      timeLeftText  = "$daysLeft days left";
      timeLeftColor = const Color(0xFFD97706);
      timeLeftBg    = const Color(0xFFFFFBEB);
    } else {
      timeLeftText  = "$daysLeft days left";
      timeLeftColor = const Color(0xFF059669);
      timeLeftBg    = const Color(0xFFECFDF5);
    }

    final formattedDeadline = DateFormat('MMM d, y').format(widget.hackathon.deadline);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: t.cardBg,
        border: Border.all(
          color: widget.isHighlighted ? t.accentColor : t.cardBorder,
          width: widget.isHighlighted ? 1.6 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Row 1: Company  |  serial #  |  ⋮ ───────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 13, color: t.mutedText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.hackathon.company,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.companyColor,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.serialNumber != null || widget.hackathon.typeSerialNo != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          "#${widget.serialNumber ?? widget.hackathon.typeSerialNo}",
                          style: TextStyle(
                            color: t.accentColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (widget.onEdit != null && widget.onDelete != null) ...[
                        const SizedBox(width: 2),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_vert, size: 18, color: t.mutedText),
                            onPressed: () => showOpportunityOptions(
                              context,
                              onEdit: widget.onEdit!,
                              onDelete: widget.onDelete!,
                              title: widget.hackathon.title,
                              subtitle: widget.hackathon.company,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Row 2: Location, Deadline & Prize ──────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location & Prize
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.hackathon.location.isNotEmpty &&
                                widget.hackathon.location != 'N/A') ...[
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 11, color: t.accentColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.hackathon.location,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: t.accentColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.hackathon.prizes.isNotEmpty)
                                const SizedBox(height: 4),
                            ],
                            if (widget.hackathon.prizes.isNotEmpty)
                              Align(
                                alignment: const Alignment(0.6, 0), // Shift slightly right of center
                                child: _Pill(
                                  icon: Icons.emoji_events_outlined,
                                  text: widget.hackathon.prizes,
                                  iconColor: t.accentColor,
                                  textColor: t.accentColor,
                                  bg: t.accentBg,
                                  border: t.accentColor.withValues(alpha: 0.25),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Deadline & Days Left
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_outlined, size: 11, color: t.mutedText),
                              const SizedBox(width: 3),
                              Text(
                                formattedDeadline,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: t.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _TimePill(
                            text: timeLeftText,
                            color: timeLeftColor,
                            bg: timeLeftBg,
                          ),
                        ]
                      )
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Event date range (centered) ──────────────────
                  if (widget.hackathon.startDate != null &&
                      widget.hackathon.endDate != null) ...[
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.date_range_outlined, size: 11, color: t.mutedText),
                          const SizedBox(width: 3),
                          Text(
                            "${DateFormat('MMM d').format(widget.hackathon.startDate!)}  →  "
                            "${widget.hackathon.startDate!.year == widget.hackathon.endDate!.year ? DateFormat('MMM d').format(widget.hackathon.endDate!) : DateFormat('MMM d, y').format(widget.hackathon.endDate!)}",
                            style: TextStyle(
                              fontSize: 11,
                              color: t.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],

                  // ── Hero Title ───────────────────────────────────
                  SizedBox(
                    height: 38,
                    child: Center(
                      child: Text(
                        widget.hackathon.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _titleFontSize(widget.hackathon.title) * 0.9,
                          fontWeight: FontWeight.w800,
                          color: t.titleColor,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  // ── Team + Rounds pills ──────────────────────────
                  if ((widget.hackathon.teamSize.isNotEmpty && widget.hackathon.teamSize != 'N/A') ||
                      widget.hackathon.rounds > 0) ...[
                    const SizedBox(height: 2),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: [
                          if (widget.hackathon.teamSize.isNotEmpty &&
                              widget.hackathon.teamSize != 'N/A')
                            _Pill(
                              icon: Icons.group_outlined,
                              text: "Team: ${widget.hackathon.teamSize}",
                              iconColor: t.secondaryText,
                              textColor: t.pillText,
                              bg: t.pillBg,
                              border: t.pillBorder,
                            ),
                          if (widget.hackathon.rounds > 0)
                            _Pill(
                              icon: Icons.layers_outlined,
                              text: "${widget.hackathon.rounds} Rounds",
                              iconColor: t.secondaryText,
                              textColor: t.pillText,
                              bg: t.pillBg,
                              border: t.pillBorder,
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // ── Apply button & Bookmark ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ApplyButton(
                          onTap: _launchURL,
                          outlined: t.buttonOutlined,
                          bgColor: t.buttonBg,
                          textColor: t.buttonText,
                          borderColor: t.buttonText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSaved ? t.bookmarkActive.withValues(alpha: 0.1) : t.pillBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _isSaved ? t.bookmarkActive.withValues(alpha: 0.3) : t.cardBorder,
                            ),
                          ),
                          child: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                            size: 18,
                            color: _isSaved ? t.bookmarkActive : t.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _titleFontSize(String title) {
    final len = title.length;
    if (len <= 20) return 22;
    if (len <= 35) return 18;
    if (len <= 50) return 15;
    return 13;
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared small components
// ─────────────────────────────────────────────────────────────

class _TimePill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;

  const _TimePill({required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final Color bg;
  final Color border;

  const _Pill({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool outlined;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _ApplyButton({
    required this.onTap,
    required this.outlined,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp:   (_) => setState(() => _down = false),
      onTapCancel: ()  => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: widget.outlined ? Colors.transparent : widget.bgColor,
            borderRadius: BorderRadius.circular(9),
            border: widget.outlined
                ? Border.all(color: widget.borderColor, width: 1.3)
                : null,
            boxShadow: widget.outlined || _down
                ? null
                : [
                    BoxShadow(
                      color: widget.bgColor.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Apply Now",
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_outward_rounded,
                size: 13,
                color: widget.textColor.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}