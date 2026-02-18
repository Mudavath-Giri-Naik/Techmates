import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';
import '../services/bookmark_service.dart';

class UnifiedBookmarkCard extends StatefulWidget {
  final dynamic item;
  final VoidCallback onRemove;

  const UnifiedBookmarkCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  State<UnifiedBookmarkCard> createState() => _UnifiedBookmarkCardState();
}

class _UnifiedBookmarkCardState extends State<UnifiedBookmarkCard> {
  // ── Palette ──
  static const Color _cardBg = Colors.white;
  static const Color _borderColor = Color(0xFFE5E7EB); // Gray-200
  static const Color _titleColor = Color(0xFF1F2937); // Gray-800
  static const Color _subtitleColor = Color(0xFF6B7280); // Gray-500
  // Type Colors
  static const Color _internshipColor = Color(0xFF2563EB); // Blue-600
  static const Color _hackathonColor = Color(0xFF059669); // Emerald-600
  static const Color _eventColor = Color(0xFFD97706); // Amber-600
  static const Color _defaultColor = Color(0xFF4B5563); // Gray-600

  // ── Helper Getters ──

  String get _title {
    if (widget.item is InternshipDetailsModel) return (widget.item as InternshipDetailsModel).title;
    if (widget.item is HackathonDetailsModel) return (widget.item as HackathonDetailsModel).title;
    if (widget.item is EventDetailsModel) return (widget.item as EventDetailsModel).title;
    if (widget.item is Opportunity) return (widget.item as Opportunity).title;
    return 'Unknown Opportunity';
  }

  String get _organization {
    if (widget.item is InternshipDetailsModel) return (widget.item as InternshipDetailsModel).company;
    if (widget.item is HackathonDetailsModel) return (widget.item as HackathonDetailsModel).company;
    if (widget.item is EventDetailsModel) return (widget.item as EventDetailsModel).organiser;
    if (widget.item is Opportunity) return (widget.item as Opportunity).organization;
    return '';
  }

  String get _location {
    if (widget.item is InternshipDetailsModel) return (widget.item as InternshipDetailsModel).location;
    if (widget.item is HackathonDetailsModel) return (widget.item as HackathonDetailsModel).location;
    if (widget.item is EventDetailsModel) return (widget.item as EventDetailsModel).venue;
    if (widget.item is Opportunity) return (widget.item as Opportunity).location;
    return 'N/A';
  }

  DateTime? get _deadline {
    if (widget.item is InternshipDetailsModel) return (widget.item as InternshipDetailsModel).deadline;
    if (widget.item is HackathonDetailsModel) return (widget.item as HackathonDetailsModel).deadline;
    if (widget.item is EventDetailsModel) return (widget.item as EventDetailsModel).startDate; // Use start date for events usually
    if (widget.item is Opportunity) return (widget.item as Opportunity).deadline;
    return null;
  }

  String get _link {
    if (widget.item is InternshipDetailsModel) return (widget.item as InternshipDetailsModel).link;
    if (widget.item is HackathonDetailsModel) return (widget.item as HackathonDetailsModel).link;
    if (widget.item is EventDetailsModel) return (widget.item as EventDetailsModel).applyLink; // or link?
    if (widget.item is Opportunity) return (widget.item as Opportunity).link;
    return '';
  }

  String get _typeLabel {
    if (widget.item is InternshipDetailsModel) return "INTERNSHIP";
    if (widget.item is HackathonDetailsModel) return "HACKATHON";
    if (widget.item is EventDetailsModel) return "EVENT";
    if (widget.item is Opportunity) return (widget.item as Opportunity).type.toUpperCase();
    return "OPPORTUNITY";
  }
  
  Color get _typeColor {
    if (widget.item is InternshipDetailsModel) return _internshipColor;
    if (widget.item is HackathonDetailsModel) return _hackathonColor;
    if (widget.item is EventDetailsModel) return _eventColor;
    return _defaultColor;
  }

  int? get _serialNumber {
     if (widget.item is InternshipDetailsModel) return (widget.item as InternshipDetailsModel).typeSerialNo;
     if (widget.item is HackathonDetailsModel) return (widget.item as HackathonDetailsModel).typeSerialNo;
     if (widget.item is EventDetailsModel) return (widget.item as EventDetailsModel).typeSerialNo;
     if (widget.item is Opportunity) return (widget.item as Opportunity).typeSerialNo;
     return null;
  }

  Future<void> _launchURL() async {
    final urlString = _link;
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
  
  Future<void> _removeBookmark() async {
    final service = BookmarkService();
    // Assuming dynamic item works, or we might need to cast/wrap.
    // The service takes specific types usually, or 'Opportunity'.
    // Let's check logic: service.toggleBookmark() handles checking type.
    // Use the callback to refresh UI parent as well.
    await service.toggleBookmark(widget.item);
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _deadline != null ? DateFormat('MMM d, y').format(_deadline!) : 'N/A';
    final typeColor = _typeColor;
    final sn = _serialNumber;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _launchURL,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: Type Indicator Strip ──
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // ── Center: Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Type Badge & Serial
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (sn != null) ...[
                             const SizedBox(width: 6),
                             Text(
                               "#$sn",
                               style: TextStyle(
                                 fontSize: 11,
                                 fontWeight: FontWeight.w500,
                                 color: Colors.grey.shade400,
                               ),
                             ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Title
                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Organization
                      if (_organization.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _organization,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _subtitleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 10),
                      
                      // Metadata Row
                      Row(
                        children: [
                           // Date
                           Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade400),
                           const SizedBox(width: 4),
                           Text(
                             dateStr,
                             style: TextStyle(
                               fontSize: 11.5,
                               color: Colors.grey.shade600,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const SizedBox(width: 12),
                           // Location
                           if (_location.isNotEmpty && _location != 'N/A') ...[
                             Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                             const SizedBox(width: 4),
                             Flexible(
                               child: Text(
                                 _location,
                                 style: TextStyle(
                                   fontSize: 11.5,
                                   color: Colors.grey.shade600,
                                   fontWeight: FontWeight.w500,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ── Right: Action Buttons ──
                Column(
                  children: [
                    // Bookmark (Remove)
                    InkWell(
                      onTap: _removeBookmark,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.bookmark_remove_rounded,
                          size: 20,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // External Link Icon (Apply)
                    Icon(
                       Icons.arrow_outward_rounded,
                       size: 18,
                       color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
