import 'package:flutter/material.dart';

/// Material Design 3 color tokens for the Home Screen.
/// All values match the design reference exactly.
class HomeTheme {
  HomeTheme._();

  // ── Primary ──
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color primaryContainer(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
  static Color onPrimaryContainer(BuildContext context) => Theme.of(context).colorScheme.onPrimaryContainer;

  // ── Secondary ──
  static Color secondaryContainer(BuildContext context) => Theme.of(context).colorScheme.secondaryContainer;
  static Color onSecondaryContainer(BuildContext context) => Theme.of(context).colorScheme.onSecondaryContainer;

  // ── Tertiary ──
  static Color tertiary(BuildContext context) => Theme.of(context).colorScheme.tertiary;
  static Color tertiaryContainer(BuildContext context) => Theme.of(context).colorScheme.tertiaryContainer;

  // ── Surface ──
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color surfaceContainer(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color surfaceContainerLow(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color surfaceContainerHigh(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color surfaceContainerHighest(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;

  // ── On Surface ──
  static Color onSurface(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color onSurfaceVariant(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  // ── Outline ──
  static Color outlineVariant(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  // ── Accent Orange (Keep somewhat static as these are branding/accents, but darken container if needed) ──
  static const Color accentOrange = Color(0xFFE8651A);
  static Color accentOrangeContainer(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4A1F02) : const Color(0xFFFFDBC9);

  // ── Accent Green ──
  static const Color accentGreen = Color(0xFF1A7A4A);
  static Color accentGreenContainer(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0D3D25) : const Color(0xFFB8F5D4);

  // ── Accent Blue ──
  static const Color accentBlue = Color(0xFF0061A4);
  static Color accentBlueContainer(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF003052) : const Color(0xFFD3E4FF);

  // ── Error ──
  static Color error(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color errorContainer(BuildContext context) => Theme.of(context).colorScheme.errorContainer;

  // ── Background ──
  static Color background(BuildContext context) => Theme.of(context).colorScheme.surface;

  // ── Type chip colors ──
  static Color typeChipBg(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'internship':
        return accentBlueContainer(context);
      case 'hackathon':
        return accentGreenContainer(context);
      case 'event':
        return tertiaryContainer(context);
      default:
        return surfaceContainerHigh(context);
    }
  }

  static Color typeChipText(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'internship':
        return accentBlue;
      case 'hackathon':
        return accentGreen;
      case 'event':
        return tertiary(context);
      default:
        return onSurfaceVariant(context);
    }
  }

  /// Company logo colors for known brands
  static ({Color bg, Color text}) companyColors(BuildContext context, String company) {
    final lower = company.toLowerCase();
    if (lower.contains('google')) return (bg: Colors.white, text: const Color(0xFF4285F4));
    if (lower.contains('microsoft')) return (bg: Colors.white, text: const Color(0xFF00A4EF));
    if (lower.contains('amazon')) return (bg: const Color(0xFF232F3E), text: const Color(0xFFFF9900));
    return (bg: primaryContainer(context), text: primary(context));
  }

  /// Countdown pill colors based on days remaining
  static ({Color bg, Color text}) countdownColors(BuildContext context, int daysLeft) {
    if (daysLeft <= 3) return (bg: errorContainer(context), text: error(context));
    return (bg: accentGreenContainer(context), text: accentGreen);
  }
}
