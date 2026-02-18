import 'package:flutter/material.dart';

class EliteBadge extends StatelessWidget {
  const EliteBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The ribbon banner itself
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(65, 65),
              painter: _RibbonPainter(),
            ),
          ),
          // The ELITE text
          Positioned(
            top: 16,
            right: 4,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: const Text(
                'ELITE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    
    // 1. The main ribbon path (the part that crosses the corner)
    final Paint ribbonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF87171), // Light red
          Color(0xFFDC2626), // Medium red
          Color(0xFFB91C1C), // Dark red
        ],
      ).createShader(Rect.fromLTWH(0, 0, s, s));

    final Path ribbonPath = Path()
      ..moveTo(s * 0.4, 0)      // Top edge start
      ..lineTo(s, s * 0.6)      // Right edge end
      ..lineTo(s, s)            // Right edge bottom
      ..lineTo(0,0)             // Origin
      ..close();
    
    // Actually, let's draw a proper strip
    final Path stripPath = Path()
      ..moveTo(s * 0.3, 0)
      ..lineTo(s, s * 0.7)
      ..lineTo(s, s * 0.95)
      ..lineTo(s * 0.05, 0)
      ..close();

    // 2. Shadows/Folds for depth (wrapping around)
    final Paint foldPaint = Paint()..color = const Color(0xFF7F1D1D);
    
    // Top fold
    final Path topFold = Path()
      ..moveTo(s * 0.3, 0)
      ..lineTo(s * 0.3, -4)
      ..lineTo(s * 0.4, 0)
      ..close();
      
    // Right fold
    final Path rightFold = Path()
      ..moveTo(s, s * 0.7)
      ..lineTo(s + 4, s * 0.7)
      ..lineTo(s, s * 0.8)
      ..close();

    // Draw shadow first
    canvas.drawShadow(stripPath, Colors.black, 3.0, false);
    
    // Draw ribbon
    canvas.drawPath(stripPath, ribbonPaint);
    
    // Draw folds
    canvas.drawPath(topFold, foldPaint);
    canvas.drawPath(rightFold, foldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

