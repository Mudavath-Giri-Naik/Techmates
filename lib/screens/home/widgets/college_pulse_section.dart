import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_theme.dart';

/// Section 6 — College Pulse: overlapping avatars + student count.
class CollegePulseSection extends StatelessWidget {
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

  static List<Color> _avatarColors(BuildContext context) => [
        HomeTheme.primary(context),
        const Color(0xFFE8651A), // HomeTheme.accentOrange
        const Color(0xFF1A7A4A), // HomeTheme.accentGreen
      ];

  @override
  Widget build(BuildContext context) {
    if (studentCount == 0 || collegeName.isEmpty) return const SizedBox.shrink();

    String shortCollege = collegeName;
    if (shortCollege.length > 30) {
      // Just truncate if excessively long
      shortCollege = '${shortCollege.substring(0, 27)}...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your College',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: HomeTheme.onSurface(context),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HomeTheme.surfaceContainer(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HomeTheme.outlineVariant(context), width: 1),
              ),
              child: Row(
                children: [
                  // Overlapping avatars
                  SizedBox(
                    width: _calcAvatarWidth(),
                    height: 34,
                    child: Stack(
                      children: [
                        ...List.generate(
                          topStudents.take(3).length,
                          (i) => Positioned(
                            left: i * 20.0,
                            child: _avatar(topStudents[i], i, context),
                          ),
                        ),
                        if (studentCount > 3)
                          Positioned(
                            left: topStudents.take(3).length * 20.0,
                            child: _overflowCircle(studentCount - 3, context),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$studentCount students from $shortCollege on Techmates',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: HomeTheme.onSurface(context),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View College Leaderboard →',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: HomeTheme.primary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: HomeTheme.onSurfaceVariant(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calcAvatarWidth() {
    final count = topStudents.take(3).length + (studentCount > 3 ? 1 : 0);
    if (count <= 1) return 34;
    return 34 + (count - 1) * 20.0;
  }

  Widget _avatar(Map<String, dynamic> student, int index, BuildContext context) {
    final name = (student['name'] as String?) ?? '';
    final avatarUrl = student['avatar_url'] as String?;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = _avatarColors(context);
    final color = colors[index % colors.length];

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: HomeTheme.surfaceContainer(context), width: 2.5),
      ),
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 29,
                height: 29,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _overflowCircle(int overflow, BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HomeTheme.surfaceContainerHigh(context),
        border: Border.all(color: HomeTheme.surfaceContainer(context), width: 2.5),
      ),
      child: Center(
        child: Text(
          '+$overflow',
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: HomeTheme.onSurfaceVariant(context),
          ),
        ),
      ),
    );
  }
}
