class InternshipDetailsModel {
  final String opportunityId;
  final String title;
  final String company;
  final String description;
  final String location;
  final DateTime deadline;
  final String empType; // mode
  final int stipend;
  final List<String> tags;
  final String eligibility;
  final String link;
  final DateTime createdAt;

  InternshipDetailsModel({
    required this.opportunityId,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.deadline,
    required this.empType,
    required this.stipend,
    required this.tags,
    required this.eligibility,
    required this.link,
    required this.createdAt,
  });

  factory InternshipDetailsModel.fromJson(Map<String, dynamic> json) {
    return InternshipDetailsModel(
      opportunityId: (json['opportunity_id'] ?? json['id']).toString(),
      title: json['title'] as String,
      company: (json['company'] ?? json['organization'] ?? 'Unknown').toString(),
      description: json['description'] as String? ?? '',
      location: json['location'] as String,
      deadline: DateTime.tryParse(json['deadline'].toString()) ?? DateTime.now(),
      empType: json['emp_type'] as String? ?? json['mode'] as String? ?? 'Full-time',
      stipend: json['stipend'] is int 
          ? json['stipend'] 
          : int.tryParse(json['stipend'].toString()) ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      eligibility: json['eligibility'] as String? ?? '',
      link: json['link'] as String,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunity_id': opportunityId,
      'title': title,
      'company': company,
      'description': description,
      'location': location,
      'deadline': deadline.toIso8601String(),
      'emp_type': empType,
      'stipend': stipend,
      'tags': tags,
      'eligibility': eligibility,
      'link': link,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  // Helper to convert to Opportunity if absolutely needed for migration, 
  // but User said "DO NOT return Opportunity" from services.
  // We'll keep it commented or remove it.
  
  // Getters for compatibility if needed (e.g. id)
  String get id => opportunityId;
}
