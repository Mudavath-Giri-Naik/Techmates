import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/internship_post.dart';
import '../../core/theme/internship_carousel_colors.dart';

/// Slide 2 — DETAILS GRID
///
/// Header bar with company name + "The Details", then a 2×3 grid of
/// bordered cells showing Deadline, Status, Duration, Stipend, Posted On,
/// and Opens On.
class Slide2Details extends StatelessWidget {
  final InternshipPost post;
  const Slide2Details({required this.post, super.key});

  @override
  Widget build(BuildContext context) {
    final c = InternshipCarouselColors.of(context);

    return ClipRect(
      child: Container(
        color: c.surfaceSecondary,
        child: Column(
          children: [
            // ── Header bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              decoration: BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: c.dividerColor, width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE DETAILS',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          letterSpacing: 3,
                          color: c.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.company,
                        style: GoogleFonts.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: c.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '02 / 05',
                    style: GoogleFonts.dmMono(fontSize: 10, color: c.subtleText),
                  ),
                ],
              ),
            ),

            // ── 2×3 Grid ──
            Expanded(
              child: Column(
                children: [
                  // Row 1: Deadline | Status
                  Expanded(
                    child: Row(
                      children: [
                        _GridCell(
                          label: 'DEADLINE',
                          value: DateFormat('MMM dd').format(post.deadline),
                          sub: post.deadline.year.toString(),
                          valueStyle: GoogleFonts.bebasNeue(
                              fontSize: 46, color: c.accentCoral),
                          c: c,
                          showRightBorder: true,
                          showBottomBorder: true,
                        ),
                        _GridCell(
                          label: 'STATUS',
                          value: post.status,
                          sub: 'Accepting apps',
                          valueStyle: GoogleFonts.bebasNeue(
                              fontSize: 46, color: c.accentGreenText),
                          c: c,
                          showRightBorder: false,
                          showBottomBorder: true,
                        ),
                      ],
                    ),
                  ),
                  // Row 2: Duration | Stipend
                  Expanded(
                    child: Row(
                      children: [
                        _GridCell(
                          label: 'DURATION',
                          value: post.duration ?? '—',
                          sub: 'Full term',
                          valueStyle: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                          c: c,
                          showRightBorder: true,
                          showBottomBorder: true,
                        ),
                        _GridCell(
                          label: 'STIPEND',
                          value: post.stipend != null && post.stipend! > 0
                              ? '₹${post.stipend}/mo'
                              : 'Unpaid',
                          sub: '/month',
                          valueStyle: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                          c: c,
                          showRightBorder: false,
                          showBottomBorder: true,
                        ),
                      ],
                    ),
                  ),
                  // Row 3: Posted On | Opens On
                  Expanded(
                    child: Row(
                      children: [
                        _GridCell(
                          label: 'POSTED ON',
                          value:
                              DateFormat('MMM d, yyyy').format(post.createdAt),
                          sub: '',
                          valueStyle: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                          c: c,
                          showRightBorder: true,
                          showBottomBorder: false,
                        ),
                        _GridCell(
                          label: 'OPENS ON',
                          value: post.opensOn != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(post.opensOn!)
                              : 'Now',
                          sub: '',
                          valueStyle: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                          c: c,
                          showRightBorder: false,
                          showBottomBorder: false,
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

/// A single cell in the 2×3 details grid.
class _GridCell extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final TextStyle valueStyle;
  final InternshipCarouselColors c;
  final bool showRightBorder;
  final bool showBottomBorder;

  const _GridCell({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueStyle,
    required this.c,
    required this.showRightBorder,
    required this.showBottomBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          border: Border(
            right: showRightBorder
                ? BorderSide(color: c.dividerColor, width: 2)
                : BorderSide.none,
            bottom: showBottomBorder
                ? BorderSide(color: c.dividerColor, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.dmMono(
                fontSize: 9,
                letterSpacing: 2,
                color: c.subtleText,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: valueStyle),
              ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: c.subtleText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
