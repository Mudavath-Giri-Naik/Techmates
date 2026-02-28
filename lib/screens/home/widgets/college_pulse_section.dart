import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_theme.dart';

/// Section 6 — College Pulse: overlapping avatars + student count.
class CollegePulseSection extends StatefulWidget {
  final int studentCount;
  final String collegeName;
  final List<Map<String, dynamic>> topStudents;
  final VoidCallback? onTap;

  const CollegePulseSection({
    super.key,
    required this.studentCount,
    required this.collegeName,
    required this.topStudents,
    this.onTap,
  });

  @override
  State<CollegePulseSection> createState() => _CollegePulseSectionState();
}

class _CollegePulseSectionState extends State<CollegePulseSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Google Brand Colors 
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleGreen = Color(0xFF34A853);

  static List<Color> _avatarColors() => [
        googleBlue,
        googleRed,
        googleGreen,
        googleYellow,
      ];

  @override
  Widget build(BuildContext context) {
    if (widget.studentCount == 0 || widget.collegeName.isEmpty) {
      return const SizedBox.shrink();
    }

    String shortCollege = widget.collegeName;
    if (shortCollege.length > 30) {
      shortCollege = '${shortCollege.substring(0, 27)}...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your College',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HomeTheme.onSurface(context),
                ),
              ),
              const SizedBox(width: 8),
              // Animated dot
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: googleGreen.withValues(alpha: 0.4 + (0.6 * _pulseCtrl.value)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                 return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HomeTheme.surfaceContainerLow(context), // Flat minimal background without borders or shadows
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: child,
                );
              },
              child: Row(
                children: [
                  // Overlapping avatars
                  SizedBox(
                    width: _calcAvatarWidth(),
                    height: 38,
                    child: Stack(
                      children: [
                        ...List.generate(
                          widget.topStudents.take(3).length,
                          (i) => Positioned(
                            left: i * 22.0,
                            child: _avatar(widget.topStudents[i], i, context),
                          ),
                        ),
                        if (widget.studentCount > 3)
                          Positioned(
                            left: widget.topStudents.take(3).length * 22.0,
                            child: _overflowCircle(widget.studentCount - 3, context),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 2,
                          text: TextSpan(
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: HomeTheme.onSurface(context),
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text: '${widget.studentCount} ',
                                style: const TextStyle(color: googleBlue),
                              ),
                              const TextSpan(text: 'students from '),
                              TextSpan(
                                text: shortCollege,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(text: ' on Techmates'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'View Leaderboard',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: HomeTheme.onSurfaceVariant(context),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: HomeTheme.onSurfaceVariant(context),
                            ),
                          ],
                        ),
                      ],
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

  double _calcAvatarWidth() {
    final count = widget.topStudents.take(3).length + (widget.studentCount > 3 ? 1 : 0);
    if (count <= 1) return 38;
    return 38 + (count - 1) * 22.0;
  }

  Widget _avatar(Map<String, dynamic> student, int index, BuildContext context) {
    final name = (student['name'] as String?) ?? '';
    final avatarUrl = student['avatar_url'] as String?;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = _avatarColors();
    final color = colors[index % colors.length];

    // Create a very subtle "Google" colored ring around each avatar
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2), // spacing for the colored ring
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HomeTheme.surfaceContainerLow(context), // Match background to simulate margin cutout
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15), // Very light inner backdrop
        ),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackInitials(initials, color),
                ),
              )
            : _fallbackInitials(initials, color),
      ),
    );
  }

  Widget _fallbackInitials(String initials, Color color) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _overflowCircle(int overflow, BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HomeTheme.surfaceContainerLow(context),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: googleYellow.withValues(alpha: 0.15),
        ),
        child: Center(
          child: Text(
            '+$overflow',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: googleYellow, // Vibrant text color on light backdrop
            ),
          ),
        ),
      ),
    );
  }
}
