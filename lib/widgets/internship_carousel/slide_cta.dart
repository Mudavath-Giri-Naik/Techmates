import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/internship_post.dart';

/// Slide 5 — APPLY NOW (CTA)
///
/// Always uses accentCoral (#FF4D2E) as background. Features a "GO"
/// watermark, hero "DON'T MISS THIS." text, deadline/days-left info,
/// and an apply strip with url_launcher.
class Slide5CTA extends StatelessWidget {
  final InternshipPost post;
  const Slide5CTA({required this.post, super.key});

  Future<void> _launchApply() async {
    if (post.link.isEmpty) return;
    final url = Uri.parse(post.link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFFF4D2E); // accentCoral — always

    return ClipRect(
      child: Container(
        color: bg,
        child: Stack(
          children: [
            // ── Background "GO" watermark ──
            Positioned(
              bottom: -30,
              right: -20,
              child: Text(
                'GO',
                style: GoogleFonts.bebasNeue(
                  fontSize: 200,
                  color: const Color(0x14000000), // rgba(0,0,0,0.08)
                ),
              ),
            ),

            // ── Foreground content ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: company pill + slide number ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x26000000), // rgba(0,0,0,0.15)
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          post.company.toUpperCase(),
                          style: GoogleFonts.dmMono(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: const Color(0xCCFFFFFF), // rgba(255,255,255,0.8)
                          ),
                        ),
                      ),
                      Text(
                        '05 / 05',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: const Color(0x66FFFFFF), // rgba(255,255,255,0.4)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Hero text ──
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "DON'T\nMISS\nTHIS.",
                        style: GoogleFonts.bebasNeue(
                          fontSize: 72,
                          height: 0.88,
                          letterSpacing: -1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Deadline row ──
                  Flexible(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0x26000000),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEADLINE',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    color: const Color(0x99FFFFFF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(post.deadline),
                                      style: GoogleFonts.syne(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0x26000000),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DAYS LEFT',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    color: const Color(0x99FFFFFF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${post.daysLeft} days',
                                      style: GoogleFonts.syne(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Apply strip ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.link,
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              color: const Color(0xFF888888),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _launchApply,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8FF00),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'APPLY NOW ↗',
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                        ),
                      ],
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
