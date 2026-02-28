import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/student_network_model.dart';
import '../devcard/devcard_screen.dart';

const _blue = Color(0xFF1565C0);

class StudentProfileScreen extends StatelessWidget {
  final StudentNetworkModel student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Student Profile',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _HeaderCard(student: student),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _StatsCard(student: student),
            ),
          ),
          if (!student.isContentHidden)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SocialLinksCard(student: student),
              ),
            ),
          if (student.isContentHidden)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _PrivateProfileCard(),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DevCardScreen(userId: student.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.badge_rounded, size: 18),
                  label: Text(
                    'View DevCard',
                    style: GoogleFonts.sora(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 24 +
                  MediaQuery.paddingOf(context).bottom +
                  kBottomNavigationBarHeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final StudentNetworkModel student;

  const _HeaderCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(student: student),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: student.displayName),
                      if (student.collegeVerified)
                        const TextSpan(text: '\u00A0'),
                      if (student.collegeVerified)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _blue,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [student.branch, student.yearTabLabel]
                      .where((e) => e != null && e.isNotEmpty)
                      .join('  -  '),
                  style: GoogleFonts.sora(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if ((student.college ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    student.college!,
                    style: GoogleFonts.sora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final StudentNetworkModel student;

  const _Avatar({required this.student});

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: student.avatarUrl != null && student.avatarUrl!.isNotEmpty
          ? Image.network(
              student.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  _initials(student.name),
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(student.name),
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final StudentNetworkModel student;

  const _StatsCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Followers',
            value: student.followerCount.toString(),
          ),
          _divider(cs),
          _StatItem(
            label: 'Following',
            value: student.followingCount.toString(),
          ),
          _divider(cs),
          _StatItem(
            label: 'GitHub Score',
            value: student.githubScore.toString(),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) =>
      Container(width: 1, height: 26, color: cs.outlineVariant);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLinksCard extends StatelessWidget {
  final StudentNetworkModel student;

  const _SocialLinksCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect',
            style: GoogleFonts.sora(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((student.githubUrl ?? '').isNotEmpty)
                _LinkButton(
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  url: student.githubUrl!,
                ),
              if ((student.linkedinUrl ?? '').isNotEmpty)
                _LinkButton(
                  icon: Icons.business_center_rounded,
                  label: 'LinkedIn',
                  url: student.linkedinUrl!,
                ),
              if ((student.instagramUrl ?? '').isNotEmpty)
                _LinkButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  url: student.instagramUrl!,
                ),
              if ((student.githubUrl ?? '').isEmpty &&
                  (student.linkedinUrl ?? '').isEmpty &&
                  (student.instagramUrl ?? '').isEmpty)
                Text(
                  'No social links available',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: _open,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        textStyle: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _PrivateProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This profile is private. Limited details are visible.',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
