import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/college_service.dart';
import '../services/college_otp_service.dart';
import '../utils/email_validator.dart';
import 'college_otp_screen.dart';

class CollegeVerificationScreen extends StatefulWidget {
  const CollegeVerificationScreen({super.key});

  @override
  State<CollegeVerificationScreen> createState() =>
      _CollegeVerificationScreenState();
}

class _CollegeVerificationScreenState extends State<CollegeVerificationScreen> {
  // ── Colors ──
  static const Color _ink = Color(0xFF0D0D1A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _red = Color(0xFFEF4444);
  static const Color _green = Color(0xFF059669);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _fieldBg = Color(0xFFF9FAFB);

  // ── Services ──
  final CollegeService _collegeService = CollegeService();
  final CollegeOtpService _otpService = CollegeOtpService();

  // ── Controllers ──
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _customCollegeController = TextEditingController();

  // ── State ──
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSending = false;
  bool _showCustomInput = false;
  String? _emailError;

  // Selected college info
  String? _selectedCollegeId;
  String? _selectedCollegeName;
  String? _selectedCollegeDomain;
  bool _collegeChosen = false;

  // Search debounce
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _customCollegeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search with debounce ──
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _collegeService.searchColleges(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectCollege(Map<String, dynamic> college) {
    setState(() {
      _selectedCollegeId = college['id'] as String?;
      _selectedCollegeName = college['name'] as String?;
      _selectedCollegeDomain = college['domain'] as String?;
      _collegeChosen = true;
      _showCustomInput = false;
      _searchResults = [];
      _searchController.text = _selectedCollegeName ?? '';
    });
  }

  void _showCustomCollegeInput() {
    setState(() {
      _showCustomInput = true;
      _selectedCollegeId = null;
      _selectedCollegeDomain = null;
      _searchResults = [];
    });
  }

  void _confirmCustomCollege() {
    final name = _customCollegeController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _selectedCollegeName = name;
      _selectedCollegeId = null;
      _selectedCollegeDomain = null;
      _collegeChosen = true;
    });
  }

  void _resetSelection() {
    setState(() {
      _collegeChosen = false;
      _selectedCollegeId = null;
      _selectedCollegeName = null;
      _selectedCollegeDomain = null;
      _showCustomInput = false;
      _searchController.clear();
      _emailController.clear();
      _emailError = null;
    });
  }

  // ── Send OTP ──
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return;
    }

    if (EmailValidator.isPersonalEmail(email)) {
      setState(() =>
          _emailError = 'Please use your college email, not a personal one.');
      return;
    }

    setState(() {
      _emailError = null;
      _isSending = true;
    });

    final userId = AuthService().user?.id;
    if (userId == null) {
      setState(() => _isSending = false);
      _showSnackbar('Not logged in. Please restart the app.');
      return;
    }

    final result = await _otpService.sendOtp(userId, email);

    if (!mounted) return;
    setState(() => _isSending = false);

    switch (result) {
      case OtpSendResult.success:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CollegeOtpScreen(
            userId: userId,
            collegeEmail: email,
            collegeName: _selectedCollegeName,
            collegeId: _selectedCollegeId,
          ),
        ));
        break;
      case OtpSendResult.limitReached:
        _showLimitReachedDialog();
        break;
      case OtpSendResult.failed:
        _showSnackbar('Something went wrong. Please try again.');
        break;
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Limit Reached Dialog ──
  void _showLimitReachedDialog() {
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
              _buildCollegeSelection(),
              if (_collegeChosen) ...[
                const SizedBox(height: 28),
                _buildEmailInput(),
              ],
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'VERIFICATION',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _blue,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Verify Your\nCollege Email',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _ink,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connect your college email to access all features and join your campus community.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: _muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── STAGE 1 — College Selection ──

  Widget _buildCollegeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIND YOUR COLLEGE',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Search field
        Container(
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 0.8),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.dmSans(
                fontSize: 14, color: _ink, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Search by college name...',
              hintStyle:
                  GoogleFonts.dmSans(color: const Color(0xFFB0B7C3), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 20, color: _muted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),

        // Loading indicator
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
              ),
            ),
          ),

        // Search results
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: _ink.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _border.withOpacity(0.5)),
              itemBuilder: (context, index) {
                final college = _searchResults[index];
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded,
                        size: 18, color: _blue),
                  ),
                  title: Text(
                    college['name'] ?? '',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  subtitle: Text(
                    college['domain'] ?? '',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _muted),
                  ),
                  onTap: () => _selectCollege(college),
                );
              },
            ),
          ),

        // Selected college badge
        if (_collegeChosen && _selectedCollegeName != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withOpacity(0.2), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCollegeName!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (_selectedCollegeDomain != null)
                        Text(
                          _selectedCollegeDomain!,
                          style: GoogleFonts.dmSans(fontSize: 11, color: _muted),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _resetSelection,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: _muted),
                ),
              ],
            ),
          ),

        // "My college isn't listed" option
        if (!_collegeChosen && !_showCustomInput)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Divider(color: _border.withOpacity(0.6))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: _border.withOpacity(0.6))),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showCustomCollegeInput,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _border.withOpacity(0.8), width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            size: 16, color: _muted),
                        const SizedBox(width: 8),
                        Text(
                          "My college is not listed",
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Custom college name input
        if (_showCustomInput && !_collegeChosen)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'ENTER YOUR COLLEGE NAME',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: TextField(
                  controller: _customCollegeController,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: _ink, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'e.g. VIT University, Vellore',
                    hintStyle: GoogleFonts.dmSans(
                        color: const Color(0xFFB0B7C3), fontSize: 13),
                    prefixIcon: const Icon(Icons.edit_rounded,
                        size: 18, color: _muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _confirmCustomCollege,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Confirm College',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── STAGE 2 — Email Input ──

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _border.withOpacity(0.5)),
        const SizedBox(height: 20),
        Text(
          'COLLEGE EMAIL',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _emailError != null ? _red.withOpacity(0.5) : _border,
              width: 0.8,
            ),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            style: GoogleFonts.dmSans(
                fontSize: 14, color: _ink, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'you@college.edu.in',
              hintStyle: GoogleFonts.dmSans(
                  color: const Color(0xFFB0B7C3), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.email_outlined, size: 18, color: _muted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),

        // Error or help text
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _emailError ?? 'Personal emails (Gmail, Yahoo, etc.) are not accepted.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: _emailError != null ? _red : _muted,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Send OTP button
        GestureDetector(
          onTap: _isSending ? null : _sendOtp,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Send Code',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
