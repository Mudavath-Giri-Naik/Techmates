import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/devcard/devcard_model.dart';
import '../../services/devcard/devcard_service.dart';
import '../../services/devcard/github_service.dart';
import '../../widgets/devcard/devcard_shimmer.dart';
import '../../widgets/devcard/devcard_widget.dart';

class DevCardScreen extends StatefulWidget {
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
  bool _isDark = true;
  int _loadingStep = 0;

  String? _userName;
  String? _userCollege;
  String? _userBranch;
  String? _userYear;

  final _repaintKey = GlobalKey();

  static const _loadingMessages = [
    'Fetching GitHub profile...',
    'Analyzing repositories...',
    'Calculating DIC score...',
    'Building your DevCard...',
  ];

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

  // ─── Data loading ─────────────────────────────────────────────

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
      _loadingStep = 0;
    });
    _cycleLoadingMessages();
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

  void _cycleLoadingMessages() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_isLoading) return false;
      setState(() => _loadingStep = (_loadingStep + 1) % _loadingMessages.length);
      return true;
    });
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dev Card refreshed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Refresh failed: $e'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFF43F5E)));
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ─── Share ────────────────────────────────────────────────────

  Future<void> _share() async {
    try {
      // If share is triggered from inside the card (footer button),
      // let that tap/ripple frame settle before capturing the boundary.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final fileName = 'techmates_devcard_${_devCard?.githubUsername ?? 'user'}.png';
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'image/png')],
        text: 'Check out my DevCard on Techmates!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Share failed: $e'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  // ─── Report ───────────────────────────────────────────────────

  void _showReport() {
    if (_devCard == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(devCard: _devCard!, isDark: _isDark),
    );
  }

  // ─── GitHub URL dialog ────────────────────────────────────────

  void _showGitHubDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            _isDark ? const Color(0xFF141E2F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Add GitHub',
            style: TextStyle(
                color: _isDark
                    ? const Color(0xFFEDF2FF)
                    : const Color(0xFF1A1A2E))),
        content: TextField(
          controller: controller,
          style: TextStyle(
              color: _isDark
                  ? const Color(0xFFEDF2FF)
                  : const Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: 'github.com/username',
            hintStyle: TextStyle(
                color: _isDark
                    ? const Color(0xFF6B7FA0)
                    : const Color(0xFF6B7280)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: _isDark
                      ? const Color(0xFF1E2D42)
                      : const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: _isDark
                        ? const Color(0xFF6B7FA0)
                        : const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('profiles')
                    .update({'github_url': url}).eq('id', _targetUserId);
                setState(() => _githubUrl = url);
                _loadDevCard();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      behavior: SnackBarBehavior.floating));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: const Color(0xFF0D1120),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceBg = theme.colorScheme.surface;
    final appBarBg = theme.colorScheme.surface;
    final text1 = theme.colorScheme.onSurface;
    final text2 = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('DevCard',
            style: TextStyle(
                color: text1,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: false,
        iconTheme: IconThemeData(color: text1),
        actions: [
          // Dark/Light toggle
          IconButton(
            onPressed: () => setState(() => _isDark = !_isDark),
            icon: Icon(
                _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20),
            color: text2,
            tooltip: _isDark ? 'Preview Light DevCard' : 'Preview Dark DevCard',
          ),
          if (_isOwnCard && _devCard != null) ...[
            // Refresh
            if (_isRefreshing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF00D4FF))),
              )
            else
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: text2,
                tooltip: 'Refresh',
              ),
            // Share
            IconButton(
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              color: text2,
              tooltip: 'Share',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // State 1: No GitHub URL
    if (_githubUrl == null || _githubUrl!.isEmpty) {
      if (!_isLoading) return _connectPrompt(context);
    }

    // State 2: Loading
    if (_isLoading && _devCard == null) {
      return Column(
        children: [
          Expanded(child: DevCardShimmer(isDark: _isDark)),
          Container(
            padding: const EdgeInsets.all(16),
            color: _isDark ? const Color(0xFF0D1120) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF00D4FF))),
                const SizedBox(width: 10),
                Text(_loadingMessages[_loadingStep],
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      );
    }

    // State 3: Error
    if (_error != null && _devCard == null) {
      return _errorState(context);
    }

    // State 4: Loaded
    if (_devCard != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RepaintBoundary(
              key: _repaintKey,
              child: DevCardWidget(
                devCard: _devCard!,
                isDark: _isDark,
                userName: _userName,
                college: _userCollege,
                branch: _userBranch,
                year: _userYear,
                onReport: _showReport,
                onShare: _share,
              ),
            ),
          ),
        ),
      );
    }

    return DevCardShimmer(isDark: _isDark);
  }

  Widget _connectPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final text1 = theme.colorScheme.onSurface;
    final text2 = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code_rounded,
                size: 64,
                color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Connect your GitHub',
                style: TextStyle(
                    color: text1,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Connect your GitHub to generate your DevCard',
              textAlign: TextAlign.center,
              style: TextStyle(color: text2, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showGitHubDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF0D1120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add GitHub',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final theme = Theme.of(context);
    final text1 = theme.colorScheme.onSurface;
    final text2 = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFF43F5E)),
            const SizedBox(height: 12),
            Text('Failed to load Dev Card',
                style: TextStyle(
                    color: text1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: text2, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadDevCard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style:
                  TextButton.styleFrom(foregroundColor: const Color(0xFF00D4FF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report Bottom Sheet ──────────────────────────────────────────

class _ReportSheet extends StatelessWidget {
  final DevCardModel devCard;
  final bool isDark;

  const _ReportSheet({required this.devCard, required this.isDark});

  Color get _bg => isDark ? const Color(0xFF0D1120) : Colors.white;
  Color get _surface => isDark ? const Color(0xFF141E2F) : const Color(0xFFF9FAFB);
  Color get _text1 => isDark ? const Color(0xFFEDF2FF) : const Color(0xFF1A1A2E);
  Color get _text2 => isDark ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);
  Color get _border => isDark ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B8B8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sb = devCard.scoreBreakdown;
    final rankColor = _parseHex(sb.rankColor);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Full Report',
                      style: TextStyle(
                          color: _text1,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${sb.rankEmoji} ${sb.rank} · ${sb.total}/1000',
                        style: TextStyle(
                            color: rankColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Divider(color: _border, height: 1),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Score Breakdown ──
                  _sectionTitle('SCORE BREAKDOWN'),
                  const SizedBox(height: 8),
                  _scoreCard(
                    'Depth',
                    sb.depth,
                    const Color(0xFF00D4FF),
                    sb.depthReason,
                    sb.depthTip,
                    '⚡',
                  ),
                  _scoreCard(
                    'Consistency',
                    sb.consistency,
                    const Color(0xFF8B5CF6),
                    sb.consistencyReason,
                    sb.consistencyTip,
                    '🔄',
                  ),
                  _scoreCard(
                    'Breadth',
                    sb.breadth,
                    const Color(0xFFF59E0B),
                    sb.breadthReason,
                    sb.breadthTip,
                    '🌐',
                  ),
                  _scoreCard(
                    'Activity',
                    sb.activity,
                    const Color(0xFFF43F5E),
                    sb.activityReason,
                    sb.activityTip,
                    '🔥',
                  ),

                  const SizedBox(height: 16),
                  // ── Overall Stats ──
                  _sectionTitle('OVERALL STATISTICS'),
                  const SizedBox(height: 8),
                  _statsGrid(),

                  const SizedBox(height: 16),
                  // ── Top Project ──
                  if (sb.topProjectName.isNotEmpty) ...[
                    _sectionTitle('TOP PROJECT'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sb.topProjectName,
                                    style: TextStyle(
                                        color: _text1,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text('Score: ${sb.topProjectScore}/100',
                                    style: TextStyle(
                                        color: _text2,
                                        fontSize: 11,
                                        fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  // ── Per-Project Scores ──
                  if (devCard.projectScores.isNotEmpty) ...[
                    _sectionTitle('PROJECT-BY-PROJECT ANALYSIS'),
                    const SizedBox(height: 8),
                    ...devCard.projectScores.asMap().entries.map((e) {
                      final i = e.key;
                      final ps = e.value;
                      return _projectScoreCard(i, ps);
                    }),
                  ],

                  const SizedBox(height: 16),
                  // ── Language Distribution ──
                  if (devCard.topLanguages.isNotEmpty) ...[
                    _sectionTitle('LANGUAGE DISTRIBUTION'),
                    const SizedBox(height: 8),
                    ...devCard.topLanguages.map(_langRow),
                  ],

                  const SizedBox(height: 16),
                  // ── Personality Tags ──
                  if (devCard.personalityTags.isNotEmpty) ...[
                    _sectionTitle('DEVELOPER PERSONALITY'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: devCard.personalityTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF)
                                .withValues(alpha: isDark ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF00D4FF)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(
            color: _text2,
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5));
  }

  Widget _scoreCard(String label, int value, Color color, String reason,
      String tip, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: _text1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$value / 100',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
            ),
          ]),
          const SizedBox(height: 6),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 ', style: TextStyle(fontSize: 10)),
                Expanded(
                    child: Text(reason,
                        style: TextStyle(color: _text2, fontSize: 11))),
              ],
            ),
          ],
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 ', style: TextStyle(fontSize: 10)),
                Expanded(
                    child: Text(tip,
                        style: TextStyle(
                            color: const Color(0xFF22C55E), fontSize: 11))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final items = [
      ('Commits', '${devCard.totalCommitsLastYear}'),
      ('Repos', '${devCard.totalPublicRepos}'),
      ('Stars', '${devCard.totalStars}'),
      ('PRs', '${devCard.totalPRs}'),
      ('Current Streak', '${devCard.currentStreak}d'),
      ('Best Streak', '${devCard.longestStreak}d'),
      ('Active Days', '${(devCard.activeDaysPercentage * 100).toStringAsFixed(0)}%'),
      ('Issues', '${devCard.totalIssues}'),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        return Container(
          width: (MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size.width - 50) / 2,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.$1,
                  style: TextStyle(
                      color: _text2, fontSize: 10, fontFamily: 'monospace')),
              Text(item.$2,
                  style: TextStyle(
                      color: _text1,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _projectScoreCard(int index, ProjectScore ps) {
    final badgeColor = ps.finalScore >= 80
        ? const Color(0xFF22C55E)
        : ps.finalScore >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFF43F5E);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('#${index + 1}',
                style: TextStyle(
                    color: _text2,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(ps.projectName,
                    style: TextStyle(
                        color: _text1,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text('${ps.finalScore.round()}/100',
                  style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _miniStat('Commit', ps.commitScore),
            _miniStat('README', ps.readmeScore),
            _miniStat('Tech', ps.techScore),
            if (ps.timelineMultiplier != 1.0)
              _miniStat('×${ps.timelineMultiplier.toStringAsFixed(1)}', null),
          ]),
          const SizedBox(height: 4),
          Container(
            height: 3,
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (ps.finalScore / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int? value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: _text2, fontSize: 8, fontFamily: 'monospace')),
          if (value != null)
            Text('$value',
                style: TextStyle(
                    color: _text1,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _langRow(LanguageStat l) {
    final color = _parseHex(l.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        SizedBox(
            width: 80,
            child: Text(l.name,
                style: TextStyle(color: _text1, fontSize: 11))),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: l.percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(l.percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                color: _text2, fontSize: 10, fontFamily: 'monospace')),
      ]),
    );
  }
}
