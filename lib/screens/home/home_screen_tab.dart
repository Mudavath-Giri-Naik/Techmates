import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/opportunity_feed_item.dart';
import '../../services/home_feed_service.dart';
import '../../utils/time_ago.dart';

import '../../widgets/hackathon_feed_card.dart';
import '../../widgets/internship_feed_card.dart';
import '../../widgets/event_feed_card.dart';
import '../profile/profile_screen.dart'; // Ensure ProfileScreen is imported
import '../../core/supabase_client.dart';

/// Instagram-style Home feed tab wired to real opportunity data.
class HomeScreenTab extends StatefulWidget {
  const HomeScreenTab({super.key});

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab> {
  // ── Services ──────────────────────────────────────────────────
  final HomeFeedService _feedService = HomeFeedService();

  // ── Feed state ────────────────────────────────────────────────
  List<OpportunityFeedItem> _feedItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _hasMore = true;
  late ScrollController _scrollController;

  // ── Watched stories tracking ─────────────────────────────────
  final Set<String> _watchedStoryIds = {};

  // ── Elite stories from feed ───────────────────────────────────
  List<OpportunityFeedItem> get _eliteItems =>
      _feedItems.where((i) => i.isElite).toList();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────

  Future<void> _loadFeed() async {
    try {
      final items = await _feedService.fetchHomeFeed(
        page: 0,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _feedItems = items;
          _currentPage = 0;
          _isLoading = false;
          _hasMore = items.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint('❌ [HomeScreenTab] _loadFeed error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final items = await _feedService.fetchHomeFeed(
        page: nextPage,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _feedItems.addAll(items);
          _currentPage = nextPage;
          _isLoadingMore = false;
          _hasMore = items.length == _pageSize;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add, size: 26, color: Colors.black),
          onPressed: () {},
        ),
        title: Text.rich(
          TextSpan(
            children: const [
              TextSpan(
                text: 'Tech',
                style: TextStyle(color: Colors.red),
              ),
              TextSpan(
                text: 'mates',
                style: TextStyle(color: Colors.black),
              ),
            ],
            style: GoogleFonts.pacifico(fontSize: 28),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              size: 26,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshFeed,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Story Row ──
                    _buildStoryRow(),

                    // ── Divider ──
                    Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),

                    // ── Feed list ──
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _feedItems.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) => Divider(
                        height: 24,
                        thickness: 0.5,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        if (index == _feedItems.length) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildFeedPost(_feedItems[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _refreshFeed() async {
    final items = await _feedService.fetchHomeFeed(
      page: 0,
      pageSize: _pageSize,
    );
    if (mounted) {
      setState(() {
        _feedItems = items;
        _currentPage = 0;
        _hasMore = items.length == _pageSize;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  // STORY ROW
  // ══════════════════════════════════════════════════════════════

  Widget _buildStoryRow() {
    // 1. Get the current user ID
    final currentUserId = SupabaseClientManager.instance.auth.currentUser?.id;

    // 2. Identify if the current user has any elite stories
    final myEliteItems = _eliteItems
        .where((i) => i.posterUserId == currentUserId)
        .toList();

    // 3. Show only other users' elite stories (no "Your story")
    final otherEliteItems = _eliteItems
        .where((i) => i.posterUserId != currentUserId)
        .toList();

    if (otherEliteItems.isEmpty) return const SizedBox.shrink();

    // Sort: unwatched first, watched last
    otherEliteItems.sort((a, b) {
      final aWatched = _watchedStoryIds.contains(a.opportunityId) ? 1 : 0;
      final bWatched = _watchedStoryIds.contains(b.opportunityId) ? 1 : 0;
      return aWatched.compareTo(bWatched);
    });

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: 10),
        itemCount: otherEliteItems.length,
        itemBuilder: (context, index) {
          final item = otherEliteItems[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildEliteStoryItem(item, isYourStory: false),
          );
        },
      ),
    );
  }

  Widget _buildStoryItem(String name, {required bool isYourStory}) {
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          isYourStory
              ? _buildYourStoryAvatar(null)
              : _buildGradientRingAvatar(null),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildEliteStoryItem(
    OpportunityFeedItem item, {
    bool isYourStory = false,
  }) {
    final displayName = isYourStory
        ? 'Your story'
        : (item.posterName ?? item.posterUsername ?? 'TechMates');
    final isWatched = _watchedStoryIds.contains(item.opportunityId);
    final isSpinning = _spinningStoryId == item.opportunityId;

    return GestureDetector(
      onTap: () => _onStoryTap(item),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (isSpinning)
              _buildSpinningAvatar(item.posterAvatarUrl)
            else if (isWatched)
              _buildGreyRingAvatar(item.posterAvatarUrl)
            else
              _buildGradientRingAvatar(item.posterAvatarUrl),
            const SizedBox(height: 4),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isWatched ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _spinningStoryId;

  Future<void> _onStoryTap(OpportunityFeedItem item) async {
    // Start in-place spin
    setState(() => _spinningStoryId = item.opportunityId);

    await Future.delayed(const Duration(milliseconds: 500));

    // Mark as watched, stop spinning
    if (mounted) {
      setState(() {
        _spinningStoryId = null;
        _watchedStoryIds.add(item.opportunityId);
      });
    }

    // Open the story viewer
    _showEliteStoryViewer(item);
  }

  Widget _buildSpinningAvatar(String? avatarUrl) {
    return SizedBox(
      width: 67,
      height: 67,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spinning gradient ring only
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 2 * 3.14159),
            duration: const Duration(milliseconds: 500),
            builder: (context, angle, _) {
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: 67,
                  height: 67,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFf09433),
                        Color(0xFFe6683c),
                        Color(0xFFdc2743),
                        Color(0xFFcc2366),
                        Color(0xFFbc1888),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Static avatar on top
          Container(
            width: 59,
            height: 59,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: CircleAvatar(
              radius: 29,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600])
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreyRingAvatar(String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[350]!, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: 29,
          backgroundColor: Colors.grey[300],
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
      ),
    );
  }

  Widget _buildYourStoryAvatar(String? avatarUrl) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 31,
          backgroundColor: Colors.grey[300],
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.add, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientRingAvatar(String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFf09433),
            Color(0xFFe6683c),
            Color(0xFFdc2743),
            Color(0xFFcc2366),
            Color(0xFFbc1888),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: 29,
          backgroundColor: Colors.grey[300],
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FEED POST CARD
  // ══════════════════════════════════════════════════════════════

  Widget _buildFeedPost(OpportunityFeedItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        _buildPostHeader(item),

        // ── Card body (reusing existing card widgets) ──
        _buildCardBody(item),

        // ── Action row ──
        _buildActionRow(item, timeAgo(item.createdAt)),
      ],
    );
  }

  Widget _buildActionRow(OpportunityFeedItem item, String timeAgoText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIcon(
                const Icon(
                  Icons.favorite_border,
                  size: 22,
                  color: Colors.black87,
                ),
                onTap: () {},
              ),
              const SizedBox(width: 14),
              _actionIcon(
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 22,
                  color: Colors.black87,
                ),
                onTap: () {},
              ),
              const SizedBox(width: 14),
              _actionIcon(_sendIcon(), onTap: () {}),
              const Spacer(),
              _actionIcon(
                const Icon(
                  Icons.bookmark_border,
                  size: 22,
                  color: Colors.black87,
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            timeAgoText.toUpperCase(),
            style: GoogleFonts.dmMono(
              fontSize: 10,
              letterSpacing: 0.8,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(Widget icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.all(4), child: icon),
    );
  }

  Widget _sendIcon() {
    return Transform.rotate(
      angle: -45 * math.pi / 180,
      child: const Icon(Icons.send, size: 22, color: Colors.black87),
    );
  }

  Widget _buildPostHeader(OpportunityFeedItem item) {
    final displayName = item.posterName ?? item.posterUsername ?? 'TechMates';
    final role = item.posterRole;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: item.type == OpportunityType.internship ? 0 : 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          // Poster avatar
          GestureDetector(
            onTap: () => _navigateToPoster(item),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  item.posterAvatarUrl != null &&
                      item.posterAvatarUrl!.isNotEmpty
                  ? NetworkImage(item.posterAvatarUrl!)
                  : null,
              child:
                  item.posterAvatarUrl == null || item.posterAvatarUrl!.isEmpty
                  ? Icon(Icons.person, size: 20, color: Colors.grey[600])
                  : null,
            ),
          ),
          const SizedBox(width: 8),

          // Name + role badge
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToPoster(item),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (role == 'admin' || role == 'super_admin') _buildRoleBadge(role!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        role == 'super_admin' ? 'SA' : 'A',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: role == 'super_admin' ? Colors.red[600] : Colors.amber[700],
        ),
      ),
    );
  }

  Widget _buildCardBody(OpportunityFeedItem item) {
    switch (item.type) {
      case OpportunityType.hackathon:
        return HackathonFeedCard(opportunity: item);
      case OpportunityType.internship:
        return InternshipFeedCard(
          opportunity: item,
          useDarkTemplate: item.isElite,
        );
      case OpportunityType.event:
        return EventFeedCard(opportunity: item);
    }
  }

  // ── Navigation ────────────────────────────────────────────────

  void _navigateToPoster(OpportunityFeedItem item) {
    if (item.posterUserId == null) return;

    // Navigate to the full User Profile screen instead of the minimal dummy
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: item.posterUserId),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ELITE STORY VIEWER
  // ══════════════════════════════════════════════════════════════

  void _showEliteStoryViewer(OpportunityFeedItem item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close story',
      barrierColor: Colors.black87,
      pageBuilder: (ctx, anim1, anim2) {
        return _EliteStoryViewer(item: item);
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ELITE STORY VIEWER (full-screen modal)
// ══════════════════════════════════════════════════════════════════════════════

class _EliteStoryViewer extends StatefulWidget {
  final OpportunityFeedItem item;
  const _EliteStoryViewer({required this.item});

  @override
  State<_EliteStoryViewer> createState() => _EliteStoryViewerState();
}

class _EliteStoryViewerState extends State<_EliteStoryViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final topPad = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _progressCtrl.stop(),
          onLongPressEnd: (_) => _progressCtrl.forward(),
          onTapDown: (_) => _progressCtrl.stop(),
          onTapUp: (_) => _progressCtrl.forward(),
          onTapCancel: () => _progressCtrl.forward(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // ── Main content ──
              Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: EdgeInsets.only(
                      top: topPad + 8,
                      left: 12,
                      right: 12,
                    ),
                    child: AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _progressCtrl.value,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.black87,
                            ),
                            minHeight: 2.5,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Top row: poster info + close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              item.posterAvatarUrl != null &&
                                  item.posterAvatarUrl!.isNotEmpty
                              ? NetworkImage(item.posterAvatarUrl!)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.posterName ?? item.posterUsername ?? 'TechMates',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card body
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: SingleChildScrollView(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: Colors.white,
                              child: _buildStoryCard(item),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        // View Post button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                item.postLink != null && item.postLink!.isNotEmpty
                                ? () => _openUrl(item.postLink)
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(
                                color:
                                    item.postLink != null &&
                                        item.postLink!.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey[400]!,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'View Post',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Apply Now button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                item.applyLink != null &&
                                    item.applyLink!.isNotEmpty
                                ? () => _openUrl(item.applyLink)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Now',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStoryCard(OpportunityFeedItem item) {
    switch (item.type) {
      case OpportunityType.hackathon:
        return HackathonFeedCard(opportunity: item);
      case OpportunityType.internship:
        return InternshipFeedCard(
          opportunity: item,
          useDarkTemplate: item.isElite,
        );
      case OpportunityType.event:
        return EventFeedCard(opportunity: item);
    }
  }
}
