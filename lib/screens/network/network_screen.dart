import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/network_service.dart';
import 'college_dashboard_screen.dart';

// ─── Brand Constants ──────────────────────────────────────────────
const _blue = Color(0xFF1565C0);
const _blueOn = Color(0xFF0D47A1);
const _blueCont = Color(0xFFE3F2FD);

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────
  List<CollegeNetworkInfo> _allColleges = [];
  List<CollegeNetworkInfo> _filteredColleges = [];
  String? _myCollegeId;
  CollegeNetworkInfo? _myCollege;

  int _totalColleges = 0;
  int _totalStudents = 0;
  int _totalStates = 0;

  String _activeStateFilter = 'All States';
  List<String> _stateList = [];
  String _searchQuery = '';

  bool _isLoading = true;
  bool _hasError = false;

  final _searchController = TextEditingController();
  final _networkService = NetworkService();

  late AnimationController _shimmerAnimController;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _shimmerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
    _fetchData();
  }

  @override
  void dispose() {
    _shimmerAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _networkService.getColleges(),
        _networkService.getCurrentUserCollegeId(),
      ]);

      final colleges = results[0] as List<CollegeNetworkInfo>;
      final myCollegeId = results[1] as String?;

      // Compute stats
      final totalStudents =
          colleges.fold<int>(0, (sum, c) => sum + c.studentCount);
      final states = colleges
          .map((c) => c.state)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet();
      final stateList = states.toList()..sort();

      CollegeNetworkInfo? myCollege;
      if (myCollegeId != null) {
        final matches = colleges.where((c) => c.id == myCollegeId);
        if (matches.isNotEmpty) myCollege = matches.first;
      }

      if (!mounted) return;
      setState(() {
        _allColleges = colleges;
        _myCollegeId = myCollegeId;
        _myCollege = myCollege;
        _totalColleges = colleges.length;
        _totalStudents = totalStudents;
        _totalStates = states.length;
        _stateList = stateList;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('❌ [NetworkScreen] Error: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ── Filter logic ──────────────────────────────────────────────
  void _applyFilters() {
    _filteredColleges = _allColleges.where((c) {
      final matchState = _activeStateFilter == 'All States' ||
          c.state == _activeStateFilter;
      final matchSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery) ||
          (c.location ?? '').toLowerCase().contains(_searchQuery) ||
          (c.state ?? '').toLowerCase().contains(_searchQuery);
      return matchState && matchSearch;
    }).toList();
  }

  void _filterByState(String state) {
    setState(() {
      _activeStateFilter = state;
      _applyFilters();
    });
  }

  void _onSearchChanged(String q) {
    setState(() {
      _searchQuery = q.toLowerCase().trim();
      _applyFilters();
    });
  }

  // ── Navigation ────────────────────────────────────────────────
  void _openCollege(CollegeNetworkInfo college) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => CollegeDashboardScreen(college: college),
        ));
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) return _buildShimmer(cs);
    if (_hasError) return _buildError(cs);

    // Colleges excluding "My College" for the list
    final listColleges = _filteredColleges
        .where((c) => c.id != _myCollegeId)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          // ── Fixed header ──────────────────────────────────────
          _buildHeader(cs),

          // ── Scrollable content ────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: _blue,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsRow(cs)),
                  if (_myCollege != null) ...[
                    SliverToBoxAdapter(child: _sectionLabel('My College', cs)),
                    SliverToBoxAdapter(
                        child: _buildMyCollegeCard(_myCollege!, cs)),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _sectionLabel('All Colleges', cs),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildCollegeItem(listColleges[index], index, cs),
                      childCount: listColleges.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 24 +
                          MediaQuery.paddingOf(context).bottom +
                          kBottomNavigationBarHeight,
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

  // ═══════════════════════════════════════════════════════════════
  // HEADER (fixed, does not scroll)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(ColorScheme cs) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: cs.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Network',
                  style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A2533)
                        : const Color(0xFFD1E7FE),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded,
                          size: 14, color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF90CAF9)
                              : const Color(0xFF1565C0)),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalColleges colleges',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF90CAF9)
                              : const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search colleges, cities, states…',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: GoogleFonts.sora(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      style: GoogleFonts.sora(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // State filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildStateChip('All States', cs, icon: Icons.public_rounded),
                  ..._stateList.map((s) => _buildStateChip(s, cs)),
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(String label, ColorScheme cs, {IconData? icon}) {
    final isActive = _activeStateFilter == label;
    return GestureDetector(
      onTap: () => _filterByState(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A2533)
                  : const Color(0xFFD1E7FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isActive
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFF1565C0))
                  : cs.onSurfaceVariant),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFF1565C0))
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsRow(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          _netStatCard(
            cs,
            iconBg: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A2533)
                : const Color(0xFFD1E7FE),
            icon: Icons.school_rounded,
            iconColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF90CAF9)
                : const Color(0xFF1565C0),
            value: '$_totalColleges',
            label: 'Colleges',
          ),
          const SizedBox(width: 8),
          _netStatCard(
            cs,
            iconBg: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF142E26)
                : const Color(0xFFBAF1E3),
            icon: Icons.people_rounded,
            iconColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF6EE7B7)
                : const Color(0xFF0D7355),
            value: '$_totalStudents',
            label: 'Students',
          ),
          const SizedBox(width: 8),
          _netStatCard(
            cs,
            iconBg: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D2006)
                : const Color(0xFFFFF3D1),
            icon: Icons.location_on_rounded,
            iconColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFFBBF24)
                : const Color(0xFFB45309),
            value: '$_totalStates',
            label: 'States',
          ),
        ],
      ),
    );
  }

  Widget _netStatCard(
    ColorScheme cs, {
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconBg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION LABEL
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: cs.outlineVariant),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MY COLLEGE CARD (Featured)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMyCollegeCard(CollegeNetworkInfo college, ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    
    // Light mode: pale green theme
    // Dark mode: very dark, muted green theme
    final bgColor = isDark ? const Color(0xFF0B2117) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF166534).withOpacity(0.5) : const Color(0xFFDCFCE7);
    
    // Yours badge
    final badgeBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
    final badgeText = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
    
    // Divider
    final dividerColor = isDark ? const Color(0xFF166534).withOpacity(0.3) : const Color(0xFFBBF7D0).withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: () => _openCollege(college),
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Column(
                children: [
                  // Top row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _collegeAvatarBox(college.name, 0, cs, large: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                text: college.name,
                                style: GoogleFonts.sora(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                                children: [
                                  if (college.isVerified) ...[
                                    const WidgetSpan(
                                      child: SizedBox(width: 4),
                                    ),
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(Icons.verified_rounded,
                                          size: 14, color: _blue),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [college.state, college.location]
                                  .where(
                                      (e) => e != null && e.isNotEmpty)
                                  .join(' · '),
                              style: GoogleFonts.sora(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom stats row
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        _mcStat(Icons.people_rounded,
                            '${college.studentCount}', 'students', cs),
                        if (college.location != null && college.location!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          _mcStat(Icons.location_on_rounded,
                              college.location!, '', cs),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Yours badge at top right
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'yours',
                  style: GoogleFonts.sora(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ),
            ),
            
            // Yours badge at top right
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'yours',
                  style: GoogleFonts.sora(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ),
            ),
            // Shimmer sweep overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedBuilder(
                  animation: _shimmerAnimController,
                  builder: (context, _) {
                    final dx = _shimmerAnimController.value * 400 - 80;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mcStat(
      IconData icon, String value, String label, ColorScheme cs,
      {bool isSuffix = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 5),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: GoogleFonts.sora(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              TextSpan(
                text: label,
                style: GoogleFonts.sora(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COLLEGE LIST ITEM
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCollegeItem(CollegeNetworkInfo college, int index, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: () => _openCollege(college),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6), width: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _collegeAvatarBox(college.name, index, cs),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            college.name,
                            style: GoogleFonts.sora(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (college.isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 13, color: _blue),
                        ],
                      ],
                    ),
                    Text(
                      [college.state, college.location]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' · '),
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${college.studentCount}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Students',
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COLLEGE AVATAR BOX
  // ═══════════════════════════════════════════════════════════════
  Widget _collegeAvatarBox(String name, int index, ColorScheme cs,
      {bool large = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorPairs = <List<Color>>[
      [
        isDark ? const Color(0xFF1A2533) : const Color(0xFFD1E7FE),
        isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
      ],
      [
        isDark ? const Color(0xFF142E26) : const Color(0xFFBAF1E3),
        isDark ? const Color(0xFF6EE7B7) : const Color(0xFF0D7355),
      ],
      [
        isDark ? const Color(0xFF2D2006) : const Color(0xFFFFF3D1),
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      ],
      [
        isDark ? const Color(0xFF1C0A00) : const Color(0xFFFFF7ED),
        isDark ? const Color(0xFFFB923C) : const Color(0xFF9A3412),
      ],
      [
        isDark ? const Color(0xFF042F2E) : const Color(0xFFF0FDFA),
        isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
      ],
      [
        isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8EAF6),
        isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB),
      ],
    ];
    final pair = colorPairs[index % colorPairs.length];
    final side = large ? 46.0 : 42.0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final radius = large ? 14.0 : 12.0;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: pair[0].withOpacity(0.7),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.sora(
            fontSize: large ? 20 : 17,
            fontWeight: FontWeight.w800,
            color: pair[1],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHIMMER / LOADING
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
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 140,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 80,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: List.generate(
                    3,
                    (_) => Expanded(
                      child: Container(
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Featured card
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                // College items
                ...List.generate(
                  5,
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
              'Failed to load colleges',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchData,
              child: Text('Try again',
                  style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
