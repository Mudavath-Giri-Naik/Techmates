import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';

class ProjectsSection extends StatefulWidget {
  final DevCardModel devCard;
  final bool isDark;
  final VoidCallback? onReport;

  const ProjectsSection(
      {super.key, required this.devCard, required this.isDark, this.onReport});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  final Set<int> _expanded = {};

  bool get d => widget.isDark;
  Color get _cardBg => d ? const Color(0xFF0D1120) : Colors.white;
  Color get _boxBg => d ? const Color(0xFF141E2F) : const Color(0xFFF9FAFB);
  Color get _text1 => d ? const Color(0xFFEDF2FF) : const Color(0xFF1A1A2E);
  Color get _text2 => d ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);
  Color get _borderCol => d ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);

  Color _scoreBadgeColor(double score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFF43F5E);
  }

  // Match project analysis to project score by name
  ProjectScore? _findScore(String name) {
    try {
      return widget.devCard.projectScores
          .firstWhere((s) => s.projectName == name);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.devCard.projects.take(3).toList();
    if (projects.isEmpty) return const SizedBox.shrink();
    final remaining = widget.devCard.projects.length - 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...projects.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final score = _findScore(p.name);
            return _compactCard(i, p, score);
          }),
          if (remaining > 0)
            GestureDetector(
              onTap: widget.onReport,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('+ $remaining more repos →',
                    style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactCard(int index, ProjectAnalysis p, ProjectScore? score) {
    final sVal = score?.finalScore ?? 0;
    final badgeColor = _scoreBadgeColor(sVal);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _boxBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          Text('#${index + 1}',
              style: TextStyle(
                  color: _text2,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(p.name,
                style: TextStyle(
                    color: _text1,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (p.frameworks.isNotEmpty) ...[
            ...p.frameworks.take(2).map((f) => Container(
                  margin: const EdgeInsets.only(left: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _borderCol,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          color: _text2,
                          fontSize: 8,
                          fontFamily: 'monospace')),
                )),
            if (p.frameworks.length > 2)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text('+${p.frameworks.length - 2}',
                    style: TextStyle(
                        color: _text2,
                        fontSize: 8,
                        fontFamily: 'monospace')),
              ),
          ],
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: d ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${sVal.round()}',
                style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _projectCard(
      int index, ProjectAnalysis p, ProjectScore? score, bool expanded) {
    final sVal = score?.finalScore ?? 0;
    final badgeColor = _scoreBadgeColor(sVal);

    return GestureDetector(
      onTap: () => setState(() {
        expanded ? _expanded.remove(index) : _expanded.add(index);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _boxBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderCol),
        ),
        child: Column(
          children: [
            // Collapsed row
            Row(
              children: [
                Text('#${index + 1}',
                    style: TextStyle(
                        color: _text2,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p.name,
                      style: TextStyle(
                          color: _text1,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                // Framework emojis
                if (p.frameworks.isNotEmpty)
                  ...p.frameworks.take(3).map((f) => Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(_fwEmoji(f),
                            style: const TextStyle(fontSize: 12)),
                      )),
                const SizedBox(width: 6),
                // Score badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: d ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text('${sVal.round()}',
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace')),
                ),
                const SizedBox(width: 4),
                Icon(expanded ? Icons.expand_less : Icons.chevron_right,
                    color: _text2, size: 16),
              ],
            ),

            // Expanded details
            if (expanded) ...[
              const SizedBox(height: 8),
              Divider(color: _borderCol, height: 1),
              const SizedBox(height: 8),
              _detailRow('Class', p.codeStyleLabel),
              _detailRow('Language', p.primaryLanguage ?? 'Unknown'),
              _detailRow('Commits', '${p.commitCount}'),
              _detailRow('Contributors', '${p.contributorCount}'),
              _detailRow('Built in', '${p.builtInDays} days'),
              if (p.description?.isNotEmpty == true)
                _detailRow('Description', p.description!),
              const SizedBox(height: 6),
              // Score breakdown
              if (score != null) ...[
                _scoreRow('Commit', score.commitScore),
                _scoreRow('README', score.readmeScore),
                _scoreRow('Tech', score.techScore),
                const SizedBox(height: 4),
                // Gradient progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: _borderCol,
                      borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (sVal / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(colors: [
                          const Color(0xFF00D4FF),
                          badgeColor,
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(
                      color: _text2, fontSize: 10, fontFamily: 'monospace'))),
          Expanded(
              child: Text(value,
                  style: TextStyle(color: _text1, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: _text2, fontSize: 9, fontFamily: 'monospace'))),
          Text('$score',
              style: TextStyle(
                  color: _text1,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  String _fwEmoji(String fw) {
    final lower = fw.toLowerCase();
    if (lower.contains('react')) return '⚛️';
    if (lower.contains('flutter')) return '💎';
    if (lower.contains('node') || lower.contains('express')) return '🟢';
    if (lower.contains('python') || lower.contains('django') || lower.contains('flask')) return '🐍';
    if (lower.contains('next')) return '▲';
    if (lower.contains('vue')) return '💚';
    if (lower.contains('firebase')) return '🔥';
    if (lower.contains('docker')) return '🐳';
    if (lower.contains('mongo')) return '🍃';
    if (lower.contains('postgres') || lower.contains('sql')) return '🐘';
    return '⚙️';
  }
}
