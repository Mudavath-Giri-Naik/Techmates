import 'package:flutter/material.dart';
import '../../services/compete_service.dart';
import '../../utils/proxy_url.dart';
import '../profile/profile_screen.dart';
import 'arena_game_screen.dart';

/// Arena detail screen showing leaderboard + play button.
/// Navigated to from the compete screen when user taps an arena card.
class ArenaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> arena;
  final String userId;
  final String? collegeId;

  const ArenaDetailScreen({
    super.key,
    required this.arena,
    required this.userId,
    this.collegeId,
  });

  @override
  State<ArenaDetailScreen> createState() => _ArenaDetailScreenState();
}

class _ArenaDetailScreenState extends State<ArenaDetailScreen> {
  final _service = CompeteService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  String get _arenaName => widget.arena['name'] as String? ?? 'Arena';
  String get _arenaId => widget.arena['id'] as String;

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
      final data = await _service.fetchArenaLeaderboard(_arenaId);
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

  void _navigateToGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArenaGameScreen(
          arena: widget.arena,
          userId: widget.userId,
          collegeId: widget.collegeId,
        ),
      ),
    ).then((_) => _loadLeaderboard());
  }

  void _openProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _arenaName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_entries.length} players',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _error != null
              ? _buildError(cs, theme)
              : _buildContent(cs, theme),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToGame,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Play',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimary,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildError(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadLeaderboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, ThemeData theme) {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 48, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No players yet. Be the first!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _loadLeaderboard,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Podium for top 3
          if (_entries.length >= 3)
            SliverToBoxAdapter(child: _buildPodium(cs, theme)),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Rankings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Full list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildLeaderboardRow(index, cs, theme),
              childCount: _entries.length,
            ),
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Podium ──────────────────────────────────────────

  Widget _buildPodium(ColorScheme cs, ThemeData theme) {
    final top3 = _entries.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _podiumItem(top3[1], 2, cs, theme),
          const SizedBox(width: 6),
          _podiumItem(top3[0], 1, cs, theme),
          const SizedBox(width: 6),
          _podiumItem(top3[2], 3, cs, theme),
        ],
      ),
    );
  }

  Widget _podiumItem(
      Map<String, dynamic> entry, int position, ColorScheme cs, ThemeData theme) {
    final profile = entry['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'Unknown';
    final avatarUrl = proxyUrl(profile?['avatar_url'] as String?);
    final userId = entry['user_id'] as String? ?? '';
    final rating = entry['rating'];
    final ratingStr = rating != null
        ? double.tryParse(rating.toString())?.toStringAsFixed(0) ?? '—'
        : '—';

    final isCurrentUser = userId == widget.userId;
    final avatarSize = position == 1 ? 64.0 : position == 2 ? 52.0 : 48.0;
    final pillarH = position == 1 ? 48.0 : position == 2 ? 32.0 : 24.0;
    final label = position == 1 ? '1ST' : position == 2 ? '2ND' : '3RD';

    final podiumColor = position == 1
        ? const Color(0xFFF59E0B)
        : position == 2
            ? const Color(0xFF64748B)
            : const Color(0xFFCD7F32);

    return Expanded(
      child: GestureDetector(
        onTap: () => _openProfile(userId),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? cs.primary : podiumColor.withOpacity(0.6),
                  width: isCurrentUser ? 3 : 2,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(name, cs),
                      )
                    : _avatarFallback(name, cs),
              ),
            ),
            const SizedBox(height: 6),

            // Name
            Text(
              _firstName(name),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                color: isCurrentUser ? cs.primary : cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // Rating
            Text(
              ratingStr,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: podiumColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Pillar
            Container(
              height: pillarH,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: podiumColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: podiumColor,
                    letterSpacing: 0.4,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Leaderboard Rows ─────────────────────────────────

  Widget _buildLeaderboardRow(int index, ColorScheme cs, ThemeData theme) {
    final entry = _entries[index];
    final rank = index + 1;
    final userId = entry['user_id'] as String? ?? '';
    final isCurrentUser = userId == widget.userId;

    final profile = entry['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'Unknown';
    final avatarUrl = proxyUrl(profile?['avatar_url'] as String?);
    final college = profile?['college'] as String?;
    final branch = profile?['branch'] as String?;
    final year = profile?['year'] as String?;
    final rating = entry['rating'];
    final ratingStr = rating != null
        ? double.tryParse(rating.toString())?.toStringAsFixed(0) ?? '—'
        : '—';
    final sessions = entry['total_sessions'];
    final sessionsStr = sessions != null ? '$sessions games' : '';

    // Build subtitle: "College · Branch · Year" or partial
    final subtitleParts = <String>[
      if (college != null && college.isNotEmpty) college,
      if (branch != null && branch.isNotEmpty) branch,
      if (year != null && year.isNotEmpty) year,
    ];
    final subtitleStr = subtitleParts.join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: isCurrentUser
            ? cs.primaryContainer.withOpacity(0.12)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _openProfile(userId),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrentUser
                    ? cs.primary.withOpacity(0.3)
                    : cs.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: rank <= 3 ? FontWeight.w800 : FontWeight.w600,
                      color: rank == 1
                          ? const Color(0xFFF59E0B)
                          : rank == 2
                              ? const Color(0xFF64748B)
                              : rank == 3
                                  ? const Color(0xFFCD7F32)
                                  : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar — larger
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          _initials(name),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Name + details (two-line subtitle)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                          color: isCurrentUser ? cs.primary : cs.onSurface,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // College name
                      if (college != null && college.isNotEmpty)
                        Text(
                          college,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      // Branch
                      if (branch != null && branch.isNotEmpty)
                        Text(
                          branch,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      // Year
                      if (year != null && year.isNotEmpty)
                        Text(
                          year,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Rating column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ratingStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'rating',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────

  Widget _avatarFallback(String name, ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _firstName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    return name.split(' ').first;
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
