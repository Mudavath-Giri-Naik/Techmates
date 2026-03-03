import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../services/bookmark_service.dart';
import '../home_theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Per-card accent palettes — rotate on each transition
// ──────────────────────────────────────────────────────────────────────────────
class _CardAccent {
  final Color bg;           // main colored background
  final Color bgDeep;       // slightly deeper shade for bottom section
  final Color badgeBg;      // top-right badge fill
  final Color badgeText;    // top-right badge text
  final Color italicText;   // italic subtitle color
  final Color ctaBg;        // "Apply Now" button
  final Color ctaText;

  const _CardAccent({
    required this.bg,
    required this.bgDeep,
    required this.badgeBg,
    required this.badgeText,
    required this.italicText,
    required this.ctaBg,
    required this.ctaText,
  });
}

const _kAccents = <_CardAccent>[
  // Coral / orange  (matches reference)
  _CardAccent(
    bg: Color(0xFFE8572A),
    bgDeep: Color(0xFFCC4A20),
    badgeBg: Color(0xFF4CAF50),
    badgeText: Colors.white,
    italicText: Color(0xFFE8572A),
    ctaBg: Color(0xFF1A1A1A),
    ctaText: Colors.white,
  ),
  // Deep blue
  _CardAccent(
    bg: Color(0xFF1B4FD8),
    bgDeep: Color(0xFF1440B0),
    badgeBg: Color(0xFFFBBF24),
    badgeText: Color(0xFF1A0A00),
    italicText: Color(0xFF1B4FD8),
    ctaBg: Color(0xFF1A1A1A),
    ctaText: Colors.white,
  ),
  // Violet
  _CardAccent(
    bg: Color(0xFF7C3AED),
    bgDeep: Color(0xFF6027CC),
    badgeBg: Color(0xFFEC4899),
    badgeText: Colors.white,
    italicText: Color(0xFF7C3AED),
    ctaBg: Color(0xFF1A1A1A),
    ctaText: Colors.white,
  ),
  // Emerald
  _CardAccent(
    bg: Color(0xFF059669),
    bgDeep: Color(0xFF047857),
    badgeBg: Color(0xFFF59E0B),
    badgeText: Color(0xFF1A0A00),
    italicText: Color(0xFF047857),
    ctaBg: Color(0xFF1A1A1A),
    ctaText: Colors.white,
  ),
  // Crimson
  _CardAccent(
    bg: Color(0xFFDC2626),
    bgDeep: Color(0xFFB91C1C),
    badgeBg: Color(0xFFFBBF24),
    badgeText: Color(0xFF1A0A00),
    italicText: Color(0xFFDC2626),
    ctaBg: Color(0xFF1A1A1A),
    ctaText: Colors.white,
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// Main Section Widget
// ──────────────────────────────────────────────────────────────────────────────
class ElitePicksSection extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const ElitePicksSection({super.key, required this.items});

  @override
  State<ElitePicksSection> createState() => _ElitePicksSectionState();
}

class _ElitePicksSectionState extends State<ElitePicksSection>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Original pulse controller kept for FEATURED badge
  late AnimationController _pulseCtrl;
  final _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    // Reuse pulse animation for badge
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _animCtrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _advance());
  }

  void _advance() {
    if (!mounted) return;
    _animCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.items.length;
      });
      _animCtrl.forward();
    });
  }

  void _jumpTo(int idx) {
    if (idx == _currentIndex || !mounted) return;
    _timer?.cancel();
    _animCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentIndex = idx);
      _animCtrl.forward();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final item = widget.items[_currentIndex];
    final accent = _kAccents[_currentIndex % _kAccents.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Elite Picks',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.onSurface(context),
                ),
              ),
              // Pulsing FEATURED badge (original behaviour preserved)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final scale = 1.0 + 0.08 * _pulseCtrl.value;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: HomeTheme.primaryContainer(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('★',
                              style: TextStyle(
                                  color: HomeTheme.onPrimaryContainer(context),
                                  fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            'FEATURED',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HomeTheme.onPrimaryContainer(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Animated card ────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _EliteCard(
                item: item,
                accent: accent,
                bookmarkService: _bookmarkService,
                onBookmarkChanged: () => setState(() {}),
              ),
            ),
          ),

          // ── Dot indicators ───────────────────────────────────
          if (widget.items.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final isActive = i == _currentIndex;
                final dotColor =
                    _kAccents[i % _kAccents.length].bg;
                return GestureDetector(
                  onTap: () => _jumpTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: isActive ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? dotColor
                          : dotColor.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Card — matches reference image layout 1:1
// ──────────────────────────────────────────────────────────────────────────────
class _EliteCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final _CardAccent accent;
  final BookmarkService bookmarkService;
  final VoidCallback onBookmarkChanged;

  const _EliteCard({
    required this.item,
    required this.accent,
    required this.bookmarkService,
    required this.onBookmarkChanged,
  });

  // ── Data helpers ────────────────────────────────────────────

  String get _opportunityId => (item['opportunity_id'] ?? '').toString();
  String get _company => (item['company'] as String?) ?? '';
  String get _title => (item['title'] as String?) ?? 'Untitled';
  String get _empType => (item['emp_type'] as String?) ?? '';
  String get _duration => (item['duration'] as String?) ?? '';
  String get _link => (item['link'] as String?) ?? '';

  /// "• Full Time  ·  3 months •" row label
  String get _labelRow {
    final parts = <String>[];
    if (_empType.isNotEmpty) parts.add(_empType);
    if (_duration.isNotEmpty) parts.add(_duration);
    if (parts.isEmpty) return 'Internship / Opportunity';
    return parts.join('  ·  ');
  }

  /// Italic subtitle — company name styled as in reference
  String get _italicSubtitle {
    if (_company.isNotEmpty) return _company;
    return 'curated for top students';
  }

  /// Formatted stipend
  String get _stipendMain {
    final stipend = item['stipend'];
    if (stipend != null && stipend is num && stipend > 0) {
      try {
        return '₹${NumberFormat('#,##,###').format(stipend)}';
      } catch (_) {
        return '₹$stipend';
      }
    }
    return 'Apply';
  }

  String get _stipendSub {
    final stipend = item['stipend'];
    if (stipend != null && stipend is num && stipend > 0) return '/ month';
    return 'for free';
  }

  /// Badge text — deadline or type-based
  String get _badgeText {
    final deadlineStr = (item['deadline'] ?? '').toString();
    final deadline = DateTime.tryParse(deadlineStr);
    if (deadline != null) {
      final diff = deadline.difference(DateTime.now()).inDays;
      if (diff <= 0) return 'Closes today';
      if (diff == 1) return '1 day left';
      if (diff <= 7) return '$diff days left';
      try { return 'By ${DateFormat('MMM d').format(deadline)}'; } catch (_) {}
    }
    return 'Elite Pick';
  }

  /// Mini-card right side
  String get _miniCardHeadline {
    final deadlineStr = (item['deadline'] ?? '').toString();
    final deadline = DateTime.tryParse(deadlineStr);
    if (deadline != null) {
      try {
        return 'Deadline: ${DateFormat('MMM d, yyyy').format(deadline)}';
      } catch (_) {}
    }
    return 'Not sure if this fits your needs?';
  }

  /// Feature bullets — tags + derived
  List<String> _buildFeatures() {
    final list = <String>[];
    final rawTags = item['tags'];
    if (rawTags is List) {
      for (final t in rawTags) {
        final s = t?.toString() ?? '';
        if (s.isNotEmpty) list.add(s);
      }
    }
    // Derived from type
    final type = _empType.toLowerCase();
    if (type.contains('intern')) {
      _addIfAbsent(list, ['Industry mentorship', 'Work certificate',
          'Resume builder', 'Peer networking', 'Flexible hours', 'Skill growth']);
    } else if (type.contains('hack') || type.contains('compet')) {
      _addIfAbsent(list, ['Team collaboration', 'Cash prizes',
          'Expert judges', 'Swag & goodies', 'Career exposure', 'Portfolio boost']);
    } else {
      _addIfAbsent(list, ['Curated for you', 'High impact',
          'Skill builder', 'Peer network', 'Certificate', 'Career growth']);
    }
    return list.take(6).toList();
  }

  void _addIfAbsent(List<String> list, List<String> extras) {
    for (final e in extras) {
      if (list.length < 6 && !list.contains(e)) list.add(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBookmarked = bookmarkService.isBookmarked(_opportunityId);
    final features = _buildFeatures();
    // Half for each column
    final half = (features.length / 2).ceil();
    final leftFeatures = features.take(half).toList();
    final rightFeatures = features.skip(half).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: accent.bg,
        child: Stack(
          children: [
            // Decorative radial highlight top-right
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ════════════════════════════════════════════
                // WHITE FLOATING CARD
                // ════════════════════════════════════════════
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row 1: label dots + badge ──────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Dot
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(
                                  color: accent.bg, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          // Label
                          Expanded(
                            child: Text(
                              _labelRow,
                              style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B7280),
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 5),
                          // Dot
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(
                                  color: accent.bg, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _badgeText,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accent.badgeText,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Title (bold, large) ─────────────────
                      Text(
                        _title,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111827),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // ── Italic subtitle (company / tagline) ─
                      Text(
                        _italicSubtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: accent.italicText,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 14),

                      // ── Bottom row: stipend + CTA  |  mini card ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left: stipend + Apply Now
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stipend
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _stipendMain,
                                        style: GoogleFonts.nunito(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF111827),
                                          height: 1.0,
                                          letterSpacing: -1.2,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' $_stipendSub',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Apply Now pill
                                GestureDetector(
                                  onTap: () async {
                                    if (_link.isNotEmpty) {
                                      final uri = Uri.tryParse(_link);
                                      if (uri != null) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: accent.ctaBg,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      'Apply Now',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: accent.ctaText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Right: mini card (deadline / bookmark)
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon circle
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: accent.bg.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      size: 14,
                                      color: accent.bg,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  Text(
                                    _miniCardHeadline,
                                    style: GoogleFonts.nunito(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF374151),
                                      height: 1.25,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 8),

                                  // Bookmark / Save button
                                  GestureDetector(
                                    onTap: () {
                                      bookmarkService.toggleBookmarkById(
                                          _opportunityId);
                                      onBookmarkChanged();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isBookmarked
                                            ? accent.bg.withOpacity(0.1)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isBookmarked
                                              ? accent.bg.withOpacity(0.4)
                                              : const Color(0xFFE5E7EB),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isBookmarked
                                                ? Icons.bookmark_rounded
                                                : Icons.bookmark_border_rounded,
                                            size: 12,
                                            color: isBookmarked
                                                ? accent.bg
                                                : const Color(0xFF374151),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isBookmarked ? 'Saved' : 'Save',
                                            style: GoogleFonts.nunito(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isBookmarked
                                                  ? accent.bg
                                                  : const Color(0xFF374151),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ════════════════════════════════════════════
                // COLORED BOTTOM — feature checklist
                // ════════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: leftFeatures
                              .map((f) => _featureTile(f))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: rightFeatures
                              .map((f) => _featureTile(f))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTile(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circle check icon
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 11, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.93),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}