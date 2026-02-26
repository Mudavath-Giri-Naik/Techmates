import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';

class CommitsSection extends StatelessWidget {
  final List<CommitActivity> commits;
  final List<String> frameworks;
  final List<ProjectAnalysis> projects;
  final bool isDark;

  const CommitsSection({
    super.key,
    required this.commits,
    required this.isDark,
    this.frameworks = const [],
    this.projects = const [],
  });

  Color get _cardBg => isDark ? const Color(0xFF0D1120) : Colors.white;
  Color get _text1 => isDark ? const Color(0xFFEDF2FF) : const Color(0xFF1A1A2E);
  Color get _text2 => isDark ? const Color(0xFF6B7FA0) : const Color(0xFF6B7280);
  Color get _borderCol => isDark ? const Color(0xFF1E2D42) : const Color(0xFFE5E7EB);

  static const _dots = [
    Color(0xFF00D4FF),
    Color(0xFF8B5CF6),
    Color(0xFF22C55E),
  ];

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  int _fwProjectCount(String fw) {
    return projects
        .where((p) => p.frameworks
            .any((f) => f.toLowerCase() == fw.toLowerCase()))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    if (commits.isEmpty && frameworks.isEmpty) return const SizedBox.shrink();
    final shown = commits.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _cardBg,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Left: Commits ────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: shown.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  final dotColor = _dots[i % _dots.length];
                  final isLast = i == shown.length - 1;
                  return _commitRow(c, dotColor, isLast);
                }).toList(),
              ),
            ),

            // ─── Divider ──────────────────────────────
            if (frameworks.isNotEmpty) ...[
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: _borderCol,
              ),

              // ─── Right: Tech Stack ────────────────────
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...frameworks.take(3).map((fw) {
                      final count = _fwProjectCount(fw);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: _text2,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(fw,
                                  style: TextStyle(
                                      color: _text1,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('$count',
                                style: TextStyle(
                                    color: _text2,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }),
                    if (frameworks.length > 3)
                      Text('+${frameworks.length - 3} technologies',
                          style: TextStyle(
                              color: const Color(0xFF00D4FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _commitRow(CommitActivity c, Color dotColor, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 7,
            child: Column(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: _borderCol,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _text1,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(c.repoName,
                          style: const TextStyle(
                              color: Color(0xFF00D4FF), fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Text(_timeAgo(c.committedDate),
                        style: TextStyle(color: _text2, fontSize: 9)),
                    if (c.additions > 0 || c.deletions > 0) ...[
                      const SizedBox(width: 4),
                      Text('+${c.additions}',
                          style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 2),
                      Text('-${c.deletions}',
                          style: const TextStyle(
                              color: Color(0xFFF43F5E),
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
