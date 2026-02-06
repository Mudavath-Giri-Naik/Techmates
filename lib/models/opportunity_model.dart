class Opportunity {
  final String id;
  final String type; // internship, hackathon, etc.
  final String title;
  final String organization;
  final String location;
  final String link;
  final DateTime deadline;
  final DateTime createdAt; // Added for caching logic
  
  // Optional Details (from joins)
  final String? stipend;
  final String? duration;
  final String? mode;
  final String? eligibility;

  Opportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.organization,
    required this.location,
    required this.link,
    required this.deadline,
    required this.createdAt,
    this.stipend,
    this.duration,
    this.mode,
    this.eligibility,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    // Determine type
    final type = json['type'] as String? ?? 'event';
    
    // Check for nested details
    // We try to find details in any of the potential joined tables
    var details = json['internship_details'];
    if (details == null || (details is List && details.isEmpty)) {
      details = json['hackathon_details'];
    }
    if (details == null || (details is List && details.isEmpty)) {
      details = json['event_details'];
    }

    Map<String, dynamic>? detailMap;
    
    if (details is List && details.isNotEmpty) {
      detailMap = details.first; 
    } else if (details is Map<String, dynamic>) {
      detailMap = details;
    }

    // Parse Deadline safely
    DateTime? parsedDeadline;
    if (json['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(json['deadline']);
    }
    if (parsedDeadline == null && detailMap != null && detailMap['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(detailMap['deadline']);
    }

    // Parse CreatedAt safely
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at']);
    }

    return Opportunity(
      id: json['id'].toString(),
      type: type,
      title: json['title'] ?? 'Untitled Opportunity',
      organization: json['organization'] ?? 'Unknown Org',
      location: json['location'] ?? 'Remote',
      link: json['link'] ?? '',
      deadline: parsedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      createdAt: parsedCreatedAt ?? DateTime.now(), // Fallback if missing
      // Map generic fields, checking for common variants (e.g. prize_pool for hackathons)
      stipend: detailMap?['stipend']?.toString() ?? detailMap?['prize_pool']?.toString(),
      duration: detailMap?['duration']?.toString(),
      mode: detailMap?['mode']?.toString(),
      eligibility: detailMap?['eligibility']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'organization': organization,
      'location': location,
      'link': link,
      'deadline': deadline.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      // We flatten the details for local cache storage to simplify
      // OR we can reconstruct the nested structure if we want to reuse fromJson exactly.
      // Let's reconstruct the nested structure to keep consistent with fromJson logic
      // which expects 'internship_details' to exist for extracting details.
      'internship_details': [
        {
          'stipend': stipend,
          'duration': duration,
          'mode': mode,
          'eligibility': eligibility,
          'deadline': deadline.toIso8601String(), // Valid to duplicate
        }
      ]
    };
  }
}
