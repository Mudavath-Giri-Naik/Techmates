import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/devcard/devcard_model.dart';
import '../../services/devcard/devcard_service.dart';
import '../../services/devcard/github_service.dart';
import '../../widgets/devcard/devcard_header.dart';
import '../../widgets/devcard/personality_tags_row.dart';
import '../../widgets/devcard/quick_stats_grid.dart';
import '../../widgets/devcard/languages_section.dart';
import '../../widgets/devcard/strongest_at_section.dart';
import '../../widgets/devcard/recent_activity_feed.dart';
import '../../widgets/devcard/contribution_heatmap.dart';
import '../../widgets/devcard/projects_section.dart';
import '../../widgets/devcard/devcard_shimmer.dart';

class DevCardScreen extends StatefulWidget {
  /// Pass a userId to view another user's DevCard (read-only from cache).
  /// If null, shows the current user's DevCard with refresh capability.
  final String? userId;

  const DevCardScreen({super.key, this.userId});

  @override
  State<DevCardScreen> createState() => _DevCardScreenState();
}

class _DevCardScreenState extends State<DevCardScreen> {
  DevCardModel? _devCard;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String? _githubUrl;

  // Profile info
  String? _userName;
  String? _userCollege;
  String? _userBranch;
  String? _userYear;

  bool get _isOwnCard =>
      widget.userId == null ||
      widget.userId == Supabase.instance.client.auth.currentUser?.id;

  String get _targetUserId =>
      widget.userId ?? Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _targetUserId)
          .limit(1);
      if (rows.isNotEmpty && mounted) {
        final p = rows.first as Map<String, dynamic>;
        setState(() {
          _githubUrl = p['github_url'] as String?;
          _userName = p['name'] as String?;
          _userCollege = p['college'] as String?;
          _userBranch = p['branch'] as String?;
          _userYear = p['year'] as String?;
        });
        if (_githubUrl != null && _githubUrl!.isNotEmpty) {
          _loadDevCard();
        }
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _loadDevCard() async {
    if (_githubUrl == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      DevCardModel? card;
      if (_isOwnCard) {
        card = await DevCardService.getDevCard(_targetUserId, _githubUrl!);
      } else {
        card = await DevCardService.getOtherUserDevCard(_targetUserId);
      }
      if (mounted) setState(() => _devCard = card);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_githubUrl == null || !_isOwnCard) return;
    setState(() {
      _isRefreshing = true;
      _error = null;
    });
    try {
      final username = GitHubService.extractUsername(_githubUrl!);
      final card =
          await DevCardService.refreshDevCard(_targetUserId, username);
      if (mounted) {
        setState(() => _devCard = card);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dev Card refreshed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFF85149),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Dev Card',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _devCard == null) {
      return const DevCardShimmer();
    }

    if (_githubUrl == null || _githubUrl!.isEmpty) {
      return _buildConnectPrompt();
    }

    if (_error != null && _devCard == null) {
      return _buildErrorState();
    }

    if (_devCard != null) {
      return _buildDevCard();
    }

    return const DevCardShimmer();
  }

  Widget _buildConnectPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code_rounded,
                size: 64, color: Color(0xFF30363D)),
            const SizedBox(height: 16),
            const Text(
              'Connect your GitHub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your GitHub URL in your profile to generate your Dev Card.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFF85149)),
            const SizedBox(height: 12),
            const Text(
              'Failed to load Dev Card',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadDevCard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF58A6FF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevCard() {
    final dc = _devCard!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DevCardHeader(
            devCard: dc,
            userName: _userName,
            college: _userCollege,
            branch: _userBranch,
            year: _userYear,
          ),
          const SizedBox(height: 12),
          PersonalityTagsRow(tags: dc.personalityTags),
          const SizedBox(height: 12),
          QuickStatsGrid(devCard: dc),
          const SizedBox(height: 12),
          LanguagesSection(languages: dc.topLanguages),
          const SizedBox(height: 12),
          StrongestAtSection(frameworks: dc.topFrameworks),
          const SizedBox(height: 12),
          RecentActivityFeed(commits: dc.recentCommits),
          const SizedBox(height: 12),
          ContributionHeatmap(days: dc.heatmapData),
          const SizedBox(height: 12),
          ProjectsSection(projects: dc.projects),
          const SizedBox(height: 12),
          _buildRefreshFooter(),
        ],
      ),
    );
  }

  Widget _buildRefreshFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Refreshed ${_timeAgo(_devCard!.lastFetchedAt)}',
            style:
                const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          if (_isOwnCard) ...[
            const SizedBox(width: 16),
            if (_isRefreshing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF58A6FF)),
              )
            else
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF58A6FF),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
