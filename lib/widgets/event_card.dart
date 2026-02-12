
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_details_model.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final EventDetailsModel event;
  final int? serialNumber;

  const EventCard({
    super.key, 
    required this.event,
    this.serialNumber,
  });

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Color _getTagColor(String text) {
    if (text.contains('Free')) return Colors.green;
    if (text.contains('Paid') || text.contains('\$') || text.contains('₹')) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    // Formatting Dates
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(event.applyDeadline.year, event.applyDeadline.month, event.applyDeadline.day);
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
    
    String eventDateString = "${dateFormat.format(event.startDate)}";
    if (event.startDate.day != event.endDate.day || event.startDate.month != event.endDate.month || event.startDate.year != event.endDate.year) {
      eventDateString += " - ${dateFormat.format(event.endDate)}";
    } else {
       // Same day, maybe show time?
       eventDateString += " • ${timeFormat.format(event.startDate)}";
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
                        event.title,
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
                
                const SizedBox(height: 8),

                // Details List
                // Organiser
                if (event.organiser.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.organiser,
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
                  ),

                // Venue
                if (event.venue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.venue,
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
                  ),
                // Event Date
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        eventDateString,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                 // Entry Fee
                 Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (event.entryFee != null && event.entryFee!.isNotEmpty) ? event.entryFee! : "Free",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Footer: Deadline (Left) + Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Deadline (Bottom Left) - Consistent Style
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_filled, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy').format(event.applyDeadline),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700, // Bold
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(), // Push actions to the right

                    // Map Button
                    if (event.locationLink.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(right: 8.0),
                         child: IconButton(
                           padding: EdgeInsets.zero,
                           constraints: const BoxConstraints(),
                           icon: const Icon(Icons.map, size: 20, color: Colors.grey),
                           onPressed: () => _launchURL(event.locationLink),
                           tooltip: 'Map',
                         ),
                       ),

                    // Actions: Register
                    if (event.applyLink.isNotEmpty)
                      TextButton(
                        onPressed: () => _launchURL(event.applyLink),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          splashFactory: InkRipple.splashFactory,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Register",
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
  }}
