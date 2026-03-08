import 'package:flutter/material.dart';

class MultiplierBadgeWidget extends StatelessWidget {
  final int multiplier;

  const MultiplierBadgeWidget({super.key, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final isBase = multiplier <= 1;
    final bg = isBase
        ? const Color(0xFFF7F9FC)
        : const Color(0xFFEAF2FF);
    final border = isBase
        ? const Color(0xFFD7E0EC)
        : const Color(0xFFBFD2FB);
    final fg = isBase
        ? const Color(0xFF5F6E86)
        : const Color(0xFF245FD9);

    return AnimatedOpacity(
      opacity: isBase ? 0.8 : 1,
      duration: const Duration(milliseconds: 180),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          'x$multiplier',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

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
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
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
