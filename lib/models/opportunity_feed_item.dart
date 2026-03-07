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

  /// `student`, `admin`, `super_admin`, or null.
  final String? posterRole;

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
    this.postLink,
    this.applyLink,
  });
}
