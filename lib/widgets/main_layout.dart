import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import 'smart_avatar.dart';
import '../screens/edit_profile_screen.dart';
import '../services/profile_service.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title; // Optional override

  const MainLayout({
    super.key,
    required this.child,
    this.title = "Techmates",
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _auth = AuthService();
  final ProfileService _profileService = ProfileService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchProfileName();
  }

  Future<void> _fetchProfileName() async {
    final user = _auth.user;
    if (user != null) {
      final profile = await _profileService.fetchProfile(user.id);
      if (mounted) {
        setState(() {
          _userName = profile?.name;
        });
      }
    }
  }

  void _handleLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in to show correct avatar/name
    final userEmail = _auth.user?.email ?? "User";
    final displayName = _userName ?? "User";
    final initial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "U";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white, // Global White Background
      appBar: AppBar(
        backgroundColor: Colors.white, // Flat White AppBar
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
         // Dynamic Title Logic
        title: widget.title == 'Techmates' 
            ? RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: 'Tech', style: TextStyle(color: Colors.red)),
                    TextSpan(text: 'mates', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              )
            : Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SmartAvatar(
            size: 32, 
            isEditable: false,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(0), bottomRight: Radius.circular(0)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    const SmartAvatar(size: 72, isEditable: true),
                    const SizedBox(height: 16),
                    
                    // Name & Role
                    Row(
                      children: [
                        Text(
                          "Welcome $displayName", // Replace with real name if available
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _auth.isAdmin ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _auth.isAdmin ? "ADMIN" : "STUDENT",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _auth.isAdmin ? Colors.green : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Stats Row (Optional)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Applied", "0"),
                    _buildStatItem("Saved", "0"),
                    _buildStatItem("Posted", "0"),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),

              // 3. Menu Options
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(Icons.edit_outlined, "Edit Profile", () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.bookmark_outline, "Saved Opportunities", () {}),
                    _buildMenuItem(Icons.work_outline, "Applied Opportunities", () {}),
                    if (_auth.isAdmin)
                      _buildMenuItem(Icons.dashboard_outlined, "Admin Dashboard", () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      }, color: Colors.green),
                    _buildMenuItem(Icons.notifications_outlined, "Notifications", () {
                         Navigator.pop(context);
                         Navigator.of(context).push(
                           MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                         );
                    }),
                     Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                    _buildMenuItem(Icons.help_outline, "Help & Support", () {}),
                    _buildMenuItem(Icons.settings_outlined, "Settings", () {}),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade100),
              
              // 4. Logout
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                  icon: const Icon(Icons.logout, size: 20, color: Colors.red),
                  label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    alignment: Alignment.centerLeft,
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade600, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
