class HackathonDetailsModel {
  final String opportunityId;
  final String title;
  final String company;
  final String teamSize;
  final String location;
  final String description;
  final String eligibility;
  final int rounds;
  final String prizes;
  final DateTime deadline;
  final String link;
  final DateTime createdAt;

  HackathonDetailsModel({
    required this.opportunityId,
    required this.title,
    required this.company,
    required this.teamSize,
    required this.location,
    required this.description,
    required this.eligibility,
    required this.rounds,
    required this.prizes,
    required this.deadline,
    required this.link,
    required this.createdAt,
  });

  factory HackathonDetailsModel.fromJson(Map<String, dynamic> json) {
    return HackathonDetailsModel(
      opportunityId: (json['opportunity_id'] ?? json['id']).toString(),
      title: json['title'] as String,
      company: json['company'] as String,
      teamSize: json['team_size'] as String? ?? 'N/A',
      location: json['location'] as String? ?? 'Remote',
      description: json['description'] as String? ?? '',
      eligibility: json['eligibility'] as String? ?? '',
      rounds: json['rounds'] is int 
          ? json['rounds'] 
          : int.tryParse(json['rounds'].toString()) ?? 1,
      prizes: json['prizes'] as String? ?? '',
      deadline: DateTime.tryParse(json['deadline'].toString()) ?? DateTime.now(),
      link: json['link'] as String,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunity_id': opportunityId,
      'title': title,
      'company': company,
      'team_size': teamSize,
      'location': location,
      'description': description,
      'eligibility': eligibility,
      'rounds': rounds,
      'prizes': prizes,
      'deadline': deadline.toIso8601String(),
      'link': link,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
