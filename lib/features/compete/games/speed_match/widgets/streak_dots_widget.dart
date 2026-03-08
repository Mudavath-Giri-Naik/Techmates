import 'package:flutter/material.dart';

/// Six dots showing streak progress toward the next multiplier tier.
///
/// Filled dots glow with [cs.primary]. Empty dots use [cs.surfaceContainerHighest].
class StreakDotsWidget extends StatelessWidget {
  final int filledCount;
  final int totalDots;

  const StreakDotsWidget({
    super.key,
    required this.filledCount,
    this.totalDots = 6,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (i) {
        final filled = i < filledCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedScale(
            scale: filled ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? cs.primary : cs.surfaceContainerHighest,
                border: Border.all(
                  color: filled
                      ? cs.primary
                      : cs.outlineVariant
                          .withOpacity(isDark ? 0.25 : 0.5),
                  width: 1,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
