import 'package:flutter/material.dart';

import '../../models/devcard/devcard_model.dart';

class StrongestAtSection extends StatelessWidget {
  final List<FrameworkStat> frameworks;

  const StrongestAtSection({super.key, required this.frameworks});

  Color _categoryColor(String category) {
    switch (category) {
      case 'mobile':
        return const Color(0xFF2196F3);
      case 'web':
        return const Color(0xFF4CAF50);
      case 'backend':
        return const Color(0xFFFF9800);
      case 'ml':
        return const Color(0xFF9C27B0);
      case 'devops':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STRONGEST AT',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (frameworks.isEmpty)
            const Text(
              'Not enough data',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            )
          else
            ...frameworks.map((fw) {
              final maxCount = frameworks.first.projectCount;
              final fraction =
                  maxCount > 0 ? fw.projectCount / maxCount : 0.0;
              final color = _categoryColor(fw.category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        fw.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction.clamp(0.05, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${fw.projectCount} ${fw.projectCount == 1 ? 'project' : 'projects'}',
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 12),
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
