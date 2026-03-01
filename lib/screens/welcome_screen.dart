import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/user_role_service.dart';
import '../utils/proxy_url.dart';
import 'main_screen.dart';

// ══════════════════════════════════════════════════════════════════════
//  WELCOME SCREEN — Role-Personalised Onboarding for Techmates
//  Student  → 2-page swipe flow (Hunt Mode → Unfair Edge)
//  Admin    → 1-page Curation Mode
//  SuperAdmin → 1-page Command Center
// ══════════════════════════════════════════════════════════════════════

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ── User Data ──────────────────────────────────────────────────────
  String _name = '';
  String _roleLabel = 'STUDENT';
  String _roleKey = 'student';
  String _monogram = 'T';
  String? _avatarUrl;
  bool _hasAvatar = false;
  bool _dataLoaded = false;

  // ── Page (student only) ───────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Animation Controllers ──────────────────────────────────────────
  late final AnimationController _revealCtrl;      // text reveals
  late final AnimationController _celebrationCtrl; // confetti burst
  late final AnimationController _orbitCtrl;       // constant rotation
  late final AnimationController _pulseCtrl;       // gentle breathe
  late final AnimationController _unlockCtrl;      // lock open anim
  late final AnimationController _diagramCtrl;     // diagram draw-in
  late final AnimationController _radarCtrl;       // radar sweep loop

  // ── Palette ────────────────────────────────────────────────────────
  static const Color _ink    = Color(0xFF0C0E12);
  static const Color _muted  = Color(0xFF6B7280);
  static const Color _blue   = Color(0xFF1D4ED8);
  static const Color _red    = Color(0xFFB91C1C);
  static const Color _amber  = Color(0xFFD97706);
  static const Color _green  = Color(0xFF065F46);

  // Backgrounds — very light, role-tinted
  static const Color _bgStudent    = Color(0xFFFAF9F7); // warm cream
  static const Color _bgAdmin      = Color(0xFFF0F5FF); // cool periwinkle
  static const Color _bgSuperAdmin = Color(0xFFF4F0FF); // subtle violet

  // ── Lifecycle ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _revealCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1900));
    _celebrationCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3200));
    _orbitCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 9000))..repeat();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _unlockCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100));
    _diagramCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2600));
    _radarCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3400))..repeat();
  }

  Future<void> _loadUserData() async {
    final auth = AuthService();
    final user = auth.user;
    if (user == null) { _goHome(); return; }

    await UserRoleService().fetchAndCacheRole(user.id);

    String name = user.userMetadata?['full_name']
        ?? user.userMetadata?['name'] ?? '';
    if (name.isEmpty) {
      final p = await ProfileService().fetchProfile(user.id);
      if (p?.name != null && p!.name!.isNotEmpty) name = p.name!;
    }
    if (name.isEmpty && user.email != null) {
      name = user.email!.split('@')[0];
    }
    if (name.isEmpty) name = 'Techmate';

    String? avatarUrl = proxyUrl(
        (user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture']) as String?);
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final p = await ProfileService().fetchProfile(user.id);
      if (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty) {
        avatarUrl = p.avatarUrl;
      }
    }

    final rs = UserRoleService();
    final role = rs.isSuperAdmin
        ? 'super_admin'
        : (rs.isAdmin ? 'admin' : 'student');

    if (!mounted) return;
    setState(() {
      _name      = name;
      _monogram  = name.isNotEmpty ? name[0].toUpperCase() : 'T';
      _avatarUrl = avatarUrl;
      _hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
      _roleKey   = role;
      _roleLabel = role == 'super_admin'
          ? 'SUPER ADMIN'
          : (role == 'admin' ? 'ADMIN' : 'STUDENT');
      _dataLoaded = true;
    });

    _revealCtrl.forward();
    _celebrationCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _unlockCtrl.forward();
        _diagramCtrl.forward();
      }
    });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 540),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _revealCtrl.dispose();
    _celebrationCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _unlockCtrl.dispose();
    _diagramCtrl.dispose();
    _radarCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg = _roleKey == 'super_admin'
        ? _bgSuperAdmin
        : (_roleKey == 'admin' ? _bgAdmin : _bgStudent);

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _revealCtrl, _celebrationCtrl, _orbitCtrl,
          _pulseCtrl, _unlockCtrl, _diagramCtrl, _radarCtrl,
        ]),
        builder: (ctx, _) => Stack(children: [
          if (_dataLoaded) _buildRoleScreen(),
          if (!_dataLoaded)
            const Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Celebration overlay
          if (_dataLoaded)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CelebrationPainter(
                    progress: _celebrationCtrl.value,
                    roleKey: _roleKey,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildRoleScreen() {
    switch (_roleKey) {
      case 'super_admin': return _buildSuperAdminScreen();
      case 'admin':       return _buildAdminScreen();
      default:            return _buildStudentFlow();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  STUDENT FLOW — 2 pages
  // ══════════════════════════════════════════════════════════════════

  Widget _buildStudentFlow() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (i) => setState(() => _currentPage = i),
      children: [_studentPage1(), _studentPage2()],
    );
  }

  // ── Student Page 1 ─────────────────────────────────────────────────
  Widget _studentPage1() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _identityRow(),
          const SizedBox(height: 22),
          _s1Kicker(),
          const SizedBox(height: 10),
          _s1Headlines(),
          const SizedBox(height: 12),
          _s1SubText(),
          const SizedBox(height: 22),
          _s1OpportunityMap(),   // THE STAR DIAGRAM
          const SizedBox(height: 24),
          _s1CTA(),
          const SizedBox(height: 10),
          _dots(0, 2),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _s1Kicker() => _fadeIn(0.0, 0.28,
    Text('HUNT MODE: ON',
      style: GoogleFonts.ibmPlexMono(
        fontSize: 11, letterSpacing: 2.4,
        fontWeight: FontWeight.w600, color: _muted,
      )),
  );

  Widget _s1Headlines() => _fadeIn(0.04, 0.38,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('You Bring',    style: _bb(54, _ink)),
      Text('Ambition.',    style: _bb(54, _blue)),
      Text('We Bring Targets.', style: _bb(54, _red)),
    ]),
  );

  Widget _s1SubText() => _fadeIn(0.18, 0.52,
    Text(
      'No more 37 tabs. No mystery deadlines. Just curated hits — filtered, tracked, and delivered straight to you.',
      style: GoogleFonts.dmSans(
        fontSize: 15, height: 1.6, color: _muted,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _s1OpportunityMap() {
    final dp = _diagramCtrl.value;
    final orbit = _orbitCtrl.value;
    final pulse = _pulseCtrl.value;
    return SizedBox(
      height: 310,
      child: Stack(children: [
        // The main painter
        Positioned.fill(
          child: CustomPaint(
            painter: _OpportunityMapPainter(
              progress: dp,
              orbit: orbit,
              pulse: pulse,
            ),
          ),
        ),
        // LEFT side labels (mirroring plant health diagram)
        _mapLabel('INTERNSHIPS',    Alignment(-0.96, -0.72), dp, 0.08),
        _mapLabel('HACKATHONS',     Alignment(-0.96, -0.08), dp, 0.18),
        _mapLabel('EVENTS &\nMEETUPS', Alignment(-0.96,  0.55), dp, 0.28),
        // RIGHT side labels
        _mapLabel('DEADLINE\nALERTS',  Alignment(0.82, -0.65), dp, 0.38),
        _mapLabel('SMART\nFILTERS',    Alignment(0.82,  0.04), dp, 0.48),
        _mapLabel('YOUR\nPROFILE',     Alignment(0.82,  0.72), dp, 0.58),
        // Center label
        Align(
          alignment: Alignment.center,
          child: Opacity(
            opacity: _seg(dp, 0.65, 0.85),
            child: Text('TM',
              style: GoogleFonts.bebasNeue(
                fontSize: 20, color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _mapLabel(String text, Alignment align, double p, double start) {
    final opacity = _seg(p, start, start + 0.22);
    return Align(
      alignment: align,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset((1 - opacity) * (align.x < 0 ? -16 : 16), 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: align.x < 0
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(text,
                textAlign: align.x < 0 ? TextAlign.left : TextAlign.right,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9.5, fontWeight: FontWeight.w700,
                  color: _ink, letterSpacing: 1.3, height: 1.5,
                ),
              ),
              Container(
                height: 1.5,
                width: 30,
                color: _ink.withOpacity(0.35),
                margin: const EdgeInsets.only(top: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _s1CTA() {
    final pulse = 1 + (_pulseCtrl.value * 0.03);
    final borderColor = Color.lerp(_ink, _blue, _pulseCtrl.value) ?? _ink;
    return _fadeIn(0.70, 1.0,
      Transform.scale(
        scale: pulse,
        child: OutlinedButton(
          onPressed: _nextPage,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            side: BorderSide(color: borderColor, width: 1.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white.withOpacity(0.55),
          ),
          child: Row(children: [
            // Animated unlock icon
            SizedBox(width: 36, height: 36,
              child: CustomPaint(
                painter: _UnlockIconPainter(
                  progress: _unlockCtrl.value,
                  color: _blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See What\'s Waiting',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _ink,
                    )),
                  const SizedBox(height: 2),
                  Text('Your opportunities, fully decoded',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: _muted, fontWeight: FontWeight.w500,
                    )),
                ],
              ),
            ),
            Transform.rotate(
              angle: _orbitCtrl.value * 2 * math.pi * 0.08,
              child: const Icon(Icons.arrow_forward_rounded,
                  color: _ink, size: 22),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Student Page 2 ─────────────────────────────────────────────────
  Widget _studentPage2() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _identityRow(),
          const SizedBox(height: 22),
          _fadeIn(0.0, 0.3,
            Text('YOUR UNFAIR EDGE',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, letterSpacing: 2.4,
                fontWeight: FontWeight.w600, color: _muted,
              )),
          ),
          const SizedBox(height: 10),
          _fadeIn(0.05, 0.38, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('One Feed.',   style: _bb(54, _ink)),
              Text('Zero Noise.', style: _bb(54, _blue)),
              Text('All Yours.',  style: _bb(54, _red)),
            ],
          )),
          const SizedBox(height: 12),
          _fadeIn(0.2, 0.5,
            Text(
              'Built for students who are serious about their careers — and seriously tired of searching for opportunities.',
              style: GoogleFonts.dmSans(
                fontSize: 15, height: 1.6, color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 26),
          _featureGrid(),
          const SizedBox(height: 28),
          _dropInCTA(),
          const SizedBox(height: 10),
          _dots(1, 2),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _featureGrid() {
    final items = [
      _FItem('🎯', 'Smart Feed',
          'Internships, hackathons, events.\nAll curated, zero clutter.',
          '500+\nOpportunities', _blue),
      _FItem('⏰', 'Never Miss',
          'Deadline alerts that actually\narrive before it\'s too late.',
          'Zero\nMissed Deals', _red),
      _FItem('📊', 'Track It All',
          'Applied → Interviewing →\nAccepted. All in one view.',
          '100%\nVisibility', _green),
      _FItem('🏆', 'Build Cred',
          'One link. All your wins,\nskills, and achievements.',
          '1 Link.\nAll You.', _amber),
    ];
    return Column(children: [
      Row(children: [
        Expanded(child: _featureCard(items[0])),
        const SizedBox(width: 12),
        Expanded(child: _featureCard(items[1])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _featureCard(items[2])),
        const SizedBox(width: 12),
        Expanded(child: _featureCard(items[3])),
      ]),
    ]);
  }

  Widget _featureCard(_FItem item) {
    return _fadeIn(0.35, 0.75,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink.withOpacity(0.07), width: 1),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Text(item.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w700, color: _ink,
            )),
          const SizedBox(height: 5),
          Text(item.desc,
            style: GoogleFonts.dmSans(
              fontSize: 11.5, color: _muted, height: 1.45,
            )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(item.stat,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: item.accentColor, height: 1.3,
              )),
          ),
        ]),
      ),
    );
  }

  Widget _dropInCTA() {
    final pulse = 1 + (_pulseCtrl.value * 0.03);
    final borderColor = Color.lerp(_ink, _blue, _pulseCtrl.value) ?? _ink;
    return _fadeIn(0.75, 1.0,
      Transform.scale(
        scale: pulse,
        child: OutlinedButton(
          onPressed: _goHome,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            side: BorderSide(color: borderColor, width: 1.8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white.withOpacity(0.55),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Drop In',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _ink,
                    )),
                  const SizedBox(height: 2),
                  Text('Find your next unfair advantage',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: _muted,
                      fontWeight: FontWeight.w500,
                    )),
                ],
              ),
            ),
            Transform.rotate(
              angle: _orbitCtrl.value * 2 * math.pi * 0.08,
              child: const Icon(Icons.arrow_forward_rounded,
                  color: _ink, size: 22),
            ),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  ADMIN SCREEN — Curation Mode
  // ══════════════════════════════════════════════════════════════════

  Widget _buildAdminScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _identityRow(),
          const SizedBox(height: 22),
          _fadeIn(0.0, 0.28,
            Text('CURATION MODE',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, letterSpacing: 2.4,
                fontWeight: FontWeight.w600, color: _muted,
              )),
          ),
          const SizedBox(height: 10),
          _fadeIn(0.04, 0.38,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Chief of',     style: _bb(54, _ink)),
              Text('Clean Feeds', style: _bb(54, _blue)),
              Text('& Fast Wins.', style: _bb(54, _red)),
            ]),
          ),
          const SizedBox(height: 12),
          _fadeIn(0.18, 0.52,
            Text(
              'Your superpower: spotting bad posts before they reach students. Quality is your language. Clarity is your mission.',
              style: GoogleFonts.dmSans(
                fontSize: 15, height: 1.6, color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _adminPipelineDiagram(),
          const SizedBox(height: 26),
          _bullet('Review and publish opportunities that actually matter.', 0.55),
          _bullet('Moderate with precision — keep quality high, not robotic.', 0.65),
          _bullet('Every approval ships clarity to a scrolling student.', 0.75),
          const SizedBox(height: 28),
          _adminCTA(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _adminPipelineDiagram() {
    final dp = _diagramCtrl.value;
    return SizedBox(
      height: 280,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _AdminFlowPainter(
              progress: dp,
              orbit: _orbitCtrl.value,
              pulse: _pulseCtrl.value,
            ),
          ),
        ),
        // Left-side stage labels
        _pipeLabel('DRAFT\nSUBMITTED',  Alignment(-0.94, -0.68), dp, 0.08, _muted),
        _pipeLabel('ADMIN\nREVIEW',      Alignment(-0.94,  0.00), dp, 0.20, _blue),
        _pipeLabel('QUALITY\nCHECK',    Alignment(-0.94,  0.68), dp, 0.32, _ink),
        // Right-side stage labels
        _pipeLabel('APPROVED\n→ LIVE',   Alignment(0.84, -0.68), dp, 0.44, _green),
        _pipeLabel('STUDENTS\nNOTIFIED', Alignment(0.84,  0.00), dp, 0.56, _blue),
        _pipeLabel('IMPACT\nLOGGED',     Alignment(0.84,  0.68), dp, 0.66, _amber),
      ]),
    );
  }

  Widget _pipeLabel(String text, Alignment align, double p,
      double start, Color color) {
    final opacity = _seg(p, start, start + 0.22);
    return Align(
      alignment: align,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align.x < 0
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(text,
              textAlign: align.x < 0 ? TextAlign.left : TextAlign.right,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: color, letterSpacing: 1.0, height: 1.5,
              ),
            ),
            Container(
              height: 1.5, width: 28,
              color: color.withOpacity(0.4),
              margin: const EdgeInsets.only(top: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCTA() {
    final pulse = 1 + (_pulseCtrl.value * 0.03);
    final borderColor = Color.lerp(_ink, _blue, _pulseCtrl.value) ?? _ink;
    return _fadeIn(0.75, 1.0,
      Transform.scale(
        scale: pulse,
        child: OutlinedButton(
          onPressed: _goHome,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            side: BorderSide(color: borderColor, width: 1.8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white.withOpacity(0.55),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _blue, borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dashboard_customize_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Open Dashboard',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _ink,
                    )),
                  const SizedBox(height: 2),
                  Text('Queue looks better with you in it',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: _muted,
                      fontWeight: FontWeight.w500,
                    )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: _ink, size: 22),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  SUPER ADMIN SCREEN — Command Center
  // ══════════════════════════════════════════════════════════════════

  Widget _buildSuperAdminScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _identityRow(),
          const SizedBox(height: 22),
          _fadeIn(0.0, 0.28,
            Text('SYSTEM COMMAND CENTER',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, letterSpacing: 2.4,
                fontWeight: FontWeight.w600, color: _muted,
              )),
          ),
          const SizedBox(height: 10),
          _fadeIn(0.04, 0.38,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('You Don\'t Enter.',    style: _bb(52, _ink)),
              Text('You Launch',          style: _bb(52, _blue)),
              Text('Control Rooms.',      style: _bb(52, _red)),
            ]),
          ),
          const SizedBox(height: 12),
          _fadeIn(0.18, 0.52,
            Text(
              'Today\'s mood: servers happy, logs honest, chaos permanently unemployed. You hold every key.',
              style: GoogleFonts.dmSans(
                fontSize: 15, height: 1.6, color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _superAdminHexDiagram(),
          const SizedBox(height: 26),
          _bullet('Own user roles, access boundaries, and trust levels.', 0.55),
          _bullet('Steer moderation with fewer clicks, sharper calls.', 0.65),
          _bullet('Turn platform noise into high-signal decisions.', 0.75),
          const SizedBox(height: 28),
          _superAdminCTA(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _superAdminHexDiagram() {
    final dp = _diagramCtrl.value;
    final radar = _radarCtrl.value;
    return SizedBox(
      height: 290,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CommandGridPainter(
              progress: dp,
              orbit: _orbitCtrl.value,
              pulse: _pulseCtrl.value,
              radar: radar,
            ),
          ),
        ),
        _hexLabel('ROOT\nACCESS',     Alignment(-0.90, -0.72), dp, 0.10),
        _hexLabel('USER\nROLES',      Alignment( 0.82, -0.68), dp, 0.20),
        _hexLabel('AUTH\nBOUNDARY',  Alignment(-0.90,  0.08), dp, 0.30),
        _hexLabel('CONTENT\nOPS',    Alignment( 0.82,  0.12), dp, 0.40),
        _hexLabel('SYSTEM\nLOGS',    Alignment(-0.72,  0.78), dp, 0.50),
        _hexLabel('TRUST\nCONFIG',   Alignment( 0.68,  0.80), dp, 0.60),
      ]),
    );
  }

  Widget _hexLabel(String text, Alignment align, double p, double start) {
    final opacity = _seg(p, start, start + 0.22);
    return Align(
      alignment: align,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align.x < 0
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(text,
              textAlign: align.x < 0 ? TextAlign.left : TextAlign.right,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: _ink, letterSpacing: 1.0, height: 1.5,
              ),
            ),
            Container(
              height: 1.5, width: 28,
              color: _ink.withOpacity(0.35),
              margin: const EdgeInsets.only(top: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _superAdminCTA() {
    final pulse = 1 + (_pulseCtrl.value * 0.03);
    final borderColor = Color.lerp(_ink, _red, _pulseCtrl.value) ?? _ink;
    return _fadeIn(0.75, 1.0,
      Transform.scale(
        scale: pulse,
        child: OutlinedButton(
          onPressed: _goHome,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            side: BorderSide(color: borderColor, width: 1.8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white.withOpacity(0.55),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _red, borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.terminal_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Arm Console',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _ink,
                    )),
                  const SizedBox(height: 2),
                  Text('Boot into full-control mode',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: _muted,
                      fontWeight: FontWeight.w500,
                    )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: _ink, size: 22),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════

  Widget _identityRow() {
    final revealOpacity = _seg(_revealCtrl.value, 0.0, 0.32);
    final slide = (1 - revealOpacity) * 20;
    final pulse = 1.0 + (_pulseCtrl.value * 0.05);
    return Opacity(
      opacity: revealOpacity,
      child: Transform.translate(
        offset: Offset(0, -slide),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Transform.scale(scale: pulse, child: _avatarWidget()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hey $_name',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26, fontWeight: FontWeight.w700,
                    color: _ink, height: 1.05,
                  )),
                const SizedBox(height: 3),
                Text(_roleLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12, letterSpacing: 2.2,
                    fontWeight: FontWeight.w600, color: _muted,
                  )),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _bullet(String text, double start) {
    final opacity = _seg(_revealCtrl.value, start, start + 0.2);
    final shift = (1 - opacity) * 22;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(shift, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('>',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 16, fontWeight: FontWeight.w700, color: _ink,
              )),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: _ink, height: 1.38,
                )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dots(int current, int total) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? _ink : _muted.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _avatarWidget() {
    const size = 62.0;
    return SizedBox(
      width: size, height: size,
      child: Stack(fit: StackFit.expand, children: [
        CustomPaint(
          painter: _AvatarRingPainter(
            orbit: _orbitCtrl.value,
            burst: _celebrationCtrl.value,
            roleKey: _roleKey,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(7),
          child: ClipOval(
            child: _hasAvatar
                ? CachedNetworkImage(
                    imageUrl: _avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _monogramWidget(),
                    errorWidget: (_, __, ___) => _monogramWidget(),
                  )
                : _monogramWidget(),
          ),
        ),
      ]),
    );
  }

  Widget _monogramWidget() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _ink.withOpacity(0.18), width: 1),
      ),
      child: Text(_monogram,
        style: GoogleFonts.bebasNeue(
          fontSize: 30, color: _ink, letterSpacing: 1.2,
        )),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  /// Fade + optional slide for a section, driven by _revealCtrl
  Widget _fadeIn(double start, double end, Widget child) {
    final opacity = _seg(_revealCtrl.value, start, end);
    final slide = (1 - opacity) * 18;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(offset: Offset(0, slide), child: child),
    );
  }

  TextStyle _bb(double size, Color color) => GoogleFonts.bebasNeue(
    fontSize: size, color: color, height: 0.95, letterSpacing: 1.8,
  );

  double _seg(double t, double s, double e) {
    if (t <= s) return 0;
    if (t >= e) return 1;
    return Curves.easeOutCubic.transform((t - s) / (e - s));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  DATA
// ══════════════════════════════════════════════════════════════════════

class _FItem {
  const _FItem(this.emoji, this.title, this.desc, this.stat, this.accentColor);
  final String emoji, title, desc, stat;
  final Color accentColor;
}

// ══════════════════════════════════════════════════════════════════════
//  PAINTER  ①  AVATAR RING
// ══════════════════════════════════════════════════════════════════════

class _AvatarRingPainter extends CustomPainter {
  const _AvatarRingPainter(
      {required this.orbit, required this.burst, required this.roleKey});
  final double orbit, burst;
  final String roleKey;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;

    canvas.drawCircle(
      c, r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF101114).withOpacity(0.15),
    );

    // Role-specific arc color
    final arcColor = roleKey == 'super_admin'
        ? const Color(0xFF7C3AED)
        : (roleKey == 'admin'
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF1D4ED8));

    final sweep = lerpDouble(1.2, 5.0, burst.clamp(0, 1))!;
    _drawArc(canvas, c, r, orbit * 2 * math.pi, sweep / 8,
        arcColor.withOpacity(0.7), 2.0);
    _drawArc(canvas, c, r, orbit * -2.3 * math.pi + 1.2, sweep / 7,
        const Color(0xFFB91C1C).withOpacity(0.55), 2.0);
  }

  void _drawArc(Canvas canvas, Offset c, double r,
      double start, double sweep, Color color, double width) {
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start, sweep, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter o) =>
      o.orbit != orbit || o.burst != burst;
}

// ══════════════════════════════════════════════════════════════════════
//  PAINTER  ②  STUDENT — OPPORTUNITY MAP
//  Inspired by "plant health" diagram: central illustration,
//  dashed circles on nodes, labels with underlines on sides.
// ══════════════════════════════════════════════════════════════════════

class _OpportunityMapPainter extends CustomPainter {
  const _OpportunityMapPainter(
      {required this.progress, required this.orbit, required this.pulse});
  final double progress, orbit, pulse;

  static const Color _ink   = Color(0xFF0C0E12);
  static const Color _blue  = Color(0xFF1D4ED8);
  static const Color _amber = Color(0xFFD97706);
  static const Color _muted = Color(0xFF6B7280);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.48);

    // ── Soft background blob ──────────────────────────────────────
    final blobPaint = Paint()
      ..color = _blue.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    final blob = Path();
    final br = size.shortestSide * 0.42;
    blob.addOval(Rect.fromCenter(
        center: center, width: br * 1.85, height: br * 1.6));
    canvas.drawPath(blob, blobPaint);

    // ── Concentric guide rings ─────────────────────────────────────
    _dashedCircle(canvas, center, br * 0.52,
        _muted.withOpacity(0.12), dashLen: 4, gapLen: 4, width: 1.0);
    _dashedCircle(canvas, center, br * 0.88,
        _muted.withOpacity(0.10), dashLen: 5, gapLen: 5, width: 1.0);

    // ── 6 orbit nodes ─────────────────────────────────────────────
    final baseAngle = orbit * math.pi * 0.18; // very slow drift
    final nodeAngles = [
      -math.pi * 0.75 + baseAngle,  // top-left   → INTERNSHIPS
       math.pi * 0.25 + baseAngle,  // right       → DEADLINES
      -math.pi * 0.25 + baseAngle,  // top-right   → HACKATHONS ... wait
    ];

    // 3 left, 3 right nodes
    final leftAngles = [
      -math.pi * 0.78 + baseAngle,
      -math.pi * 0.98 + baseAngle,
       math.pi * 0.82 + baseAngle,
    ];
    final rightAngles = [
      -math.pi * 0.22 + baseAngle,
       math.pi * 0.02 + baseAngle,
       math.pi * 0.22 + baseAngle,
    ];
    final radii = [br * 0.68, br * 0.78, br * 0.68,
                   br * 0.70, br * 0.80, br * 0.70];
    final allAngles = [...leftAngles, ...rightAngles];

    for (int i = 0; i < allAngles.length; i++) {
      final np = _segP(progress, i * 0.08, i * 0.08 + 0.28);
      if (np <= 0) continue;
      final pos = Offset(
        center.dx + math.cos(allAngles[i]) * radii[i],
        center.dy + math.sin(allAngles[i]) * radii[i],
      );

      // Connection line from center
      _drawDashedLine(canvas, center, pos, np,
          _ink.withOpacity(0.12), dashLen: 5, gapLen: 4, width: 1.0);

      // Dashed circle highlight (amber, like plant diagram)
      _dashedCircle(canvas, pos, 18,
          _amber.withOpacity(0.5 * np), dashLen: 3, gapLen: 3, width: 1.4);

      // Node dot
      canvas.drawCircle(
        pos, 7.5 * np,
        Paint()..color = _ink.withOpacity(0.12 + np * 0.08),
      );
      canvas.drawCircle(
        pos, 4.5 * np,
        Paint()..color = _ink.withOpacity(0.55),
      );
    }

    // ── Center hub ────────────────────────────────────────────────
    final cp = _segP(progress, 0.60, 0.80);
    if (cp > 0) {
      final pulsedR = 26.0 + pulse * 3;
      // Outer glow ring
      canvas.drawCircle(
        center, pulsedR + 6,
        Paint()
          ..color = _blue.withOpacity(0.08 * cp)
          ..style = PaintingStyle.fill,
      );
      // Hub circle
      canvas.drawCircle(
        center, pulsedR,
        Paint()..color = _ink.withOpacity(0.92 * cp),
      );
      // Thin border ring
      canvas.drawCircle(
        center, pulsedR + 2,
        Paint()
          ..color = _blue.withOpacity(0.5 * cp)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _dashedCircle(Canvas canvas, Offset center, double radius,
      Color color, {required double dashLen, required double gapLen,
      required double width}) {
    final circumference = 2 * math.pi * radius;
    final total = dashLen + gapLen;
    final count = (circumference / total).floor();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (int i = 0; i < count; i++) {
      final startAngle = (i * total / circumference) * 2 * math.pi;
      final sweepAngle = (dashLen / circumference) * 2 * math.pi;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to,
      double progress, Color color,
      {required double dashLen, required double gapLen, required double width}) {
    final total = (to - from).distance;
    final draw = total * progress;
    final dir = (to - from) / total;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    double traveled = 0;
    bool drawing = true;
    while (traveled < draw) {
      final seg = drawing ? dashLen : gapLen;
      final end = math.min(traveled + seg, draw);
      if (drawing) {
        canvas.drawLine(from + dir * traveled, from + dir * end, paint);
      }
      traveled += seg;
      drawing = !drawing;
    }
  }

  double _segP(double t, double s, double e) {
    if (t <= s) return 0;
    if (t >= e) return 1;
    return Curves.easeOutCubic.transform((t - s) / (e - s));
  }

  @override
  bool shouldRepaint(covariant _OpportunityMapPainter o) => true;
}

// ══════════════════════════════════════════════════════════════════════
//  PAINTER  ③  ADMIN — CONTENT FLOW PIPELINE
//  Vertical pipeline with animated data-flow dots
// ══════════════════════════════════════════════════════════════════════

class _AdminFlowPainter extends CustomPainter {
  const _AdminFlowPainter(
      {required this.progress, required this.orbit, required this.pulse});
  final double progress, orbit, pulse;

  static const Color _ink   = Color(0xFF0C0E12);
  static const Color _blue  = Color(0xFF1D4ED8);
  static const Color _green = Color(0xFF065F46);
  static const Color _muted = Color(0xFF6B7280);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final totalH = size.height;

    // ── Soft background blob ──────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, 0, size.width * 0.64, totalH),
        const Radius.circular(24),
      ),
      Paint()..color = _blue.withOpacity(0.04),
    );

    // ── 5 pipeline stages ─────────────────────────────────────────
    final stageH = totalH / 5.2;
    final stages = ['INPUT', 'REVIEW', 'APPROVE', 'PUBLISH', 'IMPACT'];
    final stageColors = [_muted, _blue, _blue, _green, _green];
    final stageY = List.generate(5, (i) => stageH * (i + 0.5));

    // Draw connecting lines first
    for (int i = 0; i < stages.length - 1; i++) {
      final lp = _segP(progress, i * 0.14, i * 0.14 + 0.25);
      if (lp <= 0) continue;
      canvas.drawLine(
        Offset(cx, stageY[i] + 16),
        Offset(cx, stageY[i] + (stageY[i + 1] - stageY[i] - 32) * lp + 16),
        Paint()
          ..color = _ink.withOpacity(0.12)
          ..strokeWidth = 2,
      );
    }

    // Animated data flow dot on the main line
    final flowT = (orbit * 2.5) % 1.0;
    final flowY = stageY.first + 16 + (stageY.last - stageY.first) * flowT;
    if (progress > 0.5) {
      canvas.drawCircle(
        Offset(cx, flowY),
        4,
        Paint()..color = _blue.withOpacity(0.7),
      );
    }

    // Draw stage pills
    for (int i = 0; i < stages.length; i++) {
      final sp = _segP(progress, i * 0.15, i * 0.15 + 0.28);
      if (sp <= 0) continue;

      final pillW = 90.0 * sp;
      final pillH = 30.0;
      final pillY = stageY[i] - pillH / 2;

      // Pill shadow/glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - pillW / 2 - 2, pillY - 2, pillW + 4, pillH + 4),
          const Radius.circular(18),
        ),
        Paint()..color = stageColors[i].withOpacity(0.08 * sp),
      );

      // Pill fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - pillW / 2, pillY, pillW, pillH),
          const Radius.circular(16),
        ),
        Paint()..color = stageColors[i].withOpacity(0.12 + sp * 0.05),
      );

      // Pill border
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - pillW / 2, pillY, pillW, pillH),
          const Radius.circular(16),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = stageColors[i].withOpacity(0.4 * sp),
      );

      // Stage label
      final tp = TextPainter(
        text: TextSpan(
          text: stages[i],
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: stageColors[i].withOpacity(sp),
            letterSpacing: 1.8,
            fontFamily: 'IBMPlexMono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(cx - tp.width / 2, stageY[i] - tp.height / 2));
    }

    // Arrow heads between stages
    for (int i = 0; i < stages.length - 1; i++) {
      final ap = _segP(progress, i * 0.14 + 0.18, i * 0.14 + 0.36);
      if (ap <= 0) continue;
      final arrowY = (stageY[i] + stageY[i + 1]) / 2;
      _drawArrowHead(canvas, Offset(cx, arrowY), ap);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset pos, double opacity) {
    final path = Path()
      ..moveTo(pos.dx - 5, pos.dy - 4)
      ..lineTo(pos.dx, pos.dy + 2)
      ..lineTo(pos.dx + 5, pos.dy - 4);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _ink.withOpacity(0.3 * opacity),
    );
  }

  double _segP(double t, double s, double e) {
    if (t <= s) return 0;
    if (t >= e) return 1;
    return Curves.easeOutCubic.transform((t - s) / (e - s));
  }

  @override
  bool shouldRepaint(covariant _AdminFlowPainter o) => true;
}

// ══════════════════════════════════════════════════════════════════════
//  PAINTER  ④  SUPER ADMIN — COMMAND GRID (Hexagonal Network)
// ══════════════════════════════════════════════════════════════════════

class _CommandGridPainter extends CustomPainter {
  const _CommandGridPainter(
      {required this.progress, required this.orbit,
       required this.pulse, required this.radar});
  final double progress, orbit, pulse, radar;

  static const Color _ink    = Color(0xFF0C0E12);
  static const Color _blue   = Color(0xFF1D4ED8);
  static const Color _purple = Color(0xFF6D28D9);
  static const Color _red    = Color(0xFFB91C1C);
  static const Color _muted  = Color(0xFF6B7280);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);

    // ── Background blob ───────────────────────────────────────────
    canvas.drawCircle(center, size.shortestSide * 0.40,
        Paint()..color = _purple.withOpacity(0.04));

    // ── Grid / circuit board lines ─────────────────────────────────
    final gridPaint = Paint()
      ..color = _ink.withOpacity(0.05)
      ..strokeWidth = 1.0;
    const gridStep = 22.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Radar sweep ────────────────────────────────────────────────
    final radarAngle = radar * 2 * math.pi;
    final radarR = size.shortestSide * 0.38;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(radarAngle);
    final radarPaint = Paint()
      ..shader = RadialGradient(
        colors: [_purple.withOpacity(0.18 * progress), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radarR));
    final radarPath = Path()
      ..moveTo(0, 0)
      ..lineTo(radarR, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: radarR),
        0, math.pi * 0.35, false,
      )
      ..close();
    canvas.drawPath(radarPath, radarPaint);
    canvas.restore();

    // ── Concentric rings ──────────────────────────────────────────
    for (int r = 1; r <= 3; r++) {
      canvas.drawCircle(
        center, r * 42.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _ink.withOpacity(0.08),
      );
    }

    // ── 6 hex nodes at orbit positions ────────────────────────────
    final baseAngle = orbit * math.pi * 0.12;
    for (int i = 0; i < 6; i++) {
      final np = _segP(progress, i * 0.09, i * 0.09 + 0.30);
      if (np <= 0) continue;
      final angle = (i * math.pi / 3) + baseAngle;
      final r = 72.0;
      final pos = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      // Line from center
      canvas.drawLine(
        center, pos,
        Paint()
          ..color = _ink.withOpacity(0.10 * np)
          ..strokeWidth = 1.2,
      );
      // Hexagon node
      _drawHex(canvas, pos, 14 * np,
          _purple.withOpacity(0.18 * np), _purple.withOpacity(0.45 * np));
    }

    // ── Central command hex ────────────────────────────────────────
    final cp = _segP(progress, 0.55, 0.78);
    if (cp > 0) {
      final pulsedR = 26.0 + pulse * 3;
      // Outer ring
      canvas.drawCircle(
        center, pulsedR + 7,
        Paint()..color = _purple.withOpacity(0.10 * cp),
      );
      // Hex fill
      _drawHex(canvas, center, pulsedR * cp,
          _ink.withOpacity(0.90 * cp), Colors.transparent);
      // Inner hex border accent
      canvas.drawCircle(
        center, pulsedR - 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _purple.withOpacity(0.6 * cp),
      );
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r,
      Color fill, Color stroke) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 6;
      final p = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    if (fill != Colors.transparent) {
      canvas.drawPath(path, Paint()..color = fill);
    }
    if (stroke != Colors.transparent) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = stroke,
      );
    }
  }

  double _segP(double t, double s, double e) {
    if (t <= s) return 0;
    if (t >= e) return 1;
    return Curves.easeOutCubic.transform((t - s) / (e - s));
  }

  @override
  bool shouldRepaint(covariant _CommandGridPainter o) => true;
}

// ══════════════════════════════════════════════════════════════════════
//  PAINTER  ⑤  UNLOCK ICON  (animated lock → unlock)
// ══════════════════════════════════════════════════════════════════════

class _UnlockIconPainter extends CustomPainter {
  const _UnlockIconPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Lock body (rectangle)
    final bodyT = 1.0 - (progress * 0.3).clamp(0.0, 1.0);
    final bodyH = 9.0;
    final bodyW = 14.0;
    final bodyY = cy + 2 - bodyH / 2 + (1 - bodyT) * 0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + 3),
            width: bodyW, height: bodyH),
        const Radius.circular(3),
      ),
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + 3),
            width: bodyW, height: bodyH),
        const Radius.circular(3),
      ),
      paint,
    );

    // Shackle (arc that swings open)
    final shackleOpenAngle = progress * math.pi * 0.85;
    final shackleRect = Rect.fromCenter(
      center: Offset(cx, cy - 3),
      width: 10, height: 9,
    );
    canvas.drawArc(
      shackleRect,
      math.pi + shackleOpenAngle,
      math.pi - shackleOpenAngle,
      false,
      paint,
    );

    // Keyhole inside body
    if (progress > 0.6) {
      final kp = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, cy + 2.5),
        2.5 * kp,
        Paint()..color = color.withOpacity(0.7 * kp),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UnlockIconPainter o) =>
      o.progress != progress;
}

// ══════════════════════════════════════════════════════════════════════
//  PAINTER  ⑥  CELEBRATION CONFETTI
//  Role-specific particle shapes:
//  student     → code brackets  {} () <>
//  admin       → checkmarks ✓
//  super_admin → binary 0 / 1 fragments
// ══════════════════════════════════════════════════════════════════════

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter(
      {required this.progress, required this.roleKey});
  final double progress;
  final String roleKey;

  static const _palette = [
    Color(0xFF0C0E12),
    Color(0xFF1D4ED8),
    Color(0xFFB91C1C),
    Color(0xFF6B7280),
    Color(0xFFD97706),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rng = math.Random(42);

    for (int i = 0; i < 88; i++) {
      final lane  = i % 4;
      final x     = (size.width / 22) * (i % 22) + rng.nextDouble() * 8;
      final startY = lane == 0 ? -20.0
          : lane == 1 ? size.height * 0.08
          : lane == 2 ? size.height * 0.18
          : size.height * 0.28;
      final endY  = size.height + 28;
      final speed = 0.40 + rng.nextDouble() * 0.60;
      final p     = (progress * speed).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;

      final y     = startY + (endY - startY) * p;
      final sway  = math.sin((progress * math.pi * 5) + i) * (5 + lane * 2);
      final alpha = (1 - p) * 0.88;
      final color = _palette[i % _palette.length].withOpacity(alpha);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate((i * 0.25) + (p * math.pi * 4));

      if (roleKey == 'student') {
        // Code brackets
        final sym = i % 3;
        if (sym == 0) {
          canvas.drawLine(const Offset(-4, -4), const Offset(-2, 0), paint);
          canvas.drawLine(const Offset(-2, 0), const Offset(-4, 4), paint);
        } else if (sym == 1) {
          canvas.drawLine(const Offset(4, -4), const Offset(2, 0), paint);
          canvas.drawLine(const Offset(2, 0), const Offset(4, 4), paint);
        } else {
          canvas.drawLine(const Offset(-4, 0), const Offset(4, 0), paint);
        }
      } else if (roleKey == 'admin') {
        // Checkmarks
        canvas.drawLine(const Offset(-4, 0), const Offset(-1, 3), paint);
        canvas.drawLine(const Offset(-1, 3), const Offset(4, -3), paint);
      } else {
        // Binary / circuit dots
        if (i % 2 == 0) {
          canvas.drawCircle(Offset.zero, 2.5, Paint()..color = color);
        } else {
          canvas.drawLine(const Offset(-4, 0), const Offset(4, 0), paint);
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter o) =>
      o.progress != progress;
}