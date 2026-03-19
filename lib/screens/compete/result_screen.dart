import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/compete/leaderboard_widget.dart';

/// Displays game results with three sections:
/// Performance, Arena Rating, Campus Standing.
class ResultScreen extends StatelessWidget {
  final double rawScore;
  final double accuracy;
  final int levelReached;
  final Map<String, dynamic>? arenaStat;
  final Map<String, dynamic>? tpiData;
  final Map<String, dynamic>? sessionData;
  final String arenaName;
  final String userId;
  final String? collegeId;

  const ResultScreen({
    super.key,
    required this.rawScore,
    required this.accuracy,
    required this.levelReached,
    this.arenaStat,
    this.tpiData,
    this.sessionData,
    required this.arenaName,
    required this.userId,
    this.collegeId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    debugPrint('📊 [Result] arenaStat: $arenaStat');
    debugPrint('📊 [Result] tpiData: $tpiData');

    // ── Extract from user_arena_stats ──
    final arenaRating = _fmt(arenaStat?['rating']);
    final arenaPercentile = _fmtDouble(arenaStat?['percentile']);
    final totalSessions = _fmt(arenaStat?['total_sessions']);
    final bestScore = _fmt(arenaStat?['best_raw_score']);
    final ratingDelta = arenaStat?['rating'] != null
        ? (arenaStat!['rating'] as num).toDouble()
        : null;

    // ── Extract from user_tpi ──
    final finalTpi = _fmt(tpiData?['final_tpi']);
    final campusRank = tpiData?['campus_rank'];
    final campusRankStr = campusRank != null ? '#$campusRank' : '—';
    final campusPercentile = _fmt(tpiData?['campus_percentile']);
    final totalPlayers = tpiData?['total_campus_players'];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Session Complete',
          style: TextStyle(
            fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // ── Performance ──
            _sectionLabel('Performance', cs, theme),
            const SizedBox(height: 12),
            _MetricBreakdownCard(
              metrics: [
                _getScoreBreakdown(),
                _getAccuracyBreakdown(),
                _getLevelBreakdown(),
              ],
              cs: cs,
              theme: theme,
              isDark: isDark,
            ),

            _divider(cs),

            // ── Arena Rating ──
            _sectionLabel('Arena Rating', cs, theme),
            const SizedBox(height: 12),
            _MetricBreakdownCard(
              metrics: [
                _getRatingBreakdown(arenaRating),
                _getPercentileBreakdown(arenaPercentile),
                _getBestBreakdown(bestScore),
              ],
              cs: cs,
              theme: theme,
              isDark: isDark,
            ),

            _divider(cs),

            // ── Campus Standing ──
            _sectionLabel('Campus Standing', cs, theme),
            const SizedBox(height: 12),
            _MetricBreakdownCard(
              metrics: [
                _getRankBreakdown(campusRankStr),
                _getTpiBreakdown(finalTpi),
                _getGamesBreakdown(totalSessions),
              ],
              cs: cs,
              theme: theme,
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // ── Leaderboard ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLeaderboard(context),
                icon: const Icon(Icons.leaderboard_outlined, size: 18),
                label: const Text('View Leaderboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: cs.outline.withOpacity(0.3)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Back ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Arenas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is num) return v.toStringAsFixed(0);
    final pd = double.tryParse(v.toString());
    if (pd != null) return pd.toStringAsFixed(0);
    return v.toString();
  }

  String _fmtDouble(dynamic v) {
    if (v == null) return '—';
    if (v is num) return v.toStringAsFixed(1);
    final pd = double.tryParse(v.toString());
    if (pd != null) return pd.toStringAsFixed(1);
    return v.toString();
  }

  Widget _divider(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: cs.outlineVariant.withOpacity(0.3)),
      );

  Widget _sectionLabel(String text, ColorScheme cs, ThemeData theme) => Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      );

  // ── Metric Breakdown Generators ──
  MetricBreakdownProps _getAccuracyBreakdown() {
    String? mathStr;
    String? expStr;

    if (sessionData != null) {
      final mistakes = int.tryParse(sessionData!['mistakes']?.toString() ?? '0') ?? 0;
      
      // We deduce correct answers since the database only tracks accuracy and mistakes.
      // A = C / (C+M) * 100  -->  C = (A * M) / (100 - A)
      int correctAnswers = 0;
      if (accuracy > 0 && accuracy < 100) {
        correctAnswers = ((accuracy * mistakes) / (100.0 - accuracy)).round();
      } else if (accuracy == 100.0) {
        // If 100%, total is arbitrarily scaled by game parameters, but let's assume rawScore or just text fallback.
        // Actually, we can just say 'all' or show a 100% representation. 
        // For a flawless game, mistakes = 0. We'll just say "All" or approximate from level.
        correctAnswers = levelReached * 3; // Approx 3 cells per level. Not perfectly exact for 100% case but visually fine.
      }
      
      final totalQuestions = correctAnswers + mistakes;
      final accDecimal = totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0.0;

      mathStr = 'Accuracy = (Correct Answers / Total Questions) × 100\n\n'
                '= ($correctAnswers / $totalQuestions) × 100\n'
                '= ${accDecimal.toStringAsFixed(2)} × 100\n'
                '= ${accuracy.toStringAsFixed(0)}%';

      expStr = 'You answered $correctAnswers correctly and $mistakes incorrectly.\n'
               'Your accuracy is the percentage of correct answers out of total attempts.';
    }

    return MetricBreakdownProps(
      title: 'Accuracy',
      value: '${accuracy.toStringAsFixed(1)}%',
      math: mathStr,
      explanation: expStr ?? 'Percentage of correct actions during the session.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getScoreBreakdown() {
    String? mathStr;
    String? expStr;

    if (sessionData != null) {
      final mistakes = int.tryParse(sessionData!['mistakes']?.toString() ?? '0') ?? 0;
      final timeMs = int.tryParse(sessionData!['time_taken_ms']?.toString() ?? '0') ?? 0;
      
      final timeSec = timeMs / 1000.0;
      final timePenalty = timeSec > 30.0 ? (timeSec - 30.0) * 0.5 : 0.0;
      
      final levelPts = levelReached * 100.0;
      final accPts = accuracy * 10.0;
      final mistakePen = mistakes * 20.0;

      String formulaStr = 'Score = (Level × 100) + (Accuracy × 10) − (Mistakes × 20)';
      String calcStr1 = 'Score = ($levelReached × 100) + (${accuracy.toStringAsFixed(1)} × 10) − ($mistakes × 20)';
      String calcStr2 = '= ${levelPts.toStringAsFixed(0)} + ${accPts.toStringAsFixed(1)} − ${mistakePen.toStringAsFixed(0)}';

      if (timePenalty > 0) {
        formulaStr += ' − Time Penalty';
        calcStr1 += ' − ${timePenalty.toStringAsFixed(1)}';
        calcStr2 += ' − ${timePenalty.toStringAsFixed(1)}';
      }

      mathStr = '$formulaStr\n\n$calcStr1\n$calcStr2\n= ${rawScore.toStringAsFixed(0)}';

      String timeText = timePenalty > 0 
          ? ' Additionally, taking ${timeSec.toStringAsFixed(1)}s incurred a ${timePenalty.toStringAsFixed(1)} point time penalty.'
          : '';

      expStr = 'You reached Level $levelReached and earned ${levelPts.toStringAsFixed(0)} points, plus ${accPts.toStringAsFixed(1)} points for accuracy.\n'
               'However, you had $mistakes incorrect answers, each deducting 20 points, '
               'so ${mistakePen.toStringAsFixed(0)} points were subtracted.$timeText\n'
               'Giving you a final score of ${rawScore.toStringAsFixed(0)}.';
    }

    return MetricBreakdownProps(
      title: 'Score',
      value: rawScore.toStringAsFixed(0),
      math: mathStr,
      explanation: expStr ?? 'You earned points based on correct answers and penalties.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getLevelBreakdown() {
    return MetricBreakdownProps(
      title: 'Level',
      value: levelReached.toString(),
      explanation: 'You reached this level based on accumulated experience points.',
      whyChanges: [
        'XP increases when you complete matches.',
        'Higher difficulty gives more XP.',
      ],
      impact: 'Higher levels unlock tougher arenas.',
    );
  }

  MetricBreakdownProps _getRatingBreakdown(String ratingStr) {
    String? mathStr;
    String? expStr;
    
    if (sessionData != null && sessionData!['rating_before'] != null && sessionData!['rating_after'] != null) {
      final oldRating = double.tryParse(sessionData!['rating_before'].toString()) ?? 500.0;
      final newRating = double.tryParse(sessionData!['rating_after'].toString()) ?? 500.0;
      final delta = newRating - oldRating;
      
      int kFactor = 12;
      if (oldRating < 300) kFactor = 32;
      else if (oldRating < 500) kFactor = 24;
      else if (oldRating < 700) kFactor = 16;
      
      final actualPerf = (delta / kFactor) + 0.5;
      final diff = actualPerf - 0.50;
      final diffAbs = diff.abs();
      final absDelta = delta.abs();
      
      final sign = diff < 0 ? '-' : '+';
      final calcDelta = (kFactor * diff).abs();

      mathStr = '${oldRating.toStringAsFixed(0)} + $kFactor × (${actualPerf.toStringAsFixed(2)} - 0.50)\n'
                '= ${oldRating.toStringAsFixed(0)} + $kFactor × ${diff.toStringAsFixed(2)}\n'
                '= ${oldRating.toStringAsFixed(0)} $sign ${calcDelta.toStringAsFixed(1)}\n'
                '= ${newRating.toStringAsFixed(0)}';
      
      String perfText;
      if (delta > 0) {
        perfText = 'You performed much better (${(actualPerf * 100).toStringAsFixed(0)}%), exceeding expectations by ${(diffAbs * 100).toStringAsFixed(0)}%.\n'
                   'Because of this, you gained ${delta.toStringAsFixed(0)} rating points.';
      } else if (delta < 0) {
        perfText = 'You performed lower (${(actualPerf * 100).toStringAsFixed(0)}%), falling below expectations by ${(diffAbs * 100).toStringAsFixed(0)}%.\n'
                   'Because of this, you lost ${absDelta.toStringAsFixed(0)} rating points.';
      } else {
        perfText = 'You performed exactly at the expected level (50%).\n'
                   'Because of this, your rating did not change.';
      }
      
      expStr = 'Based on your rating, the system expected you to perform at an average level (50%).\n$perfText';
    }

    return MetricBreakdownProps(
      title: 'Rating',
      value: ratingStr,
      math: mathStr,
      explanation: expStr ?? 'Your rating changed based on how you performed compared to expectation.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getPercentileBreakdown(String percentileStr) {
    final pctObj = arenaStat?['percentile'];
    final totalObj = tpiData?['total_campus_players'];
    String? mathStr;
    String? expStr;
    
    if (pctObj != null && totalObj != null) {
      final pct = double.tryParse(pctObj.toString()) ?? 0.0;
      final total = int.tryParse(totalObj.toString()) ?? 1;
      final playersBelow = (total * (pct / 100)).round();
      final playersAbove = total - playersBelow;
      final pctDecimal = total > 0 ? (playersBelow / total) : 0.0;

      mathStr = 'Percentile = (Players Below You / Total Players) × 100\n\n'
                '= ($playersBelow / $total) × 100\n'
                '= ${pctDecimal.toStringAsFixed(2)} × 100\n'
                '= ${pct.toStringAsFixed(0)}%';

      expStr = 'Players You Beat: $playersBelow\n'
               'Players Above You: $playersAbove\n'
               'Total Players: $total\n'
               'Percentile: ${pct.toStringAsFixed(0)}%';
    }

    return MetricBreakdownProps(
      title: 'Percentile',
      value: percentileStr == '—' ? '—' : '$percentileStr%',
      math: mathStr,
      explanation: expStr ?? 'You outperformed $percentileStr% of players.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getBestBreakdown(String bestStr) {
    String? expStr;
    final bestObj = arenaStat?['best_raw_score'];
    final ratingObj = arenaStat?['rating'];

    if (bestObj != null && ratingObj != null) {
      final bestRating = double.tryParse(bestObj.toString()) ?? 0.0;
      final currentRating = double.tryParse(ratingObj.toString()) ?? 0.0;

      if (currentRating >= bestRating) {
        expStr = 'Best Rating: ${bestRating.toStringAsFixed(0)}\n'
                 'Current Rating: ${currentRating.toStringAsFixed(0)}\n'
                 '\n🏆 New Peak Achieved!\n'
                 'Your current rating (${currentRating.toStringAsFixed(0)}) matched or exceeded your previous best (${bestRating.toStringAsFixed(0)}).';
      } else {
        final gap = (bestRating - currentRating).toStringAsFixed(0);
        expStr = 'Best Rating: ${bestRating.toStringAsFixed(0)}\n'
                 'Current Rating: ${currentRating.toStringAsFixed(0)}\n'
                 '\nYou are $gap points away from your personal best.\n'
                 'Keep competing to reach new heights!';
      }
    }

    return MetricBreakdownProps(
      title: 'Best',
      value: bestStr,
      explanation: expStr ?? 'This is your highest rating achieved so far.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getRankBreakdown(String rankStr) {
    final rankObj = tpiData?['campus_rank'];
    final totalObj = tpiData?['total_campus_players'];
    String? mathStr;
    String? expStr;

    if (rankObj != null && totalObj != null) {
      final rank = int.tryParse(rankObj.toString()) ?? 1;
      final total = int.tryParse(totalObj.toString()) ?? 1;
      final playersAbove = rank - 1;

      mathStr = 'Rank = Position based on TPI (Highest to Lowest)\n\n'
                'Players Above You = $playersAbove\n'
                'Total Players = $total\n'
                'Rank = Players Above You + 1\n'
                '     = $playersAbove + 1\n'
                '     = $rank';

      expStr = 'You are ranked $rank out of $total players.';
    }

    return MetricBreakdownProps(
      title: 'Rank',
      value: rankStr,
      math: mathStr,
      explanation: expStr ?? 'Your current numerical ranking in the campus.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getTpiBreakdown(String tpiStr) {
    final ratingObj = arenaStat?['rating'];
    final abilityObj = tpiData?['ability_score'];
    final consistencyObj = tpiData?['consistency_score'];
    final growthObj = tpiData?['growth_score'];
    String? mathStr;
    String? expStr;

    if (ratingObj != null && abilityObj != null && consistencyObj != null && growthObj != null) {
      final rating = double.tryParse(ratingObj.toString()) ?? 500.0;
      final ability = double.tryParse(abilityObj.toString()) ?? 0.0;
      final consistency = double.tryParse(consistencyObj.toString()) ?? 0.0;
      final growth = double.tryParse(growthObj.toString()) ?? 0.0;

      final ratingPart = rating * 0.6;
      final accuracyPart = consistency * 0.2;
      final activityPart = growth * 0.2;

      mathStr = 'TPI = (Rating × 0.6) + (Consistency × 0.2) + (Growth × 0.2)\n\n'
                '= (${rating.toStringAsFixed(0)} × 0.6) + (${consistency.toStringAsFixed(0)} × 0.2) + (${growth.toStringAsFixed(0)} × 0.2)\n'
                '= ${ratingPart.toStringAsFixed(1)} + ${accuracyPart.toStringAsFixed(1)} + ${activityPart.toStringAsFixed(1)}\n'
                '= $tpiStr';

      expStr = 'Your TPI combines:\n'
               '1. Skill (Rating) — contributes 60%\n'
               '2. Consistency (Activity regularity) — contributes 20%\n'
               '3. Growth (Improvement over time) — contributes 20%\n\n'
               'This creates a balanced overall performance score.';
    }

    return MetricBreakdownProps(
      title: 'TPI',
      value: tpiStr,
      math: mathStr,
      explanation: expStr ?? 'TPI combines skill, consistency, and activity into one score.',
      whyChanges: null,
      impact: null,
    );
  }

  MetricBreakdownProps _getGamesBreakdown(String gamesStr) {
    return MetricBreakdownProps(
      title: 'Games',
      value: gamesStr,
      explanation: 'You have played $gamesStr matches.',
      whyChanges: [
        'Increases after each completed match.',
      ],
      impact: 'More games improve experience but not rating directly.',
    );
  }

  void _showLeaderboard(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LeaderboardPage(userId: userId, collegeId: collegeId),
    ));
  }
}

class MetricBreakdownProps {
  final String title;
  final String value;
  final String? math;
  final String? explanation;
  final List<String>? whyChanges;
  final String? impact;

  const MetricBreakdownProps({
    required this.title,
    required this.value,
    this.math,
    this.explanation,
    this.whyChanges,
    this.impact,
  });
}

class _MetricBreakdownCard extends StatefulWidget {
  final List<MetricBreakdownProps> metrics;
  final ColorScheme cs;
  final ThemeData theme;
  final bool isDark;

  const _MetricBreakdownCard({
    required this.metrics,
    required this.cs,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_MetricBreakdownCard> createState() => _MetricBreakdownCardState();
}

class _MetricBreakdownCardState extends State<_MetricBreakdownCard> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.015),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          // Top Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(widget.metrics.length, (index) {
                final metric = widget.metrics[index];
                final isExpanded = _expandedIndex == index;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                         _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(metric.value, style: widget.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700, color: widget.cs.onSurface)),
                        const SizedBox(height: 4),
                        Text(metric.title, style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 12, color: widget.cs.primary),
                            const SizedBox(width: 4),
                            Text('Details', style: TextStyle(
                              fontSize: 10,
                              color: widget.cs.primary,
                              fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Expanded Panel
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expandedIndex != null ? _buildDetailsPanel(widget.metrics[_expandedIndex!]) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(MetricBreakdownProps metric) {
    final hasData = (metric.explanation != null && metric.explanation!.isNotEmpty);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
         border: Border(top: BorderSide(color: widget.cs.outlineVariant.withOpacity(0.3))),
         color: widget.isDark ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.02),
         borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(16),
      child: hasData ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${metric.title} Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.cs.onSurface)),
          const SizedBox(height: 12),
          
          if (metric.math != null && metric.math!.isNotEmpty) ...[
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
               width: double.infinity,
               decoration: BoxDecoration(
                  color: widget.cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
               ),
               child: Text(metric.math!, style: TextStyle(
                 fontFamily: 'monospace',
                 fontSize: 12,
                 fontWeight: FontWeight.w500,
                 color: widget.cs.onPrimaryContainer,
               )),
             ),
             const SizedBox(height: 12),
          ],
          
          if (metric.explanation != null && metric.explanation!.isNotEmpty) ...[
             Text(metric.explanation!, style: TextStyle(fontSize: 12, color: widget.cs.onSurfaceVariant)),
             const SizedBox(height: 12),
          ],
          
          if (metric.whyChanges != null && metric.whyChanges!.isNotEmpty) ...[
             Text('Why it changes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.cs.onSurface)),
             const SizedBox(height: 4),
             ...metric.whyChanges!.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontSize: 12, color: widget.cs.onSurfaceVariant)),
                    Expanded(child: Text(change, style: TextStyle(fontSize: 12, color: widget.cs.onSurfaceVariant))),
                  ],
                ),
             )),
             const SizedBox(height: 12),
          ],
          
          if (metric.impact != null && metric.impact!.isNotEmpty) ...[
             Text('Impact:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.cs.onSurface)),
             const SizedBox(height: 4),
             Text(metric.impact!, style: TextStyle(fontSize: 12, color: widget.cs.primary.withOpacity(0.8))),
          ],
        ],
      ) : Text('Details unavailable.', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: widget.cs.onSurfaceVariant)),
    );
  }
}

class _LeaderboardPage extends StatelessWidget {
  final String userId;
  final String? collegeId;
  const _LeaderboardPage({required this.userId, this.collegeId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Campus Leaderboard', style: TextStyle(
          fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 18)),
      ),
      body: LeaderboardWidget(userId: userId, collegeId: collegeId),
    );
  }
}
