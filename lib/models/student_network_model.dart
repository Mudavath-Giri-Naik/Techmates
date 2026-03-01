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
    switch (year) {
      case '1':
        return '1st Year';
      case '2':
        return '2nd Year';
      case '3':
        return '3rd Year';
      case '4':
        return '4th Year';
      default:
        if (isAlumni) return 'Alumni';
        return 'Other';
    }
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
