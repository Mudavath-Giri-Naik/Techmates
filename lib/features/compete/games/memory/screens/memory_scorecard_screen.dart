import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../memory_notifier.dart';
import '../memory_service.dart';
import '../models/memory_game_result_model.dart';
import 'memory_game_screen.dart';

class MemoryScorecardScreen extends StatefulWidget {
  final MemoryNotifier notifier;

  const MemoryScorecardScreen({super.key, required this.notifier});

  @override
  State<MemoryScorecardScreen> createState() => _MemoryScorecardScreenState();
}

class _MemoryScorecardScreenState extends State<MemoryScorecardScreen> {
  MemoryNotifier get _n => widget.notifier;

  List<Map<String, dynamic>> _classRankings = [];

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    if (_n.collegeId == null || _n.collegeId!.isEmpty) return;

    final rankings = await MemoryService().fetchClassRankings(_n.collegeId!);
    if (mounted) {
      setState(() => _classRankings = rankings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _n.gameResult;
    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No game data')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF374151)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Memory Complete',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _scoreHeader(result),
          const SizedBox(height: 24),
          _section('Performance', _performanceCard(result)),
          if (result.brainScore != null) ...[
            const SizedBox(height: 16),
            _section('Compete', _brainScoreCard(result.brainScore!)),
          ],
          if (_classRankings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section('Class Ranking', _rankingCard()),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            MemoryGameScreen(notifier: MemoryNotifier()),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreHeader(MemoryGameResult result) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'TOTAL SCORE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: result.score),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, value, child) => Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Reached level ${result.levelReached}',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _performanceCard(MemoryGameResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Accuracy',
                  '${result.accuracy.toStringAsFixed(1)}%',
                  Icons.track_changes_rounded,
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric(
                  'Mistakes',
                  '${result.mistakes}',
                  Icons.close_rounded,
                  const Color(0xFFFEF2F2),
                  const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Level',
                  '${result.levelReached}',
                  Icons.stairs_rounded,
                  const Color(0xFFF5F3FF),
                  const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric(
                  'Time',
                  result.formattedTime,
                  Icons.schedule_rounded,
                  const Color(0xFFECFDF5),
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _brainScoreCard(int brainScore) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Updated Brain Score',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your memory run has been counted in Compete.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$brainScore',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: _classRankings.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final profile = row['profiles'] as Map<String, dynamic>?;
          final name = profile?['full_name'] as String? ?? 'Player';
          final score = (row['raw_score'] as num?)?.round() ?? 0;
          final isMe = row['player_id']?.toString() == _n.userId;

          return Container(
            margin: EdgeInsets.only(
              bottom: index == _classRankings.length - 1 ? 0 : 10,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    isMe ? '$name (You)' : name,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    );
  }
}
