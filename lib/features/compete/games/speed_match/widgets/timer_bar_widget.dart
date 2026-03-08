import 'package:flutter/material.dart';

/// Full-width pill-shaped progress bar at the very top of the game screen.
///
/// Animates from [cs.primary] to [cs.error] when [secondsRemaining] <= 10.
class TimerBarWidget extends StatelessWidget {
  /// Value from 0.0 (empty) to 1.0 (full).
  final double progress;
  final int secondsRemaining;

  const TimerBarWidget({
    super.key,
    required this.progress,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUrgent = secondsRemaining <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: progress, end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (_, value, __) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isUrgent ? cs.error : cs.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
