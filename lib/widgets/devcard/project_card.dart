import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class ProjectCard extends StatelessWidget {
  final ProjectAnalysis project;

  const ProjectCard({super.key, required this.project});

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF8B8B8B);
    final cleaned = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B8B8B);
    }
  }

  Color _codeStyleColor(String style) {
    switch (style) {
      case 'self_built':
        return const Color(0xFF3FB950);
      case 'rapid_build':
        return const Color(0xFFFF9800);
      case 'vibe_coded':
        return const Color(0xFF9C27B0);
      case 'forked':
        return const Color(0xFF6E7681);
      case 'collaborative':
        return const Color(0xFF58A6FF);
      default:
        return const Color(0xFF6E7681);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final styleColor = _codeStyleColor(project.codeStyle);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Stars
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project.stars > 0) ...[
                const Icon(Icons.star,
                    size: 12, color: Color(0xFFF1E05A)),
                const SizedBox(width: 3),
                Text('${project.stars}',
                    style: const TextStyle(
                        color: Color(0xFF8B949E), fontSize: 12)),
              ],
            ],
          ),

          // Description
          if (project.description != null &&
              project.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description!,
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 8),

          // Language + framework chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (project.primaryLanguage != null)
                _chip(
                  text: project.primaryLanguage!,
                  dotColor: _parseHex(project.primaryLanguageColor),
                  isLanguage: true,
                ),
              ...project.frameworks.take(3).map((fw) => _chip(text: fw)),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom row
          Row(
            children: [
              // Code style badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: styleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: styleColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  project.codeStyleLabel,
                  style: TextStyle(color: styleColor, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Text('${project.commitCount} commits',
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11)),
              const SizedBox(width: 8),
              const Text('·',
                  style: TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11)),
              const SizedBox(width: 8),
              Text(_timeAgo(project.pushedAt),
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11)),
              // Org badge
              if (project.repoSource == 'org' &&
                  project.orgName != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            const Color(0xFF1F6FEB).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    project.orgName!,
                    style: const TextStyle(
                        color: Color(0xFF58A6FF), fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String text,
    Color dotColor = const Color(0xFF30363D),
    bool isLanguage = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLanguage) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
