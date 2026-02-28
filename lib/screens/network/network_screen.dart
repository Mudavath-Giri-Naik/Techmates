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
        ))
        .then((_) => _fetchData());
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
      backgroundColor: cs.surface,
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
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalColleges colleges',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
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
                color: cs.surfaceContainerLow,
                border: Border.all(color: cs.outlineVariant, width: 1.5),
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
          color: isActive ? cs.primaryContainer : cs.surface,
          border: Border.all(
            color: isActive ? cs.primary : cs.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isActive ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
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
            iconBg: cs.primaryContainer,
            icon: Icons.school_rounded,
            iconColor: cs.primary,
            value: '$_totalColleges',
            label: 'Colleges',
          ),
          const SizedBox(width: 8),
          _netStatCard(
            cs,
            iconBg: cs.tertiaryContainer,
            icon: Icons.people_rounded,
            iconColor: cs.tertiary,
            value: '$_totalStudents',
            label: 'Students',
          ),
          const SizedBox(width: 8),
          _netStatCard(
            cs,
            iconBg: cs.secondaryContainer,
            icon: Icons.location_on_rounded,
            iconColor: cs.secondary,
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
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
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
                color: cs.surface,
                border: Border.all(color: cs.primary, width: 1.5),
                borderRadius: BorderRadius.circular(20),
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    college.name,
                                    style: GoogleFonts.sora(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (college.isVerified) ...[
                                  const SizedBox(width: 5),
                                  const Icon(Icons.verified_rounded,
                                      size: 14, color: _blue),
                                ],
                              ],
                            ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'yours',
                          style: GoogleFonts.sora(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          ),
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
                        top: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        _mcStat(Icons.people_rounded,
                            '${college.studentCount}', 'students', cs),
                        const SizedBox(width: 12),
                        _mcStat(Icons.category_rounded, '', 'departments', cs),
                        const SizedBox(width: 12),
                        _mcStat(Icons.military_tech_rounded, 'Top:', '', cs,
                            isSuffix: true),
                      ],
                    ),
                  ),
                ],
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
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
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
      [cs.primaryContainer, cs.onPrimaryContainer],
      [cs.tertiaryContainer, cs.onTertiaryContainer],
      [cs.secondaryContainer, cs.onSecondaryContainer],
      [
        isDark ? const Color(0xFF1E0A3C) : const Color(0xFFF3E8FF),
        isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8),
      ],
      [
        isDark ? const Color(0xFF1C0A00) : const Color(0xFFFFF7ED),
        isDark ? const Color(0xFFFB923C) : const Color(0xFF9A3412),
      ],
      [
        isDark ? const Color(0xFF042F2E) : const Color(0xFFF0FDFA),
        isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
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
        color: pair[0],
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
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
      backgroundColor: cs.surface,
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
      backgroundColor: cs.surface,
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
