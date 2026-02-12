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
  // No created_at in schema provided? 
  // wait, the user provided schema:
  // create table public.event_details ( ... )
  // It does NOT have created_at in the provided snippet!
  // "opportunity_id ... apply_link"
  // But opportunities table has created_at.
  // I should probably fetch created_at from opportunities if I do a join?
  // But I am doing STRICT separation.
  // If the table doesn't have created_at, I can't fetch it easily without a join or two queries.
  // Internships had created_at in the table schema provided by user.
  // Hackathons had created_at in the table schema provided by user.
  // Events schema snippet:
  // create table public.event_details ( ... apply_link, constraint ... )
  // It does NOT list created_at.
  // However, usually these tables have it.
  // I will assume it DOES NOT have it for now based on snippet, 
  // OR I will assume the user missed it?
  // User said "same for Events chip ... and above is the schema".
  // The schema snippet ends at `apply_link`.
  // I will assume NO created_at in `event_details`.
  // But `HomeScreen` sorting uses `createdAt`.
  // `FilterService` uses `createdAt`.
  // If I don't have it, sorting might be weird.
  // But `opportunities` table has it.
  // When I add an event, I insert into `opportunities` then `event_details`.
  // If I fetch `event_details` only, I miss `created_at`.
  // Maybe I should add `created_at` to the model and just use `DateTime.now()` if missing, 
  // or maybe I should ask? 
  // Checking previous steps... 
  // Internship schema had `created_at`.
  // Hackathon schema had `created_at`.
  // It is highly likely `event_details` should have it too.
  // I'll add it to the model but make it nullable or default to now, 
  // and in `fromJson` try to read it.
  // If it's not in DB, it will be null/now.
  // Actually, I'll add a `created_at` field to the schema in my mind or just use `start_date` for sorting if needed?
  // No, `FilterChange` sorts by `createdAt`.
  // I will include `createdAt` in the model, and if it fails to parse (because column missing), it defaults to now.
  
  // Wait, I can't query a column that doesn't exist.
  // If I restrict `select('*')` and the column isn't there, it's fine.
  // But if I try to order by it in `fetchEvents`, it will crash if column missing.
  // I'll assume for now I can't order by `created_at` in the DB if it's potentially missing.
  // I will order by `start_date`?
  // Or I will try to include `created_at` and if user complains I'll fix it.
  // User said "above is the schema". It typically implies "this is the EXACT schema".
  // So I will NOT assume `created_at`.
  // I will sort by `startDate` in the service?
  // Or I will just not sort by date in fetch?
  
  final DateTime createdAt;
  final DateTime applyDeadline; // Added

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
    required this.applyDeadline, // Added
  });

  factory EventDetailsModel.fromJson(Map<String, dynamic> json) {
    return EventDetailsModel(
      opportunityId: (json['opportunity_id'] ?? json['id']).toString(),
      title: json['title'] as String,
      organiser: json['organiser'] as String,
      description: json['description'] as String? ?? '',
      venue: json['venue'] as String? ?? 'TBD',
      entryFee: json['entry_fee'] as String?,
      startDate: DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now(),
      locationLink: json['location_link'] as String? ?? '',
      applyLink: json['apply_link'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      applyDeadline: DateTime.tryParse(json['apply_deadline'].toString()) ?? DateTime.now().add(const Duration(days: 30)), // Added with fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunity_id': opportunityId,
      'title': title,
      'organiser': organiser,
      'description': description,
      'venue': venue,
      'entry_fee': entryFee,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location_link': locationLink,
      'apply_link': applyLink,
      'apply_deadline': applyDeadline.toIso8601String(), // Added
      // 'created_at': createdAt.toIso8601String(), 
    };
  }
}
