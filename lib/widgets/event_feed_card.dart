import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/opportunity_feed_item.dart';
import 'internship_feed_card.dart';

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

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashH = 5.0;
    const gapH = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashH),
        paint,
      );
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class EventFeedCard extends StatefulWidget {
  final OpportunityFeedItem opportunity;
  const EventFeedCard({super.key, required this.opportunity});

  @override
  State<EventFeedCard> createState() => _EventFeedCardState();
}

class _EventFeedCardState extends State<EventFeedCard> {
  // Light
  static const lightBg = Color(0xFFF7F3EC);
  static const lightText = Color(0xFF111110);
  static const lightAccent = Color(0xFF0D4A42);
  static const lightMuted = Color(0xFFAAAAAA);
  static const lightRight = Color(0xFF0D4A42);
  static const lightRightText = Colors.white;

  // Dark
  static const darkBg = Color(0xFF111110);
  static const darkText = Color(0xFFF5F3EE);
  static const darkAccent = Color(0xFFC8A96E);
  static const darkMuted = Color(0x4DFFFFFF);
  static const darkRight = Color(0xFFC8A96E);
  static const darkRightText = Color(0xFF111110);

  bool get _useDark =>
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  String get _orgName {
    return widget.opportunity.event?.organiser != null &&
            widget.opportunity.event!.organiser.isNotEmpty
        ? widget.opportunity.event!.organiser
        : widget.opportunity.posterName ??
              widget.opportunity.posterUsername ??
              'TechMates';
  }

  String get _title => widget.opportunity.title;
  DateTime? get _startDate => widget.opportunity.event?.startDate;
  DateTime? get _endDate => widget.opportunity.event?.endDate;
  DateTime? get _deadline => widget.opportunity.event?.applyDeadline;
  String get _location => widget.opportunity.event?.venue ?? '—';
  String get _eligibility =>
      widget.opportunity.event?.eligible ?? 'All Students';

  bool get _isFree {
    final fee = widget.opportunity.event?.entryFee;
    if (fee == null || fee.trim().isEmpty) return true;
    if (fee.trim().toLowerCase() == 'free' || fee.trim() == '0') return true;
    return false;
  }

  int get _daysLeft {
    if (_deadline == null) return 0;
    final diff = _deadline!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  String get _applyLink =>
      widget.opportunity.applyLink ?? widget.opportunity.event?.applyLink ?? '';

  String _formatEventTitle(String title) {
    final words = title
        .toUpperCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length > 2) {
      return '${words[0]} ${words[1]}\n${words.sublist(2).join(' ')}';
    }
    return title.toUpperCase();
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'TBA';
    final s = DateFormat('MMM d').format(start);
    if (end == null || start.isAtSameMomentAs(end)) return s;
    final e = DateFormat('MMM d').format(end);
    return '$s - $e';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBA';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _serialNum() {
    final id = widget.opportunity.opportunityId;
    if (id.length >= 3) return id.substring(0, 3).toUpperCase();
    return '001';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0, // 1:1 square (1080×1080)
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _useDark ? darkBg : lightBg,
          borderRadius: BorderRadius.zero,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Grid painter behind everything
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(
                  lineColor: _useDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.055),
                ),
              ),
            ),
            // Decorative stars
            ..._buildStars(),
            // The ticket row
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLeft()),
                _buildSeparator(),
                _buildRight(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeft() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Org row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _useDark ? darkAccent : lightAccent,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _orgName.toUpperCase(),
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    letterSpacing: 2.0,
                    color: _useDark ? darkAccent : lightAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Big title — use Expanded + FittedBox for responsive sizing
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: Text(
                _formatEventTitle(_title),
                style: GoogleFonts.bebasNeue(
                  fontSize: 56,
                  letterSpacing: 1.5,
                  height: 0.92,
                  color: _useDark ? darkText : lightText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Subtitle
          Text(
            widget.opportunity.event?.source ?? 'Event',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: _useDark ? darkMuted : const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Thin divider
          Container(
            height: 1,
            color: _useDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 12),

          // 5. Meta grid (2x2)
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metaBlock(
                        'EVENT DATE',
                        _formatDateRange(_startDate, _endDate),
                      ),
                    ),
                    Expanded(child: _metaBlock('DEADLINE', _formatDate(_deadline))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _metaBlock('LOCATION', _location)),
                    Expanded(child: _metaBlock('OPEN TO', _eligibility)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 6. Entry badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: _useDark ? darkAccent : lightAccent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
              color: _useDark ? darkAccent : Colors.transparent,
            ),
            child: Text(
              _isFree ? 'FREE ENTRY' : 'PAID',
              style: GoogleFonts.dmMono(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
                color: _useDark ? const Color(0xFF111110) : lightAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 9,
            letterSpacing: 1.6,
            color: _useDark ? darkMuted : lightMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: _useDark ? darkAccent : lightAccent,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return SizedBox(
      width: 2,
      child: CustomPaint(
        painter: DashedLinePainter(
          color: _useDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.12),
        ),
      ),
    );
  }

  Widget _buildRight() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: _useDark ? darkRight : lightRight,
        borderRadius: BorderRadius.zero,
      ),
      child: Stack(
        children: [
          // Grid painter on right panel
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                lineColor: _useDark
                    ? Colors.black.withOpacity(0.055)
                    : Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Serial number
              Text(
                'NO. ${_serialNum()}',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: (_useDark ? Colors.black : Colors.white).withOpacity(
                    0.4,
                  ),
                ),
              ),

              // Days left number
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _daysLeft.toString(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 56,
                          height: 1,
                          color: _useDark ? darkRightText : lightRightText,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'DAYS\nLEFT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      height: 1.4,
                      color: (_useDark ? Colors.black : Colors.white)
                          .withOpacity(0.55),
                    ),
                  ),
                ],
              ),

              // Bar ticks
              _buildBarTicks(_daysLeft),

              // Apply button
              GestureDetector(
                onTap: () async {
                  if (_applyLink.isNotEmpty) {
                    final url = Uri.parse(_applyLink);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (_useDark ? Colors.black : Colors.white)
                          .withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: (_useDark ? Colors.black : Colors.white).withOpacity(
                      0.15,
                    ),
                  ),
                  child: Text(
                    'APPLY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: _useDark ? darkRightText : lightRightText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Rotated label
          Positioned(
            right: -28,
            top: 0,
            bottom: 0,
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'TechMates · 2026',
                  style: GoogleFonts.dmMono(
                    fontSize: 7.5,
                    letterSpacing: 2,
                    color: (_useDark ? Colors.black : Colors.white).withOpacity(
                      0.25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarTicks(int daysLeft) {
    int filled = (daysLeft / 30 * 5).round().clamp(0, 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        final heights = [20.0, 24.0, 28.0, 22.0, 26.0];
        final isFilled = i < filled;
        return Container(
          width: 4,
          height: heights[i],
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isFilled
                ? (_useDark
                      ? Colors.black.withOpacity(0.55)
                      : Colors.white.withOpacity(0.7))
                : (_useDark
                      ? Colors.black.withOpacity(0.15)
                      : Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  List<Widget> _buildStars() {
    final color = _useDark
        ? const Color(0xFFC8A96E).withOpacity(0.25)
        : const Color(0xFF0D4A42).withOpacity(0.2);
    return [
      _star(top: 22, right: 140, size: 16, color: color),
      _star(top: 60, left: 22, size: 11, color: color),
      _star(bottom: 28, left: 90, size: 13, color: color),
      _star(bottom: 34, right: 145, size: 11, color: color),
    ];
  }

  Widget _star({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Text(
        '✦',
        style: TextStyle(fontSize: size, color: color, height: 1),
      ),
    );
  }
}
