
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_details_model.dart';
import 'package:intl/intl.dart';
import '../services/bookmark_service.dart';
import '../utils/opportunity_options_sheet.dart';

class EventCard extends StatefulWidget {
  final EventDetailsModel event;
  final int? serialNumber;
  final bool isHighlighted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.serialNumber,
    this.isHighlighted = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isSaved = false;

  // ── Indigo / Navy Palette ──
  static const Color _indigo = Color(0xFF272757);
  static const Color _lavender = Color(0xFF8686AC);
  static const Color _slate = Color(0xFF505081);
  static const Color _deepNavy = Color(0xFF0F0E47);
  static const Color _textDark = Color(0xFF1A1A3E);
  static const Color _textMuted = Color(0xFF6E6E8A);

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    setState(() {
      _isSaved = _bookmarkService.isBookmarked(widget.event.opportunityId);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.event);
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

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isSaved = _bookmarkService.isBookmarked(widget.event.opportunityId);

    // ── Date formatting ──
    final dateFormat = DateFormat('MMM d');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(
      widget.event.applyDeadline.year,
      widget.event.applyDeadline.month,
      widget.event.applyDeadline.day,
    );
    final daysLeft = deadlineDate.difference(today).inDays;

    // ── Urgency logic ──
    String timeLeftText = "";
    Color timeLeftColor = _slate;

    if (daysLeft < 0) {
      timeLeftText = "Closed";
      timeLeftColor = Colors.grey;
    } else if (daysLeft == 0) {
      timeLeftText = "TODAY!";
      timeLeftColor = const Color(0xFFE53935);
    } else {
      timeLeftText = "$daysLeft days left";
      if (daysLeft <= 5) {
        timeLeftColor = const Color(0xFFE53935);
      } else if (daysLeft <= 15) {
        timeLeftColor = const Color(0xFFE65100);
      } else {
        timeLeftColor = const Color(0xFF2E7D32);
      }
    }

    // ── Event date string ──
    String dateStr = dateFormat.format(widget.event.startDate);
    bool isMultiDay = widget.event.startDate.day != widget.event.endDate.day ||
        widget.event.startDate.month != widget.event.endDate.month ||
        widget.event.startDate.year != widget.event.endDate.year;
    if (isMultiDay) {
      dateStr += " – ${dateFormat.format(widget.event.endDate)}";
    }

    // ── Entry fee ──
    final entryFeeText = (widget.event.entryFee != null && widget.event.entryFee!.isNotEmpty)
        ? widget.event.entryFee!
        : "Free";

    // ── Registration deadline ──
    final formattedDeadline = DateFormat('MMM d, y').format(widget.event.applyDeadline);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ═════════════════════════════════════════════════
              // LEFT ACCENT STRIP — indigo gradient
              // ═════════════════════════════════════════════════
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_slate, _deepNavy],
                  ),
                ),
              ),

              // ═════════════════════════════════════════════════
              // MAIN CONTENT
              // ═════════════════════════════════════════════════
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ═══════════════════════════════════════════
                      // TOP ROW: Tag + Days Left + Admin menu
                      // ═══════════════════════════════════════════
                      Row(
                        children: [
                          // "EVENT" tag — pill with gradient
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_indigo, _deepNavy],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (widget.serialNumber != null || widget.event.typeSerialNo != null)
                                  ? "EVENT #${widget.serialNumber ?? widget.event.typeSerialNo}"
                                  : "EVENT",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Days left
                          if (daysLeft >= 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: timeLeftColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 11, color: timeLeftColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    timeLeftText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: timeLeftColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (daysLeft < 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Closed",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Admin menu
                          if (widget.onEdit != null && widget.onDelete != null) ...[
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_horiz, size: 20, color: _textMuted),
                                onPressed: () => showOpportunityOptions(
                                  context,
                                  onEdit: widget.onEdit!,
                                  onDelete: widget.onDelete!,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // ═══════════════════════════════════════════
                      // TITLE
                      // ═══════════════════════════════════════════
                      const SizedBox(height: 12),
                      Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _deepNavy,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ── Organiser ──
                      if (widget.event.organiser.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 13, color: _textMuted),
                            const SizedBox(width: 4),
                            Text(
                              "by ",
                              style: TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.event.organiser,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _slate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ═══════════════════════════════════════════
                      // DETAIL GRID — 2×2 with indigo-toned boxes
                      // ═══════════════════════════════════════════
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.calendar_today_rounded,
                              label: "WHEN",
                              value: dateStr,
                              accentColor: _slate,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.location_on_rounded,
                              label: "WHERE",
                              value: widget.event.venue.isNotEmpty ? widget.event.venue : "TBD",
                              accentColor: _indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.confirmation_number_rounded,
                              label: "ENTRY",
                              value: entryFeeText,
                              accentColor: _lavender,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.hourglass_bottom_rounded,
                              label: "REGISTER BY",
                              value: formattedDeadline,
                              accentColor: _deepNavy,
                            ),
                          ),
                        ],
                      ),

                      // ═══════════════════════════════════════════
                      // BOTTOM ROW: Register + Map + Bookmark
                      // ═══════════════════════════════════════════
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Register button — indigo gradient
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _launchURL(widget.event.applyLink),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [_indigo, _deepNavy],
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "REGISTER NOW",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Map link
                          if (widget.event.locationLink.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _launchURL(widget.event.locationLink),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _lavender.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.map_outlined, size: 18, color: _slate),
                              ),
                            ),
                          ],
                          // Bookmark
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleBookmark,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isSaved
                                    ? _indigo.withValues(alpha: 0.12)
                                    : _lavender.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                                color: _isSaved ? _indigo : _textMuted,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Detail box — used in the 2×2 grid
  Widget _buildDetailBox({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _lavender.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
