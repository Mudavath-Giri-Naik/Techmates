import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';

import '../../models/opportunity_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/home_data_service.dart';

import 'widgets/greeting_header.dart';
import 'widgets/college_leaderboard_card.dart';
import 'widgets/closing_soon_section.dart';
import 'widgets/elite_picks_section.dart';
import 'widgets/new_this_week_section.dart';
import 'widgets/college_pulse_section.dart';

class HomeScreenTab extends StatefulWidget {
  const HomeScreenTab({super.key});

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab> {
  // ── State ──────────────────────────────────────────────────
  bool _isLoading = true;
  bool _hasError = false;

  UserProfile? _profile;

  // Section data
  List<Map<String, dynamic>> _closingSoon = [];
  List<Map<String, dynamic>> _elitePicks = [];
  List<Opportunity> _newThisWeek = [];
  List<Map<String, dynamic>> _leaderboardStudents = [];

  // College pulse
  int _collegeStudentCount = 0;
  String _collegeName = '';
  List<Map<String, dynamic>> _collegePulseStudents = [];

  // Stats
  int _newSinceLastVisit = 0;

  // Services
  final _homeDataService = HomeDataService();
  final _bookmarkService = BookmarkService();

  static const String _lastVisitKey = 'home_last_visit';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

      // Read last visit timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastVisitStr = prefs.getString(_lastVisitKey);
      final lastVisitTime = lastVisitStr != null
          ? DateTime.tryParse(lastVisitStr) ??
              DateTime.now().subtract(const Duration(days: 7))
          : DateTime.now().subtract(const Duration(days: 7));

      // Parallel fetch: profile + all home sections
      final results = await Future.wait([
        ProfileService().fetchProfile(userId),                      // 0
        _homeDataService.fetchClosingSoon(),                        // 1
        _homeDataService.fetchElitePicks(),                         // 2
        _homeDataService.fetchNewThisWeek(),                        // 3
        _homeDataService.fetchNewOpsSince(lastVisitTime),           // 4
      ]);

      final profile = results[0] as UserProfile?;
      final closingSoon = results[1] as List<Map<String, dynamic>>;
      final elitePicks = results[2] as List<Map<String, dynamic>>;
      final newThisWeek = results[3] as List<Opportunity>;
      final newSinceLastVisit = results[4] as int;

      // College data (needs profile.collegeId)
      List<Map<String, dynamic>> leaderboard = [];
      int collegeCount = 0;
      String collegeName = profile?.college ?? '';
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
        pulseStudents =
            ((pulseData['students'] as List?) ?? []).cast<Map<String, dynamic>>();
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
        _collegePulseStudents = pulseStudents;
        _isLoading = false;
      });

      // Update last visit timestamp
      await prefs.setString(_lastVisitKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ [HomeScreenTab] _loadData error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? _buildShimmerSkeleton(context)
          : _hasError
              ? _buildErrorState(context)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: colorScheme.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // Section 1 — Greeting Header
                      SliverToBoxAdapter(
                        child: GreetingHeader(profile: _profile),
                      ),

                      // Section 2 — College Leaderboard Spotlight
                      SliverToBoxAdapter(
                        child: CollegeLeaderboardCard(
                          students: _leaderboardStudents,
                          collegeName: _collegeName.isNotEmpty
                              ? _collegeName
                              : (_profile?.college ?? 'Your College'),
                          isLoading: false,
                          onFullBoard: () {
                            // Navigate to Network tab (index 1)
                            _navigateToTab(1);
                          },
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // Section 3 — Closing Soon
                      if (_closingSoon.isNotEmpty)
                        SliverToBoxAdapter(
                          child: ClosingSoonSection(
                            items: _closingSoon,
                            onSeeAll: () => _navigateToTab(2),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // Section 4 — Elite Picks
                      if (_elitePicks.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ElitePicksSection(items: _elitePicks),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // Section 5 — New This Week
                      if (_newThisWeek.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: NewThisWeekSection(
                              items: _newThisWeek,
                              newSinceLastVisit: _newSinceLastVisit,
                              onViewAll: () => _navigateToTab(2),
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // Section 6 — College Pulse
                      if (_collegeStudentCount > 0)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: CollegePulseSection(
                              studentCount: _collegeStudentCount,
                              collegeName: _collegeName,
                              topStudents: _collegePulseStudents,
                              onTap: () => _navigateToTab(1),
                            ),
                          ),
                        ),

                      // Bottom spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
    );
  }

  void _navigateToTab(int index) {
    // Find the MainScreen ancestor and switch tab
    // The MainScreen uses IndexedStack, so we need to use a callback
    // For now, we can use the bottom nav bar's onDestinationSelected
    // by finding the nearest ancestor State
    try {
      final mainScreenState =
          context.findAncestorStateOfType<State>();
      if (mainScreenState != null && mainScreenState.mounted) {
        // Try to call setState on MainScreen to change tab
        // This is a simple approach — we look for the _MainScreenState
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null) {
          // Navigate using Navigator if we can't reach the tab controller
        }
      }
    } catch (_) {
      // Fallback: do nothing
    }
  }

  // ── Shimmer Skeleton ──────────────────────────────────────
  Widget _buildShimmerSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2B2930) : Colors.grey.shade300;
    final highlightColor =
        isDark ? const Color(0xFF36343B) : Colors.grey.shade100;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting placeholder
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              // Leaderboard card placeholder
              Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 16),
              // Section header placeholder
              Container(
                height: 20,
                width: 140,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Horizontal cards placeholder
              SizedBox(
                height: 140,
                child: Row(
                  children: List.generate(
                    2,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 1 ? 10 : 0),
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Elite card placeholder
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              // Feed cards placeholder
              ...List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 70,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(16),
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

  // ── Error State ──────────────────────────────────────
  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Couldn\'t load your dashboard.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
