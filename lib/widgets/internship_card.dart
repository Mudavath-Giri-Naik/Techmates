import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/internship_details_model.dart';
import 'package:intl/intl.dart';

class InternshipCard extends StatelessWidget {
  final InternshipDetailsModel internship;
  final int? serialNumber;

  const InternshipCard({
    super.key, 
    required this.internship,
    this.serialNumber,
  });

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(internship.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Color _getTagColor(String text) {
    final t = text.toLowerCase();
    if (t.contains('internship')) return Colors.blue;
    if (t.contains('remote')) return Colors.green;
    if (t.contains('paid') || t.contains('stipend') || t.contains('\$') || t.contains('₹')) return Colors.orange;
    if (t.contains('urgent') || t.contains('closing')) return Colors.red;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(internship.deadline.year, internship.deadline.month, internship.deadline.day);
    final daysLeft = deadlineDate.difference(today).inDays;
    
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
      if (daysLeft <= 5) urgencyColor = Colors.red;
      else if (daysLeft <= 15) urgencyColor = Colors.orange; // Yellow/Orange
      else urgencyColor = Colors.green; 
    }

    String? stipendText;
    if (internship.stipend > 0) {
      stipendText = "₹${internship.stipend}";
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
                        internship.title,
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

                // Organization & Location (Icon)
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${internship.company}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        internship.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Eligibility (Icon)
                if (internship.eligibility.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.school, size: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          internship.eligibility,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),


                const SizedBox(height: 4),

                // Footer: Deadline (Left) + Tags + Apply Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // New Attractive Deadline (Bottom Left)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_filled, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(internship.deadline),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700, // Bold
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // Tags
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // "Internship" tag REMOVED as requested
                            if (internship.location.toLowerCase().contains("remote"))
                               Padding(padding: const EdgeInsets.only(right: 6), child: _buildTag("Remote")),
                            if (stipendText != null)
                               Padding(padding: const EdgeInsets.only(right: 6), child: _buildTag(stipendText)),
                            if (internship.empType.isNotEmpty)
                              _buildTag(internship.empType),
                          ],
                        ),
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
