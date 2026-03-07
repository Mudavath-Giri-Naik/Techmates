import 'package:flutter/material.dart';

/// Thin top-of-screen timer bar: teal → yellow → red, with pulse in last 10s.
class TimerBarWidget extends StatelessWidget {
  /// Value from 0.0 (empty) to 1.0 (full).
  final double progress;
  final int secondsRemaining;

  const TimerBarWidget({
    super.key,
    required this.progress,
    required this.secondsRemaining,
  });

  Color _barColor() {
    if (secondsRemaining > 30) return const Color(0xFF00B4D8); // teal
    if (secondsRemaining > 10) return const Color(0xFFFFC107); // yellow
    return const Color(0xFFEF4444); // red
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor();
    final pulse = secondsRemaining <= 10;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: progress, end: progress),
      duration: const Duration(milliseconds: 300),
      builder: (_, value, __) {
        return AnimatedOpacity(
          opacity: pulse
              ? (DateTime.now().millisecond % 500 < 250 ? 1.0 : 0.6)
              : 1.0,
          duration: const Duration(milliseconds: 250),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
