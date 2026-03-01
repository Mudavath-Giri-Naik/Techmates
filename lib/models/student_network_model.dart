import 'follow_model.dart';
import '../utils/proxy_url.dart';

/// Represents a student as seen in the Network feature.
/// Parsed from the `get_college_students` RPC response.
class StudentNetworkModel {
  final String id;
  final String? name;
  final String? branch;
  final String? year;
  final String? avatarUrl;
  final String? college;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? instagramUrl;
  final bool collegeVerified;
  final bool isPrivate;
  final int githubScore;
  final FollowStatus followStatus;
  final int followerCount;
  final int followingCount;

  StudentNetworkModel({
    required this.id,
    this.name,
    this.branch,
    this.year,
    this.avatarUrl,
    this.college,
    this.githubUrl,
    this.linkedinUrl,
    this.instagramUrl,
    this.collegeVerified = false,
    this.isPrivate = false,
    this.githubScore = 0,
    this.followStatus = FollowStatus.none,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory StudentNetworkModel.fromJson(Map<String, dynamic> json) {
    return StudentNetworkModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      branch: json['branch'] as String?,
      year: json['year'] as String?,
      avatarUrl: proxyUrl(json['avatar_url'] as String?),
      college: json['college'] as String?,
      githubUrl: json['github_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      collegeVerified: json['college_verified'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      githubScore: (json['github_score'] as num?)?.toInt() ?? 0,
      followStatus:
          FollowStatus.fromString(json['follow_status'] as String?),
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Computed helpers ──────────────────────────────────────────────────

  bool get isAlumni => year?.toLowerCase() == 'alumni';

  String get yearTabLabel {
    if (year == null || year!.isEmpty) return 'Other';
    final y = year!.trim().toLowerCase();

    // Match numeric: '1', '2', '3', '4'
    // Match ordinal: '1st', '2nd', '3rd', '4th'
    // Match full: '1st year', '2nd year', etc.
    // Match word: 'first', 'second', 'third', 'fourth'
    if (y == '1' || y == '1st' || y == '1st year' || y == 'first' || y == 'first year') {
      return '1st Year';
    }
    if (y == '2' || y == '2nd' || y == '2nd year' || y == 'second' || y == 'second year') {
      return '2nd Year';
    }
    if (y == '3' || y == '3rd' || y == '3rd year' || y == 'third' || y == 'third year') {
      return '3rd Year';
    }
    if (y == '4' || y == '4th' || y == '4th year' || y == 'fourth' || y == 'fourth year') {
      return '4th Year';
    }
    if (y == 'alumni') return 'Alumni';
    return 'Other';
  }

  String get displayName => name ?? 'Unknown';

  /// Content is hidden when the profile is private and the viewer
  /// hasn't been accepted (and isn't the profile owner).
  bool get isContentHidden =>
      isPrivate &&
      followStatus != FollowStatus.following &&
      followStatus != FollowStatus.self;

  /// Create a copy with updated follow-related fields for optimistic UI.
  StudentNetworkModel copyWith({
    FollowStatus? followStatus,
    int? followerCount,
    int? followingCount,
  }) {
    return StudentNetworkModel(
      id: id,
      name: name,
      branch: branch,
      year: year,
      avatarUrl: avatarUrl,
      college: college,
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      instagramUrl: instagramUrl,
      collegeVerified: collegeVerified,
      isPrivate: isPrivate,
      githubScore: githubScore,
      followStatus: followStatus ?? this.followStatus,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
