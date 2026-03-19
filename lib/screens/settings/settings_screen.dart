import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';
import '../../core/theme_notifier.dart';

// ─── Brand Constants ──────────────────────────────────────────────
const _brandRed = Color(0xFFC62828);
const _brandRedLight = Color(0xFFE53935);
const _brandBlue = Color(0xFF1565C0);
const _brandRedContainer = Color(0xFFFFEBEE);
const _brandBlueContainer = Color(0xFFE3F2FD);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  final ProfileService _profileService = ProfileService();

  bool _isPrivate = false;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _isLoading = true;
  String _appVersion = 'Loading...';
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadSettings();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      final formatted = build.isNotEmpty ? '$version ($build)' : version;
      if (!mounted) return;
      setState(() => _appVersion = formatted);
    } catch (e) {
      debugPrint('❌ [Settings] App version load error: $e');
      if (!mounted) return;
      setState(() => _appVersion = 'Unavailable');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final userId = _auth.user?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _profileService.fetchProfile(userId),
        SharedPreferences.getInstance(),
      ]);

      final profile = results[0] as UserProfile?;
      final prefs = results[1] as SharedPreferences;

      if (mounted) {
        setState(() {
          _profile = profile;
          _isPrivate = profile?.isPrivate ?? false;
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
          _darkMode = prefs.getBool('dark_mode') ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Settings] Load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePrivacy(bool value) async {
    final oldValue = _isPrivate;
    setState(() => _isPrivate = value);

    try {
      final userId = _auth.user?.id;
      if (userId == null) throw Exception('Not logged in');

      await _profileService.updateProfile(userId, {'is_private': value});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Account is now private. New followers will need your approval.'
                  : 'Account is now public. Anyone can follow you.',
              style: GoogleFonts.sora(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor:
                Theme.of(context).colorScheme.inverseSurface,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Settings] Privacy toggle error: $e');
      if (mounted) {
        setState(() => _isPrivate = oldValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update privacy setting',
                style: GoogleFonts.sora(fontSize: 12)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _brandRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications enabled' : 'Notifications disabled',
            style: GoogleFonts.sora(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _darkMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    ThemeNotifier.instance.toggleTheme(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Dark Mode Enabled' : 'Light Mode Enabled',
            style: GoogleFonts.sora(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account Section ──
                  _sectionHeader('ACCOUNT', cs),
                  const SizedBox(height: 8),
                  _settingsCard(
                    cs,
                    children: [
                      _buildPrivacyToggle(cs),
                      _divider(cs),
                      _buildAccountInfo(cs),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Preferences Section ──
                  _sectionHeader('PREFERENCES', cs),
                  const SizedBox(height: 8),
                  _settingsCard(
                    cs,
                    children: [
                      _buildNotificationsToggle(cs),
                      _divider(cs),
                      _buildDarkModeToggle(cs),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Privacy & Security Section ──
                  _sectionHeader('PRIVACY & SECURITY', cs),
                  const SizedBox(height: 8),
                  _settingsCard(
                    cs,
                    children: [
                      _buildNavItem(
                        icon: Icons.lock_outline_rounded,
                        iconBg: _brandBlueContainer,
                        iconColor: _brandBlue,
                        title: 'Blocked Users',
                        subtitle: 'Manage blocked accounts',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                      _divider(cs),
                      _buildNavItem(
                        icon: Icons.security_rounded,
                        iconBg: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFF7B1FA2),
                        title: 'Two-Factor Auth',
                        subtitle: 'Extra security for your account',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                      _divider(cs),
                      _buildNavItem(
                        icon: Icons.download_rounded,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        title: 'Download My Data',
                        subtitle: 'Export your account data',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Support Section ──
                  _sectionHeader('SUPPORT', cs),
                  const SizedBox(height: 8),
                  _settingsCard(
                    cs,
                    children: [
                      _buildNavItem(
                        icon: Icons.help_outline_rounded,
                        iconBg: cs.surfaceContainerLow,
                        iconColor: cs.onSurfaceVariant,
                        title: 'Help & FAQ',
                        subtitle: 'Get help and find answers',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                      _divider(cs),
                      _buildNavItem(
                        icon: Icons.bug_report_outlined,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        title: 'Report a Bug',
                        subtitle: 'Help us improve Techmates',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                      _divider(cs),
                      _buildNavItem(
                        icon: Icons.mail_outline_rounded,
                        iconBg: _brandBlueContainer,
                        iconColor: _brandBlue,
                        title: 'Contact Us',
                        subtitle: 'Reach out to our team',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── About Section ──
                  _sectionHeader('ABOUT', cs),
                  const SizedBox(height: 8),
                  _settingsCard(
                    cs,
                    children: [
                      _buildNavItem(
                        icon: Icons.info_outline_rounded,
                        iconBg: cs.surfaceContainerLow,
                        iconColor: cs.onSurfaceVariant,
                        title: 'App Version',
                        subtitle: _appVersion,
                        cs: cs,
                        showChevron: false,
                      ),
                      _divider(cs),
                      _buildNavItem(
                        icon: Icons.description_outlined,
                        iconBg: cs.surfaceContainerLow,
                        iconColor: cs.onSurfaceVariant,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                      _divider(cs),
                      _buildNavItem(
                        icon: Icons.privacy_tip_outlined,
                        iconBg: cs.surfaceContainerLow,
                        iconColor: cs.onSurfaceVariant,
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        cs: cs,
                        onTap: () => _showComingSoon(cs),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Danger Zone ──
                  _sectionHeader('DANGER ZONE', cs),
                  const SizedBox(height: 8),
                  _settingsCard(
                    cs,
                    borderColor: _brandRedLight.withOpacity(0.3),
                    children: [
                      _buildNavItem(
                        icon: Icons.delete_forever_rounded,
                        iconBg: _brandRedContainer,
                        iconColor: _brandRed,
                        title: 'Delete Account',
                        subtitle: 'Permanently remove your account',
                        cs: cs,
                        titleColor: _brandRed,
                        onTap: () => _showDeleteAccountDialog(cs),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ──
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Techmates',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Made with ❤️ for developers',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionHeader(String label, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS CARD CONTAINER
  // ═══════════════════════════════════════════════════════════════

  Widget _settingsCard(
    ColorScheme cs, {
    required List<Widget> children,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: borderColor ?? cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Divider(
      height: 1,
      indent: 56,
      color: cs.outlineVariant,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVACY TOGGLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPrivacyToggle(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isPrivate ? _brandRedContainer : _brandBlueContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isPrivate
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              size: 18,
              color: _isPrivate ? _brandRedLight : _brandBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Account',
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _isPrivate
                      ? 'Only approved followers can see your activity'
                      : 'Anyone can follow you and see your activity',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isPrivate,
            onChanged: _togglePrivacy,
            activeColor: _brandRedLight,
            activeTrackColor: _brandRedContainer,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACCOUNT INFO
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAccountInfo(ColorScheme cs) {
    final email = _profile?.email ?? _auth.user?.email ?? 'Unknown';
    final college = _profile?.college ?? 'Not set';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  college,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATIONS TOGGLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNotificationsToggle(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _notificationsEnabled
                  ? _brandBlueContainer
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              size: 18,
              color: _notificationsEnabled
                  ? _brandBlue
                  : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _notificationsEnabled
                      ? 'Get notified about new opportunities'
                      : 'Notifications are turned off',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: _brandBlue,
            activeTrackColor: _brandBlueContainer,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DARK MODE TOGGLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDarkModeToggle(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _darkMode
                  ? const Color(0xFF263238)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _darkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              size: 18,
              color: _darkMode
                  ? const Color(0xFFFFC107)
                  : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _darkMode ? 'Dark theme is active' : 'Light theme is active',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _darkMode,
            onChanged: _toggleDarkMode,
            activeColor: const Color(0xFFFFC107),
            activeTrackColor: const Color(0xFF263238),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION ITEM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNavItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ColorScheme cs,
    Color? titleColor,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
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
                      color: titleColor ?? cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.outline,
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showComingSoon(ColorScheme cs) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming soon! ✨',
          style: GoogleFonts.sora(fontSize: 12),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: cs.inverseSurface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteAccountDialog(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _brandRed, size: 24),
            const SizedBox(width: 10),
            Text(
              'Delete Account',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _brandRed,
              ),
            ),
          ],
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data, connections, and DevCard will be permanently removed.',
          style: GoogleFonts.sora(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(cs);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _brandRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.sora(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
