import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/leaderboard_service.dart';
import '../../services/profile_service.dart';
import '../../utils/proxy_url.dart';

/// Ranks tab — leaderboard with Class / Dept / College tabs.
class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  final _service = LeaderboardService();
  int _tabIndex = 0; // 0 = Class, 1 = Dept, 2 = College
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _classroomId, _departmentId, _collegeId;
  String? _userId;

  // Context labels
  String? _collegeName;
  String? _departmentName;
  String? _branch;
  int? _year;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _userId = user.id;
    try {
      final profile = await ProfileService().fetchProfile(user.id);
      if (profile != null && mounted) {
        _collegeId = profile.collegeId;
        _branch = profile.branch;
        _year = profile.year;

        // Get classroom_id and department_id from the leaderboard view
        // since UserProfile model doesn't expose them.
        try {
          final row = await Supabase.instance.client
              .from('v_college_leaderboard')
              .select('classroom_id, department_id')
              .eq('user_id', user.id)
              .maybeSingle();
          if (row != null) {
            _classroomId = row['classroom_id'] as String?;
            _departmentId = row['department_id'] as String?;
          }
        } catch (e) {
          debugPrint('❌ [RanksScreen] fetch ids: $e');
        }

        // Fetch context names
        await _fetchContextNames();

        if (mounted) {
          setState(() {});
          _loadLeaderboard();
        }
      }
    } catch (e) {
      debugPrint('❌ [RanksScreen] loadProfile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchContextNames() async {
    try {
      // College name
      if (_collegeId != null) {
        final col = await Supabase.instance.client
            .from('colleges')
            .select('name')
            .eq('id', _collegeId!)
            .maybeSingle();
        _collegeName = col?['name'] as String?;
      }
      // Department name
      if (_departmentId != null) {
        final dep = await Supabase.instance.client
            .from('departments')
            .select('name')
            .eq('id', _departmentId!)
            .maybeSingle();
        _departmentName = dep?['name'] as String?;
      }
    } catch (e) {
      debugPrint('❌ [RanksScreen] fetchContextNames: $e');
    }
  }

  /// Returns the context label for the current tab.
  String? get _contextLabel {
    switch (_tabIndex) {
      case 0: // Class
        if (_branch != null) {
          final yearSuffix = _year != null ? ' · Year $_year' : '';
          return '$_branch$yearSuffix';
        }
        return null;
      case 1: // Dept
        return _departmentName;
      case 2: // College
        return _collegeName;
      default:
        return null;
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    List<LeaderboardEntry> list = [];
    try {
      if (_tabIndex == 0 && _classroomId != null) {
        list = await _service.fetchClassLeaderboard(_classroomId!);
      } else if (_tabIndex == 1 && _departmentId != null) {
        list = await _service.fetchDeptLeaderboard(_departmentId!);
      } else if (_tabIndex == 2 && _collegeId != null) {
        list = await _service.fetchCollegeLeaderboard(_collegeId!);
      }
    } catch (e) {
      debugPrint('❌ [RanksScreen] loadLeaderboard: $e');
    }
    if (mounted) setState(() { _entries = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.dark.surface : AppColors.light.surface;
    final inkPrimary = isDark ? AppColors.dark.inkPrimary : AppColors.light.inkPrimary;
    final inkMid = isDark ? AppColors.dark.inkMid : AppColors.light.inkMid;
    final inkFaint = isDark ? AppColors.dark.inkFaint : AppColors.light.inkFaint;

    final contextLabel = _contextLabel;

    return Scaffold(
      backgroundColor: isDark ? surface : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Leaderboard', style: AppTextStyles.headline(color: inkPrimary)),
            ),
            // Tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                selected: {_tabIndex},
                onSelectionChanged: (s) {
                  setState(() => _tabIndex = s.first);
                  _loadLeaderboard();
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.brandPrimary,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: inkMid,
                ),
                segments: const [
                  ButtonSegment(value: 0, label: Text('Class')),
                  ButtonSegment(value: 1, label: Text('Dept')),
                  ButtonSegment(value: 2, label: Text('College')),
                ],
              ),
            ),
            // Context label
            if (contextLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    key: ValueKey(contextLabel),
                    children: [
                      Icon(
                        _tabIndex == 2
                            ? Icons.school_outlined
                            : _tabIndex == 1
                                ? Icons.domain_outlined
                                : Icons.class_outlined,
                        size: 14,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          contextLabel,
                          style: AppTextStyles.bodySmall(color: cs.primary).copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Text('No data yet', style: AppTextStyles.bodyMedium(color: inkFaint)),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadLeaderboard,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _entries.length,
                            itemBuilder: (_, i) => _buildRow(_entries[i], i, isDark),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(LeaderboardEntry e, int index, bool isDark) {
    final surfaceLight = isDark ? AppColors.dark.surfaceLight : AppColors.light.surfaceLight;
    final borderLight = isDark ? AppColors.dark.borderLight : AppColors.light.borderLight;
    final inkPrimary = isDark ? AppColors.dark.inkPrimary : AppColors.light.inkPrimary;
    final inkFaint = isDark ? AppColors.dark.inkFaint : AppColors.light.inkFaint;

    final rank = _tabIndex == 0
        ? e.classRank
        : _tabIndex == 1
            ? e.deptRank
            : e.collegeRank;
    final isMe = e.userId == _userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.brandPrimaryBg
            : (isDark ? surfaceLight : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.brandPrimaryBorder : borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x04000000),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: AppTextStyles.caption(
                color: rank <= 3 ? AppColors.brandPrimary : inkFaint,
              ),
            ),
          ),
          // Avatar
          AppAvatar(
            name: e.fullName,
            url: proxyUrl(e.avatarUrl),
            size: 36,
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.firstName,
                        style: AppTextStyles.bodyMedium(color: inkPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('YOU', style: AppTextStyles.sectionLabel(color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                if (e.streakDays > 0 || e.topDomainKey != null)
                  Text(
                    [
                      if (e.streakDays > 0) '${e.streakDays}d streak',
                      if (e.topDomainKey != null) '${e.topDomainKey} ${e.topDomainScore ?? ''}',
                    ].join(' · '),
                    style: AppTextStyles.bodySmall(color: inkFaint),
                  ),
              ],
            ),
          ),
          // Score
          Text(
            '${e.brainScore}',
            style: AppTextStyles.titleMedium(color: inkPrimary),
          ),
        ],
      ),
    );
  }
}
