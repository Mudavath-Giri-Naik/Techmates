class Opportunity {
  final String id;
  final String type;
  final String title;
  final String organization; 
  final String location;
  final String link;
  final DateTime deadline;
  final DateTime createdAt;
  
  // Storage for details of other types
  final Map<String, dynamic> extraDetails;

  Opportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.organization,
    required this.location,
    required this.link,
    required this.deadline,
    required this.createdAt,
    this.extraDetails = const {},
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    // Basic fields from parent table (mostly id, type, created_at)
    // But we extract title/org/loc from details if joined
    
    // Check for nested details
    var details = json['hackathon_details'];
    if (details == null || (details is List && details.isEmpty)) {
      details = json['event_details'];
    }
    // We do NOT check internship_details here anymore

    Map<String, dynamic> detailMap = {};
    if (details is List && details.isNotEmpty) {
      detailMap = details.first; 
    } else if (details is Map<String, dynamic>) {
      detailMap = details;
    }
    
    if (json['extra_details'] != null) {
      detailMap.addAll(json['extra_details']);
    }

    // Parse Deadline
    DateTime? parsedDeadline;
    if (json['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(json['deadline']);
    }
    if (parsedDeadline == null && detailMap['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(detailMap['deadline']);
    }

    // Parse CreatedAt
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at']);
    }
    
    // Extract common fields
    final title = json['title'] ?? detailMap['title'] ?? 'Untitled';
    final org = json['organization'] ?? detailMap['organization'] ?? 'Unknown Org';
    final loc = json['location'] ?? detailMap['location'] ?? 'Remote';
    final link = json['link'] ?? detailMap['link'] ?? '';

    return Opportunity(
      id: json['id'].toString(),
      type: json['type'] ?? 'event',
      title: title,
      organization: org,
      location: loc,
      link: link,
      deadline: parsedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      createdAt: parsedCreatedAt ?? DateTime.now(),
      extraDetails: detailMap,
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
      'extra_details': extraDetails,
    };
  }
}
