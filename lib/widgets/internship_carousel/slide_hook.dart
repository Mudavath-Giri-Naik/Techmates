import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/internship_post.dart';
import '../../core/theme/internship_carousel_colors.dart';

/// Slide 1 — HOOK
///
/// Shows status badges, company name, large title (2nd word in accent green),
/// stipend block, and location block.
class Slide1Hook extends StatelessWidget {
  final InternshipPost post;
  const Slide1Hook({required this.post, super.key});

  @override
  Widget build(BuildContext context) {
    final c = InternshipCarouselColors.of(context);

    // ── Title split: first word normal, second word accentGreen ──
    final words = post.title.split(' ').where((w) => w.isNotEmpty).toList();
    final List<InlineSpan> titleSpans = [];
    for (int i = 0; i < words.length; i++) {
      final isSecondWord = i == 1;
      final text = i < words.length - 1 ? '${words[i]}\n' : words[i];
      titleSpans.add(TextSpan(
        text: text,
        style: GoogleFonts.bebasNeue(
          fontSize: 88,
          height: 0.9,
          color: isSecondWord ? c.accentGreen : c.onSurface,
        ),
      ));
    }

    // ── Stipend display ──
    String stipendText;
    Color stipendColor;
    if (post.stipend != null && post.stipend! > 0) {
      stipendText =
          post.stipend! >= 1000 ? '₹${post.stipend! ~/ 1000}K' : '₹${post.stipend}';
      stipendColor = c.accentGreen;
    } else {
      stipendText = 'Unpaid';
      stipendColor = c.accentCoral;
    }

    return ClipRect(
      child: Container(
        color: c.surfacePrimary,
        padding: const EdgeInsets.all(28),
        child: Stack(
          children: [
            // ── Slide number top-right ──
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                '01 / 05',
                style: GoogleFonts.dmMono(fontSize: 10, color: c.subtleText),
              ),
            ),

            // ── Main layout ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TOP SECTION (flexible) ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.accentGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '● ${post.status.toUpperCase()}',
                              style: GoogleFonts.dmMono(
                                fontSize: 9,
                                letterSpacing: 2,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Emp type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: c.dividerColor, width: 1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              (post.empType ?? 'INTERNSHIP').toUpperCase(),
                              style: GoogleFonts.dmMono(
                                fontSize: 9,
                                letterSpacing: 2,
                                color: c.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Company name
                      Text(
                        post.company.toUpperCase(),
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: c.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Big title — scales down if too large
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: RichText(
                            text: TextSpan(children: titleSpans),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── BOTTOM SECTION ──
                Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: c.dividerColor),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stipend block
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY STIPEND',
                              style: GoogleFonts.dmMono(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: c.mutedText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stipendText,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 36,
                                color: stipendColor,
                              ),
                            ),
                          ],
                        ),
                        // Location block
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LOCATION',
                              style: GoogleFonts.dmMono(
                                fontSize: 9,
                                letterSpacing: 2,
                                color: c.subtleText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.location ?? 'Remote',
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
