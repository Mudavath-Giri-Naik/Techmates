import 'package:flutter/material.dart';

/// Semantic colour tokens for the 5-slide internship carousel card.
///
/// Usage: `final c = InternshipCarouselColors.of(context);`
/// then   `c.surfacePrimary`, `c.accentGreen`, etc.
class InternshipCarouselColors {
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color onSurface;
  final Color dividerColor;
  final Color mutedText;
  final Color subtleText;
  final Color accentGreen;
  final Color accentCoral;
  final Color accentGreenText;
  final Color tagBorder;
  final Color tagFilledBg;
  final Color tagFilledText;

  const InternshipCarouselColors._({
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.onSurface,
    required this.dividerColor,
    required this.mutedText,
    required this.subtleText,
    required this.accentGreen,
    required this.accentCoral,
    required this.accentGreenText,
    required this.tagBorder,
    required this.tagFilledBg,
    required this.tagFilledText,
  });

  // ─── Light theme ──────────────────────────────────────────────────────
  static const _light = InternshipCarouselColors._(
    surfacePrimary: Color(0xFFF5F2EB),
    surfaceSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0A0A0A),
    dividerColor: Color(0xFF0A0A0A),
    mutedText: Color(0xFF888888),
    subtleText: Color(0xFFAAAAAA),
    accentGreen: Color(0xFF4D8DFF),
    accentCoral: Color(0xFFFF4D2E),
    accentGreenText: Color(0xFF2B6CB0),
    tagBorder: Color(0xFF0A0A0A),
    tagFilledBg: Color(0xFF0A0A0A),
    tagFilledText: Color(0xFFF5F2EB),
  );

  // ─── Dark theme ───────────────────────────────────────────────────────
  static const _dark = InternshipCarouselColors._(
    surfacePrimary: Color(0xFF0A0A0A),
    surfaceSecondary: Color(0xFF141414),
    onSurface: Color(0xFFF5F2EB),
    dividerColor: Color(0xFF252525),
    mutedText: Color(0xFF666666),
    subtleText: Color(0xFF444444),
    accentGreen: Color(0xFF4D8DFF),
    accentCoral: Color(0xFFFF4D2E),
    accentGreenText: Color(0xFF6BA3FF),
    tagBorder: Color(0xFF333333),
    tagFilledBg: Color(0xFFF5F2EB),
    tagFilledText: Color(0xFF0A0A0A),
  );

  /// Resolve tokens from current brightness.
  static InternshipCarouselColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }

  /// Slide backgrounds alternate:
  /// slides 1, 3 → surfacePrimary; slides 2, 4 → surfaceSecondary.
  /// Slide 5 always uses accentCoral (handled separately).
  Color slideBg(int index) {
    if (index == 4) return accentCoral; // slide 5
    return index.isEven ? surfacePrimary : surfaceSecondary;
  }
}
