import 'package:flutter/material.dart';

/// Four dots showing progress toward the next multiplier tier.
///
/// Filled = teal, empty = grey.
class StreakDotsWidget extends StatelessWidget {
  final int filledCount;
  final int totalDots;

  const StreakDotsWidget({
    super.key,
    required this.filledCount,
    this.totalDots = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (i) {
        final filled = i < filledCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? const Color(0xFF00B4D8)
                  : Colors.grey.withOpacity(0.35),
              border: Border.all(
                color: filled
                    ? const Color(0xFF00B4D8)
                    : Colors.grey.withOpacity(0.5),
                width: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
