import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hackathon_details_model.dart';
import '../models/opportunity_feed_item.dart';

/// Professional Hackathon Feed Card — 1:1 square ratio (1080×1080 design)
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

  // ── Palette ───────────────────────────────────────────────────
  static const _teal        = Color(0xFF14B8A6);
  static const _tealSurface = Color(0xFFE6F7F5);

  static const _cardBg      = Color(0xFFFAFAF9);
  static const _sectionBg   = Color(0xFFF2F1EE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSub     = Color(0xFF6B7280);
  static const _textMuted   = Color(0xFF9CA3AF);

  // ── Data helpers ──────────────────────────────────────────────
  HackathonDetailsModel get _h => widget.opportunity.hackathon!;

  String get _orgName {
    final c = _h.company.trim();
    if (c.isNotEmpty) return c;
    return widget.opportunity.posterName ??
        widget.opportunity.posterUsername ??
        'TechMates';
  }

  String get _location {
    final l = _h.location.trim();
    return l.isNotEmpty ? l : 'Worldwide / Remote';
  }

  String get _prize {
    final p = _h.prizes.trim();
    return p.isNotEmpty ? p : '';
  }

  int get _daysLeft {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end   = DateTime(_h.deadline.year, _h.deadline.month, _h.deadline.day);
    final diff  = end.difference(today).inDays;
    return diff > 0 ? diff : 0;
  }

  bool get _isOpen => _daysLeft > 0;

  String get _applyLink =>
      widget.opportunity.applyLink ??
      widget.opportunity.postLink ??
      _h.link;

  String get _deadlineLabel => DateFormat('dd MMM yyyy').format(_h.deadline);

  String get _postedAgo {
    final diff = DateTime.now().difference(widget.opportunity.createdAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(widget.opportunity.createdAt);
  }

  List<String> get _chips {
    final t = <String>[];
    if (_h.teamSize.isNotEmpty && _h.teamSize != 'N/A') t.add(_h.teamSize);
    if (_h.rounds > 0) t.add('${_h.rounds} Rounds');
    if (_h.eligibility.isNotEmpty) t.add(_h.eligibility);
    return t;
  }

  String get _initials =>
      _orgName.trim().split(RegExp(r'\s+')).take(2)
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
          .join();

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

  // ══════════════════════════════════════════════════════════════
  // BUILD — fully flexible layout, no fixed heights that can overflow
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (widget.opportunity.hackathon == null) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 1.0,
      child: ColoredBox(
        color: _cardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — flex 3
            Expanded(flex: 3, child: _buildHeader()),
            // Title — flex 4
            Expanded(flex: 4, child: _buildTitleBlock()),
            // Info grid — flex 5
            Expanded(flex: 5, child: _buildInfoGrid()),
            // Chips — flex 2 (only when present)
            if (_chips.isNotEmpty)
              Expanded(flex: 2, child: _buildChips()),
            // Footer — flex 3
            Expanded(flex: 3, child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER  —  avatar · org · posted · prize badge
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Square initials avatar
          Container(
            width: 44,
            height: 44,
            color: _tealSurface,
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Org name + posted ago
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orgName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Posted $_postedAgo',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    color: _textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Prize badge
          if (_prize.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: _tealSurface,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      _prize,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _teal,
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
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TITLE BLOCK  —  category label · title
  // ══════════════════════════════════════════════════════════════

  Widget _buildTitleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'HACKATHON',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
              color: _teal,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              _h.title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.3,
                color: _textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // INFO GRID  —  2×2, fully flexible
  // ══════════════════════════════════════════════════════════════

  Widget _buildInfoGrid() {
    return ColoredBox(
      color: _sectionBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _infoCell(
                      label: 'DEADLINE',
                      value: _deadlineLabel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _infoCell(
                      label: 'DAYS LEFT',
                      value: _isOpen ? '$_daysLeft days' : 'Ended',
                      valueColor: _isOpen
                          ? (_daysLeft <= 7
                              ? const Color(0xFFD97706)
                              : _textPrimary)
                          : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _infoCell(
                      label: 'LOCATION',
                      value: _location,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _infoCell(
                      label: 'TEAM SIZE',
                      value: _h.teamSize.isNotEmpty && _h.teamSize != 'N/A'
                          ? _h.teamSize
                          : 'Open',
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

  Widget _infoCell({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 9,
            letterSpacing: 1.5,
            color: _textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? _textPrimary,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // CHIPS  —  flat section fill
  // ══════════════════════════════════════════════════════════════

  Widget _buildChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _chips.map((chip) {
            return ColoredBox(
              color: _sectionBg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  chip,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: _textSub,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FOOTER  —  rank · status dot · CTA
  // ══════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          // Rank
          Text(
            '#${widget.rank}',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textMuted,
            ),
          ),
          const SizedBox(width: 12),

          // Pulsing status dot + label
          FadeTransition(
            opacity: _isOpen ? _pulseCtrl : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _isOpen ? _teal : _textMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _isOpen ? 'Open' : 'Closed',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _isOpen ? _teal : _textMuted,
              letterSpacing: 0.3,
            ),
          ),

          const Spacer(),

          // CTA
          _CTAButton(link: _applyLink, isClosed: !_isOpen),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CTA BUTTON
// ══════════════════════════════════════════════════════════════════════════

class _CTAButton extends StatefulWidget {
  final String link;
  final bool isClosed;

  const _CTAButton({required this.link, required this.isClosed});

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.96);
  void _onTapUp(TapUpDetails _)     => setState(() => _scale = 1.0);
  void _onTapCancel()               => setState(() => _scale = 1.0);

  Future<void> _launch() async {
    if (widget.isClosed || widget.link.trim().isEmpty) return;
    final uri = Uri.tryParse(widget.link);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const teal       = Color(0xFF14B8A6);
    const closedBg   = Color(0xFFEEEDEB);
    const closedText = Color(0xFF9CA3AF);

    return GestureDetector(
      onTapDown:   widget.isClosed ? null : _onTapDown,
      onTapUp:     widget.isClosed ? null : _onTapUp,
      onTapCancel: widget.isClosed ? null : _onTapCancel,
      onTap: _launch,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: widget.isClosed ? closedBg : teal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isClosed ? 'Applications Closed' : 'Apply Now',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: widget.isClosed ? closedText : Colors.white,
                ),
              ),
              if (!widget.isClosed) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}