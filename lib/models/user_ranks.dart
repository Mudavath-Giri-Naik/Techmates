/// User rank data from `user_ranks` table.
class UserRanks {
  final String userId;
  final int classRank;
  final int deptRank;
  final int collegeRank;
  final int classTotal;
  final int deptTotal;
  final int collegeTotal;

  const UserRanks({
    required this.userId,
    this.classRank = 0,
    this.deptRank = 0,
    this.collegeRank = 0,
    this.classTotal = 0,
    this.deptTotal = 0,
    this.collegeTotal = 0,
  });

  factory UserRanks.fromJson(Map<String, dynamic> json) {
    return UserRanks(
      userId: json['user_id'] as String? ?? '',
      classRank: (json['class_rank'] as num?)?.toInt() ?? 0,
      deptRank: (json['dept_rank'] as num?)?.toInt() ?? 0,
      collegeRank: (json['college_rank'] as num?)?.toInt() ?? 0,
      classTotal: (json['class_total'] as num?)?.toInt() ?? 0,
      deptTotal: (json['dept_total'] as num?)?.toInt() ?? 0,
      collegeTotal: (json['college_total'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = UserRanks(userId: '');
}
