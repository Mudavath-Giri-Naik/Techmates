import 'package:flutter/material.dart';

/// Multiplier badge: ×1, ×2, ×4, ×8.
///
/// Uses M3 [primaryContainer] / [onPrimaryContainer] tokens.
/// Minimal when ×1, prominent when multiplier > 1.
class MultiplierBadgeWidget extends StatelessWidget {
  final int multiplier;

  const MultiplierBadgeWidget({super.key, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBase = multiplier <= 1;

    return AnimatedOpacity(
      opacity: isBase ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isBase
              ? (isDark ? cs.surfaceContainer : cs.surfaceContainerLow)
              : cs.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isBase
                ? cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.5)
                : cs.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          '×$multiplier',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isBase ? cs.onSurfaceVariant : cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Animated version that pops on multiplier change with elasticOut + flash.
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
        vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
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
