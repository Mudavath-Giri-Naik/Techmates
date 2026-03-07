import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TechMates typography constants — Google Fonts Inter everywhere.
class AppTextStyles {
  const AppTextStyles._();

  // ── Display ─────────────────────────────────────────────────────────
  static TextStyle display({Color? color}) => GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: color,
      );

  // ── Headline ────────────────────────────────────────────────────────
  static TextStyle headline({Color? color}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color,
      );

  // ── Title Large ─────────────────────────────────────────────────────
  static TextStyle titleLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color,
      );

  // ── Title Medium ────────────────────────────────────────────────────
  static TextStyle titleMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // ── Body Large ──────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Body Medium ─────────────────────────────────────────────────────
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Body Small ──────────────────────────────────────────────────────
  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Caption ─────────────────────────────────────────────────────────
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      );

  // ── Section Label ───────────────────────────────────────────────────
  static TextStyle sectionLabel({Color? color}) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );

  // ── Score Large ─────────────────────────────────────────────────────
  static TextStyle scoreLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
        color: color,
      );

  // ── Score Medium ────────────────────────────────────────────────────
  static TextStyle scoreMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color,
      );
}
