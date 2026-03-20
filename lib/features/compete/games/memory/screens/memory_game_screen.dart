import 'dart:async';

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
  bool _isLeavingScreen = false;

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
    if (_n.phase == MemoryPhase.initial) {
      _n.loadInfo();
    }
    debugPrint('🧠 MEMORY GameScreen: initState isDuel=${_n.isDuel} phase=${_n.phase}');
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    if (!mounted) return;

    final errorMessage = _n.error;
    final isCancellation = errorMessage != null &&
        errorMessage.toLowerCase().contains('cancel');

    if (!_isLeavingScreen &&
        _n.phase == MemoryPhase.modeSelect &&
        _n.gameResult == null &&
        isCancellation) {
      final message = _n.takeError();
      if (message != null && message.isNotEmpty) {
        _isLeavingScreen = true;
        Future.microtask(() {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        });
        return;
      }
    }

    setState(() {});
  }

  Future<void> _handleGameComplete({
    required double rawScore,
    required double accuracy,
    required int levelReached,
    required int timeTakenMs,
    required int mistakes,
  }) async {
    if (_n.phase == MemoryPhase.submitting) return;

    debugPrint('🧠🏁 MEMORY: game complete! score=$rawScore level=$levelReached mistakes=$mistakes');

    await _n.completeGame(
      rawScore: rawScore,
      accuracy: accuracy,
      levelReached: levelReached,
      timeTakenMs: timeTakenMs,
      mistakes: mistakes,
    );

    if (!mounted || _navigatedToScorecard) return;

    if (_n.error != null || _n.gameResult == null) {
      debugPrint('❌ MEMORY GameScreen: error or no result → snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_n.error ?? 'Unable to save score')),
      );
      return;
    }

    debugPrint('✅ MEMORY GameScreen: navigating to scorecard');
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
        title: const Text('Quit Game?'),
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

  void _exitGame() {
    if (_isLeavingScreen) return;
    _isLeavingScreen = true;
    if (_n.isDuel) {
      unawaited(_n.cancelDuelFromGame());
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
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
        _exitGame();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar with exit button and optional duel info
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: cs.onSurface),
                      onPressed: () async {
                        final shouldExit = await _confirmExit();
                        if (!context.mounted || !shouldExit) return;
                        _exitGame();
                      },
                    ),
                    if (_n.isDuel) ...[
                      const Spacer(),
                      // Compact duel score header
                      _buildDuelScoreHeader(cs),
                    ] else
                      const Spacer(),
                    Text(
                      _n.isDuel ? 'Duel' : 'Solo',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Game widget
              Expanded(
                child: MemoryGameWidget(onGameComplete: _handleGameComplete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuelScoreHeader(ColorScheme cs) {
    final myName = _n.myProfile?['full_name'] as String? ?? 'You';
    final oppName = _n.opponentProfile?['full_name'] as String? ?? 'Opponent';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _firstName(myName),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF97316),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _firstName(oppName),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  String _firstName(String? n) {
    if (n == null || n.isEmpty) return '?';
    return n.split(' ').first;
  }
}
