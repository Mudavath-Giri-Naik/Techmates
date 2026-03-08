import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/internship_post.dart';
import '../../core/theme/internship_carousel_colors.dart';

/// Slide 3 — ABOUT THE ROLE
///
/// Hero title "ABOUT / THE ROLE", description block with fade-out gradient
/// on overflow, and an eligibility strip at the bottom.
class Slide3About extends StatelessWidget {
  final InternshipPost post;
  const Slide3About({required this.post, super.key});

  @override
  Widget build(BuildContext context) {
    final c = InternshipCarouselColors.of(context);

    return ClipRect(
      child: Container(
        color: c.surfacePrimary,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Two-line title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ABOUT',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 52,
                        height: 1,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      'THE ROLE',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 52,
                        height: 1,
                        color: c.accentGreen,
                      ),
                    ),
                  ],
                ),
                Text(
                  '03 / 05',
                  style: GoogleFonts.dmMono(fontSize: 10, color: c.subtleText),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Description block ──
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  border: Border.all(color: c.dividerColor, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESCRIPTION',
                      style: GoogleFonts.dmMono(
                        fontSize: 9,
                        letterSpacing: 3,
                        color: c.subtleText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 0.85, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Text(
                            post.description ?? 'No description provided.',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              height: 1.65,
                              color: c.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Eligibility strip ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: c.accentGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    'WHO CAN APPLY',
                    style: GoogleFonts.dmMono(
                      fontSize: 9,
                      letterSpacing: 3,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: const Color(0x33000000),
                  ),
                  Expanded(
                    child: Text(
                      post.eligibility ?? 'Open to all',
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0A0A),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
}
