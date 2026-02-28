import 'package:flutter/material.dart';
import '../../models/devcard/devcard_model.dart';

class LanguagesSection extends StatelessWidget {
  final List<LanguageStat> languages;
  final List<ProjectAnalysis> projects;
  final bool isDark;

  const LanguagesSection({
    super.key,
    required this.languages,
    required this.isDark,
    this.projects = const [],
  });

  Color _cardBg(BuildContext context) => Theme.of(context).colorScheme.surface;
  Color _text1(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _text2(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  Color _borderCol(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B8B8B);
    }
  }

  int _projectCount(String langName) {
    return projects
        .where((p) =>
            p.primaryLanguage?.toLowerCase() == langName.toLowerCase())
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _cardBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...languages.map((l) => _row(l, context)),
        ],
      ),
    );
  }

  Widget _row(LanguageStat l, BuildContext context) {
    final color = _parseHex(l.color);
    final pct = (l.percentage * 100).toStringAsFixed(0);
    final count = _projectCount(l.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: Text(l.name,
                style: TextStyle(
                    color: _text1(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 80,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                  color: _borderCol(context), borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: l.percentage.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%',
              style: TextStyle(
                  color: _text2(context), fontSize: 9, fontFamily: 'monospace')),
          const Spacer(),
          Text('$count projects',
              style: TextStyle(
                  color: _text2(context), fontSize: 9, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
