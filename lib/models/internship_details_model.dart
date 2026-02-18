class InternshipDetailsModel {
  final String opportunityId;
  final String title;
  final String company;
  final String description;
  final String duration;
  final String location;
  final DateTime deadline;
  final String empType; // mode
  final int stipend;
  final List<String> tags;
  final String eligibility;
  final String link;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int? typeSerialNo; // New field
  final String? source;
  final bool isElite;

  InternshipDetailsModel({
    required this.opportunityId,
    required this.title,
    required this.company,
    required this.description,
    required this.duration,
    required this.location,
    required this.deadline,
    required this.empType,
    required this.stipend,
    required this.tags,
    required this.eligibility,
    required this.link,

    required this.createdAt,
    required this.updatedAt,
    this.typeSerialNo,
    this.source,
    this.isElite = true,
  });

  factory InternshipDetailsModel.fromJson(Map<String, dynamic> json) {
    // Handle nested structure if fetched from parent 'opportunities' table
    Map<String, dynamic> data = json;
    if (json.containsKey('internship_details') && json['internship_details'] != null) {
      if (json['internship_details'] is List && (json['internship_details'] as List).isNotEmpty) {
        data = json['internship_details'][0];
      } else if (json['internship_details'] is Map) {
        data = json['internship_details'];
      }
      // Merge parent fields if needed, but usually we just want details + serial
    }

    final serial = json['type_serial_no'];
    if (serial != null) {
        print("🔍 [InternshipModel] Found serial: $serial (Type: ${serial.runtimeType}) for ${json['title'] ?? data['title']}");
    } else {
        print("⚠️ [InternshipModel] No serial found in JSON keys: ${json.keys.toList()}");
    }

    return InternshipDetailsModel(
      opportunityId: (data['opportunity_id'] ?? data['id'] ?? json['id']).toString(),
      title: data['title'] as String,
      company: (data['company'] ?? data['organization'] ?? 'Unknown').toString(),
      description: data['description'] as String? ?? '',
      duration: data['duration'] as String? ?? 'N/A', 
      location: data['location'] as String,
      deadline: DateTime.tryParse(data['deadline'].toString())?.toLocal() ?? DateTime.now(),
      empType: data['emp_type'] as String? ?? data['mode'] as String? ?? 'Full-time',
      stipend: data['stipend'] is int 
          ? data['stipend'] 
          : int.tryParse(data['stipend'].toString()) ?? 0,
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      eligibility: data['eligibility'] as String? ?? '',
      link: data['link'] as String,
      createdAt: DateTime.tryParse((data['created_at'] ?? json['created_at']).toString())?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? data['updated_at']).toString())?.toLocal() ?? DateTime.tryParse((data['created_at'] ?? json['created_at']).toString())?.toLocal() ?? DateTime.now(),
      typeSerialNo: int.tryParse(json['type_serial_no']?.toString() ?? '') ?? (json['type_serial_no'] is int ? json['type_serial_no'] : null), // Safer parsing
      source: json['source'] as String?,
      isElite: _parseEliteFlag(data['is_elite']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunity_id': opportunityId,
      'title': title,
      'company': company,
      'description': description,
      'duration': duration,
      'location': location,
      'deadline': deadline.toIso8601String(),
      'emp_type': empType,
      'stipend': stipend,
      'tags': tags,
      'eligibility': eligibility,
      'link': link,

      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'type_serial_no': typeSerialNo,
      'source': source,
      'is_elite': isElite,
    };
  }
  
  // Helper to convert to Opportunity if absolutely needed for migration, 
  // but User said "DO NOT return Opportunity" from services.
  // We'll keep it commented or remove it.
  
  // Getters for compatibility if needed (e.g. id)
  String get id => opportunityId;

  static bool _parseEliteFlag(dynamic raw) {
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return true;
  }
}
