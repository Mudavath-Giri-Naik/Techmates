import 'package:flutter/material.dart';

import '../../../../../widgets/compete/memory_game_widget.dart';
import '../memory_notifier.dart';
import 'memory_scorecard_screen.dart';

class MemoryGameScreen extends StatefulWidget {
  final MemoryNotifier notifier;

  const MemoryGameScreen({super.key, required this.notifier});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  MemoryNotifier get _n => widget.notifier;

  bool _navigatedToScorecard = false;

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
    if (_n.phase == MemoryPhase.initial) {
      _n.loadInfo();
    }
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleGameComplete({
    required double rawScore,
    required double accuracy,
    required int levelReached,
    required int timeTakenMs,
    required int mistakes,
  }) async {
    if (_n.phase == MemoryPhase.submitting) return;

    await _n.completeGame(
      rawScore: rawScore,
      accuracy: accuracy,
      levelReached: levelReached,
      timeTakenMs: timeTakenMs,
      mistakes: mistakes,
    );

    if (!mounted || _navigatedToScorecard) return;

    if (_n.error != null || _n.gameResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_n.error ?? 'Unable to save score')),
      );
      return;
    }

    _navigatedToScorecard = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MemoryScorecardScreen(notifier: _n),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_n.phase == MemoryPhase.submitting) {
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Memory?'),
        content: const Text('Your current run will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Quit',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_n.phase == MemoryPhase.initial || _n.phase == MemoryPhase.loadingInfo) {
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

    if (_n.error != null && _n.gameResult == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 44, color: cs.error),
                const SizedBox(height: 14),
                Text(
                  _n.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _n.loadInfo,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (!context.mounted || !shouldExit) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text('Memory Arena'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldExit = await _confirmExit();
              if (!context.mounted || !shouldExit) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            MemoryGameWidget(onGameComplete: _handleGameComplete),
            if (_n.phase == MemoryPhase.submitting)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: cs.primary,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Saving score...',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
