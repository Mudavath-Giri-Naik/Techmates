import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/supabase_client.dart';
import '../services/college_service.dart';
import '../services/college_otp_service.dart';
import 'home_screen.dart';

class CollegeOtpScreen extends StatefulWidget {
  final String userId;
  final String collegeEmail;
  final String? collegeName;
  final String? collegeId;

  const CollegeOtpScreen({
    super.key,
    required this.userId,
    required this.collegeEmail,
    this.collegeName,
    this.collegeId,
  });

  @override
  State<CollegeOtpScreen> createState() => _CollegeOtpScreenState();
}

class _CollegeOtpScreenState extends State<CollegeOtpScreen> {
  // ── Colors ──
  static const Color _ink = Color(0xFF0D0D1A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _red = Color(0xFFEF4444);
  static const Color _green = Color(0xFF059669);
  static const Color _border = Color(0xFFE5E7EB);

  // ── Services ──
  final CollegeOtpService _otpService = CollegeOtpService();
  final CollegeService _collegeService = CollegeService();

  // ── OTP digit controllers ──
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // ── State ──
  bool _isVerifying = false;
  String? _errorText;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _resendCountdown--);
        if (_resendCountdown <= 0) timer.cancel();
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredCode =>
      _digitControllers.map((c) => c.text).join();

  bool get _allFilled =>
      _digitControllers.every((c) => c.text.isNotEmpty);

  void _clearAll() {
    for (final c in _digitControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // ── Handle digit input ──
  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-verify when all 6 filled
    if (_allFilled) {
      _verifyOtp();
    }
  }

  // ── Handle backspace ──
  void _onDigitKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _digitControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ── Verify OTP ──
  Future<void> _verifyOtp() async {
    if (!_allFilled || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final result = await _otpService.verifyOtp(widget.userId, _enteredCode);

    if (!mounted) return;

    switch (result) {
      case OtpVerifyResult.verified:
        await _onVerificationSuccess();
        break;
      case OtpVerifyResult.wrongCode:
        setState(() {
          _isVerifying = false;
          _errorText = 'Incorrect code. Please check and try again.';
        });
        _clearAll();
        break;
      case OtpVerifyResult.expired:
        setState(() {
          _isVerifying = false;
          _errorText = 'Code expired. Please request a new one.';
        });
        _clearAll();
        break;
      case OtpVerifyResult.failed:
        setState(() {
          _isVerifying = false;
          _errorText = 'Something went wrong. Try again.';
        });
        break;
    }
  }

  Future<void> _onVerificationSuccess() async {
    try {
      final domain = widget.collegeEmail.split('@').last.toLowerCase();

      // Save college info to profile
      await _collegeService.saveCollegeToProfile(
        widget.userId,
        widget.collegeEmail,
        domain,
        widget.collegeId,
        widget.collegeName,
      );

      // If no collegeId, call RPC to create unverified college
      if (widget.collegeId == null) {
        await _collegeService.handleUnknownDomain(
          domain,
          widget.collegeName ?? domain,
        );
      }

      // Mark onboarding as completed
      await SupabaseClientManager.instance
          .from('profiles')
          .update({'onboarding_completed': true})
          .eq('id', widget.userId);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ [CollegeOtpScreen] Post-verify error: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorText = 'Verified but could not save. Please try again.';
        });
      }
    }
  }

  // ── Resend OTP ──
  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    final result = await _otpService.sendOtp(widget.userId, widget.collegeEmail);

    if (!mounted) return;

    switch (result) {
      case OtpSendResult.success:
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('New code sent!'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ));
        break;
      case OtpSendResult.limitReached:
        _showLimitDialog();
        break;
      case OtpSendResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to resend. Try again.'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ));
        break;
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nightlight_round,
                    size: 28, color: Colors.amber),
              ),
              const SizedBox(height: 18),
              Text(
                "We'll be back tomorrow",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Techmates is growing fast and we've hit our daily verification limit. Come back tomorrow — your spot is saved.",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 5),
                    Text(
                      'Resets at midnight',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 28),
              _buildInfoBox(),
              const SizedBox(height: 28),
              _buildOtpBoxes(),
              const SizedBox(height: 8),
              _buildError(),
              const SizedBox(height: 20),
              _buildVerifyButton(),
              const SizedBox(height: 20),
              _buildResendRow(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: _ink),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check your\ncollege email',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: 14, color: _muted, height: 1.4),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: widget.collegeEmail,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blue.withOpacity(0.12), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: _blue.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open your college email app, copy the 6-digit code, come back here and enter it.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: _blue.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(), // wrapper for key events
            onKeyEvent: (event) => _onDigitKey(i, event),
            child: TextField(
              controller: _digitControllers[i],
              focusNode: _focusNodes[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (val) => _onDigitChanged(i, val),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _blue, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _red.withOpacity(0.5), width: 0.8),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildError() {
    if (_errorText == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _errorText!,
              style: GoogleFonts.dmSans(fontSize: 12, color: _red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: (_allFilled && !_isVerifying) ? _verifyOtp : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _allFilled ? _blue : _blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _isVerifying
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  'Verify Code',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResendRow() {
    return Center(
      child: _resendCountdown > 0
          ? Text(
              'Resend code in ${_resendCountdown}s',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _muted,
              ),
            )
          : GestureDetector(
              onTap: _resendOtp,
              child: Text(
                'Resend Code',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                ),
              ),
            ),
    );
  }
}
