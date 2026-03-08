import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../speed_match_notifier.dart';
import 'speed_match_pregame_screen.dart';

/// Waiting screen — Invite host / Auto-match.
class SpeedMatchWaitingScreen extends StatefulWidget {
  final SpeedMatchNotifier notifier;

  const SpeedMatchWaitingScreen({super.key, required this.notifier});

  @override
  State<SpeedMatchWaitingScreen> createState() =>
      _SpeedMatchWaitingScreenState();
}

class _SpeedMatchWaitingScreenState extends State<SpeedMatchWaitingScreen>
    with SingleTickerProviderStateMixin {
  SpeedMatchNotifier get _n => widget.notifier;
  Timer? _autoMatchTimer;
  int _autoMatchCountdown = 30;
  Timer? _inviteTimer;
  int _inviteCountdown = 120; // 2 minutes
  static const int _inviteDuration = 120;
  late AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _n.addListener(_onNotify);
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    if (_n.phase == SpeedMatchPhase.searching) _startAutoMatchTimer();
    if (_n.phase == SpeedMatchPhase.waiting) _startInviteTimer();
  }

  @override
  void dispose() {
    _n.removeListener(_onNotify);
    _autoMatchTimer?.cancel();
    _inviteTimer?.cancel();
    _breathe.dispose();
    super.dispose();
  }

  void _onNotify() {
    if (!mounted) return;
    if (_n.phase == SpeedMatchPhase.preGame ||
        _n.phase == SpeedMatchPhase.countdown) {
      HapticFeedback.mediumImpact();
      _autoMatchTimer?.cancel();
      _inviteTimer?.cancel();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => SpeedMatchPregameScreen(notifier: _n),
      ));
      return;
    }
    setState(() {});
  }

  void _startAutoMatchTimer() {
    _autoMatchCountdown = 30;
    _autoMatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _autoMatchCountdown--);
      if (_autoMatchCountdown <= 0) {
        timer.cancel();
        HapticFeedback.lightImpact();
        _n.cancelAutoMatch();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No opponent found. Try solo?'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _startInviteTimer() {
    _inviteCountdown = _inviteDuration;
    _inviteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _inviteCountdown--);
      if (_inviteCountdown <= 0) {
        timer.cancel();
        HapticFeedback.lightImpact();
        _n.cancelDuel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invite code expired. Please create a new room.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    final isInvite = _n.phase == SpeedMatchPhase.waiting;
    if (isInvite) {
      _n.cancelDuel();
    } else {
      _n.cancelAutoMatch();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isInvite = _n.phase == SpeedMatchPhase.waiting;

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
        title: Text(
          isInvite ? 'Challenge a Friend' : 'Finding Opponent',
          style: const TextStyle(
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInvite
                            ? const Color(0xFFF3F0FF)
                            : const Color(0xFFEFF6FF),
                      ),
                      child: Icon(
                        isInvite
                            ? Icons.person_add_alt_1_rounded
                            : Icons.manage_search_rounded,
                        size: 36,
                        color: isInvite
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                isInvite
                    ? 'Share this code with your friend'
                    : 'Searching for a worthy opponent',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              if (isInvite) _buildInviteSection(),
              if (!isInvite) _buildAutoMatchSection(),

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

  Widget _buildInviteSection() {
    return Column(
      children: [
        // Code display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              const Text(
                'INVITE CODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _n.inviteCode ?? '------',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Copy & Share
        Row(
          children: [
            Expanded(
              child: _lightButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                color: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF3F0FF),
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_n.inviteCode != null) {
                    Clipboard.setData(ClipboardData(text: _n.inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Code copied!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _lightButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF3F0FF),
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_n.inviteCode != null) {
                    Share.share(
                      'Join my Speed Match duel on Techmates! '
                      'Code: ${_n.inviteCode}',
                    );
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Timer + Waiting indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: _inviteCountdown / _inviteDuration,
                        strokeWidth: 3,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _inviteCountdown <= 30
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFC4B5FD),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${_inviteCountdown ~/ 60}:${(_inviteCountdown % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _inviteCountdown <= 30
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Waiting for opponent to join…',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
                  child: CircularProgressIndicator(
                    value: _autoMatchCountdown / 30.0,
                    strokeWidth: 3,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _autoMatchCountdown <= 10
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF93C5FD),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${_autoMatchCountdown}s',
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

  Widget _lightButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
