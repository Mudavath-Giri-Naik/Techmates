import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/network_service.dart';
import 'college_dashboard_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PALETTE — pastel card colors, no gradients
// Each college in the list cycles through these
// ──────────────────────────────────────────────────────────────────────────────
class _Palette {
  final Color lightBg;     // card background light
  final Color darkBg;      // card background dark
  final Color lightAccent; // icon + text accent light
  final Color darkAccent;  // icon + text accent dark
  final Color lightBorder; // border light
  final Color darkBorder;  // border dark

  const _Palette({
    required this.lightBg,
    required this.darkBg,
    required this.lightAccent,
    required this.darkAccent,
    required this.lightBorder,
    required this.darkBorder,
  });
}

const _kPalettes = <_Palette>[
  // Rose / Pink
  _Palette(
    lightBg: Color(0xFFFFE4E6), darkBg: Color(0xFF1C0A0C),
    lightAccent: Color(0xFFE11D48), darkAccent: Color(0xFFFB7185),
    lightBorder: Color(0xFFFECDD3), darkBorder: Color(0xFF4C1320),
  ),
  // Amber / Yellow
  _Palette(
    lightBg: Color(0xFFFEF9C3), darkBg: Color(0xFF1A1500),
    lightAccent: Color(0xFFB45309), darkAccent: Color(0xFFFBBF24),
    lightBorder: Color(0xFFFDE68A), darkBorder: Color(0xFF3D2800),
  ),
  // Sky / Blue
  _Palette(
    lightBg: Color(0xFFDBEAFE), darkBg: Color(0xFF050E1E),
    lightAccent: Color(0xFF1D4ED8), darkAccent: Color(0xFF60A5FA),
    lightBorder: Color(0xFFBFDAFE), darkBorder: Color(0xFF1E3A5F),
  ),
  // Mint / Green
  _Palette(
    lightBg: Color(0xFFDCFCE7), darkBg: Color(0xFF021508),
    lightAccent: Color(0xFF15803D), darkAccent: Color(0xFF4ADE80),
    lightBorder: Color(0xFFBBF7D0), darkBorder: Color(0xFF14532D),
  ),
  // Violet / Purple
  _Palette(
    lightBg: Color(0xFFEDE9FE), darkBg: Color(0xFF0C0718),
    lightAccent: Color(0xFF6D28D9), darkAccent: Color(0xFFA78BFA),
    lightBorder: Color(0xFFDDD6FE), darkBorder: Color(0xFF2E1065),
  ),
  // Peach / Orange
  _Palette(
    lightBg: Color(0xFFFFEDD5), darkBg: Color(0xFF180900),
    lightAccent: Color(0xFFEA580C), darkAccent: Color(0xFFFB923C),
    lightBorder: Color(0xFFFED7AA), darkBorder: Color(0xFF431407),
  ),
];

// Avatar ring colors — used for placeholder circles in the student row
const _kAvatarRingColors = [
  Color(0xFFFF6B6B), Color(0xFFFFB347), Color(0xFF4FC3F7),
  Color(0xFF66BB6A), Color(0xFFBA68C8), Color(0xFF26C6DA),
  Color(0xFFFF8A65), Color(0xFFAED581), Color(0xFF7986CB),
  Color(0xFFF06292),
];

const _kBlue = Color(0xFF1565C0);

// ──────────────────────────────────────────────────────────────────────────────
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────
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

  late AnimationController _sweepCtrl;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
    _fetchData();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        _networkService.getColleges(),
        _networkService.getCurrentUserCollegeId(),
      ]);

      final colleges = results[0] as List<CollegeNetworkInfo>;
      final myCollegeId = results[1] as String?;

      final totalStudents = colleges.fold<int>(0, (s, c) => s + c.studentCount);
      final states = colleges
          .map((c) => c.state).whereType<String>()
          .where((s) => s.isNotEmpty).toSet();
      final stateList = states.toList()..sort();

      CollegeNetworkInfo? myCollege;
      if (myCollegeId != null) {
        final m = colleges.where((c) => c.id == myCollegeId);
        if (m.isNotEmpty) myCollege = m.first;
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
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  // ── Filter ─────────────────────────────────────────────────────
  void _applyFilters() {
    _filteredColleges = _allColleges.where((c) {
      final matchState = _activeStateFilter == 'All States' || c.state == _activeStateFilter;
      final matchSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery) ||
          (c.location ?? '').toLowerCase().contains(_searchQuery) ||
          (c.state ?? '').toLowerCase().contains(_searchQuery);
      return matchState && matchSearch;
    }).toList();
  }

  void _filterByState(String state) {
    setState(() { _activeStateFilter = state; _applyFilters(); });
  }

  void _onSearchChanged(String q) {
    setState(() { _searchQuery = q.toLowerCase().trim(); _applyFilters(); });
  }

  // ── Navigation ─────────────────────────────────────────────────
  void _openCollege(CollegeNetworkInfo college) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CollegeDashboardScreen(college: college),
    ));
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) return _buildShimmer(isDark);
    if (_hasError) return _buildError(cs, isDark);

    final listColleges = _filteredColleges.where((c) => c.id != _myCollegeId).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          _buildHeader(cs, isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: _kBlue,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsRow(cs, isDark)),

                  if (_myCollege != null) ...[
                    SliverToBoxAdapter(child: _sectionLabel('My College', cs, isDark)),
                    SliverToBoxAdapter(child: _buildMyCollegeCard(_myCollege!, cs, isDark)),
                  ],

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _sectionLabel('All Colleges', cs, isDark),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildCollegeCard(listColleges[i], i, isDark),
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

  // ════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeader(ColorScheme cs, bool isDark) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: isDark ? Colors.black : Colors.white,
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
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: cs.onSurface, letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2533) : const Color(0xFFD1E7FE),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school_rounded, size: 14,
                        color: isDark ? const Color(0xFF90CAF9) : _kBlue),
                    const SizedBox(width: 4),
                    Text('$_totalColleges colleges',
                        style: GoogleFonts.sora(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF90CAF9) : _kBlue,
                        )),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111111) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: cs.onSurfaceVariant),
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
                          fontSize: 13.5, fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      style: GoogleFonts.sora(
                        fontSize: 13.5, fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // State chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _stateChip('All States', cs, isDark, icon: Icons.public_rounded),
                  ..._stateList.map((s) => _stateChip(s, cs, isDark)),
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _stateChip(String label, ColorScheme cs, bool isDark, {IconData? icon}) {
    final isActive = _activeStateFilter == label;
    return GestureDetector(
      onTap: () => _filterByState(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1A2533) : const Color(0xFFD1E7FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13,
                color: isActive ? (isDark ? const Color(0xFF90CAF9) : _kBlue) : cs.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: GoogleFonts.sora(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isActive ? (isDark ? const Color(0xFF90CAF9) : _kBlue) : cs.onSurfaceVariant,
              )),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STATS ROW
  // ════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(children: [
        _statCard(cs, isDark,
          bg: isDark ? const Color(0xFF111111) : const Color(0xFFD1E7FE),
          value: '$_totalColleges', label: 'Colleges'),
        const SizedBox(width: 8),
        _statCard(cs, isDark,
          bg: isDark ? const Color(0xFF111111) : const Color(0xFFBAF1E3),
          value: '$_totalStudents', label: 'Students'),
        const SizedBox(width: 8),
        _statCard(cs, isDark,
          bg: isDark ? const Color(0xFF111111) : const Color(0xFFFFF3D1),
          value: '$_totalStates', label: 'States'),
      ]),
    );
  }

  Widget _statCard(ColorScheme cs, bool isDark, {
    required Color bg,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: const Color(0xFF2A2A2A)) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: cs.onSurface, height: 1.0)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.sora(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant, letterSpacing: 0.3)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SECTION LABEL
  // ════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(children: [
        Text(text.toUpperCase(),
            style: GoogleFonts.sora(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: cs.outlineVariant)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // MY COLLEGE CARD — unique pinned "home base" design
  // ════════════════════════════════════════════════════════════════
  Widget _buildMyCollegeCard(CollegeNetworkInfo college, ColorScheme cs, bool isDark) {
    final bg = isDark ? const Color(0xFF0A1628) : const Color(0xFFF0F9FF);
    final border = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBAE6FD);
    final accent = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final accentMuted = accent.withOpacity(isDark ? 0.15 : 0.1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => _openCollege(college),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row ──
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Large initial box
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: accentMuted,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accent.withOpacity(0.3), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          college.name.isNotEmpty ? college.name[0].toUpperCase() : '?',
                          style: GoogleFonts.sora(
                            fontSize: 26, fontWeight: FontWeight.w900, color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // "Home Base" label
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('✦  Home Base',
                                style: GoogleFonts.sora(
                                  fontSize: 9.5, fontWeight: FontWeight.w700,
                                  color: accent, letterSpacing: 0.2,
                                )),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Flexible(
                            child: Text(
                              college.name,
                              style: GoogleFonts.sora(
                                fontSize: 16, fontWeight: FontWeight.w800,
                                color: cs.onSurface, height: 1.1,
                              ),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (college.isVerified) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.verified_rounded, size: 15, color: accent),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          [college.state, college.location]
                              .where((e) => e != null && e.isNotEmpty).join(' · '),
                          style: GoogleFonts.sora(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  // ── Thin divider ──
                  Container(height: 1, color: border.withOpacity(0.7)),
                  const SizedBox(height: 12),

                  // ── Bottom: count + avatar row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(color: accentMuted, shape: BoxShape.circle),
                          child: Icon(Icons.people_rounded, size: 12, color: accent),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${college.studentCount} students',
                          style: GoogleFonts.sora(
                            fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface,
                          ),
                        ),
                      ]),
                      _avatarRow(college.studentCount, accent, isDark),
                    ],
                  ),
                ],
              ),
            ),

            // Shimmer sweep overlay (very subtle)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: AnimatedBuilder(
                  animation: _sweepCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(_sweepCtrl.value * 420 - 80, 0),
                    child: Container(
                      width: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          Color(0x07FFFFFF),
                          Colors.transparent,
                        ]),
                      ),
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

  // ════════════════════════════════════════════════════════════════
  // COLLEGE LIST CARD — compact, white bg, grey border
  // ════════════════════════════════════════════════════════════════
  Widget _buildCollegeCard(CollegeNetworkInfo college, int index, bool isDark) {
    final pal = _kPalettes[index % _kPalettes.length];
    final accent = isDark ? pal.darkAccent : pal.lightAccent;
    final cardBg = isDark ? const Color(0xFF111111) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark ? Colors.white54 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => _openCollege(college),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Initial box
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: isDark ? Border.all(color: const Color(0xFF333333)) : null,
              ),
              child: Center(
                child: Text(
                  college.name.isNotEmpty ? college.name[0].toUpperCase() : '?',
                  style: GoogleFonts.sora(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + location
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      college.name,
                      style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: textMain, height: 1.15,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (college.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 13,
                        color: isDark ? Colors.white : accent),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  [college.state, college.location]
                      .where((e) => e != null && e.isNotEmpty).join(' · '),
                  style: GoogleFonts.sora(
                    fontSize: 11, fontWeight: FontWeight.w500, color: textSub,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            const SizedBox(width: 8),

            // Student count pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(50),
                border: isDark ? Border.all(color: const Color(0xFF333333)) : null,
              ),
              child: Text(
                '${college.studentCount}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : accent,
                ),
              ),
            ),

            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18,
                color: isDark ? Colors.white38 : textSub),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // AVATAR ROW — overlapping circles like reference image 2
  // Up to 5 shown, then "+N" overflow badge
  // ════════════════════════════════════════════════════════════════
  Widget _avatarRow(int count, Color accentColor, bool isDark) {
    if (count <= 0) return const SizedBox.shrink();

    const maxShow = 5;
    const size = 26.0;
    const overlap = 9.0;
    const step = size - overlap; // 17px per slot

    final showCount = count.clamp(0, maxShow);
    final overflow = count > maxShow ? count - maxShow : 0;
    final totalSlots = showCount + (overflow > 0 ? 1 : 0);
    final totalWidth = totalSlots > 0
        ? ((totalSlots - 1) * step + size).toDouble()
        : size;

    final bg = isDark ? Colors.black : Colors.white;

    return SizedBox(
      height: size,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Placeholder avatar circles
          ...List.generate(showCount, (i) {
            final color = _kAvatarRingColors[i % _kAvatarRingColors.length];
            return Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: bg, width: 2),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + i), // A, B, C, D, E
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Overflow "+N" badge
          if (overflow > 0)
            Positioned(
              left: showCount * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: bg, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SHIMMER
  // ════════════════════════════════════════════════════════════════
  Widget _buildShimmer(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF111111) : Colors.grey.shade200,
          highlightColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title row
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _sh(140, 32, 8),
                _sh(100, 28, 50),
              ]),
              const SizedBox(height: 14),
              _sh(double.infinity, 44, 16),
              const SizedBox(height: 12),
              Row(children: [_sh(80, 32, 50), const SizedBox(width: 8), _sh(80, 32, 50), const SizedBox(width: 8), _sh(80, 32, 50)]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _sh(double.infinity, 80, 16)),
                const SizedBox(width: 8),
                Expanded(child: _sh(double.infinity, 80, 16)),
                const SizedBox(width: 8),
                Expanded(child: _sh(double.infinity, 80, 16)),
              ]),
              const SizedBox(height: 16),
              _sh(double.infinity, 130, 26),
              const SizedBox(height: 16),
              ...List.generate(5, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _sh(double.infinity, 110, 24))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sh(double w, double h, double r) => Container(
    width: w == double.infinity ? null : w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  // ════════════════════════════════════════════════════════════════
  // ERROR
  // ════════════════════════════════════════════════════════════════
  Widget _buildError(ColorScheme cs, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Failed to load colleges',
              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fetchData,
            child: Text('Try again', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}