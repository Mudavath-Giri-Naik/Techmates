import 'dart:math' show min, max;

import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class ScoreBreakdownCard extends StatefulWidget {
  final DevScoreBreakdown breakdown;
  final List<ProjectScore> projectScores;
  final int uniqueLanguagesCount;
  final int uniqueFrameworksCount;
  final int totalCommitsLastYear;

  const ScoreBreakdownCard({
    super.key,
    required this.breakdown,
    required this.projectScores,
    required this.uniqueLanguagesCount,
    required this.uniqueFrameworksCount,
    required this.totalCommitsLastYear,
  });

  @override
  State<ScoreBreakdownCard> createState() => _ScoreBreakdownCardState();
}

class _ScoreBreakdownCardState extends State<ScoreBreakdownCard> {
  bool _isExpanded = false;

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.breakdown;
    final rankColor = _parseHex(b.rankColor);

    // ── DEPTH: best N = min(5, total repos) ──────────────────────────────────
    // Always fair: 1 repo student uses 1, 50 repo student uses best 5
    final totalScored = widget.projectScores.length;
    final usedCount = min(5, totalScored);
    final topN = widget.projectScores.take(usedCount).toList();

    List<String> depthItems;
    if (topN.isEmpty) {
      depthItems = ['No repositories found yet'];
    } else {
      depthItems = topN
          .map((p) =>
              '${p.projectName}  —  ${p.finalScore.toStringAsFixed(1)} pts'
              '  (${p.commitCount} commits'
              ' · ${p.timelineLabel}'
              ' · ${p.repoFrameworkCount}'
              ' framework${p.repoFrameworkCount == 1 ? '' : 's'})')
          .toList();

      // Summary line showing selection logic
      if (totalScored > 5) {
        depthItems.add(
          'Best $usedCount selected from $totalScored total repositories',
        );
      } else if (totalScored == 1) {
        depthItems.add(
          'Only 1 repository found — score based on this project alone',
        );
      } else {
        depthItems.add(
          'All $totalScored repositories considered'
          ' — best $usedCount used for average',
        );
      }
    }

    // ── CONSISTENCY ───────────────────────────────────────────────────────────
    final activeDays = (b.consistency / 100 * 365).round();
    final consistencyItems = [
      'Active coding days this year: $activeDays / 365',
      'Source: GitHub contribution calendar (last 52 weeks)',
      'A day is counted active if it has at least 1 commit',
      'Score formula: (active days ÷ 365) × 100, capped at 100',
    ];

    // ── BREADTH ───────────────────────────────────────────────────────────────
    final uLang = widget.uniqueLanguagesCount;
    final uFw = widget.uniqueFrameworksCount;
    final langPts = min(60, uLang * 12);
    final fwPts = min(40, uFw * 8);
    final breadthItems = [
      'Languages detected: $uLang'
          '  ($langPts / 60 pts  ·  12 pts per language)',
      'Frameworks detected across all repos: $uFw'
          '  ($fwPts / 40 pts  ·  8 pts per framework)',
      'Detected from package.json, pubspec.yaml, requirements.txt,'
          ' Cargo.toml, go.mod',
      'Total breadth score: $langPts + $fwPts = ${langPts + fwPts} / 100',
    ];

    // ── ACTIVITY ──────────────────────────────────────────────────────────────
    final commits = widget.totalCommitsLastYear;
    final activityItems = [
      'Total commits in the last year: $commits',
      'Score formula: commits ÷ 10, capped at 100',
      'Source: GitHub contributionsCollection',
      '1000+ commits = 100 / 100 activity score',
    ];

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Always-visible header ─────────────────────────────────────────
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.rank,
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b.total} / 1000',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _miniBar('D', b.depth,       const Color(0xFF3FB950)),
                    const SizedBox(width: 6),
                    _miniBar('C', b.consistency, const Color(0xFF58A6FF)),
                    const SizedBox(width: 6),
                    _miniBar('B', b.breadth,     const Color(0xFF9C27B0)),
                    const SizedBox(width: 6),
                    _miniBar('A', b.activity,    const Color(0xFFFF9800)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF8B949E),
                  size: 20,
                ),
              ],
            ),

            // ── Expanded breakdown ────────────────────────────────────────────
            if (_isExpanded) ...[
              const Divider(color: Color(0xFF30363D), height: 24),

              const Text(
                'Depth 30%  ·  Consistency 30%  ·  Breadth 20%  ·  Activity 20%',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 10,
                  letterSpacing: 0.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              _buildComponent(
                label: 'Depth',
                weight: '30%',
                score: b.depth,
                barColor: const Color(0xFF3FB950),
                labelIcon: Icons.layers_outlined,
                reason: b.depthReason,
                tip: b.depthTip,
                consideredItems: depthItems,
              ),
              _buildComponent(
                label: 'Consistency',
                weight: '30%',
                score: b.consistency,
                barColor: const Color(0xFF58A6FF),
                labelIcon: Icons.calendar_today_outlined,
                reason: b.consistencyReason,
                tip: b.consistencyTip,
                consideredItems: consistencyItems,
              ),
              _buildComponent(
                label: 'Breadth',
                weight: '20%',
                score: b.breadth,
                barColor: const Color(0xFF9C27B0),
                labelIcon: Icons.hub_outlined,
                reason: b.breadthReason,
                tip: b.breadthTip,
                consideredItems: breadthItems,
              ),
              _buildComponent(
                label: 'Activity',
                weight: '20%',
                score: b.activity,
                barColor: const Color(0xFFFF9800),
                labelIcon: Icons.commit,
                reason: b.activityReason,
                tip: b.activityTip,
                consideredItems: activityItems,
              ),

              // ── Transparency footer ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 12, color: Color(0xFF8B949E)),
                        SizedBox(width: 6),
                        Text(
                          'Scoring Transparency',
                          style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _footerLine(
                      Icons.layers_outlined,
                      'Depth — best project quality averaged'
                      ' (commits + README + tech stack + build time)',
                    ),
                    _footerLine(
                      Icons.calendar_today_outlined,
                      'Consistency — active coding days out of last 365',
                    ),
                    _footerLine(
                      Icons.hub_outlined,
                      'Breadth — unique languages and frameworks'
                      ' used across all repos',
                    ),
                    _footerLine(
                      Icons.commit,
                      'Activity — total commits made in the last year',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stars, followers, and total repo count'
                      ' do not affect your score.',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Component block ───────────────────────────────────────────────────────────
  Widget _buildComponent({
    required String label,
    required String weight,
    required int score,
    required Color barColor,
    required IconData labelIcon,
    required String reason,
    required String tip,
    required List<String> consideredItems,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Label row
          Row(
            children: [
              Icon(labelIcon, size: 14, color: barColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  weight,
                  style: TextStyle(color: barColor, fontSize: 10),
                ),
              ),
              const Spacer(),
              Text(
                '$score / 100',
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFF21262D),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 12, color: Color(0xFF8B949E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 12, color: Color(0xFF58A6FF)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: Color(0xFF58A6FF),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          // Considered items box
          if (consideredItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.playlist_add_check,
                          size: 12, color: Color(0xFF8B949E)),
                      SizedBox(width: 6),
                      Text(
                        'Considered in this score',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...consideredItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.only(
                                top: 5, right: 8),
                            decoration: BoxDecoration(
                              color: barColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Footer line ───────────────────────────────────────────────────────────────
  Widget _footerLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF8B949E)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mini vertical bar (collapsed state) ──────────────────────────────────────
  Widget _miniBar(String letter, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: max(2.0, 20.0 * (score / 100)),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          letter,
          style: const TextStyle(
              color: Color(0xFF8B949E), fontSize: 8),
        ),
      ],
    );
  }
}