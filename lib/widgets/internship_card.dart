import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/internship_details_model.dart';
import 'package:intl/intl.dart';
import '../services/bookmark_service.dart';
import '../utils/opportunity_options_sheet.dart';
import 'elite_badge.dart';

class InternshipCard extends StatefulWidget {
  final InternshipDetailsModel internship;
  final int? serialNumber;
  final bool isHighlighted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(bool)? onToggleElite;

  const InternshipCard({
    super.key,
    required this.internship,
    this.serialNumber,
    this.isHighlighted = false,
    this.onEdit,
    this.onDelete,
    this.onToggleElite,
    this.margin,
  });

  final EdgeInsetsGeometry? margin;

  @override
  State<InternshipCard> createState() => _InternshipCardState();
}

class _InternshipCardState extends State<InternshipCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isSaved = false;

  // ── Stormy Morning Palette ──
  static const Color _title = Color(0xFF384959);       // Dark navy
  static const Color _muted = Color(0xFF6A89A7);       // Steel blue
  static const Color _body = Color(0xFF4A6A85);        // Mid steel
  static const Color _blue = Color(0xFF88BDF2);        // Sky blue accent
  static const Color _chipBg = Color(0xFFE8F2FC);      // Very light blue tint
  static const Color _chipBorder = Color(0xFFBDDDFC);  // Pastel blue
  static const Color _divider = Color(0xFFD6E8F7);     // Soft pastel divider
  static const Color _red = Color(0xFFDC2626);         // Urgency red (preserved)
  static const Color _green = Color(0xFF16A34A);       // Urgency green (preserved)

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    setState(() {
      _isSaved = _bookmarkService.isBookmarked(widget.internship.opportunityId);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.internship);
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
    final Uri url = Uri.parse(widget.internship.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isSaved = _bookmarkService.isBookmarked(widget.internship.opportunityId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dl = DateTime(widget.internship.deadline.year, widget.internship.deadline.month, widget.internship.deadline.day);
    final daysLeft = dl.difference(today).inDays;

    String urgency;
    Color urgencyColor;
    if (daysLeft < 0) {
      urgency = "Closed";
      urgencyColor = _muted;
    } else if (daysLeft == 0) {
      urgency = "Ends today";
      urgencyColor = _red;
    } else if (daysLeft <= 7) {
      urgency = "$daysLeft days left";
      urgencyColor = _red;
    } else if (daysLeft <= 15) {
      urgency = "$daysLeft days left";
      urgencyColor = const Color(0xFFD97706);
    } else {
      urgency = "$daysLeft days left";
      urgencyColor = _green;
    }

    final deadline = DateFormat('MMM d, y').format(widget.internship.deadline);

    // Description items
    final List<_DescItem> descItems = [];
    if (widget.internship.eligibility.isNotEmpty && widget.internship.eligibility != 'N/A') {
      descItems.add(_DescItem(Icons.school_outlined, widget.internship.eligibility));
    }
    if (widget.internship.empType.isNotEmpty && widget.internship.empType != 'N/A') {
      descItems.add(_DescItem(Icons.schedule_outlined, widget.internship.empType));
    }
    if (widget.internship.location.isNotEmpty && widget.internship.location != 'N/A') {
      descItems.add(_DescItem(Icons.location_on_outlined, widget.internship.location));
    }

    // Chips (days left first, then stipend, duration)
    final List<Widget> chipWidgets = [];
    // Days left chip — colored, placed first (left-aligned)
    chipWidgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: urgencyColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: urgencyColor.withValues(alpha: 0.2), width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom_rounded, size: 11, color: urgencyColor),
            const SizedBox(width: 3),
            Text(urgency, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: urgencyColor)),
          ],
        ),
      ),
    );
    if (widget.internship.stipend > 0) {
      chipWidgets.add(_buildChip("₹${_fmt(widget.internship.stipend)}"));
    }
    if (widget.internship.duration.isNotEmpty && widget.internship.duration != 'N/A') {
      chipWidgets.add(_buildChip(widget.internship.duration));
    }

    final cardMargin = widget.margin ?? const EdgeInsets.only(left: 16, right: 16, bottom: 2);

    return Container(
      margin: cardMargin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isHighlighted ? _blue : const Color(0xFFBDDDFC),
              width: widget.isHighlighted ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A89A7).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            // ────────────────────────────────────────────
            // TOP ROW: #Serial + Title (left) | Admin + Bookmark (right)
            // ────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Serial (plain) + Title — inline
                Expanded(
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _title,
                        height: 1.3,
                      ),
                      children: [
                        if (widget.serialNumber != null || widget.internship.typeSerialNo != null)
                          TextSpan(
                            text: "#${widget.serialNumber ?? widget.internship.typeSerialNo} ",
                            style: const TextStyle(
                              color: Color(0xFF6A89A7),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        TextSpan(text: widget.internship.title),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Company: "by Company Name"
            if (widget.internship.company.isNotEmpty) ...[
              const SizedBox(height: 1),
              Padding(
                padding: EdgeInsets.only(
                  left: widget.internship.typeSerialNo != null ? 0 : 0,
                ),
                child: Row(
                  children: [
                    Text(
                      "by ",
                      style: TextStyle(fontSize: 12, color: _muted, fontStyle: FontStyle.italic),
                    ),
                    Flexible(
                      child: Text(
                        widget.internship.company,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2845D6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ────────────────────────────────────────────
            // DIVIDER + DESCRIPTION ITEMS
            // ────────────────────────────────────────────
            if (descItems.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(height: 0.8, color: _divider),
              const SizedBox(height: 4),
              ...descItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(item.icon, size: 14, color: _muted),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.text,
                        style: const TextStyle(fontSize: 12, color: _body, fontWeight: FontWeight.w400, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
            ],

            // ────────────────────────────────────────────
            // DIVIDER + CHIPS (stipend, duration, days left)
            // ────────────────────────────────────────────
            const SizedBox(height: 6),
            Container(height: 0.8, color: _divider),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: chipWidgets,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _isSaved ? _blue : _muted,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),

            // ────────────────────────────────────────────
            // DIVIDER + BOTTOM: Date (left) | Apply (right edge)
            // ────────────────────────────────────────────
            const SizedBox(height: 8),
            Container(height: 0.8, color: _divider),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 13, color: _muted),
                const SizedBox(width: 4),
                Text(
                  deadline,
                  style: const TextStyle(fontSize: 11.5, color: _body, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (widget.onEdit != null && widget.onDelete != null) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 20, color: _muted),
                      onPressed: () => showOpportunityOptions(
                        context,
                        onEdit: widget.onEdit!,
                        onDelete: widget.onDelete!,
                        isElite: widget.internship.isElite,
                        onToggleElite: widget.onToggleElite,
                        title: widget.internship.title,
                        subtitle: widget.internship.company,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Apply - right edge
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _launchURL,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF384959),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Apply", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_outward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ),
        if (widget.internship.isElite)
          const Positioned(
            top: 6,
            right: 6,
            child: EliteBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _chipBorder, width: 0.6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _body)),
    );
  }

  String _fmt(int n) {
    if (n >= 100000) {
      final l = n / 100000;
      return l == l.roundToDouble() ? "${l.toInt()}L" : "${l.toStringAsFixed(1)}L";
    } else if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble() ? "${k.toInt()}K" : "${k.toStringAsFixed(1)}K";
    }
    return n.toString();
  }
}

class _DescItem {
  final IconData icon;
  final String text;
  const _DescItem(this.icon, this.text);
}

