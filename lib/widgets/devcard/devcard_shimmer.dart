import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DevCardShimmer extends StatelessWidget {
  const DevCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF161B22),
      highlightColor: const Color(0xFF30363D),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _box(double.infinity, 80, radius: 12),
            const SizedBox(height: 12),
            // Tags
            Row(children: [
              _box(80, 30, radius: 20),
              const SizedBox(width: 8),
              _box(100, 30, radius: 20),
              const SizedBox(width: 8),
              _box(90, 30, radius: 20),
            ]),
            const SizedBox(height: 12),
            // Stats grid row 1
            Row(children: [
              Expanded(child: _box(double.infinity, 60, radius: 12)),
              const SizedBox(width: 8),
              Expanded(child: _box(double.infinity, 60, radius: 12)),
              const SizedBox(width: 8),
              Expanded(child: _box(double.infinity, 60, radius: 12)),
            ]),
            const SizedBox(height: 8),
            // Stats grid row 2
            Row(children: [
              Expanded(child: _box(double.infinity, 60, radius: 12)),
              const SizedBox(width: 8),
              Expanded(child: _box(double.infinity, 60, radius: 12)),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ]),
            const SizedBox(height: 12),
            // Languages
            ...List.generate(5, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _box(double.infinity, 20, radius: 4),
                )),
            const SizedBox(height: 12),
            // Heatmap
            _box(double.infinity, 100, radius: 8),
            const SizedBox(height: 12),
            // Project cards
            ...List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _box(double.infinity, 90, radius: 12),
                )),
          ],
        ),
      ),
    );
  }

  Widget _box(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
