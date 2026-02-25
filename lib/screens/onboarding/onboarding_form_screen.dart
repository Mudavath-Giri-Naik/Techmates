import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../services/auth_service.dart';
import '../../services/college_service.dart';
import '../../services/college_otp_service.dart';
import '../../utils/email_validator.dart';
import '../main_screen.dart';
import '../auth/login_screen.dart';

enum _CollegeState { emailInput, otpEntry, verified }

class OnboardingFormScreen extends StatefulWidget {
  final String userId;
  final String initialName;
  const OnboardingFormScreen({
    super.key,
    required this.userId,
    this.initialName = '',
  });

  @override
  State<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends State<OnboardingFormScreen>
    with SingleTickerProviderStateMixin {

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _ink     = Color(0xFF0A0A0A);
  static const _ink2    = Color(0xFF3D3D3D);
  static const _blue    = Color(0xFF1D4ED8);
  static const _blueL   = Color(0xFFEFF6FF);
  static const _red     = Color(0xFFDC2626);
  static const _green   = Color(0xFF15803D);
  static const _greenL  = Color(0xFFF0FDF4);
  static const _muted   = Color(0xFF9CA3AF);
  static const _border  = Color(0xFFE5E7EB);
  static const _borderD = Color(0xFFD1D5DB);
  static const _bg      = Color(0xFFF3F4F6);

  // ── Services ──────────────────────────────────────────────────────────────
  final _college = CollegeService();
  final _otp     = CollegeOtpService();
  final _auth    = AuthService();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _nameCtrl     = TextEditingController();
  final _githubCtrl   = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();

  final List<TextEditingController> _dig = List.generate(6, (_) => TextEditingController());
  final List<FocusNode>             _foc = List.generate(6, (_) => FocusNode());

  // ── College state ─────────────────────────────────────────────────────────
  _CollegeState _cs = _CollegeState.emailInput;
  String? _colName, _colId;
  bool _colInDb = true;

  // ── OTP ───────────────────────────────────────────────────────────────────
  String? _emailErr, _otpErr;
  bool _sending = false, _verifying = false;
  int _countdown = 0;
  Timer? _resendTimer;
  String? _verifiedEmail;

  // ── Shake ─────────────────────────────────────────────────────────────────
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  // ── Batch ─────────────────────────────────────────────────────────────────
  int? _from;
  int? get _to => _from == null ? null : _from! + 4;
  static final _fromYears = List.generate(2028 - 2018 + 1, (i) => 2018 + i);

  // ── Branch ────────────────────────────────────────────────────────────────
  String? _branch;
  static const _branches = [
    'Computer Science & Engineering (CSE)',
    'Information Technology (IT)',
    'Electronics & Communication (ECE)',
    'Electrical & Electronics (EEE)',
    'Mechanical Engineering (ME)',
    'Civil Engineering (CE)',
    'Chemical Engineering',
    'Biotechnology',
    'Aerospace Engineering',
    'Automobile Engineering',
    'Biomedical Engineering',
    'Data Science & AI',
    'Artificial Intelligence & ML',
    'Cyber Security',
    'Robotics & Automation',
    'Mining Engineering',
    'Petroleum Engineering',
    'Agricultural Engineering',
    'Textile Engineering',
    'Other',
  ];

  String get _yearLabel {
    if (_from == null) return '';
    final diff = DateTime.now().year - _from!;
    if (diff <= 1) return 'First Year';
    if (diff == 2) return 'Second Year';
    if (diff == 3) return 'Third Year';
    if (diff == 4) return 'Final Year';
    return 'Alumni';
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().length >= 2 &&
      _cs == _CollegeState.verified &&
      _from != null;

  bool _submitting = false;

  String? get _avatar {
    final m = Supabase.instance.client.auth.currentUser?.userMetadata;
    return m?['avatar_url'] as String? ?? m?['picture'] as String?;
  }

  String get _dispName {
    final m = Supabase.instance.client.auth.currentUser?.userMetadata;
    return m?['full_name'] as String? ?? m?['name'] as String? ?? widget.initialName;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end:  8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end:  0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _nameCtrl.text = _dispName;
    _nameCtrl.addListener(_rebuild);
    _githubCtrl.addListener(_rebuild);
    _linkedinCtrl.addListener(_rebuild);
    _emailCtrl.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _nameCtrl.removeListener(_rebuild);
    _githubCtrl.removeListener(_rebuild);
    _linkedinCtrl.removeListener(_rebuild);
    _emailCtrl.removeListener(_rebuild);
    _nameCtrl.dispose();
    _githubCtrl.dispose();
    _linkedinCtrl.dispose();
    _emailCtrl.dispose();
    _resendTimer?.cancel();
    for (final c in _dig) c.dispose();
    for (final f in _foc) f.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  OTP digit handling
  // ─────────────────────────────────────────────────────────────────────────

  void _onDigitChanged(int i, String v) {
    if (v.isEmpty) {
      if (i > 0) _foc[i - 1].requestFocus();
      return;
    }
    if (i < 5) _foc[i + 1].requestFocus();
    if (_dig.every((c) => c.text.isNotEmpty)) _verify();
  }

  void _clearBoxes() {
    for (final c in _dig) c.clear();
    if (mounted) _foc[0].requestFocus();
  }

  String get _code => _dig.map((c) => c.text).join();

  // ─────────────────────────────────────────────────────────────────────────
  //  OTP flow
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailErr = 'Enter a valid email address');
      return;
    }
    if (EmailValidator.isPersonalEmail(email)) {
      setState(() => _emailErr = 'Use your official college email');
      return;
    }
    setState(() { _emailErr = null; _sending = true; });
    final r = await _otp.sendOtp(widget.userId, email);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (r) {
      case OtpSendResult.success:
        setState(() => _cs = _CollegeState.otpEntry);
        _startTimer();
        break;
      case OtpSendResult.limitReached:
        _limitDialog();
        break;
      case OtpSendResult.failed:
        _snack('Something went wrong. Please try again.');
        break;
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    final r = await _otp.sendOtp(widget.userId, _emailCtrl.text.trim());
    if (!mounted) return;
    switch (r) {
      case OtpSendResult.success:
        _startTimer(); _snack('New code sent!', ok: true);
        break;
      case OtpSendResult.limitReached:
        _limitDialog();
        break;
      case OtpSendResult.failed:
        _snack('Failed to resend.');
        break;
    }
  }

  void _startTimer() {
    _countdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() { _verifying = true; _otpErr = null; });
    final r = await _otp.verifyOtp(widget.userId, _code);
    if (!mounted) return;

    switch (r) {
      case OtpVerifyResult.verified:
        final email  = _emailCtrl.text.trim();
        final domain = email.split('@').last.toLowerCase();
        await _detectCollege(domain);
        setState(() {
          _verifying = false;
          _verifiedEmail = email;
          _cs = _CollegeState.verified;
        });
        if (!_colInDb) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _notInDbDialog());
        }
        break;
      case OtpVerifyResult.wrongCode:
        setState(() { _verifying = false; _otpErr = 'Incorrect code. Try again.'; });
        _clearBoxes();
        _shakeCtrl.forward(from: 0);
        break;
      case OtpVerifyResult.expired:
        setState(() { _verifying = false; _otpErr = 'Code expired. Request a new one.'; });
        _clearBoxes();
        break;
      case OtpVerifyResult.failed:
        setState(() => _verifying = false);
        _snack('Something went wrong.');
        break;
    }
  }

  Future<void> _detectCollege(String domain) async {
    try {
      final normalizedDomain = domain.trim().toLowerCase();
      final result = await _college.getCollegeIdByDomain(normalizedDomain);
      if (result != null) {
        _colId   = result['id'] as String?;
        _colName = result['name'] as String?;
        _colInDb = true;
      } else {
        _colName = null; _colId = null; _colInDb = false;
      }
    } catch (_) {
      _colName = null; _colId = null; _colInDb = false;
    }
  }

  void _resetEmail() {
    setState(() {
      _cs = _CollegeState.emailInput;
      _emailCtrl.clear();
      _emailErr = _otpErr = null;
      _verifiedEmail = null;
      _colName = _colId = null;
      _colInDb = true;
      for (final c in _dig) c.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Submit & sign out
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    try {
      final email  = _verifiedEmail!;
      final domain = email.split('@').last.toLowerCase();
      await SupabaseClientManager.instance.from('profiles').upsert({
        'id': widget.userId,
        'name': _nameCtrl.text.trim(),
        'college': _colName ?? domain,
        'college_email': email,
        'college_email_domain': domain,
        'college_id': _colId,
        'college_verified': true,
        'branch': _branch,
        'year': _yearLabel,
        'github_url':
            _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
        'linkedin_url':
            _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      if (_colId == null) await _college.handleUnknownDomain(domain, _colName ?? domain);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
      }
    } catch (e) {
      debugPrint('❌ submit: $e');
      if (mounted) {
        setState(() => _submitting = false);
        _snack('Could not save profile.');
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Dialogs / Snack
  // ─────────────────────────────────────────────────────────────────────────

  void _snack(String m, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: GoogleFonts.dmSans(fontSize: 13)),
      backgroundColor: ok ? _green : _red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _notInDbDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: _border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline_rounded, size: 22, color: _blue),
            ),
            const SizedBox(height: 14),
            Text('College not found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            Text(
              'Your email was verified successfully!\n\n'
              "Your college isn't in our database yet, but our team will add it soon. "
              'You can continue right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: _ink2, height: 1.55),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Got it, continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _limitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: _border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.nights_stay_outlined, size: 22, color: _ink2),
            ),
            const SizedBox(height: 14),
            Text('Daily limit reached',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 6),
            Text("You've hit the daily OTP limit. Try again tomorrow.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: _muted, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink, foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Got it',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),

              // ── OUTSIDE TOP: back button + step indicator ─────────────
              _outsideTopRow(),
              const SizedBox(height: 14),

              // ── OUTSIDE: welcome blurb ────────────────────────────────
              _outsideWelcome(),
              const SizedBox(height: 14),

              // ── THE CARD ──────────────────────────────────────────────
              _invitationCard(),
              const SizedBox(height: 16),

              // ── OUTSIDE BOTTOM: help text ─────────────────────────────
              _outsideFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  OUTSIDE elements
  // ─────────────────────────────────────────────────────────────────────────

  /// Back button (left) + step dots (right)
  Widget _outsideTopRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Back / switch account button
      GestureDetector(
        onTap: _signOut,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border, width: 1.2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.arrow_back_rounded, size: 14, color: _ink2),
            const SizedBox(width: 6),
            Text('Back',
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: _ink2)),
          ]),
        ),
      ),
      const Spacer(),
      // Step indicator — 3 dots: account ✓ | profile (active) | done
      _stepDots(),
    ],
  );

  Widget _stepDots() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Step 1 — completed
      _dot(filled: true, color: _green),
      const SizedBox(width: 4),
      Text('·', style: GoogleFonts.dmSans(color: _muted, fontSize: 14)),
      const SizedBox(width: 4),
      // Step 2 — active
      _dot(filled: true, color: _blue),
      const SizedBox(width: 4),
      Text('·', style: GoogleFonts.dmSans(color: _muted, fontSize: 14)),
      const SizedBox(width: 4),
      // Step 3 — pending
      _dot(filled: false, color: _borderD),
    ]);
  }

  Widget _dot({required bool filled, required Color color}) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? color : Colors.transparent,
      border: Border.all(color: color, width: 1.4),
    ),
  );

  /// Short welcome line outside the card
  Widget _outsideWelcome() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _avatarPill(),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, color: _ink, fontWeight: FontWeight.w700),
                children: [
                  const TextSpan(text: 'Hey '),
                  TextSpan(
                    text: _dispName.isEmpty
                        ? 'there'
                        : _dispName.split(' ').first,
                    style: const TextStyle(color: _blue)),
                  const TextSpan(text: ' 👋'),
                ],
              ),
            ),
            Text('Just a few details and you\'re in.',
              style: GoogleFonts.dmSans(fontSize: 11.5, color: _muted)),
          ],
        ),
      ),
    ],
  );

  Widget _avatarPill() {
    final url  = _avatar;
    final name = _dispName;
    final ini  = name.isEmpty
        ? '?'
        : name.split(' ').take(2)
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 1.5),
      ),
      child: ClipOval(child: url != null
        ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _iniBox(ini, 36))
        : _iniBox(ini, 36)),
    );
  }

  /// Footer hint below the card
  Widget _outsideFooter() => Center(
    child: Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline_rounded, size: 11, color: _muted),
        const SizedBox(width: 4),
        Text('Your data is private and never shared',
          style: GoogleFonts.dmSans(fontSize: 11, color: _muted)),
      ]),
      const SizedBox(height: 5),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('College verification keeps the community authentic',
          style: GoogleFonts.dmSans(fontSize: 11, color: _muted)),
      ]),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  Invitation card — NO shadow, light blue-grey border
  // ─────────────────────────────────────────────────────────────────────────

  Widget _invitationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // No shadow — only a light blue-tinted border
        border: Border.all(color: const Color(0xFFD1DCF5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTopStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageHeader(),
                const SizedBox(height: 6),
                _divider(),
                const SizedBox(height: 18),
                _nameRow(),
                const SizedBox(height: 12),
                _collegeSection(),
                const SizedBox(height: 12),
                _batchRow(),
                const SizedBox(height: 12),
                _branchRow(),
                const SizedBox(height: 12),
                _githubRow(),
                const SizedBox(height: 12),
                _linkedinRow(),
                const SizedBox(height: 22),
                _submitBtn(),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'By joining you agree to our Terms & Privacy Policy',
                    style: GoogleFonts.dmSans(fontSize: 10.5, color: _muted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Card top strip (unchanged inside)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _cardTopStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _border, width: 1)),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Row(children: [
      Row(children: [
        Container(width: 7, height: 7,
          decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Container(width: 7, height: 7,
          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
        const SizedBox(width: 9),
        RichText(text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          children: const [
            TextSpan(text: 'Tech', style: TextStyle(color: _ink)),
            TextSpan(text: 'mates', style: TextStyle(color: _blue)),
          ],
        )),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _signOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: _border, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Switch',
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: _ink2)),
        ),
      ),
    ]),
  );

  Widget _avatarChip() {
    final url  = _avatar;
    final name = _dispName;
    final ini  = name.isEmpty
        ? '?'
        : name.split(' ').take(2)
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _border, width: 1.2),
        ),
        child: ClipOval(child: url != null
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _iniBox(ini, 28))
          : _iniBox(ini, 28)),
      ),
      const SizedBox(width: 8),
      Text(name.isEmpty ? 'You' : name.split(' ').first,
        style: GoogleFonts.dmSans(
          fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
    ]);
  }

  Widget _iniBox(String ini, double s) => Container(
    color: _blueL,
    child: Center(child: Text(ini,
      style: GoogleFonts.plusJakartaSans(
        fontSize: s * 0.38, fontWeight: FontWeight.w800, color: _blue))));

  // ─────────────────────────────────────────────────────────────────────────
  //  Page header (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _pageHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You're invited 🎉",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19, fontWeight: FontWeight.w800,
                color: _ink, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text('Complete your profile to join the community',
              style: GoogleFonts.dmSans(fontSize: 12.5, color: _muted)),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 5, height: 5,
            decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Onboarding',
            style: GoogleFonts.dmSans(
              fontSize: 10.5, color: _muted, fontWeight: FontWeight.w500)),
        ]),
      ),
    ],
  );

  Widget _divider() => Container(height: 1, color: _border);

  // ─────────────────────────────────────────────────────────────────────────
  //  Shared widget helpers (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _border, width: 1.2),
    ),
    child: Icon(icon, size: 18, color: color),
  );

  Widget _fieldBox(Widget child) => Expanded(
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1.1),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    ),
  );

  TextStyle _ts() =>
      GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: _ink);

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: _muted, fontSize: 13),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  Form rows (all unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _nameRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _iconBox(Icons.person_outline_rounded, _blue),
      const SizedBox(width: 10),
      _fieldBox(TextField(
        controller: _nameCtrl,
        style: _ts(),
        textCapitalization: TextCapitalization.words,
        decoration: _dec('Full name'),
      )),
    ],
  );

  Widget _githubRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _iconBox(Icons.code_rounded, _ink2),
      const SizedBox(width: 10),
      _fieldBox(TextField(
        controller: _githubCtrl,
        style: _ts(),
        decoration: _dec('github.com/username'),
      )),
    ],
  );

  Widget _linkedinRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _iconBox(Icons.link_rounded, _ink2),
      const SizedBox(width: 10),
      _fieldBox(TextField(
        controller: _linkedinCtrl,
        style: _ts(),
        decoration: _dec('linkedin.com/in/name'),
      )),
    ],
  );

  Widget _batchRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _iconBox(Icons.calendar_month_outlined, _blue),
      const SizedBox(width: 10),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _openYearPicker,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border, width: 1.1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _from != null ? '$_from' : 'Year',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: _from != null ? FontWeight.w600 : FontWeight.w400,
                      color: _from != null ? _ink : _muted),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.unfold_more_rounded, size: 14, color: _muted),
                ]),
              ),
            ),
            if (_from != null) ...[
              const SizedBox(width: 8),
              Text('→',
                style: GoogleFonts.dmSans(fontSize: 13, color: _muted)),
              const SizedBox(width: 8),
              Text('$_to',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: _blue, letterSpacing: -0.4)),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _blue.withOpacity(0.2)),
                    color: _blueL,
                  ),
                  child: Text(
                    _yearLabel,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5, fontWeight: FontWeight.w600, color: _blue),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  void _openYearPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.45),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Select Start Year',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close_rounded, size: 20, color: _muted)),
            ]),
          ),
          const SizedBox(height: 10),
          Container(height: 0.6, color: _border),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _fromYears.length,
              itemBuilder: (_, i) {
                final y = _fromYears[i];
                final selected = _from == y;
                return InkWell(
                  onTap: () {
                    setState(() => _from = y);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                    color: selected ? _blueL : Colors.transparent,
                    child: Row(children: [
                      Expanded(
                        child: Text('$y  →  ${y + 4}',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: selected
                              ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? _blue : _ink)),
                      ),
                      if (selected)
                        const Icon(Icons.check_rounded, size: 18, color: _blue),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _branchRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _iconBox(Icons.science_outlined, _blue),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: _openBranchPicker,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border, width: 1.1),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  _branch ?? 'Select Branch',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: _branch != null ? FontWeight.w600 : FontWeight.w400,
                    color: _branch != null ? _ink : _muted),
                ),
              ),
              const Icon(Icons.unfold_more_rounded, size: 14, color: _muted),
            ]),
          ),
        ),
      ),
    ],
  );

  void _openBranchPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.55),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          const SizedBox(height: 12),
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Select Branch',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close_rounded, size: 20, color: _muted)),
            ]),
          ),
          const SizedBox(height: 10),
          Container(height: 0.6, color: _border),
          // List
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _branches.length,
              itemBuilder: (_, i) {
                final b = _branches[i];
                final selected = _branch == b;
                return InkWell(
                  onTap: () {
                    setState(() => _branch = b);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                    color: selected ? _blueL : Colors.transparent,
                    child: Row(children: [
                      Expanded(
                        child: Text(b,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: selected
                              ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? _blue : _ink)),
                      ),
                      if (selected)
                        const Icon(Icons.check_rounded, size: 18, color: _blue),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  College section (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _collegeSection() {
    switch (_cs) {
      case _CollegeState.emailInput: return _cfEmailRow();
      case _CollegeState.otpEntry:   return _cfOtpSection();
      case _CollegeState.verified:   return _cfVerifiedRow();
    }
  }

  Widget _cfEmailRow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _iconBox(Icons.school_outlined, _red),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _emailErr != null ? _red : _border, width: 1.1),
            ),
            child: Row(children: [
              const Icon(Icons.alternate_email_rounded, size: 15, color: _muted),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: _ts(),
                  onChanged: (_) {
                    if (_emailErr != null) setState(() => _emailErr = null);
                  },
                  decoration: _dec('college@edu.in'),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _sendOtp,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _sending ? _border : _blue, width: 1.2),
            ),
            child: Center(
              child: _sending
                ? const SizedBox(width: 15, height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
                : Text('Verify',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _blue)),
            ),
          ),
        ),
      ]),
      if (_emailErr != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 50),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 12, color: _red),
            const SizedBox(width: 4),
            Flexible(
              child: Text(_emailErr!,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _red, fontWeight: FontWeight.w500)),
            ),
          ]),
        )
      else
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 50),
          child: Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 11, color: _muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text('Official college emails only — not Gmail or Yahoo',
                style: GoogleFonts.dmSans(fontSize: 11, color: _muted)),
            ),
          ]),
        ),
    ],
  );

  Widget _cfOtpSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _iconBox(Icons.mark_email_read_outlined, _blue),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border, width: 1.1),
            ),
            child: Row(children: [
              Expanded(
                child: Text(_emailCtrl.text,
                  style: GoogleFonts.firaCode(fontSize: 12, color: _ink),
                  overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _cs = _CollegeState.emailInput;
                  _otpErr = null;
                  for (final c in _dig) c.clear();
                }),
                child: Text('Change',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: _blue, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: 50),
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) =>
            Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
          child: _buildOtpBoxes(),
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 50),
        child: _verifying
          ? const SizedBox(width: 15, height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
          : _countdown > 0
            ? Text('Resend in ${_countdown}s',
                style: GoogleFonts.dmSans(fontSize: 12, color: _muted))
            : GestureDetector(
                onTap: _resend,
                child: Text('Resend Code',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: _blue, fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: _blue)),
              ),
      ),
      if (_otpErr != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 50),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 12, color: _red),
            const SizedBox(width: 4),
            Flexible(
              child: Text(_otpErr!,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _red, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
    ],
  );

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        return Container(
          key: ValueKey('otp_$i'),
          width: 38, height: 44,
          margin: EdgeInsets.only(right: i < 5 ? 6 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _otpErr != null ? _red : _borderD, width: 1.2),
          ),
          child: TextField(
            controller: _dig[i],
            focusNode: _foc[i],
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _onDigitChanged(i, v),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
            decoration: const InputDecoration(
              counterText: '',
              isDense: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        );
      }),
    );
  }

  Widget _cfVerifiedRow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withOpacity(0.35), width: 1.2),
            color: _greenL,
          ),
          child: const Icon(Icons.verified_rounded, size: 18, color: _green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withOpacity(0.3), width: 1.1),
              color: _greenL,
            ),
            child: Row(children: [
              Expanded(
                child: Text(_verifiedEmail ?? '',
                  style: GoogleFonts.firaCode(fontSize: 12, color: _green),
                  overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.4)),
                  color: Colors.white,
                ),
                child: Text('Verified',
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5, fontWeight: FontWeight.w700, color: _green)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _resetEmail,
                child: const Icon(Icons.close_rounded, size: 14, color: _muted),
              ),
            ]),
          ),
        ),
      ]),
      if (_colName != null)
        Padding(
          padding: const EdgeInsets.only(top: 7, left: 50),
          child: Row(children: [
            const Icon(Icons.school_outlined, size: 12, color: _blue),
            const SizedBox(width: 5),
            Flexible(
              child: Text(_colName!,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _ink2)),
            ),
          ]),
        ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  Submit button (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _submitBtn() {
    final ok = _canSubmit && !_submitting;
    return GestureDetector(
      onTap: ok ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: ok ? _ink : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _submitting
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Join Techmates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.2)),
                const SizedBox(width: 7),
                const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
              ]),
        ),
      ),
    );
  }
}