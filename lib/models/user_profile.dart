class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? college;
  final String? branch;
  final String? year;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? instagramUrl;

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
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      college: json['college'] as String?,
      branch: json['branch'] as String?,
      year: json['year'] as String?,
      avatarUrl: json['avatar_url'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'college': college,
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
    };
  }

  UserProfile copyWith({
    String? name,
    String? college,
    String? branch,
    String? year,
    String? avatarUrl,
    String? role,
    bool? isActive,
    String? linkedinUrl,
    String? githubUrl,
    String? instagramUrl,
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
    );
  }
}
