
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hackathon_details_model.dart';
import 'package:intl/intl.dart';
import '../services/bookmark_service.dart';
import '../utils/opportunity_options_sheet.dart';

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
  static const Color _midnightBlue = Color(0xFF30364F);
  static const Color _dustyBlue = Color(0xFF0B2D72);
  static const Color _ivory = Color(0xFFFFF4EA);
  static const Color _deepNavy = Color(0xFF0F1A2B);
  static const Color _buttercream = Color(0xFFD1CFC9);
  static const Color _reddish = Color(0xFF0258F7);
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
    // Re-check in build
    _isSaved = _bookmarkService.isBookmarked(widget.hackathon.opportunityId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(widget.hackathon.deadline.year, widget.hackathon.deadline.month, widget.hackathon.deadline.day);
    final daysLeft = deadlineDate.difference(today).inDays;
    
    // Logic for urgency
    String timeLeftText = "";
    Color timeLeftColor = const Color(0xFF00897B);
    
    if (daysLeft < 0) {
      timeLeftText = "Closed";
      timeLeftColor = Colors.grey;
    } else if (daysLeft == 0) {
      timeLeftText = "Ends Today";
      timeLeftColor = const Color(0xFFE53935);
    } else {
      timeLeftText = "$daysLeft days left";
      if (daysLeft <= 5) {
        timeLeftColor = const Color(0xFFE53935);
      } else if (daysLeft <= 15) {
        timeLeftColor = const Color(0xFFF9A825);
      } else {
        timeLeftColor = const Color(0xFF00897B);
      }
    }

    final formattedDeadline = DateFormat('MMM d, y').format(widget.hackathon.deadline);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: widget.isHighlighted
              ? _midnightBlue
              : Colors.grey.shade300,
          width: widget.isHighlighted ? 2.0 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Top Row: Company (left) + Serial # (right) + Admin ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company name — left side, allows 2 lines
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business_outlined, size: 14, color: _dustyBlue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.hackathon.company,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _midnightBlue,
                              letterSpacing: 0.3,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Admin menu (left of serial#)
                  if (widget.onEdit != null && widget.onDelete != null) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 20, color: _dustyBlue),
                        onPressed: () => showOpportunityOptions(
                          context,
                          onEdit: widget.onEdit!,
                          onDelete: widget.onDelete!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Serial number badge (right-aligned)
                  if (widget.serialNumber != null || widget.hackathon.typeSerialNo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        "#${widget.serialNumber ?? widget.hackathon.typeSerialNo}",
                        style: const TextStyle(
                          color: _deepNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Location (left) + Days Left (right) — parallel ──
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Location fills left side
                  Expanded(
                    child: (widget.hackathon.location.isNotEmpty && widget.hackathon.location != 'N/A')
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 13, color: _dustyBlue),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.hackathon.location,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _reddish,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  // Days left badge (right-aligned)
                  if (daysLeft >= 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 11, color: timeLeftColor),
                        const SizedBox(width: 3),
                        Text(
                          timeLeftText,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: timeLeftColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (daysLeft < 0)
                    const Text(
                      "Closed",
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),

              // ── Prizes (above title) ──
              if (widget.hackathon.prizes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: _buildMetaPill(Icons.emoji_events_outlined, widget.hackathon.prizes, iconColor: _midnightBlue),
                ),
              ],

              // ── Hero Title (centered, auto-sizing, 2 lines) ──
              if (widget.hackathon.startDate != null && widget.hackathon.endDate != null) ...[
                 const SizedBox(height: 6),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.calendar_today_outlined, size: 12, color: _dustyBlue),
                     const SizedBox(width: 4),
                     Text(
                       DateFormat('MMM d').format(widget.hackathon.startDate!),
                       style: const TextStyle(fontSize: 11, color: _deepNavy, fontWeight: FontWeight.w500),
                     ),
                     const Padding(
                       padding: EdgeInsets.symmetric(horizontal: 4),
                       child: Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey),
                     ),
                     Text(
                        // Check if same year
                        widget.hackathon.startDate!.year == widget.hackathon.endDate!.year 
                          ? DateFormat('MMM d').format(widget.hackathon.endDate!)
                          : DateFormat('MMM d, y').format(widget.hackathon.endDate!),
                       style: const TextStyle(fontSize: 11, color: _deepNavy, fontWeight: FontWeight.w500),
                     ),
                   ],
                 ),
              ],
              const SizedBox(height: 2),
              SizedBox(
                height: 50, // enough for 2 lines at fontSize 22 with height 1.25
                child: Center(
                  child: Text(
                    widget.hackathon.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: _titleFontSize(widget.hackathon.title),
                      fontWeight: FontWeight.w800,
                      color: _deepNavy,
                      letterSpacing: 0.5,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // ── Team Size + Rounds (below title, centered) ──
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (widget.hackathon.teamSize.isNotEmpty && widget.hackathon.teamSize != 'N/A')
                      _buildMetaPill(Icons.group_outlined, "Team: ${widget.hackathon.teamSize}"),
                    if (widget.hackathon.rounds > 0)
                      _buildMetaPill(Icons.layers_outlined, "${widget.hackathon.rounds} Rounds"),
                  ],
                ),
              ),

              // ── Deadline (true center) + Bookmark (right overlay) ──
              const SizedBox(height: 8),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Deadline — truly centered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: _dustyBlue),
                      const SizedBox(width: 5),
                      Text(
                        "Deadline: $formattedDeadline",
                        style: const TextStyle(
                          fontSize: 12,
                          color: _midnightBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Bookmark — positioned at right
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: _toggleBookmark,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _ivory,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _dustyBlue.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                          color: _isSaved ? _midnightBlue : _dustyBlue,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── APPLY NOW Button (full width) ──
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _launchURL,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: _deepNavy,
                        boxShadow: [
                          BoxShadow(
                            color: _deepNavy.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "APPLY NOW",
                          style: TextStyle(
                            color: _buttercream,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dynamically compute title font size based on title length
  double _titleFontSize(String title) {
    final len = title.length;
    if (len <= 20) return 22;
    if (len <= 35) return 18;
    if (len <= 50) return 15;
    return 13;
  }

  /// Clean pill for meta info (team size, prize, etc.)
  Widget _buildMetaPill(IconData icon, String text, {Color? iconColor}) {
    if (text.isEmpty || text == 'N/A') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _ivory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _dustyBlue.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? _midnightBlue),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: _midnightBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
