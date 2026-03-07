import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

/// Uppercase section header with optional trailing action.
///
/// Usage:
/// ```dart
/// SectionLabel('YOUR CLASS', action: 'See all →', onAction: () => ...)
/// ```
class SectionLabel extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const SectionLabel(
    this.text, {
    super.key,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.dark.inkGhost : AppColors.light.inkGhost;

    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: AppTextStyles.sectionLabel(color: color),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: AppTextStyles.bodySmall(
                color: AppColors.brandPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
