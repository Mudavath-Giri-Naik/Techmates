
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import 'package:intl/intl.dart';
import '../services/bookmark_service.dart';

class OpportunityCard extends StatefulWidget {
  final Opportunity opportunity;
  final int? serialNumber;
  final bool isHighlighted;

  const OpportunityCard({
    super.key, 
    required this.opportunity,
    this.serialNumber,
    this.isHighlighted = false,
  });

  @override
  State<OpportunityCard> createState() => _OpportunityCardState();
}

class _OpportunityCardState extends State<OpportunityCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    setState(() {
      _isSaved = _bookmarkService.isBookmarked(widget.opportunity.id);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.opportunity);
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
    final Uri url = Uri.parse(widget.opportunity.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Color _getAccentColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('internship')) return const Color(0xFF0052CC); // Blue
    if (t.contains('hackathon')) return const Color(0xFF171717); // Black
    if (t.contains('event')) return const Color(0xFFD32F2F); // Red
    return Colors.blueGrey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    _isSaved = _bookmarkService.isBookmarked(widget.opportunity.id);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(widget.opportunity.deadline.year, widget.opportunity.deadline.month, widget.opportunity.deadline.day);
    final daysLeft = deadlineDate.difference(today).inDays;
    
    // Logic for urgency
    String timeLeftText = "";
    Color timeLeftColor = Colors.blueGrey;
    
    if (daysLeft < 0) {
      timeLeftText = "Closed";
      timeLeftColor = Colors.grey;
    } else if (daysLeft == 0) {
      timeLeftText = "Ends Today";
      timeLeftColor = Colors.red;
    } else {
      timeLeftText = "$daysLeft days left";
      if (daysLeft <= 5) timeLeftColor = Colors.red;
      else if (daysLeft <= 15) timeLeftColor = Colors.orange;
      else timeLeftColor = Colors.green; 
    }

    final accentColor = _getAccentColor(widget.opportunity.type);

    // Extract details
    String? stipend;
    String? mode;
    
    if (widget.opportunity is InternshipDetailsModel) {
      final internship = widget.opportunity as InternshipDetailsModel;
      if (internship.stipend > 0) {
        stipend = "₹ ${internship.stipend} /Month";
      }
      mode = internship.empType;
    } else {
      stipend = widget.opportunity.extraDetails['stipend']?.toString() ?? widget.opportunity.extraDetails['prize_pool']?.toString();
      mode = widget.opportunity.extraDetails['mode']?.toString();
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6FF), // Light blue background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                              height: 1.2,
                            ),
                            children: [
                               if (widget.serialNumber != null || widget.opportunity.typeSerialNo != null)
                                  TextSpan(
                                    text: "#${widget.serialNumber ?? widget.opportunity.typeSerialNo} ",
                                    style: TextStyle(color: accentColor),
                                  ),
                               TextSpan(text: widget.opportunity.title),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${widget.opportunity.organization}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Apply Button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Apply Button (Minimal Badge Style)
                      InkWell(
                        onTap: _launchURL,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.04), 
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accentColor.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "Apply",
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Meta Info (Generic Vertical List)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                     padding: const EdgeInsets.only(bottom: 8.0),
                     child: _buildMetaItem(Icons.category_outlined, widget.opportunity.type),
                  ),
                  Padding(
                     padding: const EdgeInsets.only(bottom: 8.0),
                     child: _buildMetaItem(Icons.location_on_outlined, widget.opportunity.location),
                  ),
                  if (mode != null && mode.isNotEmpty)
                     Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildMetaItem(Icons.work_outline, mode),
                     ),
                ],
              ),

              const SizedBox(height: 16),
              
              // Tags & Stipend
              Row(
                children: [
                   Expanded(
                     child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                           // Add generic tags if available or based on type
                           _buildChip(widget.opportunity.type),
                           if (widget.opportunity.location.toLowerCase().contains("remote")) _buildChip("Remote"),
                        ],
                      ),
                   ),
                   if (stipend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_outlined, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            stipend,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Footer
              Row(
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(widget.opportunity.deadline),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: timeLeftColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 12, color: timeLeftColor),
                        const SizedBox(width: 4),
                        Text(
                          timeLeftText,
                          style: TextStyle(
                            fontSize: 11, 
                            color: timeLeftColor,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Save Button (Bookmark)
                  GestureDetector(
                    onTap: _toggleBookmark,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                        key: ValueKey(_isSaved),
                        color: _isSaved ? accentColor : Colors.blueGrey.shade300,
                        size: 26,
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

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade400),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blueGrey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
