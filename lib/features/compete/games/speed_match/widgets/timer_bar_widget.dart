import 'package:flutter/material.dart';

/// Full-width progress bar at the top of the game screen.
class TimerBarWidget extends StatelessWidget {
  final double progress;
  final int secondsRemaining;

  const TimerBarWidget({
    super.key,
    required this.progress,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsRemaining <= 10;
    final trackColor = const Color(0xFFE5EBF4);
    final borderColor = isUrgent
        ? const Color(0xFFF0C9CF)
        : const Color(0xFFD7E0EC);
    final fillColor = isUrgent
        ? const Color(0xFFE46677)
        : const Color(0xFF3478F6);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: progress, end: progress),
      duration: const Duration(milliseconds: 250),
      builder: (_, value, child) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
