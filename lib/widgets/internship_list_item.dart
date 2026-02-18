import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/internship_model.dart';
import '../services/internship_service.dart';

class InternshipListWidget extends StatefulWidget {
  const InternshipListWidget({super.key});

  @override
  State<InternshipListWidget> createState() => _InternshipListWidgetState();
}

class _InternshipListWidgetState extends State<InternshipListWidget> {
  final InternshipService _service = InternshipService();
  late Future<List<Internship>> _internshipFuture;

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  void _loadInternships() {
    _internshipFuture = _service.fetchInternships().then((details) {
      return details.map((d) => Internship(
        id: d.opportunityId,
        title: d.title,
        organization: d.company,
        location: d.location,
        link: d.link,
        deadline: d.deadline,
        stipend: d.stipend.toString(),
        mode: d.empType,
      )).toList();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadInternships();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Internship>>(
        future: _internshipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
                   const SizedBox(height: 16),
                   Text('Error: ${snapshot.error}'),
                   TextButton(onPressed: _refresh, child: const Text("Retry"))
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No internships found."));
          }

          final internships = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              return InternshipListCard(internship: internships[index]);
            },
          );
        },
      ),
    );
  }
}

class InternshipListCard extends StatelessWidget {
  final Internship internship;
  const InternshipListCard({super.key, required this.internship});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(internship.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Closing Soon Logic
    final daysLeft = internship.deadline.difference(DateTime.now()).inDays;
    final isClosingSoon = daysLeft >= 0 && daysLeft <= 3;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    internship.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isClosingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      "Closing Soon",
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              internship.organization,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 12),
            
            // Details Row
            Row(
              children: [
                _buildInfoChip(Icons.location_on_outlined, internship.location),
                const SizedBox(width: 8),
                if (internship.mode != null)
                   _buildInfoChip(Icons.work_outline, internship.mode!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                 if (internship.stipend != null)
                  _buildInfoChip(Icons.attach_money, internship.stipend!),
                 const SizedBox(width: 8),
                 if (internship.duration != null)
                  _buildInfoChip(Icons.access_time, internship.duration!),
              ],
            ),
             const SizedBox(height: 16),

             // Footer: Deadline & Apply
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   "Deadline: ${_formatDate(internship.deadline)}",
                   style: const TextStyle(fontSize: 12, color: Colors.grey),
                 ),
                 ElevatedButton(
                   onPressed: _launchURL,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).primaryColor,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                   ),
                   child: const Text("Apply Now"),
                 )
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
