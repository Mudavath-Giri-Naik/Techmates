import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/devcard/devcard_model.dart';
import '../home_theme.dart';

/// Section 2 — Horizontal stats cards row: Streak, Journey, GitHub.
class StatsCardsRow extends StatefulWidget {
  final int dayStreak; // from DevCardModel.currentStreak
  final int totalOps;
  final int savedCount;
  final int appliedCount;
  final DevCardModel? devCard;

  const StatsCardsRow({
    super.key,
    required this.dayStreak,
    required this.totalOps,
    required this.savedCount,
    this.appliedCount = 0,
    this.devCard,
  });

  @override
  State<StatsCardsRow> createState() => _StatsCardsRowState();
}

class _StatsCardsRowState extends State<StatsCardsRow>
    with TickerProviderStateMixin {
  late AnimationController _journeyBarCtrl;
  late AnimationController _githubBarCtrl;

  @override
  void initState() {
    super.initState();
    _journeyBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _githubBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _journeyBarCtrl.dispose();
    _githubBarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStreakCard(),
          const SizedBox(width: 8),
          _buildJourneyCard(),
          const SizedBox(width: 8),
          _buildGitHubCard(),
        ],
      ),
    );
  }

  // ── Streak Card ──
  Widget _buildStreakCard() {
    final streak = widget.dayStreak;
    final daysToGoal = (3 - streak).clamp(0, 3);
    final hintText = streak >= 3
        ? 'Keep it up!'
        : 'Visit $daysToGoal more days to hit your first streak 🔥';

    return Container(
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTheme.surfaceContainer(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: HomeTheme.accentOrangeContainer(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 18, color: HomeTheme.accentOrange),
              ),
              const SizedBox(width: 8),
              Text(
                '$streak',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HomeTheme.onSurface(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 7-dot row
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 6 ? 3 : 0),
                  decoration: BoxDecoration(
                    color: i < streak
                        ? HomeTheme.accentOrange
                        : HomeTheme.surfaceContainerHighest(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            hintText,
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              color: HomeTheme.onSurfaceVariant(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Journey Card ──
  Widget _buildJourneyCard() {
    final explored = widget.totalOps;
    final saved = widget.savedCount;
    final applied = widget.appliedCount;
    final progressValue = explored > 0
        ? ((saved + applied) / explored).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTheme.surfaceContainer(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: HomeTheme.accentBlueContainer(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work_rounded,
                    size: 16, color: HomeTheme.accentBlue),
              ),
              const SizedBox(width: 8),
              Text(
                'JOURNEY',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: HomeTheme.onSurfaceVariant(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('$explored', 'Explored', context),
              Container(width: 1, height: 22, color: HomeTheme.outlineVariant(context)),
              _statColumn('$saved', 'Saved', context),
              Container(width: 1, height: 22, color: HomeTheme.outlineVariant(context)),
              _statColumn('$applied', 'Applied', context),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _journeyBarCtrl,
            builder: (_, __) {
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  color: HomeTheme.surfaceContainerHighest(context),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressValue * _journeyBarCtrl.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: HomeTheme.accentBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
              fontSize: 18, fontWeight: FontWeight.w700, color: HomeTheme.onSurface(context)),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
              fontSize: 9, color: HomeTheme.onSurfaceVariant(context)),
        ),
      ],
    );
  }

  // ── GitHub Card ──
  Widget _buildGitHubCard() {
    final devCard = widget.devCard;

    if (devCard == null) {
      return Container(
        width: 152,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HomeTheme.surfaceContainer(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_rounded, size: 24,
                color: HomeTheme.onSurfaceVariant(context)),
            const SizedBox(height: 8),
            Text(
              'Connect GitHub',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeTheme.onSurface(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Link your profile',
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                color: HomeTheme.onSurfaceVariant(context),
              ),
            ),
          ],
        ),
      );
    }

    final rank = devCard.scoreBreakdown.rank;
    final score = devCard.scoreBreakdown.total;

    // Estimate next rank threshold based on score logic (out of 1000)
    int nextThreshold = 100;
    if (score < 100) nextThreshold = 100;
    else if (score < 200) nextThreshold = 200;
    else if (score < 300) nextThreshold = 300;
    else if (score < 400) nextThreshold = 400;
    else if (score < 500) nextThreshold = 500;
    else if (score < 600) nextThreshold = 600;
    else if (score < 700) nextThreshold = 700;
    else if (score < 800) nextThreshold = 800;
    else if (score < 900) nextThreshold = 900;
    else nextThreshold = 1000;

    final progress = (score / nextThreshold).clamp(0.0, 1.0);
    final pointsNeeded = (nextThreshold - score).clamp(0, nextThreshold);

    return Container(
      width: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTheme.surfaceContainer(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: HomeTheme.surfaceContainerHigh(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.code_rounded,
                    size: 16, color: HomeTheme.onSurfaceVariant(context)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HomeTheme.primaryContainer(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        size: 12, color: HomeTheme.onPrimaryContainer(context)),
                    const SizedBox(width: 3),
                    Text(
                      rank,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: HomeTheme.onPrimaryContainer(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$score Points',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: HomeTheme.onSurface(context),
            ),
          ),
          Text(
            'DevCard Score',
            style: GoogleFonts.nunito(
              fontSize: 9,
              color: HomeTheme.onSurfaceVariant(context),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$pointsNeeded pts to next rank',
                    style: GoogleFonts.nunito(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: HomeTheme.primary(context),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.nunito(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: HomeTheme.onSurfaceVariant(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _githubBarCtrl,
                builder: (_, __) {
                  return Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: HomeTheme.surfaceContainerHighest(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress * _githubBarCtrl.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: HomeTheme.primary(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
