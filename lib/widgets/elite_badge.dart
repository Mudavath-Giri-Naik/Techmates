import 'package:flutter/material.dart';

class EliteBadge extends StatefulWidget {
  const EliteBadge({super.key});

  @override
  State<EliteBadge> createState() => _EliteBadgeState();
}

class _EliteBadgeState extends State<EliteBadge> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller?.dispose();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Slower blink - 2 seconds
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(
      begin: 0.3, // More visible blink
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    ));

    _controller!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure animations are initialized
    if (_controller == null || _textOpacityAnimation == null) {
      _initializeAnimations();
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEF4444),
                  Color(0xFFDC2626),
                  Color(0xFFB91C1C),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 8,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Opacity(
                  opacity: _textOpacityAnimation?.value ?? 1.0,
                  child: const Text(
                    'ELITE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          );
      },
    );
  }
}
