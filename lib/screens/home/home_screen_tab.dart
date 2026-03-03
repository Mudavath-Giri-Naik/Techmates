import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_profile.dart';
import '../../models/opportunity_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/home_data_service.dart';
import '../../services/user_role_service.dart';
import '../../services/network_service.dart';

import '../network/college_dashboard_screen.dart';
import '../main_screen.dart';

import 'widgets/closing_soon_section.dart';
import 'widgets/elite_picks_section.dart';
import 'widgets/new_this_week_section.dart';
import 'widgets/college_pulse_section.dart';

// ──────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ──────────────────────────────────────────────────────────────────────────────
const _kSkyBlue = Color(0xFF3B9EE8);
const _kSkyBlueDark = Color(0xFF1565C0);
const double _kAvatarGlowBlur = 20.0;
const _kPodiumAreaHeight = 360.0; // space revealed above the sheet
const _kSheetRadius = Radius.circular(32);
const _kCollapsedSheetPeek = 80.0; // how much sheet is always visible at top

class HomeScreenTab extends StatefulWidget {
  const HomeScreenTab({super.key});

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  bool _isLoading = true;
  bool _hasError = false;

  UserProfile? _profile;

  List<Map<String, dynamic>> _closingSoon = [];
  List<Map<String, dynamic>> _elitePicks = [];
  List<Opportunity> _newThisWeek = [];
  List<Map<String, dynamic>> _leaderboardStudents = [];

  int _collegeStudentCount = 0;
  String _collegeName = '';
  String _collegeLocation = '';
  List<Map<String, dynamic>> _collegePulseStudents = [];
  int _newSinceLastVisit = 0;

  final _homeDataService = HomeDataService();
  final _bookmarkService = BookmarkService();
  final _scrollController = ScrollController();

  static const String _lastVisitKey = 'home_last_visit';

  // Animation
  late final AnimationController _podiumEntryCtrl;
  late final Animation<double> _podiumFadeAnim;
  late final Animation<Offset> _podiumSlideAnim;

  @override
  void initState() {
    super.initState();
    _podiumEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _podiumFadeAnim = CurvedAnimation(
      parent: _podiumEntryCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _podiumSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _podiumEntryCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));
    _loadData();
  }

  @override
  void dispose() {
    _podiumEntryCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final authService = AuthService();
      final user = authService.user;
      if (user == null) throw Exception("User not logged in");
      final userId = user.id;

      final prefs = await SharedPreferences.getInstance();
      final lastVisitStr = prefs.getString(_lastVisitKey);
      final lastVisitTime = lastVisitStr != null
          ? DateTime.tryParse(lastVisitStr) ??
              DateTime.now().subtract(const Duration(days: 7))
          : DateTime.now().subtract(const Duration(days: 7));

      final results = await Future.wait([
        ProfileService().fetchProfile(userId),
        _homeDataService.fetchClosingSoon(),
        _homeDataService.fetchElitePicks(),
        _homeDataService.fetchNewThisWeek(),
        _homeDataService.fetchNewOpsSince(lastVisitTime),
      ]);

      final profile = results[0] as UserProfile?;
      final closingSoon = results[1] as List<Map<String, dynamic>>;
      final elitePicks = results[2] as List<Map<String, dynamic>>;
      final newThisWeek = results[3] as List<Opportunity>;
      final newSinceLastVisit = results[4] as int;

      List<Map<String, dynamic>> leaderboard = [];
      int collegeCount = 0;
      String collegeName = profile?.college ?? '';
      String collegeLocation = '';
      List<Map<String, dynamic>> pulseStudents = [];

      if (profile?.collegeId != null && profile!.collegeId!.isNotEmpty) {
        final collegeResults = await Future.wait([
          _homeDataService.fetchCollegeLeaderboard(profile.collegeId),
          _homeDataService.fetchCollegePulse(profile.collegeId),
        ]);

        leaderboard = collegeResults[0] as List<Map<String, dynamic>>;
        final pulseData = collegeResults[1] as Map<String, dynamic>;
        collegeCount = (pulseData['count'] as int?) ?? 0;
        collegeName = (pulseData['collegeName'] as String?) ?? collegeName;
        collegeLocation = (pulseData['collegeLocation'] as String?) ?? '';
        pulseStudents = ((pulseData['students'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _closingSoon = closingSoon;
        _elitePicks = elitePicks;
        _newThisWeek = newThisWeek;
        _newSinceLastVisit = newSinceLastVisit;
        _leaderboardStudents = leaderboard;
        _collegeStudentCount = collegeCount;
        _collegeName = collegeName;
        _collegeLocation = collegeLocation;
        _collegePulseStudents = pulseStudents;
        _isLoading = false;
      });

      await prefs.setString(_lastVisitKey, DateTime.now().toIso8601String());
      _podiumEntryCtrl.forward();
    } catch (e) {
      debugPrint('❌ [HomeScreenTab] _loadData error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _onPullRefresh() async {
    try {
      final user = AuthService().user;
      if (user != null) {
        await Future.wait([
          UserRoleService().refreshRoleNow(user.id),
          ProfileService().refreshProfileNow(user.id),
        ]);
      }
      _podiumEntryCtrl.reset();
      await _loadData();
    } catch (e) {
      debugPrint('[REFRESH] Refresh failed: $e');
      rethrow;
    }
  }

  void _navigateToTab(int index) {
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    mainState?.switchTab(index);
  }

  void _navigateToCollegeDashboard() {
    final collegeId = _profile?.collegeId;
    if (collegeId != null && collegeId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CollegeDashboardScreen(
            college: CollegeNetworkInfo(
              id: collegeId,
              name: _collegeName.isNotEmpty
                  ? _collegeName
                  : (_profile?.college ?? 'Your College'),
            ),
          ),
        ),
      );
    }
  }

  String get _displayCollegeName =>
      _collegeName.isNotEmpty
          ? _collegeName
          : (_profile?.college ?? 'Your College');

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildShimmerSkeleton(context);
    if (_hasError) return _buildErrorState(context);

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final bgColor = isDark ? _kSkyBlueDark : _kSkyBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _onPullRefresh,
        displacement: 20,
        color: Colors.white,
        backgroundColor: bgColor,
        child: Stack(
          children: [
            // ── Layer 1: Sky background with decorative clouds ──
            Positioned.fill(
              child: _SkyBackground(isDark: isDark, topPad: topPad),
            ),

            // ── Layer 2: Fixed podium behind the scroll ──
            Positioned(
              top: topPad + 8,
              left: 0,
              right: 0,
              height: _kPodiumAreaHeight,
              child: _buildPodiumLayer(cs, isDark, topPad),
            ),

            // ── Layer 3: Scrollable bottom sheet on top ──
            _buildScrollableSheet(context, cs, isDark, topPad, bottomPad),
          ],
        ),
      ),
    );
  }

  // ── Podium Layer ─────────────────────────────────────────────
  Widget _buildPodiumLayer(ColorScheme cs, bool isDark, double topPad) {
    final top3 = _leaderboardStudents.take(3).toList();

    return FadeTransition(
      opacity: _podiumFadeAnim,
      child: SlideTransition(
        position: _podiumSlideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar: college name + Full Board ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayCollegeName,
                          style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            if (_collegeLocation.isNotEmpty) ...[
                              Icon(Icons.location_on_rounded, size: 11,
                                  color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  _collegeLocation,
                                  style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                            if (_collegeLocation.isNotEmpty && _collegeStudentCount > 0)
                              Text('  ·  ',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.5))),
                            if (_collegeStudentCount > 0) ...[
                              Icon(Icons.people_rounded, size: 11,
                                  color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Text(
                                '$_collegeStudentCount students',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_leaderboardStudents.isNotEmpty)
                    GestureDetector(
                      onTap: _navigateToCollegeDashboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Full Board',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Podium avatars + blocks ──
            if (top3.isNotEmpty) ...[
              _buildPodiumAvatarsRow(top3, cs),
              Expanded(child: _buildPodiumBlocksRow(top3, isDark)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Scrollable Sheet ──────────────────────────────────────────
  Widget _buildScrollableSheet(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    double topPad,
    double bottomPad,
  ) {
    final sheetColor = isDark ? Colors.black : Colors.white;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Transparent spacer to reveal the podium behind
        SliverToBoxAdapter(
          child: SizedBox(height: topPad + _kPodiumAreaHeight - 8),
        ),

        // The white bottom sheet — persists to end of content
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.only(
                topLeft: _kSheetRadius,
                topRight: _kSheetRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle pill ──
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.18)
                            : Colors.black.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),

                // ── Sections with subtle dividers ──
                if (_closingSoon.isNotEmpty) ...[
                  _sectionDivider(cs),
                  ClosingSoonSection(
                    items: _closingSoon,
                    onSeeAll: () => _navigateToTab(2),
                    onItemTap: (opportunityId, type) {
                      final mainState =
                          context.findAncestorStateOfType<MainScreenState>();
                      mainState?.navigateToOpportunity(opportunityId, type);
                    },
                  ),
                ],

                if (_elitePicks.isNotEmpty) ...[
                  _sectionDivider(cs),
                  ElitePicksSection(items: _elitePicks),
                ],

                if (_newThisWeek.isNotEmpty) ...[
                  _sectionDivider(cs),
                  NewThisWeekSection(
                    items: _newThisWeek,
                    newSinceLastVisit: _newSinceLastVisit,
                    onViewAll: () => _navigateToTab(2),
                  ),
                ],

                if (_collegeStudentCount > 0) ...[
                  _sectionDivider(cs),
                  CollegePulseSection(
                    studentCount: _collegeStudentCount,
                    collegeName: _collegeName,
                    topStudents: _collegePulseStudents,
                    onTap: _navigateToCollegeDashboard,
                  ),
                ],

                SizedBox(
                  height: 32 + bottomPad + kBottomNavigationBarHeight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionDivider(ColorScheme cs) => Divider(
        height: 1,
        indent: 20,
        endIndent: 20,
        color: cs.outlineVariant.withOpacity(0.25),
      );

  // ══════════════════════════════════════════════════════════════
  // PODIUM — Avatars row
  // ══════════════════════════════════════════════════════════════

  Widget _buildPodiumAvatarsRow(
      List<Map<String, dynamic>> top3, ColorScheme cs) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd
            if (second != null)
              Expanded(
                child: _podiumAvatar(student: second, size: 58, rank: 2, cs: cs),
              ),
            // 1st — elevated
            if (first != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child:
                      _podiumAvatar(student: first, size: 74, rank: 1, cs: cs),
                ),
              ),
            // 3rd
            if (third != null)
              Expanded(
                child: _podiumAvatar(student: third, size: 58, rank: 3, cs: cs),
              ),
          ],
        ),
      ),
    );
  }

  Widget _podiumAvatar({
    required Map<String, dynamic> student,
    required double size,
    required int rank,
    required ColorScheme cs,
  }) {
    final name = (student['name'] as String?) ?? '';
    final avatarUrl = student['avatarUrl'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final glowColor = _avatarGlow(rank);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st
        if (rank == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('👑', style: TextStyle(fontSize: size * 0.3)),
          )
        else
          SizedBox(height: size * 0.3 + 4),

        // Glow ring + avatar
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: glowColor,
              width: rank == 1 ? 3 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.45),
                blurRadius: rank == 1 ? 20 : 14,
                spreadRadius: rank == 1 ? 3 : 1,
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _initialsFallback(initial, size, cs),
                    placeholder: (_, __) =>
                        _initialsFallback(initial, size, cs),
                  )
                : _initialsFallback(initial, size, cs),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PODIUM — Blocks row
  // ══════════════════════════════════════════════════════════════

  Widget _buildPodiumBlocksRow(
      List<Map<String, dynamic>> top3, bool isDark) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(
              child: _podiumBlock(rank: 2, heightFraction: 0.78, isDark: isDark, student: second),
            ),
          const SizedBox(width: 5),
          if (first != null)
            Expanded(
              child: _podiumBlock(rank: 1, heightFraction: 1.0, isDark: isDark, student: first),
            ),
          const SizedBox(width: 5),
          if (third != null)
            Expanded(
              child: _podiumBlock(rank: 3, heightFraction: 0.72, isDark: isDark, student: third),
            ),
        ],
      ),
    );
  }

  Widget _podiumBlock({
    required int rank,
    required double heightFraction,
    required bool isDark,
    required Map<String, dynamic> student,
  }) {
    final colors = _podiumColors(rank, isDark);
    final name = (student['name'] as String?) ?? '';
    final branch = (student['branch'] as String?) ?? '';
    final year = (student['year'] as String?) ?? '';
    final shortBranch = _shortBranch(branch);
    final score = (student['score'] as int?) ?? 0;

    return FractionallySizedBox(
      heightFactor: heightFraction,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: colors[0],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Rank number
            Text(
              '#$rank',
              style: GoogleFonts.sora(
                fontSize: rank == 1 ? 20 : 16,
                fontWeight: FontWeight.w900,
                color: colors[1].withOpacity(0.25),
                height: 1.0,
              ),
            ),
            // Name
            Text(
              _shortName(name),
              style: GoogleFonts.sora(
                fontSize: rank == 1 ? 12 : 10,
                fontWeight: FontWeight.w700,
                color: colors[1],
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Branch & Year
            if (shortBranch.isNotEmpty || year.isNotEmpty)
              Text(
                [shortBranch, year].where((s) => s.isNotEmpty).join(' · '),
                style: GoogleFonts.sora(
                  fontSize: rank == 1 ? 8 : 7,
                  fontWeight: FontWeight.w500,
                  color: colors[1].withOpacity(0.6),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 2),
            // Score
            Text(
              _formatScore(score),
              style: GoogleFonts.sora(
                fontSize: rank == 1 ? 15 : 12,
                fontWeight: FontWeight.w800,
                color: colors[1].withOpacity(0.9),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _podiumColors(int rank, bool isDark) {
    switch (rank) {
      case 1:
        return isDark
            ? [const Color(0xFFE8A020), const Color(0xFF1A0A00)]
            : [const Color(0xFFF5B800), const Color(0xFF5A3A00)];
      case 2:
        return isDark
            ? [const Color(0xFF7B9CCC), Colors.white]
            : [const Color(0xFFB0C8E8), const Color(0xFF1A3A6A)];
      case 3:
        return isDark
            ? [const Color(0xFFB07040), Colors.white]
            : [const Color(0xFFE8A878), const Color(0xFF5A2800)];
      default:
        return [Colors.white24, Colors.white];
    }
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  Widget _initialsFallback(String initial, double size, ColorScheme cs) =>
      Container(
        width: size,
        height: size,
        color: cs.primaryContainer,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.sora(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer,
          ),
        ),
      );

  Color _avatarGlow(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB300);
      case 2:
        return const Color(0xFF64B5F6);
      case 3:
        return const Color(0xFFEF9A9A);
      default:
        return const Color(0xFF90CAF9);
    }
  }

  String _shortName(String name) {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }

  String _shortBranch(String branch) {
    if (branch.isEmpty) return '';
    final b = branch.toLowerCase().trim();
    // Common abbreviations
    if (b.contains('computer science') && b.contains('engineer')) return 'CSE';
    if (b.contains('computer science')) return 'CS';
    if (b.contains('artificial intelligence') || (b.contains('ai') && b.contains('ml'))) return 'AI & ML';
    if (b.contains('machine learning')) return 'ML';
    if (b.contains('data science')) return 'DS';
    if (b.contains('information technology')) return 'IT';
    if (b.contains('electronics') && b.contains('communication')) return 'ECE';
    if (b.contains('electrical') && b.contains('electronics')) return 'EEE';
    if (b.contains('electrical')) return 'EE';
    if (b.contains('electronics')) return 'ECE';
    if (b.contains('mechanical')) return 'ME';
    if (b.contains('civil')) return 'CE';
    if (b.contains('chemical')) return 'CHE';
    if (b.contains('biotech')) return 'BT';
    if (b.contains('bio medical') || b.contains('biomedical')) return 'BME';
    if (b.contains('aerospace')) return 'AE';
    if (b.contains('automobile') || b.contains('automotive')) return 'AUTO';
    if (b.contains('mining')) return 'MINING';
    if (b.contains('cyber') && b.contains('security')) return 'CS';
    if (b.contains('iot') || b.contains('internet of things')) return 'IoT';
    // If already short (≤ 6 chars), return as-is
    if (branch.length <= 6) return branch.toUpperCase();
    // Fallback: take first letters of each word
    final words = branch.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return words.map((w) => w[0].toUpperCase()).join('');
    }
    return branch;
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return '$score';
  }

  // ══════════════════════════════════════════════════════════════
  // SHIMMER SKELETON
  // ══════════════════════════════════════════════════════════════

  Widget _buildShimmerSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2B2930) : Colors.grey.shade300;
    final highlightColor =
        isDark ? const Color(0xFF36343B) : Colors.grey.shade100;
    final bgColor = isDark ? _kSkyBlueDark : _kSkyBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Shimmer podium area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            height: 20,
                            width: 160,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8))),
                        Container(
                            height: 28,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _shimmerCircle(56, Colors.white),
                        const SizedBox(width: 16),
                        _shimmerCircle(72, Colors.white),
                        const SizedBox(width: 16),
                        _shimmerCircle(56, Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _shimmerBlock(60, Colors.white)),
                          const SizedBox(width: 5),
                          Expanded(child: _shimmerBlock(84, Colors.white)),
                          const SizedBox(width: 5),
                          Expanded(child: _shimmerBlock(48, Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // White sheet shimmer
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: _kSheetRadius,
                    topRight: _kSheetRadius,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                            height: 68,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(16))),
                        const SizedBox(height: 20),
                        Container(
                            height: 18,
                            width: 120,
                            decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 14),
                        Row(
                          children: List.generate(
                            2,
                            (i) => Expanded(
                              child: Container(
                                height: 130,
                                margin:
                                    EdgeInsets.only(right: i == 0 ? 10 : 0),
                                decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              height: 70,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _shimmerBlock(double height, Color color) => Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
      );

  // ══════════════════════════════════════════════════════════════
  // ERROR STATE
  // ══════════════════════════════════════════════════════════════

  Widget _buildErrorState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _kSkyBlue,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Couldn't load your dashboard.",
                style: GoogleFonts.sora(
                    fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadData,
                style: FilledButton.styleFrom(backgroundColor: _kSkyBlue),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SKY BACKGROUND PAINTER
// ══════════════════════════════════════════════════════════════

class _SkyBackground extends StatelessWidget {
  final bool isDark;
  final double topPad;

  const _SkyBackground({required this.isDark, required this.topPad});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? _kSkyBlueDark : _kSkyBlue;

    return Container(
      color: bgColor,
      child: CustomPaint(
        painter: _CloudPainter(isDark: isDark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final bool isDark;
  _CloudPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.06 : 0.18)
      ..style = PaintingStyle.fill;

    void drawCloud(double cx, double cy, double scale) {
      final path = Path();
      path.addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: 70 * scale, height: 40 * scale));
      path.addOval(Rect.fromCenter(
          center: Offset(cx + 30 * scale, cy - 8 * scale),
          width: 55 * scale,
          height: 34 * scale));
      path.addOval(Rect.fromCenter(
          center: Offset(cx - 28 * scale, cy + 2 * scale),
          width: 45 * scale,
          height: 28 * scale));
      canvas.drawPath(path, paint);
    }

    drawCloud(size.width * 0.12, size.height * 0.08, 1.0);
    drawCloud(size.width * 0.78, size.height * 0.06, 0.8);
    drawCloud(size.width * 0.55, size.height * 0.15, 0.55);
    drawCloud(size.width * 0.30, size.height * 0.20, 0.45);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}