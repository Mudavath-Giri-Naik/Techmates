import '../utils/proxy_url.dart';

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? college;
  final String? branch;
  final int? year;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? instagramUrl;
  final String? collegeEmail;
  final String? collegeEmailDomain;
  final bool collegeVerified;
  final String? collegeId;
  final bool onboardingCompleted;
  final bool isPrivate;
  // New Stats Fields
  final int? streakDays;
  final int? longestStreak;
  final int? githubScore;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.college,
    this.branch,
    this.year,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.linkedinUrl,
    this.githubUrl,
    this.instagramUrl,
    this.collegeEmail,
    this.collegeEmailDomain,
    this.collegeVerified = false,
    this.collegeId,
    this.onboardingCompleted = false,
    this.isPrivate = false,
    this.streakDays,
    this.longestStreak,
    this.githubScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      college: json['college'] as String?,
      branch: json['branch'] as String?,
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      avatarUrl: proxyUrl(json['avatar_url'] as String?),
      role: json['role'] as String? ?? 'student',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
      linkedinUrl: json['linkedin_url'] as String?,
      githubUrl: json['github_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      collegeEmail: json['college_email'] as String?,
      collegeEmailDomain: json['college_email_domain'] as String?,
      collegeVerified: json['college_verified'] as bool? ?? false,
      collegeId: json['college_id'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      streakDays: json['streak_days'] != null ? int.tryParse(json['streak_days'].toString()) : null,
      longestStreak: json['longest_streak'] != null ? int.tryParse(json['longest_streak'].toString()) : null,
      githubScore: json['github_score'] != null ? int.tryParse(json['github_score'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'branch': branch,
      'year': year,
      'avatar_url': avatarUrl,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'linkedin_url': linkedinUrl,
      'github_url': githubUrl,
      'instagram_url': instagramUrl,
      'college_email': collegeEmail,
      'college_email_domain': collegeEmailDomain,
      'college_verified': collegeVerified,
      'college_id': collegeId,
      'onboarding_completed': onboardingCompleted,
      'is_private': isPrivate,
      'streak_days': streakDays,
      'longest_streak': longestStreak,
      'github_score': githubScore,
    };
  }

  UserProfile copyWith({
    String? name,
    String? college,
    String? branch,
    int? year,
    String? avatarUrl,
    String? role,
    bool? isActive,
    String? linkedinUrl,
    String? githubUrl,
    String? instagramUrl,
    String? collegeEmail,
    String? collegeEmailDomain,
    bool? collegeVerified,
    String? collegeId,
    bool? onboardingCompleted,
    bool? isPrivate,
    int? streakDays,
    int? longestStreak,
    int? githubScore,
  }) {
    return UserProfile(
      id: id,
      email: email,
      name: name ?? this.name,
      college: college ?? this.college,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      collegeEmail: collegeEmail ?? this.collegeEmail,
      collegeEmailDomain: collegeEmailDomain ?? this.collegeEmailDomain,
      collegeVerified: collegeVerified ?? this.collegeVerified,
      collegeId: collegeId ?? this.collegeId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isPrivate: isPrivate ?? this.isPrivate,
      streakDays: streakDays ?? this.streakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      githubScore: githubScore ?? this.githubScore,
    );
  }
}
