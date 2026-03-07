import '../utils/proxy_url.dart';

/// Follow status for a user relationship.
enum FollowStatus {
  none,
  pending,
  following,
  self;

  /// Parse a string (from the database) into a [FollowStatus].
  static FollowStatus fromString(String? s) {
    switch (s) {
      case 'accepted':
        return FollowStatus.following;
      case 'pending':
        return FollowStatus.pending;
      case 'self':
        return FollowStatus.self;
      default:
        return FollowStatus.none;
    }
  }

  /// Human-readable label for the follow button.
  String get label {
    switch (this) {
      case FollowStatus.none:
        return 'Follow';
      case FollowStatus.pending:
        return 'Requested';
      case FollowStatus.following:
        return 'Following';
      case FollowStatus.self:
        return '';
    }
  }
}

/// Represents an incoming follow request from another user.
class FollowRequestModel {
  final String followId;
  final String followerId;
  final String? name;
  final String? avatarUrl;
  final String? college;
  final String? branch;
  final String? year;
  final DateTime? createdAt;

  FollowRequestModel({
    required this.followId,
    required this.followerId,
    this.name,
    this.avatarUrl,
    this.college,
    this.branch,
    this.year,
    this.createdAt,
  });

  factory FollowRequestModel.fromJson(Map<String, dynamic> json) {
    return FollowRequestModel(
      followId: json['follow_id'] as String,
      followerId: json['follower_id'] as String,
      name: (json['full_name'] ?? json['name']) as String?,
      avatarUrl: proxyUrl(json['avatar_url'] as String?),
      college: (json['college_name'] ?? json['college']) as String?,
      branch: json['branch'] as String?,
      year: json['year'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
    );
  }
}

/// Represents a user in a followers/following list.
class FollowUserItem {
  final String id;
  final String? name;
  final String? branch;
  final String? year;
  final String? avatarUrl;
  final String? college;
  final bool isPrivate;
  final FollowStatus followStatus;

  const FollowUserItem({
    required this.id,
    this.name,
    this.branch,
    this.year,
    this.avatarUrl,
    this.college,
    required this.isPrivate,
    required this.followStatus,
  });

  factory FollowUserItem.fromJson(Map<String, dynamic> json) {
    // handle both 'follow_back_status' (followers list) and 'follow_status' (following list)
    final statusStr =
        (json['follow_back_status'] ?? json['follow_status']) as String?;
    return FollowUserItem(
      id: json['id'] as String,
      name: (json['full_name'] ?? json['name']) as String?,
      branch: json['branch'] as String?,
      year: json['year'] as String?,
      avatarUrl: proxyUrl(json['avatar_url'] as String?),
      college: (json['college_name'] ?? json['college']) as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      followStatus: FollowStatus.fromString(statusStr),
    );
  }

  String get displayName => name ?? 'Unknown';
}
