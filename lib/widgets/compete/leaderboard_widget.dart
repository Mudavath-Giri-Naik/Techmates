import 'package:flutter/material.dart';
import '../../services/compete_service.dart';
import '../../utils/proxy_url.dart';

/// Reusable leaderboard widget showing campus TPI rankings.
class LeaderboardWidget extends StatefulWidget {
  final String userId;
  final String? collegeId;
  final int limit;

  const LeaderboardWidget({
    super.key,
    required this.userId,
    this.collegeId,
    this.limit = 50,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final _service = CompeteService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchLeaderboard(
        widget.collegeId,
        limit: widget.limit,
      );

      if (mounted) {
        setState(() {
          _entries = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leaderboard';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text(
          'No leaderboard data yet',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _loadLeaderboard,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
        ),
        itemBuilder: (context, index) => _buildRow(index),
      ),
    );
  }

  Widget _buildRow(int index) {
    final entry = _entries[index];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final rank = index + 1;
    final userId = entry['user_id'] as String? ?? '';
    final tpi = entry['final_tpi'];
    final tpiStr = tpi != null
        ? double.tryParse(tpi.toString())?.toStringAsFixed(0) ?? '—'
        : '—';

    // Extract profile data from the join
    final profile = entry['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'Unknown';
    final avatarUrl = proxyUrl(profile?['avatar_url'] as String?);

    final isCurrentUser = userId == widget.userId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: isCurrentUser
          ? BoxDecoration(
              color: cs.primaryContainer.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.w500,
                color: rank <= 3 ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Icon(Icons.person, size: 16, color: cs.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                color: cs.onSurface,
              ),
            ),
          ),

          // TPI
          Text(
            tpiStr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
