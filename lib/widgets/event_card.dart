import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

// NOTE: Ensure you import your specific models/services here
import '../models/event_details_model.dart';
import '../services/bookmark_service.dart';
import '../utils/opportunity_options_sheet.dart';

class EventCard extends StatefulWidget {
  final EventDetailsModel event;
  final int? serialNumber;
  final bool isHighlighted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.serialNumber,
    this.isHighlighted = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isSaved = false;

  // ── Design System ──────────────────────────────────────────────────────────
  // The palette is built around aged ivory, deep charcoal ink, and a single
  // warm-amber accent — evoking a quality printed ticket with brass hardware.

  static const Color _surface      = Color(0xFFFAF8F4); // Aged ivory / warm paper
  static const Color _stubSurface  = Color(0xFFF3F0EA); // Slightly darker stub
  static const Color _inkDeep      = Color(0xFF1C1C1E); // Near-black for headings
  static const Color _inkMid       = Color(0xFF5C5C5E); // Mid-grey for labels
  static const Color _inkFaint     = Color(0xFFB0AAA0); // Faint for dividers / tertiary
  static const Color _amber        = Color(0xFFC8862A); // Warm amber accent
  static const Color _danger       = Color(0xFFA0291E); // Muted red for urgency
  static const Color _success      = Color(0xFF2A6B3E); // Forest green for healthy
  static const Color _border       = Color(0xFFD8D2C8); // Ticket outline

  // ── Typography ────────────────────────────────────────────────────────────
  // Playfair Display → expressive editorial display
  // Courier Prime    → authentic ticket mono for codes & numbers
  // Add to pubspec.yaml:
  //   google_fonts: ^6.x
  // Then: import 'package:google_fonts/google_fonts.dart';
  // Replace TextStyle references below with GoogleFonts calls if desired.
  // Currently using named fontFamilies as fallback strings — replace as needed.

  TextStyle get _styleTitle => const TextStyle(
    fontFamily: 'PlayfairDisplay', // GoogleFonts.playfairDisplay()
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: _inkDeep,
    height: 1.15,
    letterSpacing: -0.2,
  );

  TextStyle get _styleMicro => const TextStyle(
    fontFamily: 'CourierPrime',    // GoogleFonts.courierPrime()
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: _inkMid,
  );

  TextStyle get _styleData => const TextStyle(
    fontFamily: 'CourierPrime',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _inkDeep,
    letterSpacing: 0.2,
  );

  TextStyle get _styleVenue => const TextStyle(
    fontFamily: 'CourierPrime',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: _inkMid,
    letterSpacing: 0.1,
  );

  // ── State & Init ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _isSaved = _bookmarkService.isBookmarked(widget.event.opportunityId);
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.event);
    setState(() {
      _isSaved = _bookmarkService.isBookmarked(widget.event.opportunityId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSaved ? 'Saved to collection' : 'Removed from collection',
            style: const TextStyle(
              fontFamily: 'CourierPrime',
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _inkDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'TBA';
    final f = DateFormat('MMM d');
    if (end == null || start == end) return f.format(start);
    return '${f.format(start)} – ${f.format(end)}';
  }

  // ── Status helpers ────────────────────────────────────────────────────────
  _StatusConfig _getStatus(int daysLeft) {
    if (daysLeft < 0)  return _StatusConfig('CLOSED',    _inkFaint);
    if (daysLeft == 0) return _StatusConfig('LAST CALL', _danger);
    if (daysLeft <= 5) return _StatusConfig('$daysLeft DAYS', _danger);
    return _StatusConfig('$daysLeft DAYS', _success);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final deadline = widget.event.applyDeadline;
    final daysLeft = deadline.difference(today).inDays;
    final status   = _getStatus(daysLeft);

    final bool isFree = widget.event.entryFee == null ||
        widget.event.entryFee!.isEmpty ||
        widget.event.entryFee == 'Free';

    // Serial string e.g. "001"
    final String serial = widget.serialNumber != null
        ? widget.serialNumber!.toString().padLeft(3, '0')
        : '001';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Drop-shadow that mimics a slightly lifted card on a table
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TicketPainter(
          borderColor: _border,
          stubLineColor: _inkFaint.withOpacity(0.6),
        ),
        child: ClipPath(
          clipper: _TicketClipper(),
          child: SizedBox(
            height: 186,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── LEFT — Main body ─────────────────────────────────────
                Expanded(
                  flex: 68,
                  child: Container(
                    color: _surface,
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Organiser + fee badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                (widget.event.organiser ?? 'ORGANISER').toUpperCase(),
                                style: _styleMicro,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FeaturePill(
                              label: isFree ? 'FREE' : widget.event.entryFee!,
                              textStyle: _styleMicro.copyWith(
                                fontSize: 8,
                                color: isFree ? _success : _amber,
                              ),
                              borderColor: isFree
                                  ? _success.withOpacity(0.35)
                                  : _amber.withOpacity(0.35),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Row 2: Title
                        Text(
                          widget.event.title ?? 'Untitled Event',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _styleTitle,
                        ),

                        const SizedBox(height: 8),

                        // Row 3: Venue
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: _inkFaint,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.venue ?? 'Venue TBA',
                                style: _styleVenue,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Thin divider
                        Container(height: 1, color: _border),

                        const SizedBox(height: 10),

                        // Row 4: Date / Deadline columns
                        Row(
                          children: [
                            _InfoColumn(
                              label: 'EVENT DATE',
                              value: _formatDateRange(
                                widget.event.startDate,
                                widget.event.endDate,
                              ),
                              labelStyle: _styleMicro.copyWith(fontSize: 8),
                              valueStyle: _styleData,
                            ),
                            const SizedBox(width: 20),
                            _InfoColumn(
                              label: 'DEADLINE',
                              value: DateFormat('MMM d').format(deadline),
                              labelStyle: _styleMicro.copyWith(fontSize: 8),
                              valueStyle: _styleData.copyWith(
                                color: status.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── RIGHT — Stub ─────────────────────────────────────────
                Expanded(
                  flex: 32,
                  child: Container(
                    color: _stubSurface,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top: serial
                        Text(
                          'NO. $serial',
                          style: _styleMicro.copyWith(
                            color: _inkFaint,
                            letterSpacing: 1.4,
                          ),
                        ),

                        // Middle: status + mini barcode
                        Column(
                          children: [
                            // Status label
                            Text(
                              status.text,
                              textAlign: TextAlign.center,
                              style: _styleMicro.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                                color: status.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LEFT',
                              textAlign: TextAlign.center,
                              style: _styleMicro.copyWith(
                                fontSize: 7,
                                color: _inkFaint,
                                letterSpacing: 2.0,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Mini decorative barcode
                            _MiniBarcode(color: _inkFaint.withOpacity(0.55)),
                          ],
                        ),

                        // Bottom: action icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.onEdit != null) ...[
                              _StubIcon(
                                icon: Icons.tune,
                                onTap: () => showOpportunityOptions(
                                  context,
                                  onEdit: widget.onEdit!,
                                  onDelete: widget.onDelete!,
                                  title: widget.event.title,
                                  subtitle: widget.event.organiser,
                                ),
                              ),
                            ] else ...[
                              _StubIcon(
                                icon: Icons.arrow_outward_rounded,
                                onTap: () => _launchURL(widget.event.applyLink),
                              ),
                            ],
                            const SizedBox(width: 14),
                            _StubIcon(
                              icon: _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              onTap: _toggleBookmark,
                              color: _isSaved ? _amber : _inkMid,
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
        ),
      ),
    );
  }
}

// ── Helper sub-widgets ────────────────────────────────────────────────────────

/// Small pill badge (FREE, ₹500, etc.)
class _FeaturePill extends StatelessWidget {
  final String label;
  final TextStyle textStyle;
  final Color borderColor;

  const _FeaturePill({
    required this.label,
    required this.textStyle,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label.toUpperCase(), style: textStyle),
    );
  }
}

/// Labelled value column (Date, Deadline, etc.)
class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 3),
        Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Pressable icon in the stub area
class _StubIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _StubIcon({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF1C1C1E),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Decorative barcode made of random-width vertical lines
class _MiniBarcode extends StatelessWidget {
  final Color color;
  const _MiniBarcode({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 22),
      painter: _BarcodePainter(color: color),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final Color color;
  // Fixed pattern — no randomness so it stays deterministic across repaints
  static const List<double> _pattern = [
    2, 1, 3, 1, 2, 2, 1, 3, 1, 1, 2, 1, 3, 2, 1, 2, 1, 1, 3, 1,
  ];

  const _BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final double totalUnits = _pattern.fold(0.0, (a, b) => a + b) + _pattern.length;
    final double unitW = size.width / totalUnits;

    double x = 0;
    for (int i = 0; i < _pattern.length; i++) {
      final double barW = _pattern[i] * unitW;
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), paint);
      }
      x += barW + unitW; // unitW gap
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Ticket Shape Helpers ──────────────────────────────────────────────────────

class _StatusConfig {
  final String text;
  final Color color;
  const _StatusConfig(this.text, this.color);
}

/// Clips the widget into a ticket shape with notches at the perforation line
class _TicketClipper extends CustomClipper<Path> {
  static const double _cornerR  = 10;
  static const double _notchR   = 9;
  static const double _stubFrac = 0.685; // stub starts at 68.5% of width

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w * _stubFrac; // x of perforation

    final path = Path();

    // Top edge: left corner → notch cutout → right corner
    path.moveTo(_cornerR, 0);
    path.lineTo(sx - _notchR, 0);
    path.arcToPoint(Offset(sx + _notchR, 0),
        radius: Radius.circular(_notchR), clockwise: false);
    path.lineTo(w - _cornerR, 0);
    path.arcToPoint(Offset(w, _cornerR),
        radius: const Radius.circular(_cornerR));

    // Right edge
    path.lineTo(w, h - _cornerR);
    path.arcToPoint(Offset(w - _cornerR, h),
        radius: const Radius.circular(_cornerR));

    // Bottom edge: right → notch → left
    path.lineTo(sx + _notchR, h);
    path.arcToPoint(Offset(sx - _notchR, h),
        radius: Radius.circular(_notchR), clockwise: false);
    path.lineTo(_cornerR, h);
    path.arcToPoint(Offset(0, h - _cornerR),
        radius: const Radius.circular(_cornerR));

    // Left edge
    path.lineTo(0, _cornerR);
    path.arcToPoint(Offset(_cornerR, 0),
        radius: const Radius.circular(_cornerR));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

/// Draws the outer ticket border + the dashed perforation line
class _TicketPainter extends CustomPainter {
  final Color borderColor;
  final Color stubLineColor;

  static const double _cornerR  = 10;
  static const double _notchR   = 9;
  static const double _stubFrac = 0.685;

  const _TicketPainter({
    required this.borderColor,
    required this.stubLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final sx = w * _stubFrac;

    // ── Outer border ────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..color       = borderColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(_cornerR, 0);
    path.lineTo(sx - _notchR, 0);
    path.arcToPoint(Offset(sx + _notchR, 0),
        radius: Radius.circular(_notchR), clockwise: false);
    path.lineTo(w - _cornerR, 0);
    path.arcToPoint(Offset(w, _cornerR),
        radius: const Radius.circular(_cornerR));
    path.lineTo(w, h - _cornerR);
    path.arcToPoint(Offset(w - _cornerR, h),
        radius: const Radius.circular(_cornerR));
    path.lineTo(sx + _notchR, h);
    path.arcToPoint(Offset(sx - _notchR, h),
        radius: Radius.circular(_notchR), clockwise: false);
    path.lineTo(_cornerR, h);
    path.arcToPoint(Offset(0, h - _cornerR),
        radius: const Radius.circular(_cornerR));
    path.lineTo(0, _cornerR);
    path.arcToPoint(Offset(_cornerR, 0),
        radius: const Radius.circular(_cornerR));

    canvas.drawPath(path, borderPaint);

    // ── Dashed perforation line ─────────────────────────────────────────────
    const double dashH   = 5.0;
    const double gapH    = 4.0;
    final double topY    = _notchR + 4;
    final double bottomY = h - _notchR - 4;

    final dashPaint = Paint()
      ..color       = stubLineColor
      ..strokeWidth = 1.0
      ..strokeCap   = StrokeCap.round;

    double y = topY;
    while (y < bottomY) {
      canvas.drawLine(
        Offset(sx, y),
        Offset(sx, math.min(y + dashH, bottomY)),
        dashPaint,
      );
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}