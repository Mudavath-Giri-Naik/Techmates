import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';

class HeaderSection extends StatefulWidget {
  final DevCardModel devCard;
  final bool isDark;
  final String? userName;
  final String? college;
  final String? branch;
  final String? year;

  const HeaderSection({
    super.key,
    required this.devCard,
    required this.isDark,
    this.userName,
    this.college,
    this.branch,
    this.year,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get d => widget.isDark;
  Color get _cardBg => d ? const Color(0xFF0D1120) : Colors.white;
  Color get _text1 => d ? const Color(0xFFEDF2FF) : const Color(0xFF1A1A2E);
  Color get _text2 => d ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);
  Color get _borderCol => d ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);
  Color get _boxBg => d ? const Color(0xFF141E2F) : const Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final dc = widget.devCard;
    final sb = dc.scoreBreakdown;
    final displayName = widget.userName?.isNotEmpty == true
        ? widget.userName!
        : dc.githubUsername;

    return Container(
      padding: const EdgeInsets.all(16),
      color: _cardBg,
      child: Column(
        children: [
          // ─── Avatar + Identity + Score Ring ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar — top-aligned with padding to match text baseline
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: dc.githubAvatarUrl.isNotEmpty
                    ? Image.network(dc.githubAvatarUrl,
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(displayName))
                    : _initials(displayName),
                ),
              ),
              const SizedBox(width: 12),

              // Identity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(displayName,
                              style: TextStyle(
                                  color: _text1,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: d ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text('${sb.rankEmoji} ${sb.rank}',
                              style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                    Text('@${dc.githubUsername}',
                        style: TextStyle(
                            color: const Color(0xFF00D4FF),
                            fontSize: 10,
                            fontFamily: 'monospace')),
                    if (widget.branch?.isNotEmpty == true ||
                        widget.year?.isNotEmpty == true)
                      Text(
                        [
                          if (widget.branch?.isNotEmpty == true)
                            _extractAbbr(widget.branch!),
                          if (widget.year?.isNotEmpty == true) widget.year,
                        ].whereType<String>().join(' · '),
                        style: TextStyle(
                            color: _text2,
                            fontSize: 10),
                      ),
                    if (widget.college?.isNotEmpty == true)
                      Text(widget.college!,
                          style: TextStyle(
                              color: _text2, fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              // Score ring
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => _scoreRing(sb.total, _anim.value),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── 4 Sub-score bars (2×2) ─────────────────────────
          Row(children: [
            Expanded(
                child: _bar('Depth', sb.depth, const Color(0xFF00D4FF))),
            const SizedBox(width: 10),
            Expanded(
                child:
                    _bar('Craft', sb.consistency, const Color(0xFF8B5CF6))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
                child:
                    _bar('Deploy', sb.breadth, const Color(0xFF22C55E))),
            const SizedBox(width: 10),
            Expanded(
                child:
                    _bar('Consist', sb.activity, const Color(0xFFF59E0B))),
          ]),
        ],
      ),
    );
  }

  Widget _initials(String name) {
    final parts = name.split(' ');
    final ini = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, math.min(2, name.length)).toUpperCase();
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(ini,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800)),
    );
  }

  /// Extracts abbreviation from parentheses, e.g. "Computer Science (CSE)" → "CSE"
  String _extractAbbr(String text) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(text);
    if (match != null) return match.group(1)!;
    return text;
  }

  Widget _chip(String text, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: d ? 0.15 : 0.1) ??
            _boxBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: color?.withValues(alpha: 0.3) ?? _borderCol),
      ),
      child: Text(text,
          style: TextStyle(
              color: color ?? _text2,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace')),
    );
  }

  Widget _scoreRing(int score, double progress) {
    final fraction = (score / 1000).clamp(0.0, 1.0) * progress;
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _RingPainter(fraction, d),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$score',
                      style: TextStyle(
                          color: _text1,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  Text('/1000',
                      style: TextStyle(
                          color: _text2, fontSize: 7, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('DIC SCORE',
            style: TextStyle(
                color: _text2,
                fontSize: 7,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                letterSpacing: 1)),
      ],
    );
  }

  Widget _bar(String label, int value, Color color) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final animVal = (value / 100).clamp(0.0, 1.0) * _anim.value;
        return Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(label,
                  style: TextStyle(
                      color: _text2,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: _borderCol,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animVal,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 20,
              child: Text('$value',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _RingPainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = isDark ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [Color(0xFF00D4FF), Color(0xFF8B5CF6)],
      );
      final fgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);
      canvas.drawArc(
          rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
