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
  final DateTime updatedAt;
  final DateTime? startDate;

  final DateTime? endDate;
  final int? typeSerialNo; // New field
  final String? source;

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
    required this.updatedAt,
    this.startDate,

    this.endDate,
    this.typeSerialNo,
    this.source,
  });

  factory HackathonDetailsModel.fromJson(Map<String, dynamic> json) {
    // Handle nested structure from parent fetch
    Map<String, dynamic> data = json;
    if (json.containsKey('hackathon_details') && json['hackathon_details'] != null) {
       if (json['hackathon_details'] is List && (json['hackathon_details'] as List).isNotEmpty) {
        data = json['hackathon_details'][0];
       } else if (json['hackathon_details'] is Map) {
        data = json['hackathon_details'];
       }
    }

    final serial = json['type_serial_no'];
    if (serial != null) {
        print("🔍 [HackathonModel] Found serial: $serial (Type: ${serial.runtimeType}) for ${json['title'] ?? data['title']}");
    }

    print("🕑 [DEBUG] HackathonModel: Title='${data['title']}' DeadlineStr='${data['deadline']}' -> P='${DateTime.tryParse(data['deadline'].toString())}' -> L='${DateTime.tryParse(data['deadline'].toString())?.toLocal()}'");
    
    return HackathonDetailsModel(
      opportunityId: (data['opportunity_id'] ?? data['id'] ?? json['id']).toString(),
      title: data['title'] as String,
      company: data['company'] as String,
      teamSize: data['team_size'] as String? ?? 'N/A',
      location: data['location'] as String? ?? 'Remote',
      description: data['description'] as String? ?? '',
      eligibility: data['eligibility'] as String? ?? '',
      rounds: data['rounds'] is int 
          ? data['rounds'] 
          : int.tryParse(data['rounds'].toString()) ?? 1,
      prizes: data['prizes'] as String? ?? '',
      deadline: DateTime.tryParse(data['deadline'].toString())?.toLocal() ?? DateTime.now(),
      link: data['link'] as String,
      createdAt: DateTime.tryParse((data['created_at'] ?? json['created_at']).toString())?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? data['updated_at']).toString())?.toLocal() ?? DateTime.tryParse((data['created_at'] ?? json['created_at']).toString())?.toLocal() ?? DateTime.now(),
      startDate: data['start_date'] != null ? DateTime.tryParse(data['start_date'].toString())?.toLocal() : null,
      endDate: data['end_date'] != null ? DateTime.tryParse(data['end_date'].toString())?.toLocal() : null,
      typeSerialNo: int.tryParse(json['type_serial_no']?.toString() ?? '') ?? (json['type_serial_no'] is int ? json['type_serial_no'] : null),
      source: json['source'] as String?,
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
      'updated_at': updatedAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'type_serial_no': typeSerialNo,
      'source': source,
    };
  }
}
