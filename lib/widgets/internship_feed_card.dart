import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/opportunity_feed_item.dart';

// ─── Fixed card dimensions ───────────────────────────────────────────────────
// All 3 slides are rendered inside the SAME SizedBox, so height is always
// identical. No measurement / _slideHeights / OverflowBox needed.
const double _kCardHeight = 480.0;

// ─── Grid background painter ─────────────────────────────────────────────────
class GridPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;
  const GridPainter({required this.lineColor, this.spacing = 32});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.7;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      old.lineColor != lineColor || old.spacing != spacing;
}

// ─── Tag data class ──────────────────────────────────────────────────────────
class _Tag {
  final String label;
  final Color bg, border, text;
  const _Tag(this.label, this.bg, this.border, this.text);
}

// ─── Main widget ─────────────────────────────────────────────────────────────
class InternshipFeedCard extends StatefulWidget {
  final OpportunityFeedItem opportunity;
  final bool useDarkTemplate;

  const InternshipFeedCard({
    required this.opportunity,
    this.useDarkTemplate = false,
    super.key,
  });

  @override
  State<InternshipFeedCard> createState() => _InternshipFeedCardState();
}

class _InternshipFeedCardState extends State<InternshipFeedCard> {
  final PageController _pc = PageController();
  int _currentSlide = 0;

  // ── Derived getters ──────────────────────────────────────────────────────
  OpportunityFeedItem get _opp => widget.opportunity;
  String get _orgName => _opp.internship?.company ?? 'Organisation';
  String get _title => _opp.title;
  String get _stipend =>
      (_opp.internship?.stipend ?? 0) > 0
          ? '₹${_opp.internship!.stipend}/mo'
          : 'Unpaid';
  String get _duration => _opp.internship?.duration ?? '—';
  String get _applyLink => _opp.applyLink ?? _opp.internship?.link ?? '';

  String get _deadlineFormatted {
    final dl = _opp.internship?.deadline;
    return dl == null ? '—' : DateFormat('dd MMM, yyyy').format(dl);
  }

  int get _daysLeft {
    final dl = _opp.internship?.deadline;
    if (dl == null) return 0;
    final diff = DateTime(dl.year, dl.month, dl.day)
        .difference(DateTime.now())
        .inDays;
    return diff > 0 ? diff : 0;
  }

  bool get _isLight =>
      !widget.useDarkTemplate ||
      Theme.of(context).brightness == Brightness.light;

  // ── Helpers ──────────────────────────────────────────────────────────────
  void _goTo(int page) {
    setState(() => _currentSlide = page);
    _pc.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _launchApply() async {
    if (_applyLink.isEmpty) return;
    final url = Uri.parse(_applyLink);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kCardHeight,
      child: PageView(
        controller: _pc,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentSlide = i),
        children: [
          _CoverSlide(card: this),
          _DetailsSlide(card: this),
          _AboutSlide(card: this),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 1 — COVER  (fully structured column, no Positioned overlaps)
// ─────────────────────────────────────────────────────────────────────────────
class _CoverSlide extends StatelessWidget {
  final _InternshipFeedCardState card;
  const _CoverSlide({required this.card});

  @override
  Widget build(BuildContext context) {
    final bool light = card._isLight;
    final Color bg = light ? const Color(0xFFF5F3EE) : const Color(0xFF111110);
    final Color subtle = light
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.08);
    final Color labelColor = light
        ? const Color(0xFF999999)
        : Colors.white.withOpacity(0.38);

    // ── Title split: first half | italic middle word | second half ──
    final words = card._title.split(' ').where((w) => w.isNotEmpty).toList();
    String titleFirst = '', titleItalic = '', titleLast = '';
    if (words.length >= 3) {
      final mid = words.length ~/ 2;
      titleFirst = words.sublist(0, mid).join(' ');
      titleItalic = words[mid];
      titleLast = words.sublist(mid + 1).join(' ');
    } else if (words.length == 2) {
      titleFirst = words[0];
      titleItalic = words[1];
    } else {
      titleFirst = words.join(' ');
    }
    final double titleSize =
        card._title.length > 35 ? 24 : card._title.length > 22 ? 30 : 36;

    return Container(
      color: bg,
      child: Stack(
        children: [
          // ── Grid background ──
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                lineColor: light
                    ? Colors.black.withOpacity(0.045)
                    : Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // ── Full-height structured column ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── ROW 1: Org chip  +  elite badge ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _OrgChip(name: card._orgName, light: light),
                    if (card._opp.isElite) _EliteBadge(light: light),
                  ],
                ),

                const SizedBox(height: 20),

                // ── ROW 2: TYPE label + year ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: subtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INTERNSHIP',
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          letterSpacing: 1.8,
                          color: labelColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${DateTime.now().year}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        letterSpacing: 1.4,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── ROW 3: Big title ──────────────────────────────────────
                RichText(
                  text: TextSpan(children: [
                    if (titleFirst.isNotEmpty)
                      TextSpan(
                        text: '$titleFirst\n',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          color: light
                              ? const Color(0xFF111110)
                              : Colors.white,
                        ),
                      ),
                    if (titleItalic.isNotEmpty)
                      TextSpan(
                        text: '$titleItalic ',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 1.08,
                          color: const Color(0xFFC8A96E),
                        ),
                      ),
                    if (titleLast.isNotEmpty)
                      TextSpan(
                        text: titleLast,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          color: light
                              ? const Color(0xFF111110)
                              : Colors.white,
                        ),
                      ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── ROW 4: Stipend + Duration stat tiles ──────────────────
                Row(
                  children: [
                    _StatTile(
                      label: 'STIPEND',
                      value: card._stipend,
                      light: light,
                      accent: true,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      label: 'DURATION',
                      value: card._duration,
                      light: light,
                      accent: false,
                    ),
                  ],
                ),

                const Spacer(),

                // ── ROW 5: Divider ────────────────────────────────────────
                Divider(height: 1, color: subtle),

                const SizedBox(height: 14),

                // ── ROW 6: Deadline  +  Days left pill  +  Next arrow ─────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Deadline block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEADLINE',
                            style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              letterSpacing: 1.2,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card._deadlineFormatted,
                            style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: light
                                  ? const Color(0xFF111110)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Days left pill
                    _DaysLeftPill(days: card._daysLeft, light: light),

                    const SizedBox(width: 10),

                    // Next slide arrow
                    GestureDetector(
                      onTap: () => card._goTo(1),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: light
                              ? const Color(0xFF111110)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: light
                              ? Colors.white
                              : const Color(0xFF111110),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline stat tile used only on cover slide ─────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value;
  final bool light, accent;
  const _StatTile({
    required this.label,
    required this.value,
    required this.light,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueFg = accent
        ? (light ? const Color(0xFF0D9488) : const Color(0xFF34D399))
        : (light ? const Color(0xFF111110) : Colors.white);
    final Color tileBg = accent
        ? (light
            ? const Color(0xFFF0FDF9)
            : const Color(0xFF34D399).withOpacity(0.08))
        : (light ? Colors.white : Colors.white.withOpacity(0.06));
    final Color tileBorder = accent
        ? (light
            ? const Color(0xFFB2F5EA)
            : const Color(0xFF34D399).withOpacity(0.2))
        : (light
            ? Colors.black.withOpacity(0.08)
            : Colors.white.withOpacity(0.1));

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tileBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 7.5,
                letterSpacing: 1.1,
                color: light
                    ? const Color(0xFFAAAAAA)
                    : Colors.white.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 2 — DETAILS
// ─────────────────────────────────────────────────────────────────────────────
class _DetailsSlide extends StatelessWidget {
  final _InternshipFeedCardState card;
  const _DetailsSlide({required this.card});

  @override
  Widget build(BuildContext context) {
    final bool light = card._isLight;
    final Color bg = light ? Colors.white : const Color(0xFF1A1A18);
    final Color divider = light
        ? Colors.black.withOpacity(0.07)
        : Colors.white.withOpacity(0.07);

    return Container(
      color: bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                lineColor: light
                    ? Colors.black.withOpacity(0.05)
                    : Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BackButton(onTap: () => card._goTo(0), light: light),
                    _SlideLabel(label: '02 / 03', light: light),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'OPPORTUNITY DETAILS',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    letterSpacing: 2.0,
                    color: light
                        ? const Color(0xFF999999)
                        : Colors.white.withOpacity(0.35),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Detail rows ──
                Expanded(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'LOCATION',
                        value: card._opp.internship?.location ?? '—',
                        light: light,
                        highlight: false,
                      ),
                      Divider(height: 1, color: divider),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'TYPE / DURATION',
                        value:
                            '${card._opp.internship?.empType ?? 'Role'} · ${card._duration}',
                        light: light,
                        highlight: false,
                      ),
                      Divider(height: 1, color: divider),
                      _DetailRow(
                        icon: Icons.people_outline_rounded,
                        label: 'ELIGIBILITY',
                        value: card._opp.internship?.eligibility ?? 'All',
                        light: light,
                        highlight: false,
                      ),
                      Divider(height: 1, color: divider),
                      _DetailRow(
                        icon: Icons.monetization_on_outlined,
                        label: 'STIPEND',
                        value: card._stipend,
                        light: light,
                        highlight: true,
                      ),
                    ],
                  ),
                ),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => card._goTo(2),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: light
                                ? const Color(0xFF111110)
                                : Colors.white.withOpacity(0.15),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'About →',
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: light
                                ? const Color(0xFF111110)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _ApplyButton(onTap: card._launchApply, light: light)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 3 — ABOUT
// ─────────────────────────────────────────────────────────────────────────────
class _AboutSlide extends StatelessWidget {
  final _InternshipFeedCardState card;
  const _AboutSlide({required this.card});

  List<_Tag> _buildTags(bool light) {
    final tags = <_Tag>[];
    final teal = light ? const Color(0xFF0D9488) : const Color(0xFF34D399);
    final tealBg = light
        ? const Color(0xFFF0FDF9)
        : const Color(0xFF34D399).withOpacity(0.1);
    final tealBorder = light
        ? const Color(0xFF99F6E4)
        : const Color(0xFF34D399).withOpacity(0.25);
    final defaultBorder = light
        ? Colors.black.withOpacity(0.15)
        : Colors.white.withOpacity(0.2);
    final defaultText = light ? const Color(0xFF111110) : Colors.white;

    // Type chip (dark pill)
    tags.add(_Tag(
      card._opp.internship?.empType ?? 'Internship',
      light ? const Color(0xFF111110) : Colors.white,
      Colors.transparent,
      light ? Colors.white : const Color(0xFF111110),
    ));

    final loc = card._opp.internship?.location ?? '';
    if (loc.isNotEmpty) tags.add(_Tag(loc, tealBg, tealBorder, teal));

    if ((card._opp.internship?.stipend ?? 0) > 0)
      tags.add(_Tag(card._stipend, tealBg, tealBorder, teal));

    if (card._duration.isNotEmpty)
      tags.add(_Tag(card._duration, Colors.transparent, defaultBorder, defaultText));

    final elig = card._opp.internship?.eligibility ?? '';
    if (elig.isNotEmpty) {
      final short = elig.split(' ').take(2).join(' ');
      tags.add(_Tag(short, Colors.transparent, defaultBorder, defaultText));
    }

    if (card._opp.isElite)
      tags.add(_Tag('Elite ★', const Color(0xFFC8A96E), Colors.transparent, const Color(0xFF111110)));

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final bool light = card._isLight;
    final Color bg = light ? const Color(0xFFF5F3EE) : const Color(0xFF111110);
    final desc = card._opp.internship?.description ??
        card._opp.internship?.eligibility ??
        'Open opportunity for students.';
    final tags = _buildTags(light);

    return Container(
      color: bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                lineColor: light
                    ? Colors.black.withOpacity(0.05)
                    : Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BackButton(onTap: () => card._goTo(1), light: light),
                    Text(
                      'About the role',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: light
                            ? const Color(0xFF111110)
                            : Colors.white,
                      ),
                    ),
                    _SlideLabel(label: '03 / 03', light: light),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Quote mark ──
                Text(
                  '"',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 56,
                    height: 0.8,
                    color: light
                        ? Colors.black.withOpacity(0.07)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Description — scrollable if too long ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          desc,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            color: light
                                ? const Color(0xFF333333)
                                : Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: t.bg,
                                      border:
                                          Border.all(color: t.border, width: 1.4),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      t.label,
                                      style: GoogleFonts.syne(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: t.text,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Bottom row: dot indicator + apply button ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DotIndicator(
                        current: card._currentSlide, light: light),
                    _ApplyButton(onTap: card._launchApply, light: light),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _OrgChip extends StatelessWidget {
  final String name;
  final bool light;
  const _OrgChip({required this.name, required this.light});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: light ? Colors.white : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
        boxShadow: light
            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: Colors.black, shape: BoxShape.circle),
            child: const Icon(Icons.school, size: 11, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: GoogleFonts.syne(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: light ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteBadge extends StatelessWidget {
  final bool light;
  const _EliteBadge({required this.light});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: light ? const Color(0xFF111110) : const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, size: 9, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'ELITE',
            style: GoogleFonts.spaceMono(
                fontSize: 8, letterSpacing: 1.4, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DaysLeftPill extends StatelessWidget {
  final int days;
  final bool light;
  const _DaysLeftPill({required this.days, required this.light});

  @override
  Widget build(BuildContext context) {
    final teal = light ? const Color(0xFF0D9488) : const Color(0xFF34D399);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: light
            ? const Color(0xFFF0FDF9)
            : const Color(0xFF34D399).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: light
              ? const Color(0xFF99F6E4)
              : const Color(0xFF34D399).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$days',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: teal,
              height: 1,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'DAYS\nLEFT',
            style: GoogleFonts.spaceMono(
              fontSize: 7,
              letterSpacing: 0.8,
              color: teal,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}



class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool light, highlight;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.light,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: light
                  ? const Color(0xFFF5F3EE)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 14,
                color: light
                    ? const Color(0xFF666666)
                    : Colors.white.withOpacity(0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    letterSpacing: 1.1,
                    color: light
                        ? const Color(0xFFBBBBBB)
                        : Colors.white.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: highlight
                        ? (light
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF34D399))
                        : (light ? const Color(0xFF111110) : Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool light;
  const _BackButton({required this.onTap, required this.light});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: light
              ? const Color(0xFFF5F3EE)
              : Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back,
            size: 16, color: light ? Colors.black : Colors.white),
      ),
    );
  }
}

class _SlideLabel extends StatelessWidget {
  final String label;
  final bool light;
  const _SlideLabel({required this.label, required this.light});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.spaceMono(
        fontSize: 9,
        color:
            light ? const Color(0xFFAAAAAA) : Colors.white.withOpacity(0.35),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final Future<void> Function() onTap;
  final bool light;
  const _ApplyButton({required this.onTap, required this.light});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            light ? const Color(0xFF111110) : const Color(0xFFC8A96E),
        foregroundColor:
            light ? Colors.white : const Color(0xFF111110),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        elevation: 0,
      ),
      icon: Text(
        'Apply Now',
        style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      label: const Icon(Icons.north_east, size: 14),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int current;
  final bool light;
  const _DotIndicator({required this.current, required this.light});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 6),
          width: active ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? (light ? const Color(0xFF111110) : Colors.white)
                : (light
                    ? Colors.black.withOpacity(0.15)
                    : Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}