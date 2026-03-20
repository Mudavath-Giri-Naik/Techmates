import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/supabase_client.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import 'profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isInitLoading = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _colleges = [];
  String? _selectedCollegeId;
  String _selectedBranch = 'All';
  int _selectedYear = 0; // 0 means 'All'

  final List<String> _branches = [
    'All', 'CSE', 'CSM', 'CSD', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL'
  ];
  final List<int> _years = [0, 1, 2, 3, 4]; // 0 represents 'All'

  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      // Fetch colleges
      final response = await SupabaseClientManager.instance
          .from('colleges')
          .select('id, name, code')
          .order('name');
      final colleges = List<Map<String, dynamic>>.from(response);

      // Fetch user profile for defaults
      final user = SupabaseClientManager.instance.auth.currentUser;
      Map<String, dynamic>? profileRes;
      
      if (user != null) {
        profileRes = await SupabaseClientManager.instance
            .from('profiles')
            .select('college_id, branch, year')
            .eq('id', user.id)
            .maybeSingle();
      }

      if (mounted) {
        setState(() {
          _colleges = colleges;

          // Defaults
          if (colleges.isNotEmpty) {
            _selectedCollegeId = profileRes?['college_id'] as String?;
            if (_selectedCollegeId == null || !colleges.any((c) => c['id'] == _selectedCollegeId)) {
              _selectedCollegeId = colleges.first['id'] as String;
            }
          }

          final dbBranch = profileRes?['branch'] as String?;
          if (dbBranch != null) {
            final upperBranch = dbBranch.toUpperCase();
            // Try to find an exact match first
            if (_branches.contains(upperBranch)) {
              _selectedBranch = upperBranch;
            } else {
              // Try to find if the branch name contains our code (e.g., "(CSE)" contains "CSE")
              try {
                _selectedBranch = _branches.skip(1).firstWhere(
                  (b) => upperBranch.contains(b),
                );
              } catch (_) {
                _selectedBranch = 'All';
              }
            }
          }

          final year = profileRes?['year'] as int?;
          if (year != null && _years.contains(year)) {
            _selectedYear = year;
          }

          _isInitLoading = false;
        });

        _fetchClassLeaderboard();
      }
    } catch (e) {
      debugPrint('Error init data: $e');
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  Future<void> _fetchClassLeaderboard() async {
    if (_selectedCollegeId == null) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final user = SupabaseClientManager.instance.auth.currentUser;
      final entries = await LeaderboardService().fetchClassLeaderboard(
        collegeId: _selectedCollegeId!,
        branch: _selectedBranch,
        year: _selectedYear,
        currentUserId: user?.id ?? '',
      );

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch leaderboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  String _formatYear(int y) {
    if (y == 0) return 'All Years';
    if (y == 1) return '1st Year';
    if (y == 2) return '2nd Year';
    if (y == 3) return '3rd Year';
    return '${y}th Year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0), // Warm off-white
      body: SafeArea(
        child: _isInitLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF111111)))
            : Column(
                children: [
                  _buildFiltersRow(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF111111)))
                        : _buildLeaderboardView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8EC), width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Expanded(
                flex: 7, 
                child: _buildToolbarButton(label: _getCollegeLabel(), onTap: _showCollegePicker)
              ),
              Container(width: 1.0, height: 24, color: const Color(0xFFE8E8EC)),
              Expanded(
                flex: 5, 
                child: _buildToolbarButton(label: _selectedBranch, onTap: _showBranchPicker)
              ),
              Container(width: 1.0, height: 24, color: const Color(0xFFE8E8EC)),
              Expanded(
                flex: 6, 
                child: _buildToolbarButton(label: _formatYear(_selectedYear), onTap: _showYearPicker)
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCollegeLabel() {
    if (_selectedCollegeId == null) return 'College';
    final c = _colleges.firstWhere((x) => x['id'] == _selectedCollegeId, orElse: () => {});
    if (c.isEmpty) return 'College';
    final code = c['code'] as String?;
    return (code != null && code.isNotEmpty) ? code.toUpperCase() : c['name'] as String;
  }

  Widget _buildToolbarButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111111)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF666666)),
          ],
        ),
      ),
    );
  }

  void _showCollegePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE8E8EC), borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Select College', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111111))),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _colleges.length,
                  itemBuilder: (context, index) {
                    final c = _colleges[index];
                    final isSelected = c['id'] == _selectedCollegeId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      title: Text(c['name'] as String, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 15, color: isSelected ? const Color(0xFF111111) : const Color(0xFF444444))),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF111111)) : null,
                      onTap: () {
                        setState(() => _selectedCollegeId = c['id'] as String);
                        Navigator.pop(context);
                        _fetchClassLeaderboard();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBranchPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE8E8EC), borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Select Branch', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111111))),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final b = _branches[index];
                    final isSelected = b == _selectedBranch;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      title: Text(b, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 15, color: isSelected ? const Color(0xFF111111) : const Color(0xFF444444))),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF111111)) : null,
                      onTap: () {
                        setState(() => _selectedBranch = b);
                        Navigator.pop(context);
                        _fetchClassLeaderboard();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE8E8EC), borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Select Year', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111111))),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _years.length,
                  itemBuilder: (context, index) {
                    final y = _years[index];
                    final isSelected = y == _selectedYear;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      title: Text(_formatYear(y), style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 15, color: isSelected ? const Color(0xFF111111) : const Color(0xFF444444))),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF111111)) : null,
                      onTap: () {
                        setState(() => _selectedYear = y);
                        Navigator.pop(context);
                        _fetchClassLeaderboard();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardView() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'No students found matching your filters.',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666), fontWeight: FontWeight.w500),
        ),
      );
    }

    final top1 = _entries.isNotEmpty ? _entries[0] : null;
    final top2 = _entries.length > 1 ? _entries[1] : null;
    final top3 = _entries.length > 2 ? _entries[2] : null;
    final gridEntries = _entries.length > 3 ? _entries.sublist(3) : <LeaderboardEntry>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: _buildPodium(top1, top2, top3),
          ),
        ),
        if (gridEntries.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.70, // Clean layout ratio
                crossAxisSpacing: 12,
                mainAxisSpacing: 24,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridUser(gridEntries[index]),
                childCount: gridEntries.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPodium(LeaderboardEntry? top1, LeaderboardEntry? top2, LeaderboardEntry? top3) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _buildPodiumUser(top2, 2, 64)), // soft sizes
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumUser(top1, 1, 80)),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumUser(top3, 3, 64)),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(LeaderboardEntry? entry, int rank, double avatarSize) {
    if (entry == null) return const SizedBox.shrink();

    final isFirst = rank == 1;

    return GestureDetector(
      onTap: () => _navigateToProfile(entry.userId),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8E8EC), width: 1.5),
              color: Colors.white,
            ),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.person, color: Color(0xFFCCCCCC)),
                    )
                  : const Icon(Icons.person, color: Color(0xFFCCCCCC)),
            ),
          ),
          const SizedBox(height: 10),
          // Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E8EC), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    entry.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF222222)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '${entry.brainScore} pts',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Color(0xFF888888)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Rank text
          Text(
            '#$rank',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF555555)),
          ),
          if (isFirst) const SizedBox(height: 24), // push Rank 1 up
        ],
      ),
    );
  }

  Widget _buildGridUser(LeaderboardEntry entry) {
    return GestureDetector(
      onTap: () => _navigateToProfile(entry.userId),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8E8EC), width: 1.2),
              color: Colors.white,
            ),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.person, color: Color(0xFFCCCCCC)),
                    )
                  : const Icon(Icons.person, color: Color(0xFFCCCCCC)),
            ),
          ),
          const SizedBox(height: 8),
          // Pill
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8E8EC), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      entry.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFF222222)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.brainScore} pts',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 9, color: Color(0xFF888888)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
