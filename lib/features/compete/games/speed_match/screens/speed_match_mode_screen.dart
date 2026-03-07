import 'package:flutter/material.dart';

import '../speed_match_notifier.dart';
import 'speed_match_game_screen.dart';
import 'speed_match_pregame_screen.dart';
import 'speed_match_waiting_screen.dart';

/// Mode selection: Solo vs Duel, with duel sub-options.
class SpeedMatchModeScreen extends StatefulWidget {
  final SpeedMatchNotifier notifier;

  const SpeedMatchModeScreen({super.key, required this.notifier});

  @override
  State<SpeedMatchModeScreen> createState() => _SpeedMatchModeScreenState();
}

class _SpeedMatchModeScreenState extends State<SpeedMatchModeScreen> {
  SpeedMatchNotifier get _n => widget.notifier;
  bool _showDuelOptions = false;
  final _codeController = TextEditingController();
  String? _codeError;
  bool _navigating = false; // Guard against double navigation

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    _codeController.dispose();
    super.dispose();
  }

  void _onNotify() {
    if (!mounted || _navigating) return;
    print('SPEED_MATCH: ModeScreen._onNotify phase=${_n.phase}');

    switch (_n.phase) {
      case SpeedMatchPhase.countdown:
        // Solo countdown → game screen
        _navigating = true;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SpeedMatchGameScreen(notifier: _n),
        ));
        break;
      case SpeedMatchPhase.waiting:
      case SpeedMatchPhase.searching:
        _navigating = true;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SpeedMatchWaitingScreen(notifier: _n),
        )).then((_) => _navigating = false); // Reset when returning
        break;
      case SpeedMatchPhase.preGame:
        // Join code → pregame
        _navigating = true;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SpeedMatchPregameScreen(notifier: _n),
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
          '⚡ Speed Match ⚡',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: _showDuelOptions ? _buildDuelOptions(cs, theme) : _buildMainOptions(cs, theme),
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
          subtitle: 'Challenge another player — ELO is on the line',
          color: const Color(0xFFE85D2F),
          onTap: () => setState(() => _showDuelOptions = true),
          cs: cs,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildDuelOptions(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        _optionCard(
          icon: Icons.person_add_alt_1,
          title: 'Challenge a Friend',
          subtitle: 'Share a code, play together',
          color: const Color(0xFF8B5CF6),
          onTap: () => _n.createInviteDuel(),
          cs: cs,
          theme: theme,
        ),
        const SizedBox(height: 12),
        _optionCard(
          icon: Icons.search,
          title: 'Auto Match',
          subtitle: 'Find a random opponent now',
          color: const Color(0xFF00B4D8),
          onTap: () => _n.startAutoMatch(),
          cs: cs,
          theme: theme,
        ),
        const SizedBox(height: 12),
        _optionCard(
          icon: Icons.pin,
          title: 'Join a Game',
          subtitle: "Enter a friend's code",
          color: const Color(0xFFE85D2F),
          onTap: () => _showJoinCodeDialog(cs, theme),
          cs: cs,
          theme: theme,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => setState(() => _showDuelOptions = false),
          child: Text('← Back to modes',
              style: TextStyle(color: const Color(0xFF00B4D8))),
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

  void _showJoinCodeDialog(ColorScheme cs, ThemeData theme) {
    _codeController.clear();
    _codeError = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enter Invite Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  errorText: _codeError,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final code = _codeController.text.trim();
                if (code.length < 4) {
                  setDialogState(() => _codeError = 'Code too short');
                  return;
                }
                Navigator.of(ctx).pop();
                print('SPEED_MATCH: submitting join code=$code');
                await _n.joinWithCode(code);
                if (_n.error != null && mounted) {
                  print('SPEED_MATCH: join error=${_n.error}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_n.error!)),
                  );
                }
                // If joinWithCode succeeded, _onNotify will navigate to preGame
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
