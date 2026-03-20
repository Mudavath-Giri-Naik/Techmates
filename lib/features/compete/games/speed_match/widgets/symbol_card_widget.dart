import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/symbol_generator.dart';

const List<Color> _kSymbolPalette = [
  Color(0xFFE46677),
  Color(0xFF3478F6),
  Color(0xFF12A594),
  Color(0xFFF0A33B),
  Color(0xFF8365F1),
];

/// Hero card displaying the current symbol.
class SymbolCardWidget extends StatefulWidget {
  final GeneratedSymbol symbol;
  final bool? lastAnswerCorrect;

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
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.16, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant SymbolCardWidget old) {
    super.didUpdateWidget(old);
    if (widget.symbol != old.symbol) {
      _slideCtrl.forward(from: 0);
    }
    if (widget.lastAnswerCorrect != null &&
        widget.lastAnswerCorrect != old.lastAnswerCorrect) {
      _flashing = true;
      _flashCorrect = widget.lastAnswerCorrect;
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) {
          setState(() => _flashing = false);
        }
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
    // Keep a healthy 60px gap on both sides at minimum, max size 320 for clean look
    final size = min(MediaQuery.sizeOf(context).width - 60, 320.0);
    final hasColour = widget.symbol.colorIndex >= 0;
    final symbolColor = hasColour
        ? _kSymbolPalette[widget.symbol.colorIndex % _kSymbolPalette.length]
        : const Color(0xFF162033);
    final isCodeSymbol =
        RegExp(r'^[\{\}\[\]\(\)<>!=/%&|:#\-+]+$').hasMatch(widget.symbol.symbol);
    
    // Increase the visual weight of the bare symbol now that boxes are gone
    final fontSize = _fontSizeFor(widget.symbol.symbol, size) * 1.6;

    Color cardBg = const Color(0xFFFCFDFF);
    Color borderColor = const Color(0xFFD7E0EC);
    if (_flashing && _flashCorrect != null) {
      cardBg = _flashCorrect!
          ? const Color(0xFFF2FBF6)
          : const Color(0xFFFFF3F4);
      borderColor = _flashCorrect!
          ? const Color(0xFFBFE4CD)
          : const Color(0xFFF0C9CF);
    } else if (hasColour) {
      borderColor = symbolColor.withValues(alpha: 0.28);
    }

    return SlideTransition(
      position: _slideAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.symbol.symbol,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: isCodeSymbol ? 2.8 : 0,
                      color: symbolColor,
                      fontFamily: isCodeSymbol ? 'monospace' : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _fontSizeFor(String symbol, double cardSize) {
    if (symbol.length <= 1) return cardSize * 0.42;
    if (symbol.length == 2) return cardSize * 0.34;
    return cardSize * 0.24;
  }
}

class _TopTag extends StatelessWidget {
  final String label;
  final Color borderColor;

  const _TopTag({
    required this.label,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
