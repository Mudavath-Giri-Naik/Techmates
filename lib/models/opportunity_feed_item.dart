import '../models/hackathon_details_model.dart';
import '../models/internship_details_model.dart';
import '../models/event_details_model.dart';

/// The type of opportunity in the feed.
enum OpportunityType { hackathon, internship, event }

/// A single item in the home feed, wrapping the typed detail model with
/// poster profile info and metadata.
class OpportunityFeedItem {
  /// The raw opportunity row id.
  final String opportunityId;

  /// Which kind of card to render.
  final OpportunityType type;

  /// Exactly one of these is non-null, matching [type].
  final HackathonDetailsModel? hackathon;
  final InternshipDetailsModel? internship;
  final EventDetailsModel? event;

  /// Whether this opportunity is flagged as elite.
  final bool isElite;

  /// When the opportunity was created (for time-ago display).
  final DateTime createdAt;

  // ── Poster profile ──────────────────────────────────────────
  final String? posterUserId;
  final String? posterName;
  final String? posterUsername;
  final String? posterAvatarUrl;

  final String? posterRole;

  /// Added profile fields
  final String? posterCollege;
  final String? posterBranch;
  final String? posterStudyYear;

  /// The apply / post links for the story viewer.
  final String? postLink;
  final String? applyLink;

  /// The opportunity title (convenience accessor).
  String get title {
    if (hackathon != null) return hackathon!.title;
    if (internship != null) return internship!.title;
    if (event != null) return event!.title;
    return 'Untitled';
  }

  OpportunityFeedItem({
    required this.opportunityId,
    required this.type,
    this.hackathon,
    this.internship,
    this.event,
    this.isElite = false,
    required this.createdAt,
    this.posterUserId,
    this.posterName,
    this.posterUsername,
    this.posterAvatarUrl,
    this.posterRole,
    this.posterCollege,
    this.posterBranch,
    this.posterStudyYear,
    this.postLink,
    this.applyLink,
  });

  /// Serialize to JSON for local caching.
  Map<String, dynamic> toJson() {
    return {
      'opportunityId': opportunityId,
      'type': type.name,
      'hackathon': hackathon?.toJson(),
      'internship': internship?.toJson(),
      'event': event?.toJson(),
      'isElite': isElite,
      'createdAt': createdAt.toIso8601String(),
      'posterUserId': posterUserId,
      'posterName': posterName,
      'posterUsername': posterUsername,
      'posterAvatarUrl': posterAvatarUrl,
      'posterRole': posterRole,
      'posterCollege': posterCollege,
      'posterBranch': posterBranch,
      'posterStudyYear': posterStudyYear,
      'postLink': postLink,
      'applyLink': applyLink,
    };
  }

  /// Deserialize from cached JSON.
  factory OpportunityFeedItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'hackathon';
    final type = OpportunityType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => OpportunityType.hackathon,
    );

    return OpportunityFeedItem(
      opportunityId: json['opportunityId'] as String? ?? '',
      type: type,
      hackathon: json['hackathon'] != null
          ? HackathonDetailsModel.fromJson(
              json['hackathon'] as Map<String, dynamic>)
          : null,
      internship: json['internship'] != null
          ? InternshipDetailsModel.fromJson(
              json['internship'] as Map<String, dynamic>)
          : null,
      event: json['event'] != null
          ? EventDetailsModel.fromJson(
              json['event'] as Map<String, dynamic>)
          : null,
      isElite: json['isElite'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      posterUserId: json['posterUserId'] as String?,
      posterName: json['posterName'] as String?,
      posterUsername: json['posterUsername'] as String?,
      posterAvatarUrl: json['posterAvatarUrl'] as String?,
      posterRole: json['posterRole'] as String?,
      posterCollege: json['posterCollege'] as String?,
      posterBranch: json['posterBranch'] as String?,
      posterStudyYear: json['posterStudyYear'] as String?,
      postLink: json['postLink'] as String?,
      applyLink: json['applyLink'] as String?,
    );
  }
}
