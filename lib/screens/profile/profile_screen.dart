import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_role_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/profile/profile_header_card.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/regular_admin_dashboard_screen.dart';
import '../devcard/devcard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final ProfileService _profileService = ProfileService();

  UserProfile? _userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _primeRoleCache();
  }

  Future<void> _primeRoleCache() async {
    final user = _auth.user;
    if (user == null) return;
    await UserRoleService().fetchAndCacheRole(user.id);
    if (mounted) setState(() {});
  }

  Future<void> _fetchProfile() async {
    final user = _auth.user;
    if (user != null) {
      final profile = await _profileService.fetchProfile(user.id);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDashboard() async {
    final roleService = UserRoleService();
    if (roleService.isSuperAdmin) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
      return;
    }

    if (roleService.isAdmin) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegularAdminDashboardScreen()),
      );
    }
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    try {
      await _auth.signOut();
      await UserRoleService().clear();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildDevCardTile() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: const Icon(Icons.code_rounded, color: Color(0xFF8B5CF6)),
        title: const Text(
          'Dev Card',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Your GitHub analytics'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DevCardScreen()),
        ),
      ),
    );
  }

  Widget _buildDashboardTile() {
    final roleService = UserRoleService();
    if (!(roleService.isSuperAdmin || roleService.isAdmin)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Icon(
          Icons.dashboard_outlined,
          color: roleService.isSuperAdmin ? const Color(0xFFDC2626) : const Color(0xFF1565C0),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(roleService.isSuperAdmin ? 'Super admin controls' : 'Admin controls'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _openDashboard,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
          label: const Text(
            'Log out',
            style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0x1FDC2626)),
            backgroundColor: const Color(0x0FDC2626),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile != null
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      ProfileHeaderCard(profile: _userProfile!),
                      _buildDevCardTile(),
                      _buildDashboardTile(),
                      _buildLogoutButton(),
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'Profile not found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
    );
  }
}
