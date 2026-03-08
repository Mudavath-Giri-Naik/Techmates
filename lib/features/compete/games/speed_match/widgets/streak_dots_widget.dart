import 'package:flutter/material.dart';

/// Progress capsules showing streak momentum toward the next multiplier tier.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (index) {
        final filled = index < filledCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: filled ? 18 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: filled
                  ? const Color(0xFF3478F6)
                  : const Color(0xFFE6ECF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: filled
                    ? const Color(0xFF3478F6)
                    : const Color(0xFFD7E0EC),
              ),
            ),
          ),
        );
      }),
    );
  }
}
