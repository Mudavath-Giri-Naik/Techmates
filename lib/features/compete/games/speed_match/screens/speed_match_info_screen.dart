import 'package:flutter/material.dart';

import '../speed_match_notifier.dart';
import '../widgets/how_to_play_sheet.dart';
import 'speed_match_mode_screen.dart';

/// Game info screen: stats + HOW TO PLAY + PLAY CTA.
class SpeedMatchInfoScreen extends StatefulWidget {
  final SpeedMatchNotifier notifier;

  const SpeedMatchInfoScreen({super.key, required this.notifier});

  @override
  State<SpeedMatchInfoScreen> createState() => _SpeedMatchInfoScreenState();
}

class _SpeedMatchInfoScreenState extends State<SpeedMatchInfoScreen> {
  SpeedMatchNotifier get _n => widget.notifier;

  @override
  void initState() {
    super.initState();
    if (_n.phase == SpeedMatchPhase.initial) {
      _n.loadInfo();
    }
    _n.addListener(_onNotify);
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (_n.phase == SpeedMatchPhase.loadingInfo) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: cs.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final level = _n.userLevel;
    final bestScore = _n.allTimeBest;
    final bestCards = _n.bestCorrectAnswers;

    // M3 tonal surface for header
    final headerBg = isDark
        ? Color.alphaBlend(cs.primary.withOpacity(0.12), cs.surface)
        : Color.alphaBlend(cs.primary.withOpacity(0.07), cs.surface);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Header ──
          _Header(
            topPad: topPad,
            headerBg: headerBg,
            cs: cs,
            theme: theme,
            isDark: isDark,
            onClose: () => Navigator.of(context).pop(),
          ),

          // ── Body ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              children: [
                // Domain chip
                _DomainChip(cs: cs),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Train your Information Processing skills by quickly '
                  'determining whether the symbols match.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Information Processing involves quickly perceiving, '
                  'analyzing, and responding to new information.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // How to play
                OutlinedButton.icon(
                  onPressed: () => HowToPlaySheet.show(context),
                  icon: Icon(Icons.help_outline_rounded,
                      size: 17, color: cs.primary),
                  label: Text(
                    'HOW TO PLAY',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.6,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cs.outlineVariant, width: 1),
                  ),
                ),
                const SizedBox(height: 28),

                // Stats card
                _StatsCard(
                  cs: cs,
                  theme: theme,
                  isDark: isDark,
                  rows: [
                    ('Game LPI', '⚡ ${level.bestScoreAtLevel}'),
                    ('Best Score', '$bestScore'),
                    ('Best Stat', '$bestCards Cards'),
                    ('Level', '${level.currentLevel}'),
                    ('Total Plays', '${level.totalPlaysThisWeek} of 8'),
                  ],
                ),
              ],
            ),
          ),

          // ── Bottom Bar ──
          _BottomBar(
            cs: cs,
            isDark: isDark,
            bottomPad: bottomPad,
            onBack: () => Navigator.of(context).pop(),
            onPlay: () {
              _n.showModeSelect();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SpeedMatchModeScreen(notifier: _n),
              ));
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  final Color headerBg;
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onClose;

  const _Header({
    required this.topPad,
    required this.headerBg,
    required this.cs,
    required this.theme,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 4,
        left: 4,
        right: 4,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.45),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top action row
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurfaceVariant, size: 22),
                onPressed: onClose,
                tooltip: 'Close',
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.favorite_border_rounded,
                    color: cs.onSurfaceVariant, size: 22),
                onPressed: () {},
                tooltip: 'Favourite',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.bolt_rounded,
                      color: cs.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 14),
                Text(
                  'Speed Match',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  final ColorScheme cs;

  const _DomainChip({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'SPEED  ›  INFORMATION PROCESSING',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: cs.onSecondaryContainer,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;
  final List<(String, String)> rows;

  const _StatsCard({
    required this.cs,
    required this.theme,
    required this.isDark,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(isDark ? 0.3 : 0.55),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.45),
              ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final double bottomPad;
  final VoidCallback onBack;
  final VoidCallback onPlay;

  const _BottomBar({
    required this.cs,
    required this.isDark,
    required this.bottomPad,
    required this.onBack,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPad + 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(isDark ? 0.2 : 0.35),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: Icon(Icons.apps_rounded, size: 17, color: cs.primary),
            label: Text(
              'ALL GAMES',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onPlay,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              minimumSize: const Size(130, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'PLAY',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}