import 'package:flutter/material.dart';

import '../engine/symbol_generator.dart';

/// Colour palette for symbol cards (phase 5+).
const List<Color> kSymbolColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.purple,
];

/// White card showing a large symbol with slide / flash / shake animations.
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
  Color? _flashColor;

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
      _flashColor = widget.lastAnswerCorrect!
          ? Colors.green.withOpacity(0.35)
          : Colors.red.withOpacity(0.35);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _flashColor = null);
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
    final hasColour = widget.symbol.colorIndex >= 0;
    final symbolColor = hasColour
        ? kSymbolColors[widget.symbol.colorIndex % kSymbolColors.length]
        : Colors.black87;

    // Use larger font for shapes, slightly smaller for CS symbols.
    final isShort = widget.symbol.symbol.length <= 2;
    final fontSize = isShort ? 96.0 : 64.0;

    return SlideTransition(
      position: _slideAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: _flashColor ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
