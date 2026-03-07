import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular initials avatar with a pastel background.
///
/// Usage:
/// ```dart
/// AppAvatar(name: 'Giri Naik', url: avatarUrl, size: 40)
/// ```
class AppAvatar extends StatelessWidget {
  final String? name;
  final String? url;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.name,
    this.url,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final bg = _pastelBg(initials);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(initials, bg),
              )
            : _initialsWidget(initials, bg),
      ),
    );
  }

  Widget _initialsWidget(String initials, Color bg) {
    return Container(
      color: bg,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
            color: AppColors.light.inkMid,
          ),
        ),
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Deterministic pastel colour from initials.
  static Color _pastelBg(String initials) {
    const pastels = [
      Color(0xFFE0E7FF), // indigo
      Color(0xFFDDD6FE), // violet
      Color(0xFFFCE7F3), // pink
      Color(0xFFFFEDD5), // orange
      Color(0xFFD1FAE5), // green
      Color(0xFFCFFAFE), // cyan
      Color(0xFFF3E8FF), // purple
      Color(0xFFFEF3C7), // amber
    ];
    final hash = initials.codeUnits.fold<int>(0, (a, b) => a + b);
    return pastels[hash % pastels.length];
  }
}
