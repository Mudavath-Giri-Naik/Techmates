import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/internship_post.dart';
import '../core/theme/internship_carousel_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DEADLINE URGENCY
// ═════════════════════════════════════════════════════════════════════════════

Color _deadlineColor(int daysLeft) {
  if (daysLeft <= 2) return const Color(0xFFDC2626);
  if (daysLeft <= 7) return const Color(0xFFD97706);
  return const Color(0xFF16A34A);
}

String _deadlineLabel(int daysLeft) {
  if (daysLeft <= 2) return 'URGENT';
  if (daysLeft <= 7) return 'CLOSING SOON';
  return 'OPEN';
}

// ═════════════════════════════════════════════════════════════════════════════
// PALETTE — stable per post, shared across all 3 slides
// ═════════════════════════════════════════════════════════════════════════════

class _Palette {
  final Color bgLight;
  final Color bgDark;
  final Color accent;
  final Color accentDark;

  const _Palette({
    required this.bgLight,
    required this.bgDark,
    required this.accent,
    required this.accentDark,
  });

  Color fg(bool dark) => dark ? accentDark : accent;
  Color bg(bool dark) => dark ? bgDark : bgLight;
}

const List<_Palette> _kPalettes = [
  _Palette(
    bgLight: Color(0xFFCDE8FF), bgDark: Color(0xFF051D33),
    accent: Color(0xFF1A72E8), accentDark: Color(0xFF5B9BFF),
  ),
  _Palette(
    bgLight: Color(0xFFFFF3B0), bgDark: Color(0xFF1E1800),
    accent: Color(0xFFB58A00), accentDark: Color(0xFFFFD84D),
  ),
  _Palette(
    bgLight: Color(0xFFFFD6E0), bgDark: Color(0xFF280010),
    accent: Color(0xFFD63066), accentDark: Color(0xFFFF7BAB),
  ),
  _Palette(
    bgLight: Color(0xFFCCF0DC), bgDark: Color(0xFF021810),
    accent: Color(0xFF1A8A4A), accentDark: Color(0xFF4DD68C),
  ),
  _Palette(
    bgLight: Color(0xFFE4D9FF), bgDark: Color(0xFF0D0520),
    accent: Color(0xFF5B2ECC), accentDark: Color(0xFF9B7BFF),
  ),
];

_Palette _paletteFor(String title) {
  final hash = title.codeUnits.fold(0, (a, b) => a + b);
  return _kPalettes[hash % _kPalettes.length];
}

const List<String> _kHeadings = ['Overview', 'The Details', 'Apply Now'];

// ═════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class InternshipCarouselCard extends StatefulWidget {
  final InternshipPost post;
  const InternshipCarouselCard({required this.post, super.key});

  @override
  State<InternshipCarouselCard> createState() => _InternshipCarouselCardState();
}

class _InternshipCarouselCardState extends State<InternshipCarouselCard> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;
  static const int _totalSlides = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateTo(int i) => _pageController.animateToPage(
        i, duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);

  Widget _buildContent(int index, _Palette pal, bool isDark, InternshipCarouselColors c) {
    switch (index) {
      case 0: return _Slide1Overview(post: widget.post, pal: pal, isDark: isDark, c: c);
      case 1: return _Slide2Details(post: widget.post, pal: pal, isDark: isDark);
      case 2: return _Slide3Apply(post: widget.post, pal: pal, isDark: isDark);
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = InternshipCarouselColors.of(context);
    final pal = _paletteFor(widget.post.title);

    return AspectRatio(
      aspectRatio: 1.0, // 1:1 square (1080×1080)
      child: PageView.builder(
        controller: _pageController,
        itemCount: _totalSlides,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (p) => setState(() => _currentPage = p),
        itemBuilder: (context, index) => _SlideShell(
          pal: pal, isDark: isDark, currentPage: _currentPage,
          totalSlides: _totalSlides, heading: _kHeadings[index],
          companyName: widget.post.company, onIndicatorTap: _animateTo,
          child: _buildContent(index, pal, isDark, c),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE SHELL
// ═════════════════════════════════════════════════════════════════════════════

class _SlideShell extends StatelessWidget {
  final _Palette pal;
  final bool isDark;
  final int currentPage, totalSlides;
  final String heading, companyName;
  final ValueChanged<int> onIndicatorTap;
  final Widget child;

  const _SlideShell({
    required this.pal, required this.isDark, required this.currentPage,
    required this.totalSlides, required this.heading, required this.companyName,
    required this.onIndicatorTap, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg     = pal.bg(isDark);
    final Color accent = pal.fg(isDark);
    final Color cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color cardBorder = isDark
        ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07);
    final Color onBg = isDark
        ? Colors.white.withOpacity(0.95) : const Color(0xFF0D0D0D);

    return Container(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(heading, style: GoogleFonts.dmSans(
              fontSize: 24, fontWeight: FontWeight.w800, height: 1.1, color: onBg)),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CompanyPill(name: companyName, accent: accent, isDark: isDark),
                _SlideDotIndicator(
                  currentPage: currentPage, totalSlides: totalSlides,
                  activeColor: accent, isDark: isDark, onTap: onIndicatorTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 1 — OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════

class _Slide1Overview extends StatelessWidget {
  final InternshipPost post;
  final _Palette pal;
  final bool isDark;
  final InternshipCarouselColors c;
  const _Slide1Overview({required this.post, required this.pal,
    required this.isDark, required this.c});

  @override
  Widget build(BuildContext context) {
    final Color accent = pal.fg(isDark);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final Color textMuted = isDark
        ? Colors.white.withOpacity(0.38) : const Color(0xFF999999);
    final Color dividerC = isDark
        ? Colors.white.withOpacity(0.08) : const Color(0xFFEEEEEB);

    final words = post.title.split(' ').where((w) => w.isNotEmpty).toList();
    final List<InlineSpan> titleSpans = [];
    for (int i = 0; i < words.length; i++) {
      final isSecond = i == 1;
      final text = i < words.length - 1 ? '${words[i]}\n' : words[i];
      titleSpans.add(TextSpan(
        text: text,
        style: GoogleFonts.bebasNeue(
          fontSize: 80, height: 0.9,
          color: isSecond ? accent : textPrimary,
        ),
      ));
    }

    final bool hasStipend = post.stipend != null && post.stipend! > 0;
    final String stipendText = hasStipend
        ? (post.stipend! >= 1000 ? '₹${post.stipend! ~/ 1000}K' : '₹${post.stipend}')
        : 'Unpaid';
    final Color stipendColor = hasStipend
        ? (isDark ? const Color(0xFF4DD68C) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFFFF7BAB) : const Color(0xFFDC2626));

    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Badge(text: '● ${post.status.toUpperCase()}', filled: true,
                color: isDark ? const Color(0xFF4DD68C) : const Color(0xFF16A34A)),
            const SizedBox(width: 8),
            _Badge(text: (post.empType ?? 'INTERNSHIP').toUpperCase(),
                filled: false, color: textMuted, borderColor: dividerC),
          ]),
          const SizedBox(height: 16),
          Text(post.company.toUpperCase(), style: GoogleFonts.dmMono(
            fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 3, color: accent)),
          const SizedBox(height: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown, alignment: Alignment.topLeft,
              child: RichText(text: TextSpan(children: titleSpans)),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: dividerC),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MONTHLY STIPEND', style: GoogleFonts.dmMono(
                    fontSize: 9, letterSpacing: 1.8, color: textMuted)),
                const SizedBox(height: 2),
                Text(stipendText, style: GoogleFonts.bebasNeue(
                    fontSize: 36, color: stipendColor)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('LOCATION', style: GoogleFonts.dmMono(
                    fontSize: 9, letterSpacing: 1.8, color: textMuted)),
                const SizedBox(height: 2),
                Text(post.location ?? 'Remote', style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 2 — THE DETAILS
// ═════════════════════════════════════════════════════════════════════════════

class _Slide2Details extends StatelessWidget {
  final InternshipPost post;
  final _Palette pal;
  final bool isDark;
  const _Slide2Details({required this.post, required this.pal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color accent = pal.fg(isDark);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final Color textMuted = isDark
        ? Colors.white.withOpacity(0.38) : const Color(0xFF999999);
    final Color cellBg = isDark
        ? Colors.white.withOpacity(0.04) : const Color(0xFFFAFAF9);
    final Color cellBorder = isDark
        ? Colors.white.withOpacity(0.07) : const Color(0xFFEEEEEB);

    final int daysLeft = post.daysLeft;
    final Color urgencyColor = _deadlineColor(daysLeft);
    final String urgencyLabel = _deadlineLabel(daysLeft);
    final String deadlineStr = DateFormat('dd MMM yyyy').format(post.deadline);
    final String duration = post.duration ?? '—';
    final String empType = post.empType ?? 'Internship';
    final String opensOn = post.opensOn != null
        ? DateFormat('dd MMM yyyy').format(post.opensOn!) : 'Now';
    final String postedOn = DateFormat('dd MMM yyyy').format(post.createdAt);

    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Deadline urgency banner ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(isDark ? 0.15 : 0.08),
              border: Border(bottom: BorderSide(
                  color: urgencyColor.withOpacity(0.20), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(
                        color: urgencyColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(urgencyLabel, style: GoogleFonts.dmMono(
                        fontSize: 9, letterSpacing: 1.6, color: urgencyColor)),
                  ]),
                  const SizedBox(height: 4),
                  Text(deadlineStr, style: GoogleFonts.dmSans(
                      fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary)),
                  Text('Application deadline', style: GoogleFonts.dmMono(
                      fontSize: 10, color: textMuted)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: urgencyColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$daysLeft', style: GoogleFonts.bebasNeue(
                        fontSize: 32, height: 1, color: Colors.white)),
                    Text('DAYS\nLEFT', textAlign: TextAlign.center,
                        style: GoogleFonts.dmMono(fontSize: 8, height: 1.2,
                            letterSpacing: 0.5,
                            color: Colors.white.withOpacity(0.75))),
                  ]),
                ),
              ],
            ),
          ),

          // ── 2×2 grid ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Expanded(child: Row(children: [
                  _GridCell(
                    label: 'DURATION',
                    value: duration,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cellBg: cellBg,
                    cellBorder: cellBorder,
                    rightGap: true,
                  ),
                  _GridCell(
                    label: 'TYPE',
                    value: empType,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cellBg: cellBg,
                    cellBorder: cellBorder,
                    rightGap: false,
                  ),
                ])),
                const SizedBox(height: 10),
                Expanded(child: Row(children: [
                  _GridCell(
                    label: 'OPENS ON',
                    value: opensOn,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cellBg: cellBg,
                    cellBorder: cellBorder,
                    rightGap: true,
                  ),
                  _GridCell(
                    label: 'POSTED ON',
                    value: postedOn,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cellBg: cellBg,
                    cellBorder: cellBorder,
                    rightGap: false,
                  ),
                ])),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final String label, value;
  final Color accent, textPrimary, textMuted, cellBg, cellBorder;
  final bool rightGap;

  const _GridCell({
    required this.label, required this.value,
    required this.accent, required this.textPrimary, required this.textMuted,
    required this.cellBg, required this.cellBorder, required this.rightGap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: rightGap ? 10 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cellBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.dmMono(
                fontSize: 7, letterSpacing: 1.2, color: textMuted)),
            const SizedBox(height: 3),
            Flexible(
              child: Text(value,
                style: GoogleFonts.dmSans(fontSize: 13,
                    fontWeight: FontWeight.w700, color: textPrimary, height: 1.1),
                overflow: TextOverflow.ellipsis, maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SLIDE 3 — APPLY NOW
// ═════════════════════════════════════════════════════════════════════════════

class _Slide3Apply extends StatelessWidget {
  final InternshipPost post;
  final _Palette pal;
  final bool isDark;
  const _Slide3Apply({required this.post, required this.pal, required this.isDark});

  Future<void> _launchApply() async {
    if (post.link.isEmpty) return;
    final url = Uri.parse(post.link);
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = pal.fg(isDark);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final Color textMuted = isDark
        ? Colors.white.withOpacity(0.38) : const Color(0xFF999999);
    final Color surfaceBg = isDark
        ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F7F5);
    final Color borderC = isDark
        ? Colors.white.withOpacity(0.08) : const Color(0xFFE8E8E4);

    final int daysLeft = post.daysLeft;
    final Color urgencyColor = _deadlineColor(daysLeft);
    final String urgencyLabel = _deadlineLabel(daysLeft);
    final String deadlineStr = DateFormat('dd MMM yyyy').format(post.deadline);
    final bool hasStipend = post.stipend != null && post.stipend! > 0;

    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Top accent band with role name ───────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.18 : 0.07),
              border: Border(bottom: BorderSide(color: accent.withOpacity(0.15), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.company.toUpperCase(), style: GoogleFonts.dmMono(
                    fontSize: 9, letterSpacing: 2.5, color: accent)),
                const SizedBox(height: 3),
                Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 18,
                      fontWeight: FontWeight.w800, height: 1.2, color: textPrimary)),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Deadline urgency row ─────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(isDark ? 0.14 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: urgencyColor.withOpacity(0.22), width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(urgencyLabel, style: GoogleFonts.dmMono(
                                fontSize: 7, letterSpacing: 1.5,
                                color: urgencyColor)),
                            const SizedBox(height: 1),
                            Text(deadlineStr, style: GoogleFonts.dmSans(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: textPrimary)),
                          ],
                        )),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$daysLeft', style: GoogleFonts.bebasNeue(
                                fontSize: 24, height: 1, color: urgencyColor)),
                            Text('DAYS LEFT', style: GoogleFonts.dmMono(
                                fontSize: 6, letterSpacing: 0.8, color: textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Stipend + location quick row ─────────────────
                  Row(children: [
                    Expanded(child: _QuickStat(
                      label: 'STIPEND',
                      value: hasStipend ? '₹${post.stipend}/mo' : 'Unpaid',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      surfaceBg: surfaceBg,
                      borderC: borderC,
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _QuickStat(
                      label: 'LOCATION',
                      value: post.location ?? 'Remote',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      surfaceBg: surfaceBg,
                      borderC: borderC,
                    )),
                  ]),

                  const Spacer(),

                  // ── Apply CTA ────────────────────────────────────
                  GestureDetector(
                    onTap: _launchApply,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: accent, borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('Apply Now', style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Link row ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: surfaceBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      post.link.isNotEmpty ? post.link : 'No link provided',
                      style: GoogleFonts.dmMono(fontSize: 9, color: textMuted),
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color textPrimary, textMuted, surfaceBg, borderC;

  const _QuickStat({
    required this.label, required this.value,
    required this.textPrimary, required this.textMuted,
    required this.surfaceBg, required this.borderC,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceBg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderC, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmMono(
              fontSize: 7, letterSpacing: 1.3, color: textMuted)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  final String text;
  final bool filled;
  final Color color;
  final Color? borderColor;
  const _Badge({required this.text, required this.filled,
    required this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: filled ? color.withOpacity(0.30) : (borderColor ?? color),
            width: 1),
      ),
      child: Text(text, style: GoogleFonts.dmMono(
          fontSize: 9, letterSpacing: 1.6, color: color)),
    );
  }
}

class _CompanyPill extends StatelessWidget {
  final String name;
  final Color accent;
  final bool isDark;
  const _CompanyPill({required this.name, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.business_outlined, size: 12, color: accent),
        const SizedBox(width: 5),
        Text(name, style: GoogleFonts.dmSans(fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A1A))),
      ]),
    );
  }
}

/// Three-dot slide indicator with animated active pill.
class _SlideDotIndicator extends StatelessWidget {
  final int currentPage, totalSlides;
  final Color activeColor;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _SlideDotIndicator({
    required this.currentPage, required this.totalSlides,
    required this.activeColor, required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color inactive = isDark
        ? Colors.white.withOpacity(0.28) : Colors.black.withOpacity(0.20);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSlides, (i) {
        final isActive = i == currentPage;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactive,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}