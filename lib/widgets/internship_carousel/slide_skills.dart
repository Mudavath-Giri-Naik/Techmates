import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/internship_post.dart';
import '../../core/theme/internship_carousel_colors.dart';

/// Slide 4 — SKILLS & STACK
///
/// Stacked title "SKILLS / / STACK", tag cloud with 3 style variants
/// (filled, outlined, accent) cycling by index, and an employment type
/// strip pinned to the bottom.
class Slide4Skills extends StatelessWidget {
  final InternshipPost post;
  const Slide4Skills({required this.post, super.key});

  @override
  Widget build(BuildContext context) {
    final c = InternshipCarouselColors.of(context);
    final hasTags = post.tags != null && post.tags!.isNotEmpty;

    return ClipRect(
      child: Container(
        color: c.surfaceSecondary,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stacked title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SKILLS',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 60,
                        height: 0.9,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      '/',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 60,
                        height: 0.9,
                        color: c.accentCoral,
                      ),
                    ),
                    Text(
                      'STACK',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 60,
                        height: 0.9,
                        color: c.onSurface,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '04 / 05',
                    style:
                        GoogleFonts.dmMono(fontSize: 10, color: c.subtleText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Tag cloud ──
            Expanded(
              child: hasTags
                  ? SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(post.tags!.length, (i) {
                          return _buildTagPill(post.tags![i], i, c);
                        }),
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No tags specified',
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          color: c.mutedText,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // ── Employment type strip ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: c.onSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EMPLOYMENT TYPE',
                    style: GoogleFonts.dmMono(
                      fontSize: 9,
                      letterSpacing: 3,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    post.empType ?? 'Not specified',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill(String tag, int index, InternshipCarouselColors c) {
    final variant = index % 3;
    Color bg;
    Color textColor;
    Border? border;

    switch (variant) {
      case 0: // filled
        bg = c.tagFilledBg;
        textColor = c.tagFilledText;
        border = null;
        break;
      case 1: // outlined
        bg = Colors.transparent;
        textColor = c.onSurface;
        border = Border.all(color: c.onSurface, width: 2);
        break;
      case 2: // accent
        bg = c.accentCoral;
        textColor = Colors.white;
        border = null;
        break;
      default:
        bg = Colors.transparent;
        textColor = c.onSurface;
        border = Border.all(color: c.onSurface, width: 2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        tag.toUpperCase(),
        style: GoogleFonts.syne(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
