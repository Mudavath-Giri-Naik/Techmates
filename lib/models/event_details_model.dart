class EventDetailsModel {
  final String opportunityId;
  final String title;
  final String organiser;
  final String description;
  final String venue;
  final String? entryFee;
  final DateTime startDate;
  final DateTime endDate;
  final String locationLink;
  final String applyLink;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime applyDeadline;
  final int? typeSerialNo;
  final String? source;
  final String? eligible; // ── NEW ──

  EventDetailsModel({
    required this.opportunityId,
    required this.title,
    required this.organiser,
    required this.description,
    required this.venue,
    this.entryFee,
    required this.startDate,
    required this.endDate,
    required this.locationLink,
    required this.applyLink,
    required this.createdAt,
    required this.updatedAt,
    required this.applyDeadline,
    this.typeSerialNo,
    this.source,
    this.eligible, // ── NEW ──
  });

  factory EventDetailsModel.fromJson(Map<String, dynamic> json) {
    // Handle nested structure from parent fetch
    Map<String, dynamic> data = json;
    if (json.containsKey('event_details') && json['event_details'] != null) {
      if (json['event_details'] is List &&
          (json['event_details'] as List).isNotEmpty) {
        data = json['event_details'][0];
      } else if (json['event_details'] is Map) {
        data = json['event_details'];
      }
    }

    final serial = json['type_serial_no'];
    if (serial != null) {
      print(
          "🔍 [EventModel] Found serial: $serial (Type: ${serial.runtimeType}) for ${json['title'] ?? data['title']}");
    }

    return EventDetailsModel(
      opportunityId:
          (data['opportunity_id'] ?? data['id'] ?? json['id']).toString(),
      title: (data['title'] ?? '') as String,
      organiser: (data['organizer'] ?? data['organiser'] ?? '') as String,
      description: data['description'] as String? ?? '',
      venue: data['venue'] as String? ?? 'TBD',
      entryFee: data['entry_fee'] as String?,
      startDate:
          DateTime.tryParse(data['start_date'].toString())?.toLocal() ??
              DateTime.now(),
      endDate:
          DateTime.tryParse(data['end_date'].toString())?.toLocal() ??
              DateTime.now(),
      locationLink: data['location_link'] as String? ?? '',
      applyLink: data['apply_link'] as String? ?? '',
      createdAt: DateTime.tryParse(
                  (data['created_at'] ?? json['created_at']).toString())
              ?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
                  (json['updated_at'] ?? data['updated_at']).toString())
              ?.toLocal() ??
          DateTime.tryParse(
                  (data['created_at'] ?? json['created_at']).toString())
              ?.toLocal() ??
          DateTime.now(),
      applyDeadline: DateTime.tryParse(
                  (data['apply_deadline'] ?? json['deadline']).toString())
              ?.toLocal() ??
          DateTime.now().add(const Duration(days: 30)),
      typeSerialNo: int.tryParse(json['type_serial_no']?.toString() ?? '') ??
          (json['type_serial_no'] is int ? json['type_serial_no'] : null),
      source: json['source'] as String?,
      eligible: (data['eligible'] ?? json['eligible']) as String?, // ── NEW ──
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunity_id': opportunityId,
      'title': title,
      'organizer': organiser,
      'description': description,
      'venue': venue,
      'entry_fee': entryFee,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location_link': locationLink,
      'apply_link': applyLink,
      'apply_deadline': applyDeadline.toIso8601String(),
      'type_serial_no': typeSerialNo,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'eligible': eligible, // ── NEW ──
    };
  }
}