import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/opportunity_feed_item.dart';

// ─── Fixed card height ────────────────────────────────────────────────────────
const double _kCardHeight = 480.0;

// ─── Tag data class ───────────────────────────────────────────────────────────
class _Tag {
  final String label;
  const _Tag(this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN LANGUAGE
// ─────────────────────────────────────────────────────────────────────────────
// Aesthetic: formal document / ledger register
// - 3px top accent bar is the ONLY color element
// - Zero border radius throughout
// - IBM Plex Mono for all labels and metadata
// - Bitter for display title
// - Strict horizontal rules as separators
// - No shadows, no gradients, no filled tiles
// ─────────────────────────────────────────────────────────────────────────────

class _C {
  // Background
  static Color bg(bool light) =>
      light ? const Color(0xFFFFFFFF) : const Color(0xFF0C0C0B);

  // Primary text
  static Color ink(bool light) =>
      light ? const Color(0xFF0A0A09) : const Color(0xFFEDECE8);

  // Secondary / muted
  static Color sub(bool light) =>
      light ? const Color(0xFF6B6B67) : const Color(0xFF5A5A56);

  // Hairline borders & rules
  static Color rule(bool light) =>
      light ? const Color(0xFFD8D8D4) : const Color(0xFF242422);

  // Accent — the single color used sparingly
  static const Color accent = Color(0xFF1A6BFF);

  // Accent text (for highlighted values)
  static Color accentText(bool light) =>
      light ? const Color(0xFF1A6BFF) : const Color(0xFF5B8FFF);

  // Inverse for CTA
  static Color ctaBg(bool light) =>
      light ? const Color(0xFF0A0A09) : const Color(0xFFEDECE8);
  static Color ctaFg(bool light) =>
      light ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A09);
}

// ─── Main widget ──────────────────────────────────────────────────────────────
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
    return dl == null ? '—' : DateFormat('dd MMM yyyy').format(dl);
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

  void _goTo(int page) {
    setState(() => _currentSlide = page);
    _pc.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
// SHARED: accent top bar + card shell
// ─────────────────────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final bool light;
  final Widget child;

  const _CardShell({required this.light, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg(light),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3px accent top bar
          Container(height: 3, color: _C.accent),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: horizontal rule
// ─────────────────────────────────────────────────────────────────────────────
class _Rule extends StatelessWidget {
  final bool light;
  const _Rule({required this.light});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _C.rule(light));
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: mono label style
// ─────────────────────────────────────────────────────────────────────────────
TextStyle _monoLabel(bool light) => GoogleFonts.ibmPlexMono(
      fontSize: 9,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w500,
      color: _C.sub(light),
    );

TextStyle _monoValue(bool light) => GoogleFonts.ibmPlexMono(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _C.ink(light),
    );

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 1 — COVER
// ─────────────────────────────────────────────────────────────────────────────
class _CoverSlide extends StatelessWidget {
  final _InternshipFeedCardState card;
  const _CoverSlide({required this.card});

  @override
  Widget build(BuildContext context) {
    final bool light = card._isLight;
    final double titleSize =
        card._title.length > 38 ? 20 : card._title.length > 24 ? 25 : 30;

    return _CardShell(
      light: light,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header: org name | slide counter ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      color: _C.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card._orgName.toUpperCase(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: _C.ink(light),
                      ),
                    ),
                    if (card._opp.isElite) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: _C.rule(light), width: 1),
                        ),
                        child: Text(
                          'ELITE',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 7.5,
                            letterSpacing: 1.4,
                            color: _C.sub(light),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '01 / 03',
                  style: _monoLabel(light),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _Rule(light: light),
            const SizedBox(height: 14),

            // ── Type + year ───────────────────────────────────────────────
            Text(
              'INTERNSHIP  ·  ${DateTime.now().year}',
              style: _monoLabel(light),
            ),

            const SizedBox(height: 12),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              card._title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.bitter(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: _C.ink(light),
              ),
            ),

            const SizedBox(height: 18),
            _Rule(light: light),
            const SizedBox(height: 14),

            // ── Stats: two-column register ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _RegisterCell(
                    label: 'STIPEND',
                    value: card._stipend,
                    light: light,
                    accent: true,
                  ),
                ),
                Container(width: 1, height: 40, color: _C.rule(light)),
                Expanded(
                  child: _RegisterCell(
                    label: 'DURATION',
                    value: card._duration,
                    light: light,
                    accent: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _Rule(light: light),

            const Spacer(),

            // ── Footer: deadline | days left | next ───────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Deadline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DEADLINE', style: _monoLabel(light)),
                      const SizedBox(height: 4),
                      Text(card._deadlineFormatted, style: _monoValue(light)),
                    ],
                  ),
                ),

                // Days left block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${card._daysLeft}',
                      style: GoogleFonts.bitter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: _C.accentText(light),
                      ),
                    ),
                    Text(
                      'DAYS LEFT',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 7.5,
                        letterSpacing: 1.2,
                        color: _C.sub(light),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Next arrow
                GestureDetector(
                  onTap: () => card._goTo(1),
                  child: Container(
                    width: 38,
                    height: 38,
                    color: _C.ctaBg(light),
                    child: Icon(
                      Icons.arrow_forward,
                      color: _C.ctaFg(light),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Register cell (two-col stat) ──────────────────────────────────────────────
class _RegisterCell extends StatelessWidget {
  final String label, value;
  final bool light, accent;
  const _RegisterCell({
    required this.label,
    required this.value,
    required this.light,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _monoLabel(light)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent ? _C.accentText(light) : _C.ink(light),
            ),
          ),
        ],
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

    return _CardShell(
      light: light,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BackBtn(onTap: () => card._goTo(0), light: light),
                Text('02 / 03', style: _monoLabel(light)),
              ],
            ),

            const SizedBox(height: 14),
            _Rule(light: light),
            const SizedBox(height: 12),

            Text('OPPORTUNITY DETAILS', style: _monoLabel(light)),

            const SizedBox(height: 12),
            _Rule(light: light),

            // ── Detail rows ───────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _LedgerRow(
                    icon: Icons.location_on_outlined,
                    label: 'LOCATION',
                    value: card._opp.internship?.location ?? '—',
                    light: light,
                    accent: false,
                  ),
                  _Rule(light: light),
                  _LedgerRow(
                    icon: Icons.access_time_outlined,
                    label: 'TYPE / DURATION',
                    value:
                        '${card._opp.internship?.empType ?? 'Role'}  ·  ${card._duration}',
                    light: light,
                    accent: false,
                  ),
                  _Rule(light: light),
                  _LedgerRow(
                    icon: Icons.group_outlined,
                    label: 'ELIGIBILITY',
                    value: card._opp.internship?.eligibility ?? 'All',
                    light: light,
                    accent: false,
                  ),
                  _Rule(light: light),
                  _LedgerRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'STIPEND',
                    value: card._stipend,
                    light: light,
                    accent: true,
                  ),
                  _Rule(light: light),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Actions ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StrokeBtn(
                    label: 'About →',
                    onTap: () => card._goTo(2),
                    light: light,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SolidBtn(
                    label: 'Apply Now',
                    onTap: card._launchApply,
                    light: light,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ledger row ────────────────────────────────────────────────────────────────
class _LedgerRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool light, accent;

  const _LedgerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.light,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _C.sub(light)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: _monoLabel(light)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent ? _C.accentText(light) : _C.ink(light),
              ),
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

  List<_Tag> _buildTags() {
    final tags = <_Tag>[];
    final empType = card._opp.internship?.empType ?? '';
    if (empType.isNotEmpty) tags.add(_Tag(empType.toUpperCase()));
    final loc = card._opp.internship?.location ?? '';
    if (loc.isNotEmpty) tags.add(_Tag(loc.toUpperCase()));
    if ((card._opp.internship?.stipend ?? 0) > 0)
      tags.add(_Tag(card._stipend));
    if (card._duration.isNotEmpty) tags.add(_Tag(card._duration));
    final elig = card._opp.internship?.eligibility ?? '';
    if (elig.isNotEmpty)
      tags.add(_Tag(elig.split(' ').take(3).join(' ').toUpperCase()));
    if (card._opp.isElite) tags.add(_Tag('ELITE'));
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final bool light = card._isLight;
    final desc = card._opp.internship?.description ??
        card._opp.internship?.eligibility ??
        'Open opportunity for students.';
    final tags = _buildTags();

    return _CardShell(
      light: light,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BackBtn(onTap: () => card._goTo(1), light: light),
                Text(
                  'ABOUT THE ROLE',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                    color: _C.ink(light),
                  ),
                ),
                Text('03 / 03', style: _monoLabel(light)),
              ],
            ),

            const SizedBox(height: 14),
            _Rule(light: light),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: GoogleFonts.bitter(
                        fontSize: 14,
                        height: 1.7,
                        color: _C.ink(light),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tags as compact mono tokens
                    Wrap(
                      spacing: 0,
                      runSpacing: 8,
                      children: tags.asMap().entries.map((entry) {
                        final isLast = entry.key == tags.length - 1;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.value.label,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w500,
                                color: _C.sub(light),
                              ),
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text(
                                  '/',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 10,
                                    color: _C.rule(light),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            _Rule(light: light),
            const SizedBox(height: 14),

            // ── Bottom row: dots + apply ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SegmentDots(current: card._currentSlide, light: light),
                _SolidBtn(
                  label: 'Apply Now',
                  onTap: card._launchApply,
                  light: light,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool light;
  const _BackBtn({required this.onTap, required this.light});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 13, color: _C.sub(light)),
          const SizedBox(width: 5),
          Text(
            'BACK',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              letterSpacing: 1.4,
              color: _C.sub(light),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool light;
  const _StrokeBtn({
    required this.label,
    required this.onTap,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: _C.rule(light), width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _C.ink(light),
          ),
        ),
      ),
    );
  }
}

class _SolidBtn extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;
  final bool light;
  const _SolidBtn({
    required this.label,
    required this.onTap,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: _C.ctaBg(light),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.ctaFg(light),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.north_east, size: 12, color: _C.ctaFg(light)),
          ],
        ),
      ),
    );
  }
}

class _SegmentDots extends StatelessWidget {
  final int current;
  final bool light;
  const _SegmentDots({required this.current, required this.light});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 4),
          width: active ? 20 : 6,
          height: 2,
          color: active ? _C.accent : _C.rule(light),
        );
      }),
    );
  }
}