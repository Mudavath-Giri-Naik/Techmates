import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_network_model.dart';
import '../../models/follow_model.dart';
import '../../models/devcard/devcard_model.dart';
import '../../services/devcard/devcard_service.dart';
import '../../widgets/network/follow_button.dart';
import '../devcard/devcard_screen.dart';
import 'follow_list_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentNetworkModel student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late StudentNetworkModel _student;
  DevCardModel? _devCardModel;
  bool _devCardLoading = false;
  bool _devCardLoaded = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDevCard());
  }

  Future<void> _loadDevCard() async {
    if (_devCardLoaded) return;
    setState(() => _devCardLoading = true);
    try {
      final card = await DevCardService.getOtherUserDevCard(_student.id);
      if (mounted) {
        setState(() {
          _devCardModel = card;
          _devCardLoading = false;
          _devCardLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _devCardLoading = false;
          _devCardLoaded = true;
        });
      }
    }
  }

  void _onFollowStatusChanged(FollowStatus newStatus) {
    final previousStatus = _student.followStatus;
    int delta = 0;
    if (previousStatus == FollowStatus.none && newStatus == FollowStatus.following) {
      delta = 1;
    } else if (previousStatus == FollowStatus.following && newStatus == FollowStatus.none) {
      delta = -1;
    }
    setState(() {
      _student = _student.copyWith(
        followStatus: newStatus,
        followerCount: (_student.followerCount + delta).clamp(0, 999999999),
      );
    });
  }

  Future<void> _refresh() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;
      final results = await Future.wait([
        Supabase.instance.client.rpc('get_follow_status', params: {
          'p_viewer_id': currentUserId,
          'p_target_id': _student.id,
        }),
        Supabase.instance.client.rpc('get_follower_count', params: {'p_user_id': _student.id}),
        Supabase.instance.client.rpc('get_following_count', params: {'p_user_id': _student.id}),
      ]);
      if (mounted) {
        setState(() {
          _student = _student.copyWith(
            followStatus: FollowStatus.fromString(results[0] as String?),
            followerCount: (results[1] as num?)?.toInt() ?? _student.followerCount,
            followingCount: (results[2] as num?)?.toInt() ?? _student.followingCount,
          );
        });
      }
    } catch (e) {
      debugPrint('Error refreshing student profile: $e');
    }
  }

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF0F172A),
        strokeWidth: 1.5,
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + follow row ───────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildAvatar(72),
                        const Spacer(),
                        FollowButton(
                          targetUserId: _student.id,
                          initialStatus: _student.followStatus,
                          compact: false,
                          onStatusChanged: _onFollowStatusChanged,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Name ──────────────────────────────────────────────
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _student.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_student.collegeVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: Color(0xFF38BDF8)),
                        ],
                        if (_student.isPrivate) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.lock_outline,
                              size: 14, color: Color(0xFFB0BEC5)),
                        ],
                      ],
                    ),

                    const SizedBox(height: 3),

                    // ── Branch · Year ─────────────────────────────────────
                    if (_buildSubtitle().isNotEmpty)
                      Text(
                        _buildSubtitle(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                    // ── College ───────────────────────────────────────────
                    if (_student.college != null && _student.college!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        _student.college!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0BEC5),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Stats row ─────────────────────────────────────────
                    _buildStatsRow(),

                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 24),

                    // ── Private state ─────────────────────────────────────
                    if (_student.isContentHidden)
                      _buildPrivateState()
                    else ...[
                      _buildSocialLinks(),
                      _buildDevCardSection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatar(double size) {
    final url = _student.avatarUrl;
    final initial = _student.displayName.isNotEmpty
        ? _student.displayName[0].toUpperCase()
        : '?';

    Widget fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );

    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => fallback,
          placeholder: (_, _) => fallback,
        ),
      );
    }
    return fallback;
  }

  // ── Subtitle ──────────────────────────────────────────────────────────────
  String _buildSubtitle() {
    final parts = <String>[];
    if (_student.branch != null && _student.branch!.isNotEmpty) parts.add(_student.branch!);
    if (_student.year != null && _student.year!.isNotEmpty) {
      parts.add(_student.isAlumni ? 'Alumni' : _student.year!);
    }
    return parts.join(' · ');
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FollowListScreen(
                userId: _student.id, title: 'Followers', isFollowers: true),
          )),
          child: _statItem('${_student.followerCount}', 'followers'),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FollowListScreen(
                userId: _student.id, title: 'Following', isFollowers: false),
          )),
          child: _statItem('${_student.followingCount}', 'following'),
        ),
        if (_student.githubScore > 0) ...[
          const SizedBox(width: 24),
          _statItem('${_student.githubScore}', 'github score'),
        ],
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Social links ──────────────────────────────────────────────────────────
  Widget _buildSocialLinks() {
    final links = <_SocialLink>[];

    if (_student.githubUrl != null && _student.githubUrl!.isNotEmpty) {
      links.add(_SocialLink(
          icon: FontAwesomeIcons.github, label: 'GitHub', url: _student.githubUrl!));
    }
    if (_student.linkedinUrl != null && _student.linkedinUrl!.isNotEmpty) {
      links.add(_SocialLink(
          icon: FontAwesomeIcons.linkedin, label: 'LinkedIn', url: _student.linkedinUrl!));
    }
    if (_student.instagramUrl != null && _student.instagramUrl!.isNotEmpty) {
      links.add(_SocialLink(
          icon: FontAwesomeIcons.instagram, label: 'Instagram', url: _student.instagramUrl!));
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: links
            .map((link) => Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => _launch(link.url),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(link.icon, size: 14, color: const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          link.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── DevCard section ───────────────────────────────────────────────────────
  Widget _buildDevCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DevCard',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),

        if (_devCardLoading)
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFB0BEC5)),
          )

        else if (_devCardModel == null && _devCardLoaded)
          const Text(
            'No DevCard yet',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB0BEC5),
              fontWeight: FontWeight.w400,
            ),
          )

        else if (_devCardModel != null)
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DevCardScreen(userId: _student.id),
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score + rank
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _parseHex(_devCardModel!.scoreBreakdown.rankColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_devCardModel!.scoreBreakdown.total}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _devCardModel!.scoreBreakdown.rank,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats inline
                Text(
                  [
                    '${_devCardModel!.totalPublicRepos} repos',
                    '${_devCardModel!.totalCommitsLastYear} commits',
                    '${_devCardModel!.currentStreak}d streak',
                  ].join('  ·  '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                // Top languages
                if (_devCardModel!.topLanguages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: _devCardModel!.topLanguages.take(5).map((lang) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _parseHex(lang.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lang.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],

                // Personality tags
                if (_devCardModel!.personalityTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _devCardModel!.personalityTags.take(3).map((tag) {
                      return Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0BEC5),
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                // View full
                Row(
                  children: const [
                    Text(
                      'View full DevCard',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F172A)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Private state ─────────────────────────────────────────────────────────
  Widget _buildPrivateState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Icon(Icons.lock_outline, size: 22, color: Color(0xFFB0BEC5)),
        SizedBox(height: 10),
        Text(
          'This account is private',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Follow to see their profile.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final String url;

  _SocialLink({required this.icon, required this.label, required this.url});
}