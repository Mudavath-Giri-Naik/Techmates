import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Single domain progress bar showing name, score, and 0–1000 bar.
class DomainBar extends StatelessWidget {
  final String name;
  final String domainKey;
  final int score; // 0–1000
  final bool played;

  const DomainBar({
    super.key,
    required this.name,
    required this.domainKey,
    required this.score,
    this.played = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = played
        ? AppColors.domainColor(domainKey)
        : (isDark ? AppColors.dark.borderLight : AppColors.light.borderLight);
    final textColor = played
        ? (isDark ? AppColors.dark.inkMid : AppColors.light.inkMid)
        : (isDark ? AppColors.dark.inkGhost : AppColors.light.inkGhost);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              // Coloured dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodySmall(color: textColor),
                ),
              ),
              Text(
                played ? '$score' : '—',
                style: AppTextStyles.caption(
                  color: played
                      ? (isDark
                          ? AppColors.dark.inkPrimary
                          : AppColors.light.inkPrimary)
                      : textColor,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (score / 1000).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor:
                  isDark ? AppColors.dark.borderLight : AppColors.light.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
