import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/devcard/devcard_model.dart';
import 'dev_rank_badge.dart';
import 'score_breakdown_card.dart';

class DevCardHeader extends StatelessWidget {
  final DevCardModel devCard;
  final String? userName;
  final String? college;
  final String? branch;
  final String? year;

  const DevCardHeader({
    super.key,
    required this.devCard,
    this.userName,
    this.college,
    this.branch,
    this.year,
  });

  @override
  Widget build(BuildContext context) {
    final infoLine = [
      if (college != null && college!.isNotEmpty) college!,
      if (branch != null && branch!.isNotEmpty) branch!,
      if (year != null && year!.isNotEmpty) year!,
    ].join(' · ');

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF30363D), width: 2),
                ),
                child: ClipOval(
                  child: devCard.githubAvatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: devCard.githubAvatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Icon(
                              Icons.person,
                              size: 32,
                              color: Color(0xFF8B949E)),
                          errorWidget: (_, _, _) => const Icon(
                              Icons.person,
                              size: 32,
                              color: Color(0xFF8B949E)),
                        )
                      : const Icon(Icons.person,
                          size: 32, color: Color(0xFF8B949E)),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? devCard.githubUsername,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${devCard.githubUsername}',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 13,
                      ),
                    ),
                    if (infoLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        infoLine,
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Rank badge
              DevRankBadge(breakdown: devCard.scoreBreakdown),
            ],
          ),
        ),
        // Collapsible score breakdown
        ScoreBreakdownCard(
          breakdown: devCard.scoreBreakdown,
          projectScores: devCard.projectScores,
          uniqueLanguagesCount: devCard.topLanguages.length,
          uniqueFrameworksCount: devCard.topFrameworks.length,
          totalCommitsLastYear: devCard.totalCommitsLastYear,
        ),
      ],
    );
  }
}
