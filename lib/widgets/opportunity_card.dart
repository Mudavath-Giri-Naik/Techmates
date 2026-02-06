import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/opportunity_model.dart';
import 'package:intl/intl.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final int? serialNumber;

  const OpportunityCard({
    super.key, 
    required this.opportunity,
    this.serialNumber,
  });

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(opportunity.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Color _getTagColor(String text) {
    final t = text.toLowerCase();
    if (t.contains('internship')) return Colors.blue;
    if (t.contains('hackathon')) return Colors.purple;
    if (t.contains('remote')) return Colors.green;
    if (t.contains('paid') || t.contains('stipend') || t.contains('\$') || t.contains('₹')) return Colors.orange;
    if (t.contains('urgent') || t.contains('closing')) return Colors.red;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = opportunity.deadline.difference(now);
    final daysLeft = difference.inDays;
    
    // Logic for urgency text
    String urgencyText = "";
    Color urgencyColor = Colors.grey;
    if (daysLeft < 0) {
      urgencyText = "Closed";
      urgencyColor = Colors.grey;
    } else if (daysLeft == 0) {
      urgencyText = "Ends Today";
      urgencyColor = Colors.red;
    } else {
      urgencyText = "$daysLeft days left";
      if (daysLeft <= 3) urgencyColor = Colors.red;
      else if (daysLeft <= 10) urgencyColor = Colors.orange;
      else urgencyColor = Colors.green; // or grey if far out? Users prefer "Green = Good time left" or "Green = Go"? 
      // User said: "Red or orange text... Light background tint".
      // Let's stick to Red/Orange for urgency, Blue/Grey for normal.
      if (daysLeft > 10) urgencyColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Serial Number
          if (serialNumber != null)
             Text(
               "$serialNumber. ",
               style: TextStyle(
                 color: Colors.grey[500],
                 fontSize: 14,
                 fontWeight: FontWeight.w500,
               ),
             ),
          
          const SizedBox(width: 8),

          // 2. Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Urgency
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        opportunity.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Urgency Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        urgencyText,
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),

                // Organization & Location
                Text(
                  "${opportunity.organization} • ${opportunity.location}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Explicit Deadline
                Text(
                  "Deadline: ${_formatDate(opportunity.deadline)}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800], // Darker than loc
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                // Footer: Tags + Apply Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tags
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildTag(opportunity.type),
                          if (opportunity.location.toLowerCase().contains("remote"))
                             _buildTag("Remote"),
                          if (opportunity.stipend != null && opportunity.stipend!.isNotEmpty)
                             _buildTag("Paid"),
                          if (opportunity.mode != null && opportunity.mode!.isNotEmpty)
                            _buildTag(opportunity.mode!),
                        ],
                      ),
                    ),
                    
                    // Minimal Apply Button
                    TextButton(
                      onPressed: _launchURL,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashFactory: InkRipple.splashFactory,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Apply",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    final label = text.isEmpty ? "" : "${text[0].toUpperCase()}${text.substring(1)}";
    final color = _getTagColor(label);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('d MMM yyyy').format(dt);
  }
}
