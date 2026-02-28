import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/follow_model.dart';
import '../../models/student_network_model.dart';
import '../../services/follow_service.dart';
import '../../widgets/network/follow_button.dart';
import 'student_profile_screen.dart';

/// Reusable screen that shows a list of followers or following.
class FollowListScreen extends StatefulWidget {
  final String userId;
  final String title; // "Followers" or "Following"
  final bool isFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<FollowUserItem> _allUsers = [];
  List<FollowUserItem> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = widget.isFollowers
          ? await FollowService().getFollowersList(widget.userId)
          : await FollowService().getFollowingList(widget.userId);

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filtered = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ${widget.title.toLowerCase()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _allUsers);
      return;
    }

    setState(() {
      _filtered = _allUsers.where((u) {
        return (u.name?.toLowerCase().contains(q) ?? false) ||
            (u.college?.toLowerCase().contains(q) ?? false) ||
            (u.branch?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  void _navigateToProfile(FollowUserItem user) {
    // Construct a minimal StudentNetworkModel from the FollowUserItem
    final student = StudentNetworkModel(
      id: user.id,
      name: user.name,
      branch: user.branch,
      year: user.year,
      avatarUrl: user.avatarUrl,
      college: user.college,
      isPrivate: user.isPrivate,
      followStatus: user.followStatus,
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => StudentProfileScreen(student: student),
      ),
    )
        .then((_) => _fetchList());
  }

  Widget _buildAvatar(FollowUserItem user) {
    final url = user.avatarUrl;
    final initial =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';

    Widget fallback = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => fallback,
          placeholder: (_, _) => fallback,
        ),
      );
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchList,
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),

                      // List
                      Expanded(
                        child: _filtered.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  return _buildUserRow(_filtered[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserRow(FollowUserItem user) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _navigateToProfile(user),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isPrivate) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ],
                  ),
                  if (user.college != null || user.branch != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [user.college, user.branch]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FollowButton(
              targetUserId: user.id,
              initialStatus: user.followStatus,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _fetchList,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isFollowers
                ? 'No followers yet'
                : 'Not following anyone yet',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
