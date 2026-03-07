import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../speed_match_notifier.dart';
import 'speed_match_game_screen.dart';

/// Pre-game VS screen — shows both players, ready/cancel, countdown.
class SpeedMatchPregameScreen extends StatefulWidget {
  final SpeedMatchNotifier notifier;

  const SpeedMatchPregameScreen({super.key, required this.notifier});

  @override
  State<SpeedMatchPregameScreen> createState() =>
      _SpeedMatchPregameScreenState();
}

class _SpeedMatchPregameScreenState extends State<SpeedMatchPregameScreen>
    with SingleTickerProviderStateMixin {
  SpeedMatchNotifier get _n => widget.notifier;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  bool _countingDown = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    _countdownTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onNotify() {
    if (!mounted) return;
    if (_n.phase == SpeedMatchPhase.countdown && !_countingDown) {
      HapticFeedback.mediumImpact();
      _startCountdown();
    }
    setState(() {});
  }

  void _startCountdown() {
    _countingDown = true;
    _countdownValue = 3;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _countdownValue--);
      if (_countdownValue <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        _n.startPlaying();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SpeedMatchGameScreen(notifier: _n),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_countingDown) return _buildCountdown();
    return _buildVsScreen();
  }

  Widget _buildVsScreen() {
    final my = _n.myProfile;
    final opp = _n.opponentProfile;
    final myName = my?['full_name'] as String? ?? 'You';
    final oppName = opp?['full_name'] as String? ?? 'Opponent';
    final myBranch = my?['branch'] as String? ?? '';
    final oppBranch = opp?['branch'] as String? ?? '';
    final myYear = my?['year'] as String? ?? '';
    final oppYear = opp?['year'] as String? ?? '';
    final myCollege = my?['colleges']?['short_name'] as String? ?? '';
    final oppCollege = opp?['colleges']?['short_name'] as String? ?? '';
    final myAvatar = my?['avatar_url'] as String?;
    final oppAvatar = opp?['avatar_url'] as String?;
    final lvl = _n.duelSession?.playerLevel ?? _n.userLevel.currentLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Header
              const Text(
                'SPEED MATCH DUEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Level $lvl',
                style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
              ),

              const Spacer(),

              // ── Vs Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _playerInfo(
                        name: myName,
                        branch: myBranch,
                        year: myYear,
                        college: myCollege,
                        avatarUrl: myAvatar,
                        isReady: _n.myReady,
                        tint: const Color(0xFFEFF6FF),
                      ),
                    ),
                    // VS badge
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) {
                        final s = 1.0 + _pulse.value * 0.05;
                        return Transform.scale(
                          scale: s,
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF7ED),
                              border: Border.all(
                                  color: const Color(0xFFFED7AA), width: 1),
                            ),
                            child: const Center(
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF97316),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: _playerInfo(
                        name: oppName,
                        branch: oppBranch,
                        year: oppYear,
                        college: oppCollege,
                        avatarUrl: oppAvatar,
                        isReady: _n.opponentReady,
                        tint: const Color(0xFFFDF2F8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Ready status row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _readyDot('You', _n.myReady),
                    Container(width: 1, height: 16, color: const Color(0xFFF3F4F6)),
                    _readyDot(_firstName(oppName), _n.opponentReady),
                  ],
                ),
              ),

              const Spacer(),

              // ── Action Buttons ──
              if (!_n.myReady) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _n.setReady();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("I'M READY",
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _n.cancelDuel();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFECFDF5),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: const Color(0xFF10B981).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Waiting for opponent…',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _n.cancelDuel();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel & Leave',
                    style:
                        TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerInfo({
    required String name,
    required String branch,
    required String year,
    required String college,
    required String? avatarUrl,
    required bool isReady,
    required Color tint,
  }) {
    final sub = [if (branch.isNotEmpty) branch, if (year.isNotEmpty) year]
        .join(' · ');
    return Column(
      children: [
        // Avatar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint,
            border: Border.all(
              color: isReady
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE5E7EB),
              width: isReady ? 2.5 : 1.5,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(avatarUrl,
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) => _fallback(name))
                : _fallback(name),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(sub,
              style:
                  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              textAlign: TextAlign.center),
        ],
        if (college.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(college,
              style:
                  const TextStyle(color: Color(0xFFD1D5DB), fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _readyDot(String label, bool ready) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ready ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ${ready ? '✓' : '…'}',
          style: TextStyle(
            color: ready ? const Color(0xFF059669) : const Color(0xFFD1D5DB),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_countdownValue),
          tween: Tween(begin: 1.4, end: 0.4),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: AnimatedOpacity(
            opacity: _countdownValue > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              _countdownValue > 0 ? '$_countdownValue' : 'GO!',
              style: const TextStyle(
                fontSize: 88,
                fontWeight: FontWeight.w900,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(String name) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
              fontSize: 24),
        ),
      ),
    );
  }

  String _firstName(String? n) {
    if (n == null || n.isEmpty) return '???';
    return n.split(' ').first;
  }
}
