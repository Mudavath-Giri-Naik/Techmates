import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/user_role_service.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  // Data
  String _name = '';
  String _roleLabel = 'STUDENT';
  String _roleKey = 'student';
  String _monogram = 'T';
  String? _avatarUrl;
  bool _hasAvatar = false;
  bool _dataLoaded = false;

  // Animations
  late final AnimationController _revealController;
  late final AnimationController _celebrationController;
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  static const Color _ink = Color(0xFF101114);
  static const Color _muted = Color(0xFF69707D);
  static const Color _blue = Color(0xFF1E40AF);
  static const Color _red = Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _headerFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _revealController, curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic)),
    );
    _contentFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.28, 0.92, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
      CurvedAnimation(parent: _revealController, curve: const Interval(0.25, 0.95, curve: Curves.easeOutCubic)),
    );
  }

  Future<void> _loadUserData() async {
    final auth = AuthService();
    final user = auth.user;
    if (user == null) {
      _navigateToHome();
      return;
    }

    await UserRoleService().fetchAndCacheRole(user.id);

    String name = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '';
    if (name.isEmpty) {
      final profile = await ProfileService().fetchProfile(user.id);
      if (profile != null && profile.name != null && profile.name!.isNotEmpty) {
        name = profile.name!;
      }
    }
    if (name.isEmpty && user.email != null) {
      name = user.email!.split('@')[0];
    }
    if (name.isEmpty) {
      name = 'Techmate';
    }

    String? avatarUrl = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final profile = await ProfileService().fetchProfile(user.id);
      if (profile != null && profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        avatarUrl = profile.avatarUrl;
      }
    }

    final roleService = UserRoleService();
    final role = roleService.isSuperAdmin
        ? 'super_admin'
        : (roleService.isAdmin ? 'admin' : 'student');

    if (!mounted) return;
    setState(() {
      _name = name;
      _monogram = name.isNotEmpty ? name[0].toUpperCase() : 'T';
      _avatarUrl = avatarUrl;
      _hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
      _roleKey = role;
      _roleLabel = role == 'super_admin'
          ? 'SUPER ADMIN'
          : (role == 'admin' ? 'ADMIN' : 'STUDENT');
      _dataLoaded = true;
    });

    _revealController.forward();
    _celebrationController.forward();
  }

  _RoleCopy get _copy {
    switch (_roleKey) {
      case 'super_admin':
        return const _RoleCopy(
          kicker: 'SYSTEM COMMAND CENTER',
          headlineA: 'You Don\'t Enter',
          headlineB: 'You Launch',
          headlineC: 'Control Rooms',
          oneLiner: 'Today\'s mood: keep servers happy, logs honest, and chaos unemployed.',
          bulletA: 'Own user roles, access, and trust boundaries.',
          bulletB: 'Steer moderation with fewer clicks, better calls.',
          bulletC: 'Turn platform noise into sharp decisions.',
          actionLabel: 'Arm Console',
          actionSubline: 'Boot into full-control mode',
        );
      case 'admin':
        return const _RoleCopy(
          kicker: 'CURATION MODE',
          headlineA: 'Chief of',
          headlineB: 'Clean Feeds',
          headlineC: 'and Fast Wins',
          oneLiner: 'Your superpower: spotting bad posts before they spot students.',
          bulletA: 'Review and publish opportunities that actually matter.',
          bulletB: 'Keep quality high without becoming a robot.',
          bulletC: 'Ship clarity to every scrolling student.',
          actionLabel: 'Open Dashboard',
          actionSubline: 'Queue looks better with you in it',
        );
      default:
        return const _RoleCopy(
          kicker: 'HUNT MODE: ON',
          headlineA: 'You Bring',
          headlineB: 'Ambition.',
          headlineC: 'We Bring Targets.',
          oneLiner: 'No more 37 tabs. No more mystery deadlines. Just clean hits.',
          bulletA: 'Search internships and events without scavenger hunts.',
          bulletB: 'Track applies, later-list, and deadline pressure.',
          bulletC: 'Get back to building your actual future.',
          actionLabel: 'Drop In',
          actionSubline: 'Find your next unfair advantage',
        );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    _celebrationController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _revealController,
          _celebrationController,
          _orbitController,
          _pulseController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              if (_dataLoaded)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _OrbitGlyphPainter(
                        orbit: _orbitController.value,
                        burst: _celebrationController.value,
                        roleKey: _roleKey,
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: _dataLoaded ? _buildContent() : _buildLoading(),
              ),
              if (_dataLoaded)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CelebrationPainter(progress: _celebrationController.value),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: _buildTopIdentity(),
            ),
          ),
          const SizedBox(height: 28),
          SlideTransition(
            position: _contentSlide,
            child: FadeTransition(
              opacity: _contentFade,
              child: _buildRoleNarrative(),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildTopIdentity() {
    final pulse = 1.0 + (_pulseController.value * 0.06);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.scale(
          scale: pulse,
          child: _buildAvatar(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey $_name',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _roleLabel,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleNarrative() {
    final copy = _copy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.kicker,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        const SizedBox(height: 10),
        _buildAnimatedHeadline(copy),
        const SizedBox(height: 16),
        Text(
          copy.oneLiner,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            height: 1.5,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        _buildBullet(copy.bulletA, 0.47),
        _buildBullet(copy.bulletB, 0.58),
        _buildBullet(copy.bulletC, 0.69),
        const SizedBox(height: 38),
        _buildAction(copy),
      ],
    );
  }

  Widget _buildAnimatedHeadline(_RoleCopy copy) {
    final t = _orbitController.value * math.pi * 2;
    final wiggleA = math.sin(t) * 4;
    final wiggleB = math.sin(t + 1.4) * 5;
    final wiggleC = math.sin(t + 2.2) * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: Offset(wiggleA, 0),
          child: Text(
            copy.headlineA,
            style: GoogleFonts.bebasNeue(
              fontSize: 56,
              letterSpacing: 1.8,
              color: _ink,
              height: 0.95,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(wiggleB, 0),
          child: Text(
            copy.headlineB,
            style: GoogleFonts.bebasNeue(
              fontSize: 56,
              letterSpacing: 1.8,
              color: _blue,
              height: 0.95,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(wiggleC, 0),
          child: Text(
            copy.headlineC,
            style: GoogleFonts.bebasNeue(
              fontSize: 56,
              letterSpacing: 1.8,
              color: _red,
              height: 0.95,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text, double start) {
    final opacity = _segmentValue(_revealController.value, start, start + 0.2);
    final shift = (1 - opacity) * 24;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(shift, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '>',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(_RoleCopy copy) {
    final pulse = 1 + (_pulseController.value * 0.04);
    final border = Color.lerp(_ink, _blue, _pulseController.value) ?? _ink;
    return Transform.scale(
      scale: pulse,
      child: OutlinedButton(
        onPressed: _navigateToHome,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          side: BorderSide(color: border, width: 1.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    copy.actionLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    copy.actionSubline,
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: (_orbitController.value * 2 * math.pi) * 0.07,
              child: const Icon(Icons.arrow_forward_rounded, color: _ink, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const size = 62.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _AvatarRingPainter(
              orbit: _orbitController.value,
              burst: _celebrationController.value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(7),
            child: ClipOval(
              child: _hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: _avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _monogramWidget(),
                      errorWidget: (_, _, _) => _monogramWidget(),
                    )
                  : _monogramWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monogramWidget() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _ink.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        _monogram,
        style: GoogleFonts.bebasNeue(
          fontSize: 30,
          color: _ink,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  double _segmentValue(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    final v = (t - start) / (end - start);
    return Curves.easeOutCubic.transform(v);
  }
}

class _RoleCopy {
  const _RoleCopy({
    required this.kicker,
    required this.headlineA,
    required this.headlineB,
    required this.headlineC,
    required this.oneLiner,
    required this.bulletA,
    required this.bulletB,
    required this.bulletC,
    required this.actionLabel,
    required this.actionSubline,
  });

  final String kicker;
  final String headlineA;
  final String headlineB;
  final String headlineC;
  final String oneLiner;
  final String bulletA;
  final String bulletB;
  final String bulletC;
  final String actionLabel;
  final String actionSubline;
}

class _AvatarRingPainter extends CustomPainter {
  const _AvatarRingPainter({required this.orbit, required this.burst});

  final double orbit;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1.5;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF101114).withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, base);

    final sweep = lerpDouble(1.4, 5.6, burst.clamp(0, 1))!;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E40AF).withValues(alpha: 0.65);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (orbit * 2 * math.pi),
      sweep / 8,
      false,
      arc,
    );

    final arc2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB91C1C).withValues(alpha: 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (orbit * -2.2 * math.pi) + 1.3,
      sweep / 7,
      false,
      arc2,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter oldDelegate) {
    return oldDelegate.orbit != orbit || oldDelegate.burst != burst;
  }
}

class _OrbitGlyphPainter extends CustomPainter {
  const _OrbitGlyphPainter({
    required this.orbit,
    required this.burst,
    required this.roleKey,
  });

  final double orbit;
  final double burst;
  final String roleKey;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF101114).withValues(alpha: 0.06);
    canvas.drawCircle(center, math.min(size.width, size.height) * 0.36, ringPaint);
    canvas.drawCircle(center, math.min(size.width, size.height) * 0.24, ringPaint);

    final tokens = roleKey == 'super_admin'
        ? ['ROOT', 'LOG', 'AUTH', 'OPS']
        : (roleKey == 'admin' ? ['MOD', 'REVIEW', 'POST', 'SYNC'] : ['SKILL', 'APPLY', 'WIN', 'BUILD']);

    for (int i = 0; i < tokens.length; i++) {
      final angle = (orbit * 2 * math.pi) + (i * math.pi / 2.0);
      final radius = math.min(size.width, size.height) * (0.27 + (i * 0.02));
      final pos = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: tokens[i],
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            color: const Color(0xFF69707D).withValues(alpha: 0.3 + (0.4 * burst)),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitGlyphPainter oldDelegate) {
    return oldDelegate.orbit != orbit ||
        oldDelegate.burst != burst ||
        oldDelegate.roleKey != roleKey;
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final random = math.Random(17);
    final colors = [
      const Color(0xFF101114),
      const Color(0xFF1E40AF),
      const Color(0xFFB91C1C),
      const Color(0xFF69707D),
    ];

    for (int i = 0; i < 72; i++) {
      final lane = i % 3;
      final x = (size.width / 24) * (i % 24) + random.nextDouble() * 7;
      final startY = lane == 0 ? -16.0 : (lane == 1 ? size.height * 0.1 : size.height * 0.2);
      final endY = size.height + 24;
      final speed = 0.45 + (random.nextDouble() * 0.55);
      final p = (progress * speed).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;

      final y = startY + (endY - startY) * p;
      final sway = math.sin((progress * math.pi * 4) + i) * (4 + lane * 1.4);
      final alpha = (1 - p) * 0.9;

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate((i * 0.2) + (p * math.pi * 3));
      canvas.drawLine(const Offset(-4, 0), const Offset(4, 0), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
