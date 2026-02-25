import 'package:flutter/material.dart';

class PersonalityTagsRow extends StatelessWidget {
  final List<String> tags;

  const PersonalityTagsRow({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: tags.map((tag) {
          final cleanTag = _cleanTag(tag);
          final icon = _iconForTag(cleanTag);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: const Color(0xFF8B949E)),
                const SizedBox(width: 6),
                Text(
                  cleanTag,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _cleanTag(String tag) {
    final withoutPrefix = tag.replaceFirst(
      RegExp(r'^[^\w]+', unicode: true),
      '',
    );
    return withoutPrefix.trim();
  }

  IconData _iconForTag(String tag) {
    switch (tag) {
      case 'Streak Warrior':
        return Icons.local_fire_department_outlined;
      case 'Star Magnet':
        return Icons.star_outline_rounded;
      case 'Project Builder':
        return Icons.build_outlined;
      case 'Polyglot Dev':
        return Icons.language_outlined;
      case 'Open Source Learner':
        return Icons.menu_book_outlined;
      case 'Hackathon Hunter':
        return Icons.flash_on_outlined;
      case 'Consistent Shipper':
        return Icons.rocket_launch_outlined;
      case 'Side Project Addict':
        return Icons.lightbulb_outline_rounded;
      case 'Deep Diver':
        return Icons.gps_fixed_rounded;
      case 'Rising Star':
        return Icons.auto_awesome_outlined;
      case 'Team Player':
        return Icons.groups_2_outlined;
      default:
        return Icons.label_outline_rounded;
    }
  }
}
