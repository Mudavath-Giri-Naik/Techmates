import 'package:flutter/material.dart';

/// TechMates design‐system colour tokens.
///
/// Usage: `AppColors.light.brandPrimary` or `AppColors.dark.brandPrimary`
class AppColors {
  const AppColors._();

  // ── STATIC LIGHT TOKENS ─────────────────────────────────────────────
  static const light = _LightColors();

  // ── STATIC DARK TOKENS ──────────────────────────────────────────────
  static const dark = _DarkColors();

  // ── BRAND ───────────────────────────────────────────────────────────
  static const brandPrimary = Color(0xFF6366F1);
  static const brandPrimaryBg = Color(0xFFEEF2FF);
  static const brandPrimaryBorder = Color(0xFFE0E5FF);

  // ── SEMANTIC ────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFF0FDF9);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFFFFF5F5);

  // ── DOMAIN ──────────────────────────────────────────────────────────
  static const domainSpeed = Color(0xFFF59E0B);
  static const domainMemory = Color(0xFF8B5CF6);
  static const domainAttention = Color(0xFF10B981);
  static const domainProblemSolving = Color(0xFFEF4444);
  static const domainMath = Color(0xFF6366F1);
  static const domainFlexibility = Color(0xFFEC4899);
  static const domainLanguage = Color(0xFF3B82F6);

  /// Resolve domain colour from domain_key enum string.
  static Color domainColor(String? domainKey) {
    switch (domainKey) {
      case 'speed':
        return domainSpeed;
      case 'memory':
        return domainMemory;
      case 'attention':
        return domainAttention;
      case 'problem_solving':
        return domainProblemSolving;
      case 'math':
        return domainMath;
      case 'flexibility':
        return domainFlexibility;
      case 'language':
        return domainLanguage;
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

// ── Light theme tokens ──────────────────────────────────────────────────

class _LightColors {
  const _LightColors();

  Color get surface => const Color(0xFFFFFFFF);
  Color get surfaceLight => const Color(0xFFFAFBFC);
  Color get surfaceAlt => const Color(0xFFF4F7FB);
  Color get borderLight => const Color(0xFFEDF0F5);
  Color get borderMid => const Color(0xFFE2E8F0);

  Color get inkPrimary => const Color(0xFF0F172A);
  Color get inkMid => const Color(0xFF475569);
  Color get inkFaint => const Color(0xFF94A3B8);
  Color get inkGhost => const Color(0xFFCBD5E1);
}

// ── Dark theme tokens ───────────────────────────────────────────────────

class _DarkColors {
  const _DarkColors();

  Color get surface => const Color(0xFF0F172A);
  Color get surfaceLight => const Color(0xFF1E293B);
  Color get surfaceAlt => const Color(0xFF334155);
  Color get borderLight => const Color(0xFF334155);
  Color get borderMid => const Color(0xFF475569);

  Color get inkPrimary => const Color(0xFFF8FAFC);
  Color get inkMid => const Color(0xFFCBD5E1);
  Color get inkFaint => const Color(0xFF64748B);
  Color get inkGhost => const Color(0xFF475569);
}
