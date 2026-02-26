import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DevCardShimmer extends StatelessWidget {
  final bool isDark;

  const DevCardShimmer({super.key, this.isDark = true});

  Color get _base => isDark ? const Color(0xFF141E2F) : const Color(0xFFE5E7EB);
  Color get _highlight => isDark ? const Color(0xFF1E2D42) : const Color(0xFFF3F4F6);
  Color get _bg => isDark ? const Color(0xFF0D1120) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Shimmer.fromColors(
        baseColor: _base,
        highlightColor: _highlight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rainbow stripe placeholder
              _box(double.infinity, 3, radius: 0),
              const SizedBox(height: 16),
              // Header
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(50, 50, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _box(120, 14),
                      const SizedBox(height: 6),
                      _box(80, 10),
                      const SizedBox(height: 8),
                      Row(children: [
                        _box(50, 16, radius: 4),
                        const SizedBox(width: 4),
                        _box(60, 16, radius: 4),
                      ]),
                    ])),
                _box(56, 56, radius: 28),
              ]),
              const SizedBox(height: 16),
              // Sub-bars
              Row(children: [
                Expanded(child: _box(double.infinity, 5)),
                const SizedBox(width: 10),
                Expanded(child: _box(double.infinity, 5)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _box(double.infinity, 5)),
                const SizedBox(width: 10),
                Expanded(child: _box(double.infinity, 5)),
              ]),
              const SizedBox(height: 20),
              // Stats boxes
              _box(80, 9),
              const SizedBox(height: 8),
              Row(
                  children: List.generate(
                      6,
                      (_) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: _box(double.infinity, 58, radius: 6),
                            ),
                          ))),
              const SizedBox(height: 20),
              // Languages
              _box(90, 9),
              const SizedBox(height: 10),
              ...List.generate(4, (_) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _box(double.infinity, 6),
                );
              }),
              const SizedBox(height: 20),
              // Streak
              _box(90, 9),
              const SizedBox(height: 8),
              Row(
                  children: List.generate(
                      3,
                      (_) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _box(double.infinity, 50, radius: 6),
                            ),
                          ))),
              const SizedBox(height: 20),
              // Calendar
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List.generate(28, (_) => _box(20, 20, radius: 2)),
              ),
              const SizedBox(height: 20),
              // Commits
              _box(90, 9),
              const SizedBox(height: 10),
              ...List.generate(3, (_) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _box(double.infinity, 30, radius: 6),
                );
              }),
              const SizedBox(height: 20),
              // Projects
              _box(80, 9),
              const SizedBox(height: 8),
              ...List.generate(3, (_) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _box(double.infinity, 40, radius: 8),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
