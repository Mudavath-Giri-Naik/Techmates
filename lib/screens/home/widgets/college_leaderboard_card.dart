import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/devcard/devcard_model.dart';
import '../home_theme.dart';

/// Section 2 — College Leaderboard Spotlight.
/// Premium light-themed hero card that auto-cycles through top 3 students.
class CollegeLeaderboardCard extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final String collegeName;
  final bool isLoading;
  final VoidCallback? onFullBoard;

  const CollegeLeaderboardCard({
    super.key,
    required this.students,
    required this.collegeName,
    this.isLoading = false,
    this.onFullBoard,
  });

  @override
  State<CollegeLeaderboardCard> createState() => _CollegeLeaderboardCardState();
}

class _CollegeLeaderboardCardState extends State<CollegeLeaderboardCard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _cycleTimer;
  late AnimationController _ringCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _glowPulseCtrl;

  @override
  void initState() {
    super.initState();
    // Rotating avatar ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Entrance slide-up + fade
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Ambient glow pulse
    _glowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entranceCtrl.forward();
    });

    _startCycling();
  }

  void _startCycling() {
    _cycleTimer?.cancel();
    if (widget.students.length > 1) {
      _cycleTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (mounted && widget.students.isNotEmpty) {
          setState(() =>
              _currentIndex = (_currentIndex + 1) % widget.students.length);
        }
      });
    }
  }

  @override
  void didUpdateWidget(CollegeLeaderboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students.length != widget.students.length) {
      _currentIndex = 0;
      _startCycling();
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _ringCtrl.dispose();
    _entranceCtrl.dispose();
    _glowPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildShimmer();
    if (widget.students.isEmpty) return _buildEmptyState();

    final student = widget.students[_currentIndex];

    return FadeTransition(
      opacity: _entranceCtrl,
      child: AnimatedBuilder(
        animation: _entranceCtrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - Curves.easeOutCubic.transform(_entranceCtrl.value))),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.only(
                    left: 2, right: 0, bottom: 10, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Text('🏆', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Top at ${widget.collegeName}',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HomeTheme.onSurface(context),
                        ),
                      ),
                    ]),
                    GestureDetector(
                      onTap: widget.onFullBoard,
                      child: Text(
                        'Full Board',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HomeTheme.primary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main card
              AnimatedBuilder(
                animation: _glowPulseCtrl,
                builder: (_, child) {
                  final glowOpacity =
                      0.15 + 0.12 * _glowPulseCtrl.value;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _rankAccent(
                                  (student['collegeRank'] as int?) ?? 1)
                              .withOpacity(glowOpacity),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF6750A4)
                              .withValues(alpha: glowOpacity * 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 210,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF8F0FF), // very light lavender
                          Color(0xFFEDE7FB), // soft purple tint
                          Color(0xFFF0E8FF), // warm violet cloud
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xFFD0BCFF).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Ambient radial glow top-left (warm gold / rank color)
                        Positioned(
                          top: -40,
                          left: -30,
                          child: AnimatedBuilder(
                            animation: _glowPulseCtrl,
                            builder: (_, __) => Opacity(
                              opacity: 0.3 + 0.15 * _glowPulseCtrl.value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    _rankAccent(
                                        (student['collegeRank'] as int?) ??
                                            1)
                                        .withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Ambient radial glow bottom-right (purple)
                        Positioned(
                          bottom: -50,
                          right: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                const Color(0xFF6750A4).withOpacity(0.12),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                        // Foreground content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildLeftContent(student)),
                              const SizedBox(width: 10),
                              _buildRightContent(student),
                            ],
                          ),
                        ),
                        // Big Rank Number at bottom right (replacing pagination dots)
                        Positioned(
                          bottom: 12,
                          right: 16,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            child: ShaderMask(
                              key: ValueKey('rank_${student['collegeRank']}'),
                              shaderCallback: (bounds) => LinearGradient(
                                colors: _rankGradient((student['collegeRank'] as int?) ?? 1),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                '#${student['collegeRank'] ?? 1}',
                                style: GoogleFonts.outfit(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2.0,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // "YOU" badge if current user
                        if ((student['isCurrentUser'] as bool?) == true)
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6750A4),
                                    Color(0xFF9A82DB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6750A4)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '✨ You',
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftContent(Map<String, dynamic> student) {
    final name = (student['name'] as String?) ?? '';
    final branch = (student['branch'] as String?) ?? '';
    final year = (student['year'] as String?) ?? '';
    final score = (student['score'] as int?) ?? 0;
    // Normalize global score (0-1000) down to UI index (0-100)
    final rankInfo = DevScoreBreakdown.rankInfoFromScore((score / 10).round());
    final rank = rankInfo['rank'] ?? 'Beginner';
    final hexCode = (rankInfo['color'] ?? '#9E9E9E').replaceAll('#', '');
    final fg = Color(int.parse('FF$hexCode', radix: 16));
    final bg = fg.withValues(alpha: 0.12);
    final commits = (student['commits'] as int?) ?? 0;
    final repos = (student['repos'] as int?) ?? 0;
    final collegeRank = (student['collegeRank'] as int?) ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rank badge + COLLEGE LEADERBOARD
        // Rank badge + COLLEGE LEADERBOARD
        // COLLEGE LEADERBOARD label at top left
        Row(
          children: [
            Text(
              'COLLEGE LEADERBOARD',
              style: GoogleFonts.nunito(
                color: HomeTheme.onSurface(context).withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Name with animated transition
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween(begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(anim),
              child: child,
            ),
          ),
          child: FittedBox(
            key: ValueKey('name_$name'),
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: HomeTheme.onSurface(context),
                letterSpacing: -0.5,
                height: 1.1,
              ),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: 3),
        // Branch + Year
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: Text(
            '${_shortenBranch(branch)}  ·  $year',
            key: ValueKey('branch_$name'),
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: HomeTheme.onSurfaceVariant(context),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // GitHub rank chip
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: Container(
            key: ValueKey('rank_$name'),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: fg.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rankInfo['emoji'] ?? '🌱',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 5),
                Text(
                  rank,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Divider before stats
        Container(
          height: 1,
          width: double.infinity,
          color: HomeTheme.outlineVariant(context).withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 8),
        ),
        // Stats row
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: Row(
            key: ValueKey('stats_$name'),
            children: [
              _miniStat(context, '$score', 'Score'),
              _vDivider(context),
              _miniStat(context, '$commits', 'Commits'),
              _vDivider(context),
              _miniStat(context, '$repos', 'Repos'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightContent(Map<String, dynamic> student) {
    final name = (student['name'] as String?) ?? '';
    final avatarUrl = student['avatarUrl'] as String?;
    final collegeRank = (student['collegeRank'] as int?) ?? 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated rotating ring with rank-colored gradient
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _ringCtrl.value * 2 * pi,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        _rankAccent(collegeRank).withValues(alpha: 0),
                        _rankAccent(collegeRank),
                        _rankAccent(collegeRank).withValues(alpha: 0.5),
                        const Color(0xFFD0BCFF),
                        _rankAccent(collegeRank).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // White gap ring
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F0FF),
                boxShadow: [
                  BoxShadow(
                    color:
                        _rankAccent(collegeRank).withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Avatar
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: CircleAvatar(
                key: ValueKey('avatar_$name'),
                radius: 36,
                backgroundImage:
                    (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                backgroundColor: HomeTheme.primaryContainer(context),
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: HomeTheme.primary(context),
                        ),
                      )
                    : null,
              ),
            ),
            // Rank crown at bottom
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _rankGradient(collegeRank),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _rankAccent(collegeRank).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _rankEmoji(collegeRank),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: const Color(0xFFEDE7FB),
            highlightColor: const Color(0xFFF8F0FF),
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFEDE7FB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F0FF), Color(0xFFEDE7FB)],
          ),
          border: Border.all(
              color: const Color(0xFFD0BCFF).withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎓', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              'You\'re the first from ${widget.collegeName}!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HomeTheme.onSurface(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Invite classmates to Techmates',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: HomeTheme.onSurfaceVariant(context),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: HomeTheme.primary(context).withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
              ),
              child: Text(
                'Share App',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.primary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _miniStat(BuildContext context, String val, String label) {
    return Column(
      children: [
        Text(val,
            style: GoogleFonts.nunito(
                color: HomeTheme.onSurface(context),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.nunito(
                color: HomeTheme.onSurfaceVariant(context).withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _vDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 28,
      color: HomeTheme.outlineVariant(context).withValues(alpha: 0.5),
    );
  }

  Color _rankAccent(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB800); // gold
      case 2:
        return const Color(0xFF8E99A4); // silver
      case 3:
        return const Color(0xFFCD7C2F); // bronze
      default:
        return const Color(0xFF6750A4);
    }
  }

  List<Color> _rankGradient(int rank) {
    switch (rank) {
      case 1:
        return const [Color(0xFFFFD54F), Color(0xFFFFAB00)]; // gold shine
      case 2:
        return const [Color(0xFFB0BEC5), Color(0xFF78909C)]; // silver shine
      case 3:
        return const [Color(0xFFE6A44C), Color(0xFFBF7830)]; // bronze shine
      default:
        return const [Color(0xFF9575CD), Color(0xFF6750A4)];
    }
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }

  String _shortenBranch(String branch) {
    if (branch.contains('Computer')) return 'CSE';
    if (branch.contains('Electronics')) return 'ECE';
    if (branch.contains('Mechanical')) return 'ME';
    if (branch.contains('Civil')) return 'CE';
    if (branch.contains('Information')) return 'IT';
    if (branch.contains('Electrical')) return 'EE';
    return branch.length > 8 ? branch.substring(0, 8) : branch;
  }
}
