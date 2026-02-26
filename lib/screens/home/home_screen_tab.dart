import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../models/devcard/devcard_model.dart';
import '../../models/opportunity_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/devcard/devcard_service.dart';
import '../../services/bookmark_service.dart';
import '../../widgets/main_layout.dart';

class HomeScreenTab extends StatefulWidget {
  const HomeScreenTab({super.key});

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab> {
  bool _isLoading = true;
  String _errorMessage = '';

  UserProfile? _profile;
  DevCardModel? _devCard;
  int _totalOps = 0;
  List<dynamic> _bookmarks = [];
  List<Opportunity> _recentOps = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = AuthService();
      final user = authService.user;
      if (user == null) throw Exception("User not logged in");

      // 1. Fetch Profile
      _profile = await ProfileService().fetchProfile(user.id);
      
      // 2. Fetch DevCard if github_url exists
      final githubUrl = _profile?.githubUrl;
      if (githubUrl != null && githubUrl.isNotEmpty) {
        _devCard = await DevCardService.getDevCard(user.id, githubUrl);
      }

      // 3. Fetch Total Ops Count
      try {
        final countResponse = await Supabase.instance.client
            .from('opportunities')
            .count(CountOption.exact);
        _totalOps = countResponse;
      } catch (e) {
        debugPrint("Error fetching total ops: $e");
      }

      // 4. Fetch Recent Ops
      try {
        final recentData = await Supabase.instance.client
            .from('opportunities')
            .select('*, internship_details(*), hackathon_details(*), event_details(*)')
            .order('created_at', ascending: false)
            .limit(5);
        _recentOps = (recentData as List)
            .map((json) => Opportunity.fromJson(json))
            .toList();
      } catch (e) {
        debugPrint("Error fetching recent ops: $e");
      }

      // 5. Fetch Bookmarks
      _bookmarks = BookmarkService().getBookmarks();

    } catch (e) {
      _errorMessage = "Failed to load dashboard data: $e";
      debugPrint(_errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Completeness logic
  double _calculateCompleteness() {
    if (_profile == null) return 0.0;
    int totalFields = 8;
    int filledFields = 0;
    
    if (_profile!.name?.isNotEmpty == true) filledFields++;
    if (_profile!.college?.isNotEmpty == true) filledFields++;
    if (_profile!.branch?.isNotEmpty == true) filledFields++;
    if (_profile!.year?.isNotEmpty == true) filledFields++;
    if (_profile!.githubUrl?.isNotEmpty == true) filledFields++;
    if (_profile!.linkedinUrl?.isNotEmpty == true) filledFields++;
    if (_profile!.avatarUrl?.isNotEmpty == true) filledFields++;
    if (_profile!.collegeVerified) filledFields++;

    return filledFields / totalFields;
  }

  dynamic _getNearestDeadlineBookmark() {
    if (_bookmarks.isEmpty) return null;
    
    final now = DateTime.now();
    dynamic nearest;
    Duration minDiff = const Duration(days: 9999);

    for (var item in _bookmarks) {
      DateTime? ddl;
      if (item is Opportunity) {
        ddl = item.deadline;
      }
      // Handle details objects if they don't inherit Opportunity
      else {
        // Find property deadline via reflection or cast
        try {
          // hack since we know the shape:
          final map = item.toJson();
          if (map['deadline'] != null) {
            ddl = DateTime.parse(map['deadline']);
          }
        } catch (_) {}
      }

      if (ddl != null && ddl.isAfter(now)) {
        final diff = ddl.difference(now);
        if (diff < minDiff) {
          minDiff = diff;
          nearest = item;
        }
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Techmates",
      showLeadingAvatar: false,
      titleWidget: const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Tech',
              style: TextStyle(
                color: Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                height: 1.0,
              ),
            ),
            TextSpan(
              text: 'mates',
              style: TextStyle(
                color: Color(0xFF0046FF),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: _fetchData, child: const Text('Retry'))
                ],
              )
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 20),
                  _buildQuickStats(),
                  const SizedBox(height: 20),
                  _buildProfileCompleteness(),
                  const SizedBox(height: 24),
                  _buildSmartNudge(),
                  const SizedBox(height: 24),
                  if (_devCard != null) _buildGithubSnapshot(),
                  if (_devCard != null) const SizedBox(height: 24),
                  _buildNewThisWeek(),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting() {
    final firstName = _profile?.name?.split(' ').first ?? 'Developer';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $firstName 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_profile?.college?.isNotEmpty == true)
              _buildChip(Icons.school, _profile!.college!),
            if (_profile?.branch?.isNotEmpty == true || _profile?.year?.isNotEmpty == true)
              _buildChip(Icons.book, '${_profile?.branch ?? ''} • ${_profile?.year ?? ''} Year'),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.bookmark, '${_bookmarks.length}', 'Saved Ops', Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.work, '$_totalOps', 'Total Ops', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.local_fire_department, '${_devCard?.currentStreak ?? 0}', 'Day Streak', Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withAlpha(204))),
        ],
      ),
    );
  }

  Widget _buildProfileCompleteness() {
    final completeness = _calculateCompleteness();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Profile Completeness', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(completeness * 100).toInt()}%', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completeness,
          backgroundColor: Theme.of(context).dividerColor,
          color: Theme.of(context).primaryColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        if (completeness < 1.0) ...[
          const SizedBox(height: 8),
          Text('Complete your profile to unlock more personalized opportunities.', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ]
      ],
    );
  }

  Widget _buildSmartNudge() {
    final nearest = _getNearestDeadlineBookmark();
    if (nearest == null) return const SizedBox.shrink();

    String title = 'Opportunity';
    DateTime? ddl;
    
    if (nearest is Opportunity) {
      title = nearest.title;
      ddl = nearest.deadline;
    } else {
      try {
        final map = nearest.toJson();
        title = map['title'] ?? title;
        if (map['deadline'] != null) ddl = DateTime.parse(map['deadline']);
      } catch (_) {}
    }

    if (ddl == null) return const SizedBox.shrink();

    final days = ddl.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade800, Colors.deepOrange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Approaching Deadline!', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Closes in $days days', style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildGithubSnapshot() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117), // GitHub Dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, color: Colors.white),
              const SizedBox(width: 8),
              const Text('GitHub Snapshot', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636), // GitHub Green
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Rank: ${_devCard!.scoreBreakdown.rank}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGithubStat('Score', '${_devCard!.scoreBreakdown.total}'),
              _buildGithubStat('Commits', '${_devCard!.totalCommitsLastYear}'),
              _buildGithubStat('Repos', '${_devCard!.totalPublicRepos}'),
            ],
          ),
          const SizedBox(height: 16),
          if (_devCard!.topLanguages.isNotEmpty) ...[
            const Text('Top Languages', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _devCard!.topLanguages.take(3).map((l) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: Color(int.parse(l.color.replaceFirst('#', '0xFF'))), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(l.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              )).toList(),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildGithubStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildNewThisWeek() {
    if (_recentOps.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('New This Week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentOps.length,
            itemBuilder: (context, index) {
              final op = _recentOps[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(op.type.toUpperCase(), style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(op.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(op.organization, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
