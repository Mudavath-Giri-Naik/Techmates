import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class LanguagesSection extends StatelessWidget {
  final List<LanguageStat> languages;

  const LanguagesSection({super.key, required this.languages});

  Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B8B8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LANGUAGES',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...languages.map((l) {
            final color = _parseHex(l.color);
            final pct = (l.percentage * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      l.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: l.percentage.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$pct%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
