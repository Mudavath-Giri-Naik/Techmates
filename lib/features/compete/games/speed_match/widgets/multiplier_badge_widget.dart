import 'package:flutter/material.dart';

/// Multiplier badge: ×1, ×2, ×4, ×8 with colour + scale animation.
class MultiplierBadgeWidget extends StatelessWidget {
  final int multiplier;

  const MultiplierBadgeWidget({super.key, required this.multiplier});

  Color _color() {
    switch (multiplier) {
      case 2:
        return const Color(0xFF2196F3); // blue
      case 4:
        return const Color(0xFFFFD700); // gold
      case 8:
        return const Color(0xFFFF5722); // orange-red
      default:
        return const Color(0xFF9E9E9E); // grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          '×$multiplier',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Animated version that pops on multiplier change.
class AnimatedMultiplierBadge extends StatefulWidget {
  final int multiplier;

  const AnimatedMultiplierBadge({super.key, required this.multiplier});

  @override
  State<AnimatedMultiplierBadge> createState() =>
      _AnimatedMultiplierBadgeState();
}

class _AnimatedMultiplierBadgeState extends State<AnimatedMultiplierBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedMultiplierBadge old) {
    super.didUpdateWidget(old);
    if (widget.multiplier != old.multiplier) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: MultiplierBadgeWidget(multiplier: widget.multiplier),
    );
  }
}
