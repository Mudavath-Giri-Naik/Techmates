import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/compete/games/memory/memory_notifier.dart';
import '../../features/compete/games/memory/screens/memory_game_screen.dart';
import '../../features/compete/games/speed_match/speed_match_notifier.dart';
// [HIDDEN] Info screen skipped — going directly to mode select
// import '../../features/compete/games/speed_match/screens/speed_match_info_screen.dart';
import '../../features/compete/games/speed_match/screens/speed_match_mode_screen.dart';
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
      debugPrint('[Compete] No authenticated user');
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _profileService.fetchProfile(user.id);
    if (profile == null) {
      debugPrint('[Compete] Profile is null for user=${user.id}');
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
      debugPrint('[Compete] collegeId is null/empty');
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
      debugPrint('[Compete] Error loading leaderboard: $e');
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
      debugPrint('[Compete] State updated: ${_entries.length} entries, myRank=$_currentUserRank');
    });
  }

  // ── Game domain data (unchanged) ──────────────────────────────
  final _domains = [
    { 'key': 'speed',       'label': 'Speed',    'icon': Icons.bolt,              'bg': const Color(0xFFFFF4ED), 'fg': const Color(0xFFC2440A), 'border': const Color(0xFFFED7AA) },
    { 'key': 'memory',      'label': 'Memory',   'icon': Icons.memory,            'bg': const Color(0xFFEFF6FF), 'fg': const Color(0xFF1D5BB5), 'border': const Color(0xFFBFDBFE) },
    { 'key': 'attention',   'label': 'Focus',    'icon': Icons.center_focus_weak, 'bg': const Color(0xFFF0FDF4), 'fg': const Color(0xFF166534), 'border': const Color(0xFFBBF7D0) },
    { 'key': 'flexibility', 'label': 'Logic',    'icon': Icons.hub_outlined,      'bg': const Color(0xFFFDF4FF), 'fg': const Color(0xFF7E22CE), 'border': const Color(0xFFE9D5FF) },
    { 'key': 'math',        'label': 'Math',     'icon': Icons.calculate_outlined,'bg': const Color(0xFFFFF7ED), 'fg': const Color(0xFFB45309), 'border': const Color(0xFFFDE68A) },
  ];

  // ── Game card data for Section 3 ──────────────────────────────
  // Maps domain index → list of game screens (preserves existing navigation)
  List<_GameItem> _gamesForDomain(int domainIndex) {
    if (domainIndex == 0) {
      return [
        _GameItem(
          title: 'Speed Match',
          icon: Icons.bolt,
          // [CHANGED] Skip info screen, go directly to Solo/Duel mode select
          screen: SpeedMatchModeScreen(notifier: SpeedMatchNotifier()..loadInfo()),
        ),
      ];
    }
    if (domainIndex == 1) {
      return [
        _GameItem(
          title: 'Memory Arena',
          icon: Icons.memory_rounded,
          screen: MemoryGameScreen(notifier: MemoryNotifier()),
        ),
      ];
    }
    return [];
  }

  // ── Existing game navigation handler (unchanged) ──────────────
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
            _loadLeaderboard();
          });
        },
      ),
    );
  }

  /// Navigate to a specific game by domain index.
  /// Opens the existing game picker bottom sheet for that domain.
  void _navigateToGame(int domainIndex) {
    setState(() {
      _selectedDomainKey = _domains[domainIndex]['key'] as String;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GamePickerSheet(
        domainIndex: domainIndex,
        domainName: _domains[domainIndex]['label'] as String,
        domainColor: _domains[domainIndex]['fg'] as Color,
        domainBg: _domains[domainIndex]['bg'] as Color,
        domainBorder: _domains[domainIndex]['border'] as Color,
        onGameSelected: (gameScreen) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => gameScreen)).then((_) {
            _loadLeaderboard();
          });
        },
      ),
    );
  }

  /// Shorten branch name: "Computer Science & Engineering (CSE)" -> "CSE"
  String _shortBranch(String branch) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(branch);
    if (match != null) return match.group(1)!;
    if (branch.length > 12) return branch.substring(0, 12);
    return branch;
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

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF111111),
          onRefresh: _loadLeaderboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              const SizedBox(height: 12),
              _buildScopeToggle(),
              const SizedBox(height: 14),
              _buildDomainFilter(),
              const SizedBox(height: 16),
              _buildPodium(),
              const SizedBox(height: 12),
              _buildPlayButton(),
              _buildLeaderboardList(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 1 — CLASS / COLLEGE TOGGLE
  // ══════════════════════════════════════════════════════════════

  Widget _buildScopeToggle() {
    final ctx = _contextLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.8),
            ),
            child: Row(children: [
              _scopeTab('Class', 'class'),
              _scopeTab('College', 'college'),
            ]),
          ),
          if (ctx != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(ctx),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 14,
                      color: Color(0xFF999999),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        ctx,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF999999),
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
    final isSelected = _selectedScope == value;
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
            color: isSelected ? const Color(0xFF111111) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DOMAIN FILTER PILLS
  // ══════════════════════════════════════════════════════════════

  Widget _buildDomainFilter() {
    final allFilters = [
      { 'key': null,            'label': 'All' },
      { 'key': 'speed',         'label': 'Speed' },
      { 'key': 'memory',        'label': 'Memory' },
      { 'key': 'attention',     'label': 'Focus' },
      { 'key': 'flexibility',   'label': 'Logic' },
      { 'key': 'math',          'label': 'Math' },
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: allFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final f = allFilters[i];
          final fKey = f['key'] as String?;
          final isSelected = _selectedDomainKey == fKey;

          return GestureDetector(
            onTap: () {
              if (_selectedDomainKey != fKey) {
                setState(() => _selectedDomainKey = fKey);
                _loadLeaderboard();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isSelected ? const Color(0xFF111111) : const Color(0xFFE0E0E0),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF999999),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 2 — TOP 3 PODIUM
  // ══════════════════════════════════════════════════════════════

  Widget _buildPodium() {
    if (_isLoading && _entries.isEmpty) {
      return Container(
        height: 260,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8EC), width: 0.8),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF111111), strokeWidth: 2),
        ),
      );
    }

    LeaderboardEntry? first = _entries.isNotEmpty ? _entries[0] : null;
    LeaderboardEntry? second = _entries.length > 1 ? _entries[1] : null;
    LeaderboardEntry? third = _entries.length > 2 ? _entries[2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8EC), width: 0.8),
      ),
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _podiumSlot(rank: 2, entry: second)),
            Expanded(child: _podiumSlot(rank: 1, entry: first, isFirst: true)),
            Expanded(child: _podiumSlot(rank: 3, entry: third)),
          ],
        ),
      ),
    );
  }

  Widget _podiumSlot({required int rank, LeaderboardEntry? entry, bool isFirst = false}) {
    final name = entry?.fullName ?? '-';
    final score = entry?.brainScore ?? 0;
    final avatarUrl = entry?.avatarUrl;
    final avatarSize = isFirst ? 52.0 : 42.0;

    // Podium block heights
    final double blockH;
    if (rank == 1) {
      blockH = 72;
    } else if (rank == 2) {
      blockH = 52;
    } else {
      blockH = 44;
    }

    // Podium block colors
    final Color blockBg;
    final Color blockBorder;
    final Color rankColor;
    final double rankFontSize;
    if (rank == 1) {
      blockBg = const Color(0xFFFFF8EC);
      blockBorder = const Color(0xFFF5C842);
      rankColor = const Color(0xFFC89B00);
      rankFontSize = 28;
    } else {
      blockBg = const Color(0xFFF5F5F5);
      blockBorder = const Color(0xFFDDDDDD);
      rankColor = const Color(0xFFAAAAAA);
      rankFontSize = rank == 2 ? 24 : 22;
    }

    // Initials fallback
    String initials = '-';
    if (entry != null && entry.fullName.isNotEmpty) {
      final parts = entry.fullName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return GestureDetector(
      onTap: entry != null ? () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: entry.userId),
        ));
      } : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown icon for #1
          if (isFirst) ...[
            const Icon(
              Icons.workspace_premium_rounded,
              size: 20,
              color: Color(0xFFC89B00),
            ),
            const SizedBox(height: 4),
          ],

          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F0F0),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(initials,
                          style: TextStyle(
                            fontSize: isFirst ? 18 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(initials,
                        style: TextStyle(
                          fontSize: isFirst ? 18 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),

          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),

          // Score
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 6),

          // Podium block
          Container(
            height: blockH,
            decoration: BoxDecoration(
              color: blockBg,
              border: Border.all(color: blockBorder, width: 1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontSize: rankFontSize,
                fontWeight: FontWeight.w700,
                color: rankColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PLAY BUTTON (visible when a domain with games is selected)
  // ══════════════════════════════════════════════════════════════

  Widget _buildPlayButton() {
    // Hide when "All" is selected
    if (_selectedDomainKey == null) return const SizedBox.shrink();

    final domainData = _domains.firstWhere(
      (d) => d['key'] == _selectedDomainKey,
      orElse: () => _domains[0],
    );
    final domainLabel = domainData['label'] as String;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: _onPlayTap,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(domainData['icon'] as IconData, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Play $domainLabel',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LEADERBOARD LIST (inline, always visible)
  // ══════════════════════════════════════════════════════════════

  Widget _buildLeaderboardList() {
    return Column(
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              const Text(
                'FULL RANKINGS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAAAAAA),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (_currentUserRank > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFF007AFF), width: 1),
                  ),
                  child: Text(
                    'You · #$_currentUserRank',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Loading state
        if (_isLoading && _entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF111111), strokeWidth: 2),
            ),
          )
        // Empty state
        else if (_entries.length <= 3)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _entries.isEmpty ? 'Be the first to compete!' : 'No more rankings below the podium.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          )
        // Leaderboard rows (skip top 3 — they're in the podium)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
          color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isMe ? const Color(0xFFBFDBFE) : const Color(0xFFE8E8EC),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          // Rank
          SizedBox(
            width: 24,
            child: Text(
              item.rank.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isMe ? const Color(0xFF007AFF) : const Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F0F0),
              border: Border.all(
                color: isMe ? const Color(0xFFBFDBFE) : const Color(0xFFE8E8EC),
                width: 0.8,
              ),
            ),
            child: ClipOval(
              child: item.avatarUrl != null
                  ? Image.network(item.avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_outline, size: 16, color: Color(0xFF999999)))
                  : const Icon(Icons.person_outline, size: 16, color: Color(0xFF999999)),
            ),
          ),
          const SizedBox(width: 10),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fullName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isMe ? const Color(0xFF007AFF) : const Color(0xFF111111),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isMe ? const Color(0xFF007AFF).withOpacity(0.6) : const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),

          // Score + delta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.brainScore.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isMe ? const Color(0xFF007AFF) : const Color(0xFF111111),
                  height: 1,
                ),
              ),
              if (delta != 0) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: delta > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      delta.abs().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: delta > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS (unchanged logic)
// ══════════════════════════════════════════════════════════════════════════════

class _GameItem {
  final String title;
  final IconData icon;
  final Widget screen;

  const _GameItem({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

/// Existing game picker bottom sheet — kept for backward compatibility
/// when _onPlayTap is called directly.
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
          icon: Icons.bolt,
          // [CHANGED] Skip info screen, go directly to Solo/Duel mode select
          screen: SpeedMatchModeScreen(notifier: SpeedMatchNotifier()..loadInfo()),
        ),
      ];
    }
    if (domainIndex == 1) {
      return [
        _GameItem(
          title: 'Memory Arena',
          icon: Icons.memory_rounded,
          screen: MemoryGameScreen(notifier: MemoryNotifier()),
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
        color: Color(0xFFF5F5F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
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
                border: Border.all(color: domainBorder, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                domainName.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                  color: domainColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Games',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            games.isEmpty
                ? 'No games available yet for this domain.'
                : '${games.length} game${games.length > 1 ? "s" : ""} available',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 20),

          // Game list
          ...games.map((game) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onGameSelected(game.screen),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E8EC), width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: domainBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(game.icon, size: 20, color: domainColor),
                    ),
                  ],
                ),
              ),
            ),
          )),

          if (games.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8E8EC), width: 0.8),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock_outline, size: 24, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
