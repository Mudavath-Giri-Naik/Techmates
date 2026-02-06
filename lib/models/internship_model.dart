class Internship {
  final String id;
  final String title;
  final String organization;
  final String location;
  final String link;
  final DateTime deadline;
  // Details from Joined Table
  final String? stipend;
  final String? duration;
  final String? mode;

  Internship({
    required this.id,
    required this.title,
    required this.organization,
    required this.location,
    required this.link,
    required this.deadline,
    this.stipend,
    this.duration,
    this.mode,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    // Nested details might be a list or object depending on relation type (One-to-One expected)
    // Supabase joins usually return a list if One-to-Many, or object if One-to-One.
    // Assuming one-to-one or taking first if list.
    
    final details = json['internship_details'];
    Map<String, dynamic>? detailMap;
    
    if (details is List && details.isNotEmpty) {
      detailMap = details.first; 
    } else if (details is Map<String, dynamic>) {
      detailMap = details;
    }

    // Parse Deadline safely
    DateTime? parsedDeadline;
    if (detailMap != null && detailMap['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(detailMap['deadline']);
    } 
    // Fallback to Opportunity deadline if detail deadline missing
    if (parsedDeadline == null && json['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(json['deadline']);
    }

    return Internship(
      id: json['id'].toString(),
      title: json['title'] ?? 'Untitled Internship',
      organization: json['organization'] ?? 'Unknown Org',
      location: json['location'] ?? 'Remote',
      link: json['link'] ?? '',
      deadline: parsedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      stipend: detailMap?['stipend']?.toString(),
      duration: detailMap?['duration']?.toString(),
      mode: detailMap?['mode']?.toString(),
    );
  }
}
