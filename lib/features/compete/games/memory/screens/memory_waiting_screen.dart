import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../memory_notifier.dart';
import 'memory_pregame_screen.dart';

/// Waiting screen — Auto-match for Memory Arena.
class MemoryWaitingScreen extends StatefulWidget {
  final MemoryNotifier notifier;

  const MemoryWaitingScreen({super.key, required this.notifier});

  @override
  State<MemoryWaitingScreen> createState() => _MemoryWaitingScreenState();
}

class _MemoryWaitingScreenState extends State<MemoryWaitingScreen>
    with SingleTickerProviderStateMixin {
  MemoryNotifier get _n => widget.notifier;
  Timer? _autoMatchTimer;
  int _autoMatchCount = 0;
  late AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    if (_n.phase == MemoryPhase.searching) _startAutoMatchTimer();
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    _autoMatchTimer?.cancel();
    _breathe.dispose();
    super.dispose();
  }

  void _onNotify() {
    if (!mounted) return;
    if (_n.phase == MemoryPhase.preGame ||
        _n.phase == MemoryPhase.countdown) {
      HapticFeedback.mediumImpact();
      _autoMatchTimer?.cancel();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => MemoryPregameScreen(notifier: _n),
      ));
      return;
    }
    setState(() {});
  }

  void _startAutoMatchTimer() {
    _autoMatchCount = 0;
    _autoMatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _autoMatchCount++);
    });
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    _n.cancelAutoMatch();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: Color(0xFF374151)),
            onPressed: _cancel,
          ),
          centerTitle: true,
          title: const Text(
            'Finding Opponent',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Breathing icon
                AnimatedBuilder(
                  animation: _breathe,
                  builder: (_, __) {
                    final s = 1.0 + _breathe.value * 0.06;
                    return Transform.scale(
                      scale: s,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEFF6FF),
                        ),
                        child: const Icon(
                          Icons.manage_search_rounded,
                          size: 36,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Searching for a worthy opponent',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                _buildAutoMatchSection(),

                const Spacer(flex: 3),

                // Cancel
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _cancel,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoMatchSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    backgroundColor: Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF93C5FD),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${_autoMatchCount}s',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Matching within ±200 ELO',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
