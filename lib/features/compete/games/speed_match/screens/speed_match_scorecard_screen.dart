import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_result_model.dart';
import '../speed_match_notifier.dart';
import '../speed_match_service.dart';
import 'speed_match_info_screen.dart';

/// Result / scorecard screen — shows detailed breakdown with math.
class SpeedMatchScorecardScreen extends StatefulWidget {
  final SpeedMatchNotifier notifier;

  const SpeedMatchScorecardScreen({super.key, required this.notifier});

  @override
  State<SpeedMatchScorecardScreen> createState() =>
      _SpeedMatchScorecardScreenState();
}

class _SpeedMatchScorecardScreenState extends State<SpeedMatchScorecardScreen>
    with SingleTickerProviderStateMixin {
  SpeedMatchNotifier get _n => widget.notifier;
  List<Map<String, dynamic>> _classRankings = [];
  late AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    HapticFeedback.mediumImpact();
    _loadExtras();
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  Future<void> _loadExtras() async {
    if (_n.collegeId != null) {
      final rankings =
          await SpeedMatchService().fetchClassRankings(_n.collegeId!);
      if (mounted) setState(() => _classRankings = rankings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _n.gameResult;

    if (result == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFC),
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
          icon: const Icon(Icons.close_rounded,
              size: 22, color: Color(0xFF374151)),
          onPressed: _exit,
        ),
        centerTitle: true,
        title: Text(
          result.isDuel ? 'Duel Result' : 'Game Complete',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            if (result.isDuel) _duelHeader(result),
            if (!result.isDuel) _soloHeader(result),

            const SizedBox(height: 24),
            _buildSection('Performance', _performanceCard(result)),

            const SizedBox(height: 16),
            _buildSection('Score Breakdown', _scoreBreakdownCard(result)),

            const SizedBox(height: 16),
            _buildSection('Scoring Formula', _formulaCard()),

            if (_classRankings.isNotEmpty && !result.isDuel) ...[
              const SizedBox(height: 16),
              _buildSection('Class Ranking', _rankingCard()),
            ],

            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _n.resetToInfo();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => SpeedMatchInfoScreen(notifier: _n),
                      ));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                        result.isDuel ? 'Rematch' : 'Play Again',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _exit();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Text('Exit',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Headers ──

  Widget _soloHeader(GameResult r) {
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
          tween: IntTween(begin: 0, end: r.score),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, val, __) => Text(
            _fmtScore(val),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        Text(
          'Level ${r.level}',
          style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
        ),
      ],
    );
  }

  Widget _duelHeader(GameResult r) {
    final won = r.duelWon ?? false;
    final tied = r.score == (r.opponentScore ?? 0);
    final emoji = tied ? '🤝' : won ? '🏆' : '😤';
    final label = tied ? 'TIE!' : won ? 'YOU WON!' : 'YOU LOST';
    final labelColor = tied
        ? const Color(0xFF6B7280)
        : won
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
    final bgColor = tied
        ? const Color(0xFFF9FAFB)
        : won
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: labelColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _duelScoreCol('You', r.score),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('vs',
                    style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontWeight: FontWeight.w600)),
              ),
              _duelScoreCol(
                _firstName(_n.opponentProfile?['full_name'] as String?),
                r.opponentScore ?? 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _duelScoreCol(String name, int score) {
    return Column(
      children: [
        Text(name,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, val, __) => Text(
            _fmtScore(val),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  // ── Cards ──

  Widget _buildSection(String title, Widget child) {
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

  Widget _performanceCard(GameResult r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _metric('Cards Seen', '${r.totalCards}', Icons.style_rounded, const Color(0xFFEFF6FF), const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _metric('Correct', '${r.correctCount}', Icons.check_circle_outline_rounded, const Color(0xFFECFDF5), const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metric('Wrong', '${r.wrongCount}', Icons.cancel_outlined, const Color(0xFFFEF2F2), const Color(0xFFEF4444))),
              const SizedBox(width: 12),
              Expanded(child: _metric('Accuracy', '${(r.accuracy * 100).toStringAsFixed(1)}%', Icons.percent_rounded, const Color(0xFFF3F0FF), const Color(0xFF8B5CF6))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metric('Max Streak', '${r.maxStreak}', Icons.local_fire_department_rounded, const Color(0xFFFFF7ED), const Color(0xFFF97316))),
              const SizedBox(width: 12),
              Expanded(child: _metric('Best Time', '${r.bestResponseMs}ms', Icons.bolt_rounded, const Color(0xFFFFFBEB), const Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Avg Response', '${r.avgResponseMs}ms'),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fg)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBreakdownCard(GameResult r) {
    // Calculate breakdown
    final basePoints = r.correctCount * 100;
    // Estimate speed bonus (we know avg response)
    final int estSpeedBonusPerCorrect;
    if (r.avgResponseMs <= 300) {
      estSpeedBonusPerCorrect = 50;
    } else if (r.avgResponseMs <= 600) {
      estSpeedBonusPerCorrect = 25;
    } else {
      estSpeedBonusPerCorrect = 0;
    }
    final estSpeedBonus = r.correctCount * estSpeedBonusPerCorrect;
    final estBaseTotal = basePoints + estSpeedBonus;
    final multiplierBonus = r.score - estBaseTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _breakdownRow('Base points', '${r.correctCount} × 100', '$basePoints', const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          _breakdownRow(
            'Speed bonus',
            '${r.correctCount} × $estSpeedBonusPerCorrect',
            '+$estSpeedBonus',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 8),
          _breakdownRow(
            'Multiplier bonus',
            'streak ×2/×4/×8',
            multiplierBonus > 0 ? '+$multiplierBonus' : '$multiplierBonus',
            const Color(0xFFF97316),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937))),
              const Spacer(),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: r.score),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (_, v, __) => Text(
                  _fmtScore(v),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String calculation, String value, Color fg) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
        ),
        Text(calculation,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD1D5DB),
                fontFamily: 'monospace')),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ),
      ],
    );
  }

  Widget _formulaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formulaRow('Per correct answer', '(100 + speed bonus) × multiplier'),
          const SizedBox(height: 10),
          _formulaRow('Speed bonus', '≤300ms → +50  ·  ≤600ms → +25'),
          const SizedBox(height: 10),
          _formulaRow('Multiplier', '3 streak → ×2  ·  6 → ×4  ·  10 → ×8'),
          const SizedBox(height: 10),
          _formulaRow('Wrong answer', 'Streak & multiplier reset to ×1'),
        ],
      ),
    );
  }

  Widget _formulaRow(String label, String formula) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
        ),
        Expanded(
          child: Text(formula,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  height: 1.4)),
        ),
      ],
    );
  }

  Widget _rankingCard() {
    if (_classRankings.isEmpty) return const SizedBox.shrink();

    int userRank = -1;
    for (int i = 0; i < _classRankings.length; i++) {
      if (_classRankings[i]['user_id'] == _n.userId) {
        userRank = i + 1;
        break;
      }
    }

    final top = _classRankings.first;
    final topProfile = top['profiles'] as Map<String, dynamic>?;
    final topName = topProfile?['full_name'] as String? ?? 'Unknown';
    final topScore = top['raw_score']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userRank > 0)
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  '#$userRank in your class today',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            '🥇 Top: $topName — $topScore pts',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF3F4F6)),
    );
  }

  void _exit() {
    Navigator.of(context).popUntil(
        (route) => route.isFirst || route.settings.name == '/compete');
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _fmtScore(int s) {
    return s.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _firstName(String? name) {
    if (name == null || name.isEmpty) return 'Opponent';
    return name.split(' ').first;
  }
}
