import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase_client.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/status_service.dart';
import '../../services/devcard/devcard_service.dart';
import '../../services/user_role_service.dart';
import '../../models/user_profile.dart';
import '../../models/devcard/devcard_model.dart';

import '../edit_profile_screen.dart';
import '../devcard/devcard_screen.dart';
import '../settings/settings_screen.dart';
import '../network/follow_requests_screen.dart';
import '../admin/admin_dashboard_screen.dart' as techmates_superadmin;
import '../admin/regular_admin_dashboard_screen.dart' as techmates_admin;
import '../../utils/time_ago.dart';

// Brand Color Constants from reference
const _brandRed = Color(0xFFC62828);
const _brandRedLight = Color(0xFFE53935);
const _brandBlue = Color(0xFF1565C0);
const _brandRedContainer = Color(0xFFFFEBEE);
const _brandBlueContainer = Color(0xFFE3F2FD);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Data State
  UserProfile? _profile;
  DevCardModel? _devCard;
  int _followerCount = 0;
  int _followingCount = 0;
  int _savedOpsCount = 0;
  int _appliedCount = 0;
  int _totalOpsCount = 33; // Mocked for explore just like reference
  int _pendingRequests = 0;
  
  bool _isLoading = true;
  bool _hasError = false;

  // Animations
  late AnimationController _rankGlowController;

  @override
  void initState() {
    super.initState();
    _rankGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _rankGlowController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final userId = _authService.user?.id;
      if (userId == null) throw Exception("User not logged in");

      // We use Future.wait for parallel execution
      final results = await Future.wait([
        ProfileService().fetchProfile(userId),
        DevCardService.getOtherUserDevCard(userId),
        // Wait on bookmark service initialization if needed
        BookmarkService().init().then((_) => BookmarkService().getBookmarks()),
        StatusService().init().then((_) => StatusService().getItemsByStatus('applied')),
        _fetchFollowCounts(userId),
      ]);

      if (!mounted) return;
      
      setState(() {
        _profile = results[0] as UserProfile?;
        _devCard = results[1] as DevCardModel?;
        
        final bookmarks = results[2] as List;
        _savedOpsCount = bookmarks.length;
        
        final applied = results[3] as List;
        _appliedCount = applied.length;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Fetch follower network stats from DB
  Future<void> _fetchFollowCounts(String userId) async {
    try {
      final client = SupabaseClientManager.instance;
      
      // Follower Count
      final followerResponse = await client
          .from('follows')
          .select('id')
          .eq('following_id', userId)
          .eq('status', 'accepted')
          .count();
      
      // Following Count
      final followingResponse = await client
          .from('follows')
          .select('id')
          .eq('follower_id', userId)
          .eq('status', 'accepted')
          .count();
          
      // Pending requests (if user is private)
      final pendingResponse = await client
          .from('follows')
          .select('id')
          .eq('following_id', userId)
          .eq('status', 'pending')
          .count();

      _followerCount = followerResponse.count;
      _followingCount = followingResponse.count;
      _pendingRequests = pendingResponse.count;
    } catch (e) {
      debugPrint("Error fetching follow numbers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildShimmer();
    if (_hasError) return _buildError();
    if (_profile == null) return _buildError();

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: cs.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader(_profile!, cs)),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Developer Profile',
                child: _buildDevCard(cs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Strong At',
                child: _buildStrongAt(cs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Builds With',
                child: _buildBuildsWith(cs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Top Projects',
                child: _buildTopProjects(cs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Opportunity Journey',
                child: _buildJourneyRow(cs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Connect',
                child: _buildSocialRow(_profile!, cs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(
                label: 'Account',
                child: _buildAccountActions(cs),
              ),
            ),
            SliverToBoxAdapter(child: _buildLogoutButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HERO HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeroHeader(UserProfile profile, ColorScheme cs) {
    return Container(
      color: cs.surface,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background subtle gradients
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x12C52828), Colors.transparent],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x0F1565C0), Colors.transparent],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AVATAR AND EDIT ROW ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outlineVariant, width: 3),
                          gradient: profile.avatarUrl == null
                              ? const LinearGradient(
                                  colors: [_brandBlue, _brandRedLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: profile.avatarUrl != null &&
                                profile.avatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      _buildInitials(profile),
                                ),
                              )
                            : _buildInitials(profile),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _brandBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EditProfileScreen(),
                        ),
                      );
                      _loadData(); // Re-load on back
                    },
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      textStyle: GoogleFonts.sora(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(color: cs.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── NAME AND INFO ──
              Text(
                profile.name ?? 'New User',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 5),

              if (profile.branch != null || profile.year != null)
                Text(
                  '${profile.branch ?? ''}  ·  ${profile.year ?? ''}',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              const SizedBox(height: 3),

              if (profile.college != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        profile.college!,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (profile.collegeVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _brandBlueContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 11,
                              color: _brandBlue,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Member since ${_formatJoinDate(profile.createdAt)}',
                    style: GoogleFonts.sora(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── STATS STRIP ──
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _StatItem(
                      value: _followerCount.toString(),
                      label: 'Followers',
                      cs: cs,
                      onTap: () {
                        // TODO: Navigate to Network / Connections Screen
                      },
                    ),
                    _VerticalDivider(cs: cs),
                    _StatItem(
                      value: _followingCount.toString(),
                      label: 'Following',
                      cs: cs,
                      onTap: () {},
                    ),
                    _VerticalDivider(cs: cs),
                    _StatItem(
                      value: _totalOpsCount.toString(),
                      label: 'Explored',
                      cs: cs,
                    ),
                    _VerticalDivider(cs: cs),
                    _StatItem(
                      value: _appliedCount.toString(),
                      label: 'Applied',
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(UserProfile profile) {
    String initials = "U";
    if (profile.name != null && profile.name!.isNotEmpty) {
      final parts = profile.name!.trim().split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = parts[0][0] + parts[1][0];
      } else {
        initials = parts[0][0];
      }
    }
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFamily: GoogleFonts.sora().fontFamily,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION WRAPPER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String label,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: cs.outlineVariant,
                  thickness: 1,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEV CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDevCard(ColorScheme cs) {
    if (_devCard == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(Icons.code_rounded, size: 36, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Generate your DevCard to see developer stats',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DevCardScreen()),
                );
              },
              child: const Text('Generate DevCard'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _rankGlowController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD32F2F).withOpacity(
                                0.25 + _rankGlowController.value * 0.3,
                              ),
                              blurRadius: 8 + _rankGlowController.value * 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _devCard!.scoreBreakdown.rank,
                              style: GoogleFonts.sora(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_devCard!.scoreBreakdown.total} pts',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DevCardScreen()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Full DevCard',
                      style: GoogleFonts.sora(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                _DevMetric(
                  val: _devCard!.totalCommitsLastYear.toString(),
                  label: 'Commits',
                  cs: cs,
                ),
                VerticalDivider(color: cs.outlineVariant),
                _DevMetric(
                  val: _devCard!.totalPublicRepos.toString(),
                  label: 'Repos',
                  cs: cs,
                ),
                VerticalDivider(color: cs.outlineVariant),
                _DevMetric(
                  val: _devCard!.longestStreak.toString(),
                  label: 'Streak Days',
                  cs: cs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STRONG AT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStrongAt(ColorScheme cs) {
    if (_devCard == null || _devCard!.topLanguages.isEmpty) {
      return _buildEmptySection(cs, 'No language data available');
    }

    // Sort by percentage just to be sure and grab top 5
    final langs = List<LanguageStat>.from(_devCard!.topLanguages)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final top5 = langs.take(5).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...top5.map((lang) {
            final color = _parseHexColor(lang.color);
            final pct = (lang.percentage * 100).toStringAsFixed(0);
            final count = _languageProjectCount(lang.name, lang.projectCount);
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      lang.name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: lang.percentage.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$count projects',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                      fontFamily: 'monospace',
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

  int _languageProjectCount(String langName, int fallback) {
    final devCard = _devCard;
    if (devCard == null || devCard.projects.isEmpty) {
      return fallback;
    }
    return devCard.projects
        .where((p) =>
            p.primaryLanguage?.toLowerCase() == langName.toLowerCase())
        .length;
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILDS WITH
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBuildsWith(ColorScheme cs) {
    if (_devCard == null || _devCard!.topFrameworks.isEmpty) {
      return _buildEmptySection(cs, 'No framework data available');
    }

    final frameworks = _devCard!.topFrameworks.map((e) => e.name).take(10);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: frameworks.map((tech) {
        return InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _techColor(tech, cs),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tech,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP PROJECTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopProjects(ColorScheme cs) {
    if (_devCard == null || _devCard!.projects.isEmpty) {
      return _buildEmptySection(cs, 'No popular projects available');
    }

    final projectsList = List<ProjectAnalysis>.from(_devCard!.projects)
      ..sort((a, b) => b.stars.compareTo(a.stars));
    final topProjects = projectsList.take(3).toList();

    return Column(
      children: topProjects.map((project) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (project.url.isNotEmpty) {
                launchUrl(Uri.parse(project.url));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _projectEmoji(project.name),
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (project.primaryLanguage != null) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _langColor(
                                    project.primaryLanguage!,
                                    cs,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                project.primaryLanguage!,
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFFE65100), // Amber Accent
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${project.stars}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: cs.outline,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OPPORTUNITY JOURNEY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildJourneyRow(ColorScheme cs) {
    return Row(
      children: [
        _JourneyCard(
          icon: Icons.explore_rounded,
          iconBg: _brandBlueContainer,
          iconColor: _brandBlue,
          value: _totalOpsCount.toString(),
          label: 'Explored',
          cs: cs,
        ),
        const SizedBox(width: 8),
        _JourneyCard(
          icon: Icons.bookmark_rounded,
          iconBg: _brandRedContainer,
          iconColor: _brandRed,
          value: _savedOpsCount.toString(),
          label: 'Saved',
          cs: cs,
        ),
        const SizedBox(width: 8),
        _JourneyCard(
          icon: Icons.send_rounded,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          value: _appliedCount.toString(),
          label: 'Applied',
          cs: cs,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SOCIAL LINKS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSocialRow(UserProfile profile, ColorScheme cs) {
    return Row(
      children: [
        if (profile.githubUrl != null && profile.githubUrl!.isNotEmpty)
          _SocialBtn(
            label: 'GitHub',
            icon: Icons.code_rounded,
            url: profile.githubUrl!,
            cs: cs,
          ),
        if (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty) ...[
          if (profile.githubUrl != null && profile.githubUrl!.isNotEmpty)
            const SizedBox(width: 8),
          _SocialBtn(
            label: 'LinkedIn',
            icon: Icons.work_outline_rounded,
            url: profile.linkedinUrl!,
            cs: cs,
          ),
        ],
        if (profile.instagramUrl != null && profile.instagramUrl!.isNotEmpty) ...[
          if ((profile.githubUrl != null && profile.githubUrl!.isNotEmpty) ||
              (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty))
            const SizedBox(width: 8),
          _SocialBtn(
            label: 'Instagram',
            icon: Icons.photo_camera_outlined,
            url: profile.instagramUrl!,
            cs: cs,
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACCOUNT ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAccountActions(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _ActionItem(
            iconBg: _brandBlueContainer,
            icon: Icons.person_add_rounded,
            iconColor: _brandBlue,
            title: 'Follow Requests',
            subtitle: _pendingRequests > 0
                ? '$_pendingRequests pending requests'
                : 'No pending requests',
            trailing: _pendingRequests > 0
                ? Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _brandRedLight,
                      shape: BoxShape.circle,
                    ),
                  )
                : Icon(Icons.chevron_right_rounded, color: cs.outline),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FollowRequestsScreen()),
              );
            },
            cs: cs,
          ),
          Divider(height: 1, indent: 56, color: cs.outlineVariant),
          
          _ActionItem(
            iconBg: cs.surfaceContainerHigh,
            icon: Icons.notifications_rounded,
            iconColor: cs.onSurfaceVariant,
            title: 'Notifications',
            subtitle: 'All alerts enabled',
            trailing: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _brandRedLight,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () {
              // TODO Navigate to Notifications
            },
            cs: cs,
          ),
          Divider(height: 1, indent: 56, color: cs.outlineVariant),
          
          _ActionItem(
            iconBg: cs.surfaceContainerHigh,
            icon: Icons.settings_rounded,
            iconColor: cs.onSurfaceVariant,
            title: 'Settings',
            subtitle: 'Privacy, account, preferences',
            trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            cs: cs,
          ),
          
          if (UserRoleService().role == 'admin' || UserRoleService().role == 'super_admin') ...[
            Divider(height: 1, indent: 56, color: cs.outlineVariant),
            _ActionItem(
              iconBg: const Color(0xFFFFF3E0),
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFFEF6C00),
              title: 'Admin Dashboard',
              subtitle: 'Manage app data & users',
              trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
              onTap: () {
                if (UserRoleService().role == 'super_admin') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const techmates_superadmin.AdminDashboardScreen()),
                  );
                } else if (UserRoleService().role == 'admin') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const techmates_admin.RegularAdminDashboardScreen()),
                  );
                }
              },
              cs: cs,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        onTap: _handleLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _brandRedContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: _brandRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Log out',
                style: GoogleFonts.sora(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _brandRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Log out?',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will be signed out of Techmates.',
          style: GoogleFonts.sora(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _brandRedLight),
            child: Text(
              'Log out',
              style: GoogleFonts.sora(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not log out. Please try again.',
            style: GoogleFonts.sora(),
          ),
        ),
      );
      debugPrint('Profile logout failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOADING AND ERROR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShimmer() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(height: 200, color: cs.surfaceContainerLow),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Could not load profile',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// UI COMPONENTS
// ═══════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _StatItem({
    required this.value,
    required this.label,
    required this.cs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final ColorScheme cs;
  const _VerticalDivider({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: cs.outlineVariant,
    );
  }
}

class _DevMetric extends StatelessWidget {
  final String val;
  final String label;
  final ColorScheme cs;

  const _DevMetric({
    required this.val,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final ColorScheme cs;

  const _JourneyCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url;
  final ColorScheme cs;

  const _SocialBtn({
    required this.label,
    required this.icon,
    required this.url,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: cs.onSurface),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _ActionItem({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// UTILS
// ═══════════════════════════════════════════════════════════════

Widget _buildEmptySection(ColorScheme cs, String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant),
    ),
    child: Text(
      message,
      style: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

Color _parseHexColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  try {
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return const Color(0xFF8B8B8B);
  }
}

Color _langColor(String lang, ColorScheme cs) {
  switch (lang.toLowerCase()) {
    case 'typescript': return const Color(0xFF3178C6);
    case 'dart': return const Color(0xFF00B4AB);
    case 'javascript': return const Color(0xFFD4A017);
    case 'python': return const Color(0xFF3572A5);
    case 'c++':
    case 'cpp': return const Color(0xFFF34B7D);
    case 'java': return const Color(0xFFB07219);
    case 'kotlin': return const Color(0xFF7F52FF);
    case 'swift': return const Color(0xFFF05138);
    case 'go': return const Color(0xFF00ADD8);
    case 'rust': return const Color(0xFFDEA584);
    default: return cs.primary;
  }
}

Color _techColor(String tech, ColorScheme cs) {
  switch (tech.toLowerCase()) {
    case 'flutter': return const Color(0xFF00B4AB);
    case 'react': return const Color(0xFF61DAFB);
    case 'node.js':
    case 'nodejs': return const Color(0xFF68A063);
    case 'supabase': return const Color(0xFF3ECF8E);
    case 'firebase': return const Color(0xFFFFCA28);
    case 'typescript': return const Color(0xFF3178C6);
    case 'git': return const Color(0xFFF05032);
    default: return cs.primary;
  }
}

String _formatJoinDate(DateTime? dt) {
  if (dt == null) return 'Recently';
  const months = ['January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'];
  return '${months[dt.month - 1]} ${dt.year}';
}

String _projectEmoji(String repoName) {
  final name = repoName.toLowerCase();
  if (name.contains('app') || name.contains('flutter')) return '📱';
  if (name.contains('web') || name.contains('site') || name.contains('portfolio')) return '🌐';
  if (name.contains('api') || name.contains('server') || name.contains('backend')) return '⚙️';
  if (name.contains('ml') || name.contains('ai') || name.contains('bot')) return '🤖';
  if (name.contains('game')) return '🎮';
  return '📦';
}
