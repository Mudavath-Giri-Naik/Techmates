import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/compete_service.dart';
import '../../services/profile_service.dart';
import 'arena_detail_screen.dart';

class CompeteScreen extends StatefulWidget {
  const CompeteScreen({super.key});

  @override
  State<CompeteScreen> createState() => _CompeteScreenState();
}

class _CompeteScreenState extends State<CompeteScreen> {
  final _service = CompeteService();
  final _profileService = ProfileService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _arenas = [];
  Map<String, Map<String, dynamic>> _arenaStats = {}; // arenaId → stats
  String? _userId;
  String? _collegeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not logged in';
          _loading = false;
        });
        return;
      }
      _userId = user.id;

      // Fetch profile for college_id
      final profile = await _profileService.fetchProfile(user.id);
      _collegeId = profile?.collegeId;

      // Fetch arenas and user stats in parallel
      final results = await Future.wait([
        _service.fetchArenas(),
        _service.fetchUserArenaStats(user.id),
      ]);

      final arenas = results[0] as List<Map<String, dynamic>>;
      final stats = results[1] as List<Map<String, dynamic>>;

      // Map stats by arena_id for quick lookup
      final statsMap = <String, Map<String, dynamic>>{};
      for (final s in stats) {
        final arenaId = s['arena_id'] as String?;
        if (arenaId != null) statsMap[arenaId] = s;
      }

      if (mounted) {
        setState(() {
          _arenas = arenas;
          _arenaStats = statsMap;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CompeteScreen] Load error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load arenas. Please try again.';
          _loading = false;
        });
      }
    }
  }

  // Arena icon based on name
  IconData _arenaIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('memory')) return Icons.grid_view_rounded;
    if (lower.contains('math')) return Icons.calculate_outlined;
    if (lower.contains('code') || lower.contains('logic')) {
      return Icons.code_rounded;
    }
    return Icons.bolt_rounded;
  }

  // Arena description based on name
  String _arenaDescription(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('memory')) return 'Test your visual recall and pattern recognition';
    if (lower.contains('math')) return 'Solve problems under time pressure';
    if (lower.contains('code') || lower.contains('logic')) {
      return 'Debug and reason through logic puzzles';
    }
    return 'Compete and prove your skill';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _error != null
                ? _buildError(cs)
                : _buildContent(cs, theme),
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, ThemeData theme) {
    return RefreshIndicator.adaptive(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          // ── Header ──
          Text(
            'Compete',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Test your ability under pressure',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          // ── Arena Cards ──
          if (_arenas.isEmpty)
            _buildEmptyState(cs)
          else
            ..._arenas.map((arena) => _buildArenaCard(arena, cs, theme)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          children: [
            Icon(Icons.sports_esports_outlined,
                size: 48, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No arenas available yet',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArenaCard(
      Map<String, dynamic> arena, ColorScheme cs, ThemeData theme) {
    final arenaId = arena['id'] as String;
    final name = arena['name'] as String? ?? 'Arena';
    final stats = _arenaStats[arenaId];
    final rating = stats?['rating'] != null
        ? double.tryParse(stats!['rating'].toString())?.toStringAsFixed(0) ?? '—'
        : '—';
    final sessions = stats?['total_sessions']?.toString() ?? '0';
    final icon = _arenaIcon(name);
    final description = _arenaDescription(name);

    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToGame(arena),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.015),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cs.primaryContainer.withOpacity(0.6),
                  ),
                  child: Icon(icon, size: 22, color: cs.primary),
                ),
                const SizedBox(width: 14),

                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Rating + Sessions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rating,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sessions == '0' ? 'New' : '$sessions played',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: cs.onSurfaceVariant.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToGame(Map<String, dynamic> arena) {
    if (_userId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArenaDetailScreen(
          arena: arena,
          userId: _userId!,
          collegeId: _collegeId,
        ),
      ),
    ).then((_) {
      // Refresh stats when returning from game
      _loadData();
    });
  }
}
