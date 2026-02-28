import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_profile.dart';
import '../home_theme.dart';

/// Section 1 — Greeting header with time-based greeting, name, college chip, avatar.
class GreetingHeader extends StatefulWidget {
  final UserProfile? profile;
  const GreetingHeader({super.key, this.profile});

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    // Wave emoji animation: infinite rotate loop
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _initials() {
    final name = widget.profile?.name ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.profile?.name?.split(' ').first ?? 'there';
    final college = widget.profile?.college;

    return Container(
      color: HomeTheme.surfaceContainerLow(context),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: greeting + name + college ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: HomeTheme.onSurfaceVariant(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Hello, $firstName ',
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: HomeTheme.onSurface(context),
                          letterSpacing: -0.3,
                        ),
                      ),
                      // Animated wave emoji
                      AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) {
                          // Keyframe: 0→14°→-8°→14°→-4°→10°→0°
                          final t = _waveCtrl.value;
                          double deg;
                          if (t < 0.15) {
                            deg = _lerp(0, 14, t / 0.15);
                          } else if (t < 0.30) {
                            deg = _lerp(14, -8, (t - 0.15) / 0.15);
                          } else if (t < 0.45) {
                            deg = _lerp(-8, 14, (t - 0.30) / 0.15);
                          } else if (t < 0.55) {
                            deg = _lerp(14, -4, (t - 0.45) / 0.10);
                          } else if (t < 0.65) {
                            deg = _lerp(-4, 10, (t - 0.55) / 0.10);
                          } else if (t < 0.80) {
                            deg = _lerp(10, 0, (t - 0.65) / 0.15);
                          } else {
                            deg = 0;
                          }
                          return Transform.rotate(
                            angle: deg * 3.14159 / 180,
                            child: const Text('👋', style: TextStyle(fontSize: 24)),
                          );
                        },
                      ),
                    ],
                  ),
                  if (college != null && college.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: HomeTheme.secondaryContainer(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_rounded, size: 13,
                              color: HomeTheme.onSecondaryContainer(context)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              college,
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: HomeTheme.onSecondaryContainer(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Right: Avatar circle ──
            const SizedBox(width: 12),
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [HomeTheme.primary(context), HomeTheme.tertiary(context)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: HomeTheme.outlineVariant(context), width: 1.5),
                  ),
                  child: Center(
                    child: widget.profile?.avatarUrl != null &&
                            widget.profile!.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.profile!.avatarUrl!,
                              width: 43,
                              height: 43,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _initialsWidget(),
                            ),
                          )
                        : _initialsWidget(),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget() {
    return Text(
      _initials(),
      style: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);
}
