import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_profile.dart';

/// A beautifully designed profile header card for the top of the drawer.
/// Takes a [UserProfile] and a callback to update it after edits.
class ProfileHeaderCard extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile>? onProfileUpdated;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    this.onProfileUpdated,
  });

  @override
  State<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<ProfileHeaderCard> {
  // ── Brand colors ──
  static const _primaryBlue = Color(0xFF1A73E8);
  static const _primaryRed = Color(0xFFE53935);
  static const _textBlack = Color(0xFF111111);
  static const _muted = Color(0xFF757575);
  static const _lightBg = Color(0xFFF5F5F5);
  static const _border = Color(0xFFE0E0E0);
  static const _linkedInBlue = Color(0xFF0A66C2);
  static const _disabled = Color(0xFFBDBDBD);
  static const _green = Color(0xFF2E7D32);

  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant ProfileHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _profile = widget.profile;
    }
  }

  // ── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final url = _profile.avatarUrl;
    final name = _profile.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 1.5),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                errorWidget: (_, __, ___) => _initialsCircle(initial),
                placeholder: (_, __) => _initialsCircle(initial),
              )
            : _initialsCircle(initial),
      ),
    );
  }

  Widget _initialsCircle(String initial) {
    return Container(
      width: 56,
      height: 56,
      color: _primaryBlue,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
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

  // ── Info chips ───────────────────────────────────────────────────────────

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _primaryBlue),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Social items ─────────────────────────────────────────────────────────

  Widget _socialItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    bool showAddLabel = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(height: 4),
              Text(
                showAddLabel ? 'Add' : label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: showAddLabel ? _primaryRed : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add URL dialog ───────────────────────────────────────────────────────

  Future<void> _showAddUrlDialog({
    required String title,
    required String hint,
    required String field,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textBlack,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: _textBlack),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _disabled),
            filled: true,
            fillColor: _lightBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: _primaryBlue, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({field: result})
            .eq('id', _profile.id);

        final updated = field == 'linkedin_url'
            ? _profile.copyWith(linkedinUrl: result)
            : _profile.copyWith(githubUrl: result);

        setState(() => _profile = updated);
        widget.onProfileUpdated?.call(updated);
      } catch (e) {
        debugPrint('❌ [ProfileHeaderCard] save $field error: $e');
      }
    }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROW 1: Avatar + Name + College ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      _profile.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textBlack,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // College row
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: _primaryBlue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _profile.college ?? 'College not set',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_profile.collegeVerified) _verifiedChip(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── ROW 2: Academic chips ──
          if (_profile.branch != null || _profile.year != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_profile.branch != null)
                  _infoChip(Icons.school_rounded, _profile.branch!),
                if (_profile.year != null)
                  _infoChip(Icons.calendar_today_rounded, _profile.year!),
              ],
            ),
          ],

          // ── Divider ──
          Container(
            height: 1,
            color: _lightBg,
            margin: const EdgeInsets.symmetric(vertical: 14),
          ),

          // ── ROW 3: Social links ──
          Row(
            children: [
              // Email
              _socialItem(
                icon: Icons.email_outlined,
                label: 'Email',
                iconColor: _muted,
                onTap: () {},
              ),

              // LinkedIn
              _socialItem(
                icon: Icons.link_rounded,
                label: 'LinkedIn',
                iconColor: _profile.linkedinUrl != null && _profile.linkedinUrl!.isNotEmpty
                    ? _linkedInBlue
                    : _disabled,
                showAddLabel: _profile.linkedinUrl == null || _profile.linkedinUrl!.isEmpty,
                onTap: () {
                  if (_profile.linkedinUrl != null && _profile.linkedinUrl!.isNotEmpty) {
                    _launch(_profile.linkedinUrl);
                  } else {
                    _showAddUrlDialog(
                      title: 'Add LinkedIn',
                      hint: 'linkedin.com/in/yourname',
                      field: 'linkedin_url',
                    );
                  }
                },
              ),

              // GitHub
              _socialItem(
                icon: Icons.code_rounded,
                label: 'GitHub',
                iconColor: _profile.githubUrl != null && _profile.githubUrl!.isNotEmpty
                    ? _textBlack
                    : _disabled,
                showAddLabel: _profile.githubUrl == null || _profile.githubUrl!.isEmpty,
                onTap: () {
                  if (_profile.githubUrl != null && _profile.githubUrl!.isNotEmpty) {
                    _launch(_profile.githubUrl);
                  } else {
                    _showAddUrlDialog(
                      title: 'Add GitHub',
                      hint: 'github.com/username',
                      field: 'github_url',
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
