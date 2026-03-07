/// Domain percentile / score from `domain_percentile_cache`.
class DomainScore {
  final String userId;
  final String domainId;
  final String domainKey;
  final String name;
  final double percentile;
  final int score; // percentile × 10 → 0–1000

  const DomainScore({
    required this.userId,
    required this.domainId,
    required this.domainKey,
    required this.name,
    required this.percentile,
    required this.score,
  });

  factory DomainScore.fromJson(Map<String, dynamic> json) {
    final domain = json['domains'] as Map<String, dynamic>? ?? {};
    return DomainScore(
      userId: json['user_id'] as String? ?? '',
      domainId: json['domain_id'] as String? ?? '',
      domainKey: domain['domain_key'] as String? ?? '',
      name: domain['name'] as String? ?? 'Unknown',
      percentile: (json['percentile'] as num?)?.toDouble() ?? 0,
      score: (json['domain_score'] as num?)?.toInt() ?? 0,
    );
  }
}
