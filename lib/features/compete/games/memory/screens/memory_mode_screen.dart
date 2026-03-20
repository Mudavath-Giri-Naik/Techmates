import 'package:flutter/material.dart';

import '../memory_notifier.dart';
import 'memory_game_screen.dart';
import 'memory_waiting_screen.dart';
import 'memory_pregame_screen.dart';

/// Mode selection: Solo vs Duel for Memory Arena.
class MemoryModeScreen extends StatefulWidget {
  final MemoryNotifier notifier;

  const MemoryModeScreen({super.key, required this.notifier});

  @override
  State<MemoryModeScreen> createState() => _MemoryModeScreenState();
}

class _MemoryModeScreenState extends State<MemoryModeScreen> {
  MemoryNotifier get _n => widget.notifier;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    if (!mounted || _navigating) return;
    debugPrint('🧠 MEMORY: ModeScreen._onNotify phase=${_n.phase}');

    switch (_n.phase) {
      case MemoryPhase.playing:
        // Solo → game screen
        _navigating = true;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => MemoryGameScreen(notifier: _n),
        ));
        break;
      case MemoryPhase.searching:
        _navigating = true;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MemoryWaitingScreen(notifier: _n),
        )).then((_) => _navigating = false);
        break;
      case MemoryPhase.preGame:
        _navigating = true;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MemoryPregameScreen(notifier: _n),
        )).then((_) => _navigating = false);
        break;
      default:
        setState(() {});
    }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🧠 Memory Arena 🧠',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: _buildMainOptions(cs, theme),
      ),
    );
  }

  Widget _buildMainOptions(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        _optionCard(
          icon: Icons.psychology,
          title: 'SOLO',
          subtitle: 'Play alone, beat your personal best',
          color: const Color(0xFF00B4D8),
          onTap: () => _n.startSolo(),
          cs: cs,
          theme: theme,
        ),
        const SizedBox(height: 16),
        _optionCard(
          icon: Icons.sports_martial_arts,
          title: 'DUEL',
          subtitle: 'Auto-match with another player — ELO is on the line',
          color: const Color(0xFFE85D2F),
          onTap: () => _n.startAutoMatch(),
          cs: cs,
          theme: theme,
        ),
      ],
    );
  }

  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme cs,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            color: color.withOpacity(isDark ? 0.08 : 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
