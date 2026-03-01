import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hackathon_details_model.dart';
import 'package:intl/intl.dart';
import '../services/bookmark_service.dart';
import '../utils/opportunity_options_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Card Theme (Replaced with Theme.of)
// ─────────────────────────────────────────────────────────────

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
    
    final colorScheme = Theme.of(context).colorScheme;

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
      timeLeftColor = colorScheme.onSurfaceVariant;
      timeLeftBg    = colorScheme.surfaceContainerHighest;
    } else if (daysLeft == 0) {
      timeLeftText  = "Ends Today";
      timeLeftColor = colorScheme.error;
      timeLeftBg    = colorScheme.errorContainer;
    } else if (daysLeft <= 5) {
      timeLeftText  = "$daysLeft days left";
      timeLeftColor = colorScheme.error;
      timeLeftBg    = colorScheme.errorContainer;
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
    final hasPrize    = widget.hackathon.prizes.isNotEmpty;
    final hasLocation = widget.hackathon.location.isNotEmpty &&
        widget.hackathon.location != 'N/A';

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : colorScheme.surface,
        border: Border.all(
          color: widget.isHighlighted ? colorScheme.primary : colorScheme.outlineVariant,
          width: widget.isHighlighted ? 1.6 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ══════════════════════════════════════════════════
              //  TOP SECTION
              // ══════════════════════════════════════════════════

              // ── Row 1: Company | serial # | ⋮ ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 13, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.hackathon.company,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.serialNumber != null ||
                      widget.hackathon.typeSerialNo != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      "#${widget.serialNumber ?? widget.hackathon.typeSerialNo}",
                      style: TextStyle(
                        color: colorScheme.primary,
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
                        icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurfaceVariant),
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

              const SizedBox(height: 8),

              // ── Row 2: Location + Prize (left)  |  Deadline + Days (right) ──
              //    Prize pill is parallel to the days-left pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // LEFT column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasLocation)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 11, color: colorScheme.primary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.hackathon.location,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        // Spacing mirrors the deadline text height so pills align
                        SizedBox(height: hasLocation ? 5 : 0),
                        if (hasPrize)
                          _Pill(
                            icon: Icons.emoji_events_outlined,
                            text: widget.hackathon.prizes,
                            iconColor: colorScheme.primary,
                            textColor: colorScheme.primary,
                            bg: colorScheme.primaryContainer,
                            // ── CHANGE 1: no border on prize pill ──
                            border: Colors.transparent,
                          )
                        else
                          // Empty box keeps row height stable when no prize
                          const SizedBox(height: 22),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // RIGHT column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_outlined,
                              size: 11, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            formattedDeadline,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _TimePill(
                        text: timeLeftText,
                        color: timeLeftColor,
                        bg: timeLeftBg,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 11),

              // ── Divider ──────────────────────────────────────────
              Divider(height: 1, thickness: 0.8, color: colorScheme.outlineVariant),

              const SizedBox(height: 12),

              // ══════════════════════════════════════════════════
              //  BOTTOM SECTION
              // ══════════════════════════════════════════════════

              // ── Centered Title ───────────────────────────────────
              Center(
                child: Text(
                  widget.hackathon.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _titleFontSize(widget.hackathon.title),
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Apply (left edge)  |  Bookmark (right edge) ─────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ApplyButton(
                    onTap: _launchURL,
                    textColor: colorScheme.onSurface,
                  ),
                  GestureDetector(
                    onTap: _toggleBookmark,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _isSaved
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSaved
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      child: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                        size: 16,
                        color: _isSaved ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _titleFontSize(String title) {
    final len = title.length;
    if (len <= 20) return 17;
    if (len <= 35) return 15;
    if (len <= 50) return 13.5;
    return 12;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        // ── CHANGE 1 applied here: border uses passed color (transparent) ──
        border: Border.all(color: border, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
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
  final Color textColor;

  const _ApplyButton({
    required this.onTap,
    required this.textColor,
  });

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _down = true),
      onTapUp:     (_) => setState(() => _down = false),
      onTapCancel: ()  => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            // ── CHANGE 2: always transparent background, no border ──
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Apply Now",
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_outward_rounded,
                size: 12,
                color: widget.textColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}