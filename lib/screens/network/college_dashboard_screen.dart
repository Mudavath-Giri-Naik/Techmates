import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/devcard/devcard_model.dart';
import '../../models/student_network_model.dart';
import '../../services/network_service.dart';
import '../profile/profile_screen.dart';

// ─── Brand Constants ──────────────────────────────────────────────
const _blue    = Color(0xFF1565C0);
const _blueOn  = Color(0xFF0D47A1);
const _blueCont = Color(0xFFE3F2FD);
const _gold    = Color(0xFFF59E0B);
const _silver  = Color(0xFF64748B);
const _bronze  = Color(0xFF92400E);

class CollegeDashboardScreen extends StatefulWidget {
  final CollegeNetworkInfo college;
  const CollegeDashboardScreen({super.key, required this.college});

  @override
  State<CollegeDashboardScreen> createState() => _CollegeDashboardScreenState();
}

class _CollegeDashboardScreenState extends State<CollegeDashboardScreen>
    with TickerProviderStateMixin {
  List<StudentNetworkModel> _allStudents = [];
  List<StudentNetworkModel> _filteredStudents = [];
  List<String> _branches = [];
  List<String> _yearList = [];

  String _activeDept = 'All';
  String _activeYear = 'All Years';

  bool _isLoading = true;
  bool _hasError = false;

  int _deptCount = 0;
  String _topScore = '—';
  String _topRank = '—';

  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fetchStudents();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final students =
          await NetworkService().getCollegeStudents(widget.college.id);

      // Sort by githubScore descending
      students.sort((a, b) => b.githubScore.compareTo(a.githubScore));

      final branches = NetworkService().extractBranches(students);

      // Always show all years
      final years = <String>['All Years', '1st Year', '2nd Year', '3rd Year', '4th Year'];

      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _branches = branches;
          _yearList = years;
          _deptCount = branches.length;
          _topScore =
              students.isNotEmpty ? '${students.first.githubScore}' : '—';
          _topRank = students.isNotEmpty
              ? DevScoreBreakdown.rankInfoFromScore((students.first.githubScore / 10).round())['rank']!
              : '—';
          _isLoading = false;
        });
        _listAnimController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  static String _scoreToRank(int score) {
    return DevScoreBreakdown.rankInfoFromScore((score / 10).round())['rank']!;
  }

  void _applyFilters() {
    _filteredStudents = _allStudents.where((s) {
      final matchDept =
          _activeDept == 'All' || s.branch == _activeDept;
      final matchYear =
          _activeYear == 'All Years' || s.yearTabLabel == _activeYear;
      return matchDept && matchYear;
    }).toList();
    _listAnimController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) return _buildShimmer(cs);
    if (_hasError) return _buildError(cs);

    return Scaffold(

      body: RefreshIndicator(
        onRefresh: _fetchStudents,
        color: _blue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildBackHeader(cs)),
            SliverToBoxAdapter(child: _buildCollegeHero(cs)),
            if (_allStudents.length >= 3)
              SliverToBoxAdapter(child: _buildPodium(cs)),
            SliverToBoxAdapter(child: _buildDeptFilter(cs)),
            SliverToBoxAdapter(child: _buildYearTabs(cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (_filteredStudents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          'No students found of $_activeYear',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final student = _filteredStudents[index];
                    final globalRank = _allStudents.indexOf(student) + 1;
                    return _buildLeaderboardItem(student, globalRank, cs);
                  },
                  childCount: _filteredStudents.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BACK HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBackHeader(ColorScheme cs) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    size: 20, color: cs.onSurface),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${_allStudents.length} members',
                style: GoogleFonts.sora(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COLLEGE HERO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCollegeHero(ColorScheme cs) {
    final college = widget.college;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + verified
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  college.name,
                  style: GoogleFonts.sora(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (college.isVerified) ...[
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.verified_rounded,
                      size: 18, color: _blue),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                [college.state, college.location]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(' · '),
                style: GoogleFonts.sora(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 hero stat cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heroStat('${_allStudents.length}', 'STUDENTS', cs),
                const SizedBox(width: 8),
                _heroStat('$_deptCount', 'DEPTS', cs),
                const SizedBox(width: 8),
                _heroStat('$_topScore', 'TOP SCORE', cs, suffix: ' pts'),
                const SizedBox(width: 8),
                _heroStat(_topRank, 'TOP RANK', cs, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label, ColorScheme cs,
      {String? suffix, bool small = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.05),
          border: Border.all(color: _blue.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: suffix != null
                  ? Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: value,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: suffix,
                          style: GoogleFonts.sora(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ]),
                    )
                  : Text(
                      value,
                      style: small
                          ? GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1,
                            )
                          : GoogleFonts.jetBrainsMono(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1,
                            ),
                    ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PODIUM — Top 3
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPodium(ColorScheme cs) {
    final top3 = _allStudents.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          _podiumItem(top3[1], 2, cs, 0.15),
          const SizedBox(width: 6),
          // 1st place (center — tallest)
          _podiumItem(top3[0], 1, cs, 0.0),
          const SizedBox(width: 6),
          // 3rd place (right)
          _podiumItem(top3[2], 3, cs, 0.25),
        ],
      ),
    );
  }

  Widget _podiumItem(StudentNetworkModel student, int position, ColorScheme cs,
      double animDelay) {
    final podiumColor = _podiumMedalColor(position);
    final avatarSize = position == 1 ? 70.0 : position == 2 ? 56.0 : 52.0;
    final fontSize = position == 1 ? 22.0 : position == 2 ? 18.0 : 16.0;
    final label = position == 1 ? '1ST' : position == 2 ? '2ND' : '3RD';
    final podiumHeight = position == 1 ? 48.0 : position == 2 ? 32.0 : 28.0;

    // Staggered scale animation
    final itemAnim = CurvedAnimation(
      parent: _listAnimController,
      curve: Interval(animDelay, (animDelay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutBack),
    );

    return Expanded(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _listAnimController,
          curve: Interval(animDelay, (animDelay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        )),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(itemAnim),
          child: GestureDetector(
            onTap: () => _openProfile(student),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown for 1st
                if (position == 1) const Text('👑', style: TextStyle(fontSize: 18)),
                if (position == 1) const SizedBox(height: 2),

                // Avatar with glow
                SizedBox(
                  width: avatarSize + 16,
                  height: avatarSize + 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: podiumColor, width: 3),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _podiumGradient(position),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: podiumColor.withValues(alpha: position == 1 ? 0.4 : 0.2),
                              blurRadius: position == 1 ? 20 : 12,
                              spreadRadius: position == 1 ? 2 : 0,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: student.avatarUrl != null &&
                                  student.avatarUrl!.isNotEmpty
                              ? Image.network(
                                  student.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: avatarSize,
                                  height: avatarSize,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      _initials(student.name),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _initials(student.name),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Medal badge
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: podiumColor,
                            boxShadow: [
                              BoxShadow(
                                color: podiumColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$position',
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  _firstName(student.name),
                  style: GoogleFonts.sora(
                    fontSize: position == 1 ? 13 : 11.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                // Score with shimmer for 1st
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [podiumColor, podiumColor.withValues(alpha: 0.7), podiumColor],
                  ).createShader(bounds),
                  child: Text(
                    '${student.githubScore} pts',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: position == 1 ? 14 : 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Podium bar
                const SizedBox(height: 6),
                Container(
                  height: podiumHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: podiumColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.sora(
                            fontSize: position == 1 ? 12 : 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: podiumColor,
                          ),
                        ),
                        Text(
                          _abbreviateBranch(student.branch),
                          style: GoogleFonts.sora(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            color: podiumColor.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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

  // ═══════════════════════════════════════════════════════════════
  // DEPARTMENT FILTER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDeptFilter(ColorScheme cs) {
    final depts = ['All', ..._branches];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: depts.length,
          itemBuilder: (context, index) {
            final dept = depts[index];
            final isActive = _activeDept == dept;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _activeDept = dept;
                  _applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? _blueCont : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isActive
                        ? _blueOn.withValues(alpha: 0.2)
                        : cs.outlineVariant.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  dept,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? _blueOn : cs.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // YEAR TABS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildYearTabs(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _yearList.map((year) {
            final isActive = _activeYear == year;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _activeYear = year;
                  _applyFilters();
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? cs.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  year,
                  style: GoogleFonts.sora(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEADERBOARD ITEM
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLeaderboardItem(
      StudentNetworkModel student, int rank, ColorScheme cs) {
    final rankBadge = _scoreToRank(student.githubScore);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: () => _openProfile(student),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: rank == 1
                        ? _gold
                        : rank == 2
                            ? _silver
                            : rank == 3
                                ? _bronze
                                : cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              _studentAvatar(student, rank, cs),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.displayName,
                            style: GoogleFonts.sora(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (student.collegeVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 13, color: _blue),
                        ],
                      ],
                    ),
                    Text(
                      [student.branch, student.yearTabLabel]
                          .where((e) => e != null && e!.isNotEmpty)
                          .join(' · '),
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Score + rank badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${student.githubScore}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'score',
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildRankBadge(rankBadge, cs),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentAvatar(
      StudentNetworkModel student, int rank, ColorScheme cs) {
    final borderColor = rank == 1
        ? _gold
        : rank == 2
            ? _silver
            : rank == 3
                ? _bronze
                : cs.outlineVariant;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: rank <= 3 ? 2.5 : 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _avatarGradient(student.id),
        ),
      ),
      child: ClipOval(
        child: student.avatarUrl != null && student.avatarUrl!.isNotEmpty
            ? Image.network(
                student.avatarUrl!,
                fit: BoxFit.cover,
                width: 42,
                height: 42,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _initials(student.name),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  _initials(student.name),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRankBadge(String rank, ColorScheme cs) {
    // Reverse-lookup the score bounds to match the DevCard color config
    int mockScoreForRank = 0;
    switch (rank) {
      case 'Legend':      mockScoreForRank = 90; break;
      case 'Grandmaster': mockScoreForRank = 80; break;
      case 'Master':      mockScoreForRank = 70; break;
      case 'Elite':       mockScoreForRank = 60; break;
      case 'Expert':      mockScoreForRank = 50; break;
      case 'Experienced': mockScoreForRank = 40; break;
      case 'Skilled':     mockScoreForRank = 30; break;
      case 'Intermediate':mockScoreForRank = 20; break;
      case 'Learner':     mockScoreForRank = 10; break;
      default:            mockScoreForRank = 0; break;
    }

    // Always compute rank from normalized score (0-100)
    final rankInfo = DevScoreBreakdown.rankInfoFromScore(mockScoreForRank);
    final hexCode = (rankInfo['color'] ?? '#9E9E9E').replaceAll('#', '');
    final fg = Color(int.parse('FF$hexCode', radix: 16));
    final bg = fg.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        "${rankInfo['emoji']} $rank",
        style: GoogleFonts.sora(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  void _openProfile(StudentNetworkModel student) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: student.id),
          ),
        )
        .then((_) => _fetchStudents());
  }

  static String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  static String _firstName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    return name.split(' ').first;
  }

  static String _abbreviateBranch(String? branch) {
    if (branch == null || branch.isEmpty) return '';
    // Keep first 2 words max
    final words = branch.split(' ');
    if (words.length <= 2) return branch;
    return '${words[0]} ${words[1]}';
  }

  Color _podiumMedalColor(int position) {
    if (position == 1) return _gold;
    if (position == 2) return _silver;
    return _bronze;
  }

  List<Color> _podiumGradient(int position) {
    if (position == 1) return [_blue, const Color(0xFF1E88E5)];
    if (position == 2) return [const Color(0xFF475569), const Color(0xFF64748B)];
    return [const Color(0xFF92400E), const Color(0xFFB45309)];
  }

  List<Color> _avatarGradient(String userId) {
    final gradients = [
      [_blue, const Color(0xFF1E88E5)],
      [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
      [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      [const Color(0xFF92400E), const Color(0xFFB45309)],
      [const Color(0xFF15803D), const Color(0xFF22C55E)],
      [const Color(0xFF9D174D), const Color(0xFFEC4899)],
    ];
    final hash = userId.codeUnits.fold(0, (a, b) => a + b);
    return gradients[hash % gradients.length];
  }

  // ═══════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════
  Widget _buildShimmer(ColorScheme cs) {
    return Scaffold(

      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: cs.surfaceContainerLow,
          highlightColor: cs.surfaceContainerHigh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Container(
                  width: 240, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 160, height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 16),
                // Hero stats
                Row(
                  children: List.generate(
                    4,
                    (_) => Expanded(
                      child: Container(
                        height: 56,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Podium
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),
                // Leaderboard items
                ...List.generate(
                  4,
                  (_) => Container(
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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

  // ═══════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildError(ColorScheme cs) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Failed to load students',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchStudents,
              child: Text('Try again',
                  style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
