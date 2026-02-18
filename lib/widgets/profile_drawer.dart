import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/user_role_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/regular_admin_dashboard_screen.dart';
import 'smart_avatar.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/about_us_screen.dart';

class ProfileDrawer extends StatelessWidget {
  final String displayName;
  final String email;

  const ProfileDrawer({
    super.key,
    required this.displayName,
    required this.email,
  });

  // ── Brand colors ──
  static const Color _black = Color(0xFF111827);
  static const Color _blue = Color(0xFF1565C0);
  static const Color _red = Color(0xFFDC2626);
  static const Color _grey = Color(0xFF6B7280);
  static const Color _lightGrey = Color(0xFFF3F4F6);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _muted = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final roleService = UserRoleService();

    Color badgeColor = _grey;
    String badgeText = "STUDENT";
    IconData badgeIcon = Icons.school_rounded;

    if (roleService.isSuperAdmin) {
      badgeColor = _red;
      badgeText = "SUPER ADMIN";
      badgeIcon = Icons.shield_rounded;
    } else if (roleService.isAdmin) {
      badgeColor = _blue;
      badgeText = "ADMIN";
      badgeIcon = Icons.admin_panel_settings_rounded;
    }

    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════
            // PROFILE HEADER
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  const SmartAvatar(size: 56, isEditable: true),
                  const SizedBox(width: 14),
                  // Name + Email + Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _black,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _muted,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 11, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 0.8, color: _border, margin: const EdgeInsets.symmetric(horizontal: 20)),

            // ═══════════════════════════════════════════════
            // MENU ITEMS (SCROLLABLE TOP)
            // ═══════════════════════════════════════════════
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // ── Bookmarks (FIRST) ──
                  _DrawerItem(
                    icon: Icons.bookmark_border_rounded,
                    label: "Bookmarks",
                    subtitle: "Your saved opportunities",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                      );
                    },
                  ),

                  // ── Admin Dashboard (if admin) ──
                  if (roleService.isSuperAdmin || roleService.isAdmin) ...[
                    Container(height: 0.6, color: _border, margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4)),
                    _DrawerItem(
                      icon: Icons.dashboard_outlined,
                      label: "Dashboard",
                      subtitle: roleService.isSuperAdmin ? "Super admin controls" : "Admin controls",
                      iconColor: roleService.isSuperAdmin ? _red : _blue,
                      onTap: () {
                        Navigator.pop(context);
                        if (roleService.isSuperAdmin) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegularAdminDashboardScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            // ═══════════════════════════════════════════════
            // BOTTOM SECTION (FIXED)
            // ═══════════════════════════════════════════════
            Column(
              children: [
                Container(height: 0.8, color: _border, margin: const EdgeInsets.symmetric(horizontal: 20)),
                const SizedBox(height: 4),

                // ── Help & Support ──
                _DrawerItem(
                  icon: Icons.headset_mic_outlined,
                  label: "Help & Support",
                  subtitle: "Get help or send feedback",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _HelpSupportScreen()),
                    );
                  },
                ),

                // ── About Us ──
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: "About Us",
                  subtitle: "Learn about Techmates",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 4),
                Container(height: 0.8, color: _border, margin: const EdgeInsets.symmetric(horizontal: 20)),

                // ── Logout ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleLogout(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _red.withValues(alpha: 0.12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: _red),
                            SizedBox(width: 8),
                            Text(
                              "Log out",
                              style: TextStyle(
                                color: _red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      final auth = AuthService();
      await auth.signOut();
      await UserRoleService().clear();
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

// ═════════════════════════════════════════════════════════════
// DRAWER ITEM WIDGET
// ═════════════════════════════════════════════════════════════
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ProfileDrawer._lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor ?? ProfileDrawer._grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: ProfileDrawer._black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProfileDrawer._muted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: ProfileDrawer._muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HELP & SUPPORT — FULL SCREEN
// ═════════════════════════════════════════════════════════════
class _HelpSupportScreen extends StatefulWidget {
  const _HelpSupportScreen();

  @override
  State<_HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<_HelpSupportScreen> {
  final TextEditingController _controller = TextEditingController();

  static const Color _black = Color(0xFF111827);
  static const Color _blue = Color(0xFF1565C0);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _body = Color(0xFF4B5563);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _lightGrey = Color(0xFFF3F4F6);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _black,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contact section ──
            const Text(
              "How can we help?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _black, height: 1.2),
            ),
            const SizedBox(height: 6),
            const Text(
              "Choose an option below or send us a message directly.",
              style: TextStyle(fontSize: 13, color: _body, height: 1.4),
            ),
            const SizedBox(height: 24),

            // ── Quick actions ──
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.email_outlined,
                    label: "Email Us",
                    subtitle: "yourgirinaik@gmail.com",
                    onTap: () async {
                      final Uri uri = Uri(scheme: 'mailto', path: 'yourgirinaik@gmail.com', query: 'subject=Techmates Support');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bug_report_outlined,
                    label: "Report Bug",
                    subtitle: "Something broken?",
                    onTap: () async {
                      final Uri uri = Uri(scheme: 'mailto', path: 'yourgirinaik@gmail.com', query: 'subject=Techmates Bug Report');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Divider ──
            Container(height: 0.8, color: _border),
            const SizedBox(height: 24),

            // ── Send feedback ──
            const Text(
              "Send us a message",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _black),
            ),
            const SizedBox(height: 4),
            const Text(
              "We read every message and respond within 24 hours.",
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: const TextStyle(fontSize: 13.5, color: _black),
              decoration: InputDecoration(
                hintText: "Describe your issue, suggestion, or question...",
                hintStyle: const TextStyle(color: _muted, fontSize: 13),
                filled: true,
                fillColor: _lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _border, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _blue, width: 1.2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final feedback = _controller.text.trim();
                    if (feedback.isNotEmpty) {
                      final Uri uri = Uri(
                        scheme: 'mailto',
                        path: 'yourgirinaik@gmail.com',
                        query: 'subject=Techmates Feedback&body=${Uri.encodeComponent(feedback)}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                        if (mounted) Navigator.pop(context);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Send",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
            Container(height: 0.8, color: _border),
            const SizedBox(height: 24),

            // ── FAQ Section ──
            const Text(
              "Frequently Asked",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _black),
            ),
            const SizedBox(height: 14),
            const _FaqItem(
              question: "How do I apply for an internship?",
              answer: "Tap on any internship card and click the 'Apply' button. You'll be redirected to the application page.",
            ),
            const _FaqItem(
              question: "How do I bookmark opportunities?",
              answer: "Tap the bookmark icon on any opportunity card. Access your saved items from the Bookmarks section in the menu.",
            ),
            const _FaqItem(
              question: "How do I update my profile?",
              answer: "Tap on your profile photo in the drawer to edit your details and upload a new avatar.",
            ),
            const _FaqItem(
              question: "Who can post opportunities?",
              answer: "Only admins can create and manage opportunities. Students can browse, apply, and bookmark them.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Quick action card ──
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF1565C0)),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF9CA3AF),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FAQ Item (expandable) ──
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.answer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
