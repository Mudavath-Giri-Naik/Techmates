import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hackathon_details_model.dart';
import '../models/opportunity_feed_item.dart';

/// Redesigned hackathon feed card — single dark-surfaced panel.
///
/// Always dark (#0C0C0C) background in both themes so the card pops.
/// Features a pulsing status dot, three stat cells, tag cloud, and a
/// high-contrast accentYellow CTA button.
class HackathonFeedCard extends StatefulWidget {
  final OpportunityFeedItem opportunity;
  final int rank;

  const HackathonFeedCard({
    super.key,
    required this.opportunity,
    this.rank = 1,
  });

  @override
  State<HackathonFeedCard> createState() => _HackathonFeedCardState();
}

class _HackathonFeedCardState extends State<HackathonFeedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _isSaved = false;

  // ── Color tokens — resolved per theme ──
  static const _accentHighlight = Color(0xFF3B82F6);
  static const _accentBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──

  HackathonDetailsModel get _h => widget.opportunity.hackathon!;

  // ── Theme-resolved tokens ──
  late bool _isDark;
  Color get _cardBg => _isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F2EB);
  Color get _surfaceCell => _isDark ? const Color(0xFF141414) : const Color(0xFFEDE9E0);
  Color get _divider => _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD9D0);
  Color get _dividerSubtle => _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E1D8);
  Color get _onCard => _isDark ? const Color(0xFFF5F2EB) : const Color(0xFF111110);
  Color get _mutedText => _isDark ? const Color(0xFF555555) : const Color(0xFF888888);
  Color get _subtleText => _isDark ? const Color(0xFF333333) : const Color(0xFFAAAAAA);
  Color get _tagFillBg => _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E4DB);
  Color get _tagFillText => _isDark ? const Color(0xFFAAAAAA) : const Color(0xFF555555);
  Color get _tagOutlineColor => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFCCC8BF);
  Color get _topBarBg => _isDark ? const Color(0xFF111110) : const Color(0xFFEDE9E0);
  Color get _logoBorder => _isDark ? const Color(0xFF2E2E2E) : const Color(0xFFCCC8BF);
  Color get _prizeBorder => _isDark ? const Color(0xFF252525) : const Color(0xFFCCC8BF);
  Color get _bookmarkBorder => _isDark ? const Color(0xFF252525) : const Color(0xFFCCC8BF);
  Color get _statusDot => _isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6);
  Color get _statusPillBg => _isDark ? const Color(0x143B82F6) : const Color(0x143B82F6);
  Color get _statusPillBorder => _isDark ? const Color(0x333B82F6) : const Color(0x333B82F6);
  Color get _categoryLabel => _isDark ? const Color(0xFF444444) : const Color(0xFF999999);
  Color get _closedBtnBg => _isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E4DB);
  Color get _closedBtnText => _isDark ? const Color(0xFF444444) : const Color(0xFF999999);
  Color get _applyBtnBg => const Color(0xFF3B82F6);
  Color get _applyBtnText => const Color(0xFFFFFFFF);

  String get _orgName {
    final c = _h.company.trim();
    if (c.isNotEmpty) return c;
    return widget.opportunity.posterName ??
        widget.opportunity.posterUsername ??
        'TechMates';
  }

  String get _location {
    final loc = _h.location.trim();
    return loc.isNotEmpty ? loc : 'Remote';
  }

  String get _prize {
    final p = _h.prizes.trim();
    return p.isNotEmpty ? p : '';
  }

  int get _daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(_h.deadline.year, _h.deadline.month, _h.deadline.day);
    final diff = d.difference(today).inDays;
    return diff > 0 ? diff : 0;
  }

  bool get _isOpen => _daysLeft > 0;

  String get _applyLink =>
      widget.opportunity.applyLink ??
      widget.opportunity.postLink ??
      _h.link;

  String get _postedAgo {
    final diff = DateTime.now().difference(widget.opportunity.createdAt);
    if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    }
    return DateFormat('MMM d, yyyy').format(widget.opportunity.createdAt);
  }

  List<String> get _tags {
    // Hackathon model has no tags list, but build from available fields
    final t = <String>[];
    if (_h.teamSize.isNotEmpty && _h.teamSize != 'N/A') {
      t.add('Team: ${_h.teamSize}');
    }
    if (_h.rounds > 0) t.add('${_h.rounds} Rounds');
    if (_h.eligibility.isNotEmpty) t.add(_h.eligibility);
    return t;
  }

  /// Extract year from title or deadline for accent rendering.
  ({String mainTitle, String? year}) get _splitTitle {
    final words = _h.title.split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';
    if (RegExp(r'^\d{4}$').hasMatch(lastWord)) {
      return (
        mainTitle: words.sublist(0, words.length - 1).join(' '),
        year: lastWord,
      );
    }
    return (mainTitle: _h.title, year: _h.deadline.year.toString());
  }

  @override
  Widget build(BuildContext context) {
    final hackathon = widget.opportunity.hackathon;
    if (hackathon == null) return const SizedBox.shrink();

    _isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: _cardBg,
          boxShadow: _isDark
              ? []
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            _buildStatsRow(),
            if (_tags.isNotEmpty) _buildTagsRow(),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // Top bar was removed.

  // ══════════════════════════════════════════════════════════════
  // HERO SECTION
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeroSection() {
    final titleParts = _splitTitle;
    final prize = _prize;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Organiser + Prize row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Organiser block
              Expanded(
                child: Row(
                  children: [
                    // Logo box
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _surfaceCell,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _logoBorder,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _orgName.length >= 2
                              ? _orgName.substring(0, 2).toUpperCase()
                              : _orgName.toUpperCase(),
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _accentHighlight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _orgName,
                            style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: _onCard,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'ORGANISER',
                            style: GoogleFonts.dmMono(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Prize tag
              if (prize.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _surfaceCell,
                    border: Border.all(
                      color: _prizeBorder,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Text(
                          prize,
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accentHighlight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Category label ──
          Text(
            'GLOBAL COMPETITION',
            style: GoogleFonts.dmMono(
              fontSize: 9,
              letterSpacing: 4,
              color: _categoryLabel,
            ),
          ),
          const SizedBox(height: 6),

          // ── Hero title ──
          RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: titleParts.mainTitle.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 56,
                    height: 0.92,
                    letterSpacing: 0.5,
                    color: _onCard,
                  ),
                ),
                if (titleParts.year != null) ...[
                  TextSpan(
                    text: '\n${titleParts.year}',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 56,
                      height: 0.92,
                      letterSpacing: 0.5,
                      color: _accentHighlight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    final deadlineStr = DateFormat('MMM dd').format(_h.deadline);

    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: _dividerSubtle, width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Cell 1 — Deadline
            Expanded(
              child: _statCell(
                label: 'DEADLINE',
                value: deadlineStr,
                valueColor: _accentHighlight,
                showRightBorder: true,
              ),
            ),
            // Cell 2 — Status
            Expanded(
              child: _statCell(
                label: 'STATUS',
                value: _isOpen ? 'Open' : 'Closed',
                valueColor: _accentBlue,
                showRightBorder: true,
                leading: _isOpen
                    ? FadeTransition(
                        opacity: _pulseCtrl,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _accentBlue,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            // Cell 3 — Days Left
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAYS LEFT',
                      style: GoogleFonts.dmMono(
                        fontSize: 8,
                        letterSpacing: 3,
                        color: _categoryLabel,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _daysLeft.toString(),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22,
                            height: 1,
                            color: _accentHighlight,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'DAYS',
                          style: GoogleFonts.dmMono(
                            fontSize: 8,
                            letterSpacing: 2,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell({
    required String label,
    required String value,
    required Color valueColor,
    bool showRightBorder = false,
    Widget? leading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: showRightBorder
            ? Border(right: BorderSide(color: _dividerSubtle, width: 1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmMono(
              fontSize: 8,
              letterSpacing: 3,
              color: _categoryLabel,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAGS ROW
  // ══════════════════════════════════════════════════════════════

  Widget _buildTagsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider, width: 1)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _tags.asMap().entries.map((entry) {
          final isEven = entry.key.isEven;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isEven ? _tagFillBg : Colors.transparent,
              border: Border.all(color: _tagOutlineColor, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.value.toUpperCase(),
              style: GoogleFonts.dmMono(
                fontSize: 9,
                letterSpacing: 1.5,
                color: isEven ? _tagFillText : _mutedText,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BOTTOM ACTIONS
  // ══════════════════════════════════════════════════════════════

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // ── Location row ──
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 10,
                color: _mutedText,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '$_location · Worldwide',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: _mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Apply Now button (full width) ──
          _ApplyButton(
            link: _applyLink,
            isClosed: !_isOpen,
          ),
        ],
      ),
    );
  }
}

/// Apply button with micro scale animation on press.
class _ApplyButton extends StatefulWidget {
  final String link;
  final bool isClosed;
  const _ApplyButton({required this.link, required this.isClosed});

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  Future<void> _launch() async {
    if (widget.isClosed || widget.link.trim().isEmpty) return;
    final uri = Uri.tryParse(widget.link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isClosed ? null : _onTapDown,
      onTapUp: widget.isClosed ? null : _onTapUp,
      onTapCancel: widget.isClosed ? null : _onTapCancel,
      onTap: _launch,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: widget.isClosed
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isClosed ? 'CLOSED' : 'APPLY NOW',
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: widget.isClosed
                      ? const Color(0xFF444444)
                      : Colors.white,
                ),
              ),
              if (!widget.isClosed) ...[
                const SizedBox(width: 8),
                Text(
                  '↗',
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
