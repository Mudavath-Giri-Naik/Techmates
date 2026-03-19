import 'package:flutter/material.dart';
import '../../services/compete_service.dart';
import '../../widgets/compete/memory_game_widget.dart';
import 'result_screen.dart';

/// Container screen that loads the appropriate game widget based on arena type.
class ArenaGameScreen extends StatefulWidget {
  final Map<String, dynamic> arena;
  final String userId;
  final String? collegeId;

  const ArenaGameScreen({
    super.key,
    required this.arena,
    required this.userId,
    this.collegeId,
  });

  @override
  State<ArenaGameScreen> createState() => _ArenaGameScreenState();
}

class _ArenaGameScreenState extends State<ArenaGameScreen> {
  bool _submitting = false;
  String? _submitError;

  String get _arenaName => widget.arena['name'] as String? ?? 'Arena';
  String get _arenaId => widget.arena['id'] as String;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_submitting) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 20),
              Text(
                'Processing results…',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
        ),
      );
    }

    if (_submitError != null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text(
                  _submitError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _arenaName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => _showExitDialog(context, cs),
        ),
      ),
      body: SafeArea(child: _buildGameWidget()),
    );
  }

  Widget _buildGameWidget() {
    final lower = _arenaName.toLowerCase();

    if (lower.contains('memory')) {
      return MemoryGameWidget(onGameComplete: _handleGameComplete);
    }

    // Placeholder for future arenas
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '$_arenaName coming soon',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGameComplete({
    required double rawScore,
    required double accuracy,
    required int levelReached,
    required int timeTakenMs,
    required int mistakes,
  }) async {
    if (!mounted) return;

    // Guard: college_id is required by the DB
    if (widget.collegeId == null || widget.collegeId!.isEmpty) {
      setState(() {
        _submitError = 'College verification required to compete.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final service = CompeteService();

    // 1. Insert game_session + call process_game_session RPC
    final sessionId = await service.submitGameSession(
      userId: widget.userId,
      arenaId: _arenaId,
      collegeId: widget.collegeId!,
      rawScore: rawScore,
      accuracy: accuracy,
      levelReached: levelReached,
      timeTakenMs: timeTakenMs,
      mistakes: mistakes,
    );

    if (sessionId == null) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = 'Unable to update rating. Please try again.';
        });
      }
      return;
    }

    // 2. Fetch updated stats (RPC has already completed)
    final results = await Future.wait([
      service.fetchUserArenaStat(widget.userId, _arenaId),
      service.fetchUserTpi(widget.userId),
      service.fetchGameSession(sessionId),
    ]);

    final updatedArenaStat = results[0] as Map<String, dynamic>?;
    final updatedTpi = results[1] as Map<String, dynamic>?;
    final sessionData = results[2] as Map<String, dynamic>?;

    debugPrint('📊 [ArenaGame] Arena stat: $updatedArenaStat');
    debugPrint('📊 [ArenaGame] TPI: $updatedTpi');
    debugPrint('📊 [ArenaGame] Session Data: $sessionData');

    if (!mounted) return;

    setState(() => _submitting = false);

    // 3. Navigate to result screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          rawScore: rawScore,
          accuracy: accuracy,
          levelReached: levelReached,
          arenaStat: updatedArenaStat,
          tpiData: updatedTpi,
          sessionData: sessionData,
          arenaName: _arenaName,
          userId: widget.userId,
          collegeId: widget.collegeId,
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Quit', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }
}
