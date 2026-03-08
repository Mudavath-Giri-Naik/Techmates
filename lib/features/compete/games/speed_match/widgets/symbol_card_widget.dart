import 'package:flutter/material.dart';

import '../engine/symbol_generator.dart';

/// M3-mapped symbol colours (used when phase >= 5 introduces colour variance).
List<Color> kSymbolColorsForScheme(ColorScheme cs) => [
      cs.error, // red
      cs.primary, // blue
      cs.tertiary, // green / teal
      cs.secondary, // amber
      cs.primary, // purple mapped to primary
    ];

/// Hero card displaying the current symbol — 280 × 280, M3 tonal surface,
/// slide-in + feedback flash animations.
class SymbolCardWidget extends StatefulWidget {
  final GeneratedSymbol symbol;
  final bool? lastAnswerCorrect; // null = no feedback yet

  const SymbolCardWidget({
    super.key,
    required this.symbol,
    this.lastAnswerCorrect,
  });

  @override
  State<SymbolCardWidget> createState() => _SymbolCardWidgetState();
}

class _SymbolCardWidgetState extends State<SymbolCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  bool _flashing = false;
  bool? _flashCorrect;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant SymbolCardWidget old) {
    super.didUpdateWidget(old);
    // New symbol → slide in.
    if (widget.symbol != old.symbol) {
      _slideCtrl.forward(from: 0);
    }
    // Feedback flash.
    if (widget.lastAnswerCorrect != null &&
        widget.lastAnswerCorrect != old.lastAnswerCorrect) {
      _flashing = true;
      _flashCorrect = widget.lastAnswerCorrect;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _flashing = false);
      });
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasColour = widget.symbol.colorIndex >= 0;
    final colors = kSymbolColorsForScheme(cs);
    final symbolColor = hasColour
        ? colors[widget.symbol.colorIndex % colors.length]
        : cs.onSurface;

    // Larger font for single/double-char symbols.
    final isShort = widget.symbol.symbol.length <= 2;
    final fontSize = isShort ? 112.0 : 72.0;

    // Flash background
    Color cardBg;
    if (_flashing && _flashCorrect != null) {
      cardBg = _flashCorrect!
          ? cs.tertiaryContainer
          : cs.errorContainer;
    } else {
      cardBg = isDark ? cs.surfaceContainer : cs.surfaceContainerLow;
    }

    return SlideTransition(
      position: _slideAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: cs.outlineVariant
                .withOpacity(isDark ? 0.3 : 0.6),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.symbol.symbol,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: symbolColor,
            ),
          ),
        ),
      ),
    );
  }
}
