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

    if (_n.phase == SpeedMatchPhase.loadingInfo) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final level = _n.userLevel;
    final bestScore = _n.allTimeBest;
    final bestCards = _n.bestCorrectAnswers;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Dark Navy Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2A4A), Color(0xFF0F1D33)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.favorite_border,
                          color: Colors.white70),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Speed Match',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                // Domain tag
                Text(
                  'SPEED  >  INFORMATION PROCESSING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00B4D8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Train your Information Processing skills by quickly '
                  'determining whether the symbols match.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Information Processing involves quickly perceiving, '
                  'analyzing, and responding to new information.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // How to play button
                OutlinedButton.icon(
                  onPressed: () => HowToPlaySheet.show(context),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('HOW TO PLAY'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.4)),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                _statRow('Game LPI', '⚡ ${level.bestScoreAtLevel}', cs, theme),
                _statRow('Best Score', '$bestScore', cs, theme),
                _statRow(
                    'Best Stat', '$bestCards Cards', cs, theme),
                _statRow('Level', '${level.currentLevel}', cs, theme),
                _statRow(
                  'Total Plays',
                  '${level.totalPlaysThisWeek} of 8',
                  cs,
                  theme,
                ),
              ],
            ),
          ),

          // ── Bottom Bar ──
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back,
                      size: 16, color: const Color(0xFF00B4D8)),
                  label: Text(
                    'ALL GAMES',
                    style: TextStyle(
                      color: const Color(0xFF00B4D8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      _n.showModeSelect();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            SpeedMatchModeScreen(notifier: _n),
                      ));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
      String label, String value, ColorScheme cs, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
