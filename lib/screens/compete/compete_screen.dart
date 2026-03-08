import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/compete/games/speed_match/speed_match_notifier.dart';
import '../../features/compete/games/speed_match/screens/speed_match_info_screen.dart';
import '../../services/leaderboard_service.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../profile/profile_screen.dart';

class CompeteScreen extends StatefulWidget {
  const CompeteScreen({super.key});

  @override
  State<CompeteScreen> createState() => _CompeteScreenState();
}

class _CompeteScreenState extends State<CompeteScreen> {
  String _selectedScope = 'class'; // 'class' | 'college'
  String? _selectedDomainKey;      // null = Brain Score overall
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;
  int _currentUserRank = 0;
  
  final _leaderboardService = LeaderboardService();
  final _auth = AuthService();
  final _profileService = ProfileService();

  // Context labels
  String? _branch;
  int? _year;
  String? _collegeName;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    
    final user = _auth.user;
    if (user == null) {
      debugPrint('[Compete] ❌ No authenticated user');
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _profileService.fetchProfile(user.id);
    if (profile == null) {
      debugPrint('[Compete] ❌ Profile is null for user=${user.id}');
      setState(() => _isLoading = false);
      return;
    }
    
    final collegeId = profile.collegeId;
    final branch = profile.branch ?? '';
    final year = profile.year ?? 1;

    // Store for context labels
    _branch = profile.branch;
    _year = profile.year;

    // Fetch college name if not yet loaded
    if (_collegeName == null && collegeId != null && collegeId.isNotEmpty) {
      try {
        final col = await Supabase.instance.client
            .from('colleges')
            .select('name')
            .eq('id', collegeId)
            .maybeSingle();
        _collegeName = col?['name'] as String?;
      } catch (_) {}
    }

    if (collegeId == null || collegeId.isEmpty) {
      debugPrint('[Compete] ❌ collegeId is null/empty — cannot load leaderboard');
      setState(() => _isLoading = false);
      return;
    }

    List<LeaderboardEntry> entries;

    try {
      debugPrint('=== FETCHING LEADERBOARD ===');
      debugPrint('Scope: $_selectedScope, Domain: $_selectedDomainKey');
      debugPrint('Profile params: collegeId=$collegeId, branch=$branch, year=$year');
      if (_selectedDomainKey != null) {
        entries = await _leaderboardService.fetchDomainLeaderboard(
          domainKey: _selectedDomainKey!,
          scope: _selectedScope,
          collegeId: collegeId,
          branch: branch,
          year: year,
          currentUserId: user.id,
        );
      } else if (_selectedScope == 'class') {
        entries = await _leaderboardService.fetchClassLeaderboard(
          collegeId: collegeId,
          branch: branch,
          year: year,
          currentUserId: user.id,
        );
      } else {
        entries = await _leaderboardService.fetchCollegeLeaderboard(
          collegeId: collegeId,
          currentUserId: user.id,
        );
      }
      debugPrint('Fetched ${entries.length} entries successfully.');
      for (var i = 0; i < entries.length && i < 5; i++) {
        final e = entries[i];
        debugPrint('  #${e.rank} ${e.fullName} score=${e.brainScore} isMe=${e.isCurrentUser}');
      }
    } catch (e, stackTrace) {
      entries = [];
      debugPrint('[Compete] ❌ Error loading leaderboard: $e');
      debugPrint('Stacktrace: $stackTrace');
    }

    if (!mounted) return;

    setState(() {
      _entries = entries;
      _currentUserRank = entries.firstWhere(
        (e) => e.isCurrentUser, 
        orElse: () => LeaderboardEntry(
          userId: '', fullName: '', brainScore: 0, rank: 0, rankDelta: 0, streakDays: 0, isCurrentUser: false
        )
      ).rank;
      _isLoading = false;
      debugPrint('[Compete] ✅ State updated: ${_entries.length} entries, myRank=$_currentUserRank');
    });
  }

  // Colors
  static const bg          = Color(0xFFFAFAF8);
  static const ink         = Color(0xFF111110);
  static const inkSubtle   = Color(0xFFBBBBBB);
  static const border      = Color(0xFFF0EDE6);
  static const chipBg      = Color(0xFFF0EDE6);
  static const teal        = Color(0xFF0D9488);
  static const tealLight   = Color(0xFFF0FDF9);
  static const tealBorder  = Color(0xFF99F6E4);
  static const gold        = Color(0xFFD4A017);
  static const goldLight   = Color(0xFFFFFBEB);

  final _domains = [
    { 'key': 'speed',       'label': 'Speed',    'icon': Icons.bolt,              'bg': const Color(0xFFFFF4ED), 'fg': const Color(0xFFC2440A), 'border': const Color(0xFFFED7AA) },
    { 'key': 'memory',      'label': 'Memory',   'icon': Icons.memory,            'bg': const Color(0xFFEFF6FF), 'fg': const Color(0xFF1D5BB5), 'border': const Color(0xFFBFDBFE) },
    { 'key': 'attention',   'label': 'Focus',    'icon': Icons.center_focus_weak, 'bg': const Color(0xFFF0FDF4), 'fg': const Color(0xFF166534), 'border': const Color(0xFFBBF7D0) },
    { 'key': 'flexibility', 'label': 'Logic',    'icon': Icons.hub_outlined,      'bg': const Color(0xFFFDF4FF), 'fg': const Color(0xFF7E22CE), 'border': const Color(0xFFE9D5FF) },
    { 'key': 'math',        'label': 'Math',     'icon': Icons.calculate_outlined,'bg': const Color(0xFFFFF7ED), 'fg': const Color(0xFFB45309), 'border': const Color(0xFFFDE68A) },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopNav(),        // title + scope tabs
            Expanded(
              child: RefreshIndicator(
                color: teal,
                onRefresh: _loadLeaderboard,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    _buildPodium(),        // top 3 winners
                    const SizedBox(height: 12),
                    _buildDomainChips(),   // horizontally scrollable domain selector
                    _buildPlayButton(),    // Play Now CTA
                    _buildLeaderboardList(), // full rankings
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Context label for the current scope.
  String? get _contextLabel {
    if (_selectedScope == 'class' && _branch != null) {
      final ySuffix = _year != null ? ' · Year $_year' : '';
      return '$_branch$ySuffix';
    }
    if (_selectedScope == 'college' && _collegeName != null) {
      return _collegeName;
    }
    return null;
  }

  Widget _buildTopNav() {
    final ctx = _contextLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              _scopeTab('Class',   'class'),
              _scopeTab('College', 'college'),
            ]),
          ),
          if (ctx != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(ctx),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedScope == 'college'
                          ? Icons.school_outlined
                          : Icons.class_outlined,
                      size: 13,
                      color: teal,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        ctx,
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: teal,
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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

  Widget _scopeTab(String label, String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedScope != value) {
            setState(() => _selectedScope = value);
            _loadLeaderboard();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _selectedScope == value ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _selectedScope == value
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0,1))]
              : [],
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: GoogleFonts.syne(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _selectedScope == value ? ink : inkSubtle,
            )),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (_isLoading && _entries.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: teal)),
      );
    }
    
    LeaderboardEntry? first = _entries.isNotEmpty ? _entries[0] : null;
    LeaderboardEntry? second = _entries.length > 1 ? _entries[1] : null;
    LeaderboardEntry? third = _entries.length > 2 ? _entries[2] : null;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _podiumSlot(rank: 2, entry: second, blockH: 68)),
            Expanded(child: _podiumSlot(rank: 1, entry: first,  blockH: 96, isFirst: true)),
            Expanded(child: _podiumSlot(rank: 3, entry: third, blockH: 52)),
          ],
        ),
      ),
    );
  }

  Widget _podiumSlot({required int rank, LeaderboardEntry? entry, required int blockH, bool isFirst = false}) {
    final name = entry?.fullName ?? '-';
    final score = entry?.brainScore ?? 0;
    final avatarUrl = entry?.avatarUrl;
    final isCollege = _selectedScope == 'college';
    final branchYear = isCollege && entry != null && entry.branch != null
        ? '${_shortBranch(entry.branch!)}${entry.year != null ? ' · Y${entry.year}' : ''}'
        : null;

    return GestureDetector(
      onTap: entry != null ? () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: entry.userId),
        ));
      } : null,
      child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst) const Text('👑', style: TextStyle(fontSize: 14)),
        if (isFirst) const SizedBox(height: 2),
        
        Container(
          width: isFirst ? 52 : 44,
          height: isFirst ? 52 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFirst ? goldLight : chipBg,
            border: Border.all(
              color: isFirst ? gold.withValues(alpha: 0.5) : border,
              width: isFirst ? 2.5 : 1.5,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null 
              ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person_outline, size: isFirst ? 22 : 18, color: isFirst ? gold : inkSubtle))
              : Icon(Icons.person_outline, size: isFirst ? 22 : 18, color: isFirst ? gold : inkSubtle),
          ),
        ),
        const SizedBox(height: 5),
        
        Text(name,
          style: GoogleFonts.syne(
            fontSize: isFirst ? 10 : 9,
            fontWeight: FontWeight.w600,
            color: isFirst ? ink : const Color(0xFF333333),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (branchYear != null)
          Text(branchYear,
            style: GoogleFonts.dmMono(
              fontSize: 7,
              color: inkSubtle,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 2),
        
        Text(score.toString(),
          style: GoogleFonts.dmMono(
            fontSize: 8,
            color: isFirst ? gold : inkSubtle,
          )),
        const SizedBox(height: 4),
        
        Container(
          height: blockH.toDouble(),
          decoration: BoxDecoration(
            color: isFirst ? goldLight : (rank == 2 ? chipBg : const Color(0xFFF5F4F2)),
            border: Border(
              top:   BorderSide(color: isFirst ? gold.withValues(alpha: 0.25) : border, width: 1.5),
              left:  BorderSide(color: isFirst ? gold.withValues(alpha: 0.25) : border, width: 1.5),
              right: BorderSide(color: isFirst ? gold.withValues(alpha: 0.25) : border, width: 1.5),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          alignment: Alignment.center,
          child: Text(rank.toString(),
            style: GoogleFonts.instrumentSerif(
              fontSize: 22,
              color: isFirst ? gold : inkSubtle,
            )),
        ),
      ],
    ),
    );
  }

  /// Shorten branch name: "Computer Science & Engineering (CSE)" → "CSE"
  String _shortBranch(String branch) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(branch);
    if (match != null) return match.group(1)!;
    if (branch.length > 12) return branch.substring(0, 12);
    return branch;
  }

  Widget _buildDomainChips() {
    // "All" chip + domain chips
    final allChips = [
      { 'key': 'all', 'label': 'All', 'icon': Icons.leaderboard_rounded, 'bg': const Color(0xFFF0FDF9), 'fg': const Color(0xFF0D9488), 'border': const Color(0xFF99F6E4) },
      ..._domains,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text('WEEKLY CHAMPION · PICK DOMAIN',
            style: GoogleFonts.dmMono(fontSize: 8.5, letterSpacing: 1.6, color: inkSubtle)),
        ),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
            physics: const BouncingScrollPhysics(),
            itemCount: allChips.length,
            separatorBuilder: (context, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = allChips[i];
              final chipKey = d['key'] as String;
              final isAll = chipKey == 'all';
              final isSelected = isAll
                  ? _selectedDomainKey == null
                  : _selectedDomainKey == chipKey;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDomainKey = isAll ? null : chipKey;
                  });
                  _loadLeaderboard();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? d['bg'] as Color : chipBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? d['border'] as Color : border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                      ? [BoxShadow(color: (d['fg'] as Color).withOpacity(0.18), blurRadius: 10, offset: const Offset(0,2))]
                      : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(d['icon'] as IconData, size: 13,
                        color: isSelected ? d['fg'] as Color : inkSubtle),
                      const SizedBox(width: 6),
                      Text(d['label'] as String,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? d['fg'] as Color : inkSubtle,
                        )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    // Hide when "All" is selected
    if (_selectedDomainKey == null) return const SizedBox.shrink();

    final domainData = _domains.firstWhere(
      (d) => d['key'] == _selectedDomainKey,
      orElse: () => _domains[0],
    );
    final domainLabel = domainData['label'] as String;
    final domainFg = domainData['fg'] as Color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: _onPlayTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(domainData['icon'] as IconData, color: domainFg, size: 18),
              const SizedBox(width: 8),
              Text('Play $domainLabel',
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.02,
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _onPlayTap() {
    int activeIndex = 0;
    if (_selectedDomainKey != null) {
      activeIndex = _domains.indexWhere((d) => d['key'] == _selectedDomainKey);
      if (activeIndex == -1) activeIndex = 0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GamePickerSheet(
        domainIndex: activeIndex,
        domainName: _domains[activeIndex]['label'] as String,
        domainColor: _domains[activeIndex]['fg'] as Color,
        domainBg: _domains[activeIndex]['bg'] as Color,
        domainBorder: _domains[activeIndex]['border'] as Color,
        onGameSelected: (gameScreen) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => gameScreen)).then((_) {
            // refresh leaderboard after game completes
            _loadLeaderboard();
          });
        },
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FULL RANKINGS',
                style: GoogleFonts.dmMono(fontSize: 8.5, letterSpacing: 1.6, color: inkSubtle)),
              if (_currentUserRank > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tealLight,
                    border: Border.all(color: tealBorder),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('You · #$_currentUserRank',
                    style: GoogleFonts.dmMono(fontSize: 9, color: teal, letterSpacing: 0.8)),
                ),
            ],
          ),
        ),
        if (_isLoading && _entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: teal)),
          )
        else if (_entries.length <= 3)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _entries.isEmpty ? 'Be the first to compete!' : 'No more rankings below the podium.',
                style: GoogleFonts.syne(color: inkSubtle),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: _entries.sublist(3).map((e) => _buildLbRow(e)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLbRow(LeaderboardEntry item) {
    final isMe = item.isCurrentUser;
    final delta = item.rankDelta;
    final isCollege = _selectedScope == 'college';
    
    String subtitle;
    if (isCollege && item.branch != null) {
      subtitle = '${_shortBranch(item.branch!)}${item.year != null ? ' · Y${item.year}' : ''}';
    } else if (item.topDomain != null) {
      subtitle = item.totalSessions != null
          ? '${item.topDomain} · ${item.totalSessions} sessions'
          : item.topDomain!;
    } else {
      subtitle = '${item.streakDays}d streak';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: item.userId),
        ));
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? tealLight : Colors.white,
        border: Border.all(
          color: isMe ? tealBorder : border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        SizedBox(
          width: 22,
          child: Text(item.rank.toString(),
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: isMe ? teal : inkSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMe ? tealLight : chipBg,
            border: Border.all(
              color: isMe ? tealBorder : border,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: item.avatarUrl != null 
              ? Image.network(item.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person_outline, size: 16, color: isMe ? teal : inkSubtle))
              : Icon(Icons.person_outline, size: 16, color: isMe ? teal : inkSubtle),
          ),
        ),
        const SizedBox(width: 10),
        
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.fullName,
              style: GoogleFonts.syne(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMe ? teal : ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(subtitle,
              style: GoogleFonts.dmMono(
                fontSize: 9,
                color: isMe ? teal.withValues(alpha: 0.6) : inkSubtle,
                letterSpacing: 0.05,
              )),
          ],
        )),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(item.brainScore.toString(),
              style: GoogleFonts.instrumentSerif(
                fontSize: 19,
                color: isMe ? teal : ink,
                height: 1,
              )),
            if (delta != 0)
              const SizedBox(height: 3),
            if (delta != 0)
              Text(delta > 0 ? '▲ +$delta' : '▼ ${delta.abs()}',
                style: GoogleFonts.dmMono(
                  fontSize: 8,
                  letterSpacing: 0.6,
                  color: delta > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                )),
          ],
        ),
      ]),
    ),
    );
  }
}

class _GameItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _GameItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}

class _GamePickerSheet extends StatelessWidget {
  final int domainIndex;
  final String domainName;
  final Color domainColor;
  final Color domainBg;
  final Color domainBorder;
  final void Function(Widget gameScreen) onGameSelected;

  const _GamePickerSheet({
    required this.domainIndex,
    required this.domainName,
    required this.domainColor,
    required this.domainBg,
    required this.domainBorder,
    required this.onGameSelected,
  });

  List<_GameItem> _gamesForDomain(int domainIndex) {
    if (domainIndex == 0) {
      return [
        _GameItem(
          title: 'Speed Match',
          subtitle: 'Match the pattern fast',
          icon: Icons.bolt,
          screen: SpeedMatchInfoScreen(notifier: SpeedMatchNotifier()),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final games = _gamesForDomain(domainIndex);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDAD2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: domainBg,
                border: Border.all(color: domainBorder, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                domainName.toUpperCase(),
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w500,
                  color: domainColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Games',
              style: GoogleFonts.instrumentSerif(
                fontSize: 22,
                color: const Color(0xFF111110),
              )),
          ]),
          const SizedBox(height: 6),
          Text(
            games.isEmpty
              ? 'No games available yet for this domain.'
              : '${games.length} game${games.length > 1 ? "s" : ""} available · tap to play',
            style: GoogleFonts.dmMono(
              fontSize: 9,
              letterSpacing: 0.8,
              color: const Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(height: 20),

          // Game grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: games.isEmpty ? 4 : games.length,
            itemBuilder: (context, i) {
              if (games.isEmpty || i >= games.length) {
                return _emptyGameBox(i + 1);
              }
              return _gameBox(games[i]);
            },
          ),
        ],
      ),
    );
  }

  Widget _gameBox(_GameItem game) {
    return GestureDetector(
      onTap: () => onGameSelected(game.screen),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF0EDE6), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: domainBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: domainBorder, width: 1),
              ),
              child: Icon(game.icon, size: 18, color: domainColor),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title,
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111110),
                  )),
                const SizedBox(height: 2),
                Text(game.subtitle,
                  style: GoogleFonts.dmMono(
                    fontSize: 9,
                    color: const Color(0xFFBBBBBB),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyGameBox(int num) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EE),
        border: Border.all(
          color: const Color(0xFFE8E5DE),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFECEAE4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline,
              size: 16,
              color: Color(0xFFCCC9C0)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80, height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0DDD6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 5),
              Text('Coming soon',
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: const Color(0xFFCCC9C0),
                  letterSpacing: 0.4,
                )),
            ],
          ),
        ],
      ),
    );
  }
}
