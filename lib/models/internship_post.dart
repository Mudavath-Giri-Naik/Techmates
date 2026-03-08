import 'internship_details_model.dart';

/// Data model for the 5-slide internship carousel card.
///
/// Maps fields from `internship_details` joined with `opportunities`.
/// All text, numbers, dates, and tags are injected — nothing is hardcoded.
class InternshipPost {
  final String opportunityId;
  final String title;
  final String company;
  final String? description;
  final String? location;
  final DateTime deadline;
  final String? empType;
  final int? stipend; // rupees per month
  final List<String>? tags;
  final String? eligibility;
  final String link;
  final DateTime createdAt;
  final String? duration;
  final DateTime? opensOn;
  final bool isElite;
  final String status; // e.g. "Open", "Closed"

  InternshipPost({
    required this.opportunityId,
    required this.title,
    required this.company,
    this.description,
    this.location,
    required this.deadline,
    this.empType,
    this.stipend,
    this.tags,
    this.eligibility,
    required this.link,
    required this.createdAt,
    this.duration,
    this.opensOn,
    this.isElite = false,
    this.status = 'Open',
  });

  /// Computed: number of days until deadline.
  int get daysLeft {
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Build from a raw JSON map (internship_details joined with opportunities).
  factory InternshipPost.fromJson(Map<String, dynamic> json) {
    // Handle nested join structure
    Map<String, dynamic> data = json;
    if (json.containsKey('internship_details') &&
        json['internship_details'] != null) {
      if (json['internship_details'] is List &&
          (json['internship_details'] as List).isNotEmpty) {
        data = json['internship_details'][0];
      } else if (json['internship_details'] is Map) {
        data = json['internship_details'] as Map<String, dynamic>;
      }
    }

    final deadlineDt =
        DateTime.tryParse(data['deadline']?.toString() ?? '')?.toLocal() ??
            DateTime.now().add(const Duration(days: 30));

    final now = DateTime.now();
    final isOpen = deadlineDt.isAfter(now);

    return InternshipPost(
      opportunityId:
          (data['opportunity_id'] ?? data['id'] ?? json['id']).toString(),
      title: (data['title'] ?? json['title'] ?? 'Untitled').toString(),
      company:
          (data['company'] ?? data['organization'] ?? json['organization'] ?? 'Unknown')
              .toString(),
      description: data['description'] as String?,
      location: data['location'] as String?,
      deadline: deadlineDt,
      empType: data['emp_type'] as String? ?? data['mode'] as String?,
      stipend: data['stipend'] is int
          ? data['stipend']
          : int.tryParse(data['stipend']?.toString() ?? ''),
      tags: (data['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      eligibility: data['eligibility'] as String?,
      link: (data['link'] ?? json['link'] ?? '').toString(),
      createdAt: DateTime.tryParse(
                  (data['created_at'] ?? json['created_at'])?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      duration: data['duration'] as String?,
      opensOn: data['opens_on'] != null
          ? DateTime.tryParse(data['opens_on'].toString())?.toLocal()
          : null,
      isElite: _parseBool(data['is_elite']),
      status: isOpen ? 'Open' : 'Closed',
    );
  }

  /// Convenience: build from an existing [InternshipDetailsModel].
  factory InternshipPost.fromDetailsModel(
    InternshipDetailsModel m, {
    String? posterLink,
  }) {
    final now = DateTime.now();
    final isOpen = m.deadline.isAfter(now);
    return InternshipPost(
      opportunityId: m.opportunityId,
      title: m.title,
      company: m.company,
      description: m.description.isNotEmpty ? m.description : null,
      location: m.location.isNotEmpty ? m.location : null,
      deadline: m.deadline,
      empType: m.empType,
      stipend: m.stipend > 0 ? m.stipend : null,
      tags: m.tags.isNotEmpty ? m.tags : null,
      eligibility: m.eligibility.isNotEmpty ? m.eligibility : null,
      link: posterLink ?? m.link,
      createdAt: m.createdAt,
      duration: m.duration != 'N/A' ? m.duration : null,
      opensOn: null,
      isElite: m.isElite,
      status: isOpen ? 'Open' : 'Closed',
    );
  }

  static bool _parseBool(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }
}
