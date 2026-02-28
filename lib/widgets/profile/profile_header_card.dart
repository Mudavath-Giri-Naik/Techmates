import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/user_profile.dart';

/// A beautifully designed profile header card for the top of the drawer.
/// Takes a [UserProfile] and a callback to update it after edits.
class ProfileHeaderCard extends StatefulWidget {
  final UserProfile profile;
  final bool isCurrentUser;
  final ValueChanged<UserProfile>? onProfileUpdated;
  final VoidCallback? onEditProfile;
  final VoidCallback? onViewArchive;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    this.isCurrentUser = true,
    this.onProfileUpdated,
    this.onEditProfile,
    this.onViewArchive,
  });

  @override
  State<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<ProfileHeaderCard> {
  // ── Brand colors ──
  static const _primaryBlue = Color(0xFF1A73E8);
  static const _green = Color(0xFF2E7D32);

  late UserProfile _profile;
  String _repoCount = '-';

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _fetchRepoCount();
  }

  Future<void> _fetchRepoCount() async {
    try {
      final cached = await Supabase.instance.client
          .from('devcard_cache')
          .select('analyzed_data')
          .eq('user_id', _profile.id)
          .maybeSingle();

      if (cached != null) {
        final data = cached['analyzed_data'] as Map<String, dynamic>?;
        if (data != null && data['total_repos'] != null) {
          if (mounted) {
            setState(() {
              _repoCount = data['total_repos'].toString();
            });
          }
          return;
        }
      }
      
      // If not in cache but we have github URL, fetch real count if possible
      // But for now, just default to 0 if we can't find it easily
      if (mounted) setState(() => _repoCount = '0');
    } catch (e) {
      debugPrint('Error fetching repo count: $e');
      if (mounted) setState(() => _repoCount = '0');
    }
  }

  @override
  void didUpdateWidget(covariant ProfileHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _profile = widget.profile;
      _fetchRepoCount();
    }
  }

  // ── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final url = _profile.avatarUrl;
    final name = _profile.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: 76,
                height: 76,
                errorWidget: (_, __, ___) => _initialsCircle(initial),
                placeholder: (_, __) => _initialsCircle(initial),
              )
            : _initialsCircle(initial),
      ),
    );
  }

  Widget _initialsCircle(String initial) {
    return Container(
      width: 76,
      height: 76,
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Verified chip ────────────────────────────────────────────────────────

  Widget _verifiedChip() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.4), width: 1),
      ),
      child: const Text(
        '✓ Verified',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: _green,
        ),
      ),
    );
  }

  // ── Stat Column ──────────────────────────────────────────────────────────

  Widget _statColumn(String count, String label) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Buttons ──────────────────────────────────────────────────────────────

  Widget _actionButton({required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  // ── Launch URL ───────────────────────────────────────────────────────────

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    var uri = url;
    if (!uri.startsWith('http://') && !uri.startsWith('https://')) {
      uri = 'https://$uri';
    }
    final parsed = Uri.tryParse(uri);
    if (parsed != null && await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Abbreviate branch if it has parentheses, e.g. "Computer Science (CSE)" -> "CSE"
    String? branchAbbr = _profile.branch;
    if (branchAbbr != null && branchAbbr.contains('(') && branchAbbr.contains(')')) {
      final startIndex = branchAbbr.indexOf('(') + 1;
      final endIndex = branchAbbr.indexOf(')');
      if (endIndex > startIndex) {
        branchAbbr = branchAbbr.substring(startIndex, endIndex).trim();
      }
    }

    final String handle = _profile.githubUrl != null && _profile.githubUrl!.isNotEmpty
        ? _profile.githubUrl!.split('/').last
        : (_profile.name?.replaceAll(' ', '').toLowerCase() ?? 'user');

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROW 1: Avatar + Stats ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      handle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statColumn(_repoCount, 'Repos'),
                        _statColumn('0', 'followers'),
                        _statColumn('0', 'following'),
                        const SizedBox(width: 8), // Padding on right
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Bio Section ──
          Text(
            _profile.name ?? 'User',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_profile.year != null || branchAbbr != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${_profile.year ?? ''}${_profile.year != null && branchAbbr != null ? ' · ' : ''}${branchAbbr ?? ''}',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
              ),
            ),
          if (_profile.college != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _profile.college!,
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_profile.collegeVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: _primaryBlue),
                  ],
                ],
              ),
            ),

          // Links
          if (_profile.githubUrl != null || _profile.linkedinUrl != null || _profile.instagramUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_profile.githubUrl != null && _profile.githubUrl!.isNotEmpty)
                    _socialLink(
                      icon: FontAwesomeIcons.github,
                      baseUrl: 'github.com',
                      url: _profile.githubUrl!,
                    ),
                  if (_profile.linkedinUrl != null && _profile.linkedinUrl!.isNotEmpty)
                    _socialLink(
                      icon: FontAwesomeIcons.linkedin,
                      baseUrl: 'linkedin.com',
                      url: _profile.linkedinUrl!,
                    ),
                  if (_profile.instagramUrl != null && _profile.instagramUrl!.isNotEmpty)
                    _socialLink(
                      icon: FontAwesomeIcons.instagram,
                      baseUrl: 'instagram.com',
                      url: _profile.instagramUrl!,
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ── Buttons ──
          Row(
            children: widget.isCurrentUser
                ? [
                    _actionButton(
                      label: 'Edit profile',
                      onTap: () {
                        if (widget.onEditProfile != null) {
                          widget.onEditProfile!();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      label: 'View archive',
                      onTap: () {
                        if (widget.onViewArchive != null) {
                          widget.onViewArchive!();
                        }
                      },
                    ),
                  ]
                : [
                    _actionButton(
                      label: 'Follow',
                      onTap: () {
                        // Mock follow action for now
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Following feature coming soon!')),
                        );
                      },
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _socialLink({required IconData icon, required String baseUrl, required String url}) {
    return GestureDetector(
      onTap: () => _launch(url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 14, color: _primaryBlue),
          const SizedBox(width: 5),
          Text(
            baseUrl,
            style: const TextStyle(
              fontSize: 13,
              color: _primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
