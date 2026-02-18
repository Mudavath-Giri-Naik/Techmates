import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/admin/dashboard_summary_grid.dart';
import '../../widgets/admin/user_management_tab.dart';
import '../../core/supabase_client.dart';

class RegularAdminDashboardScreen extends StatefulWidget {
  const RegularAdminDashboardScreen({super.key});

  @override
  State<RegularAdminDashboardScreen> createState() => _RegularAdminDashboardScreenState();
}

class _RegularAdminDashboardScreenState extends State<RegularAdminDashboardScreen> with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _border = Color(0xFFE8EAED);

  late TabController _tabController;
  final DashboardService _service = DashboardService();
  bool _isLoading = true;
  bool _isAuthorized = false;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final client = SupabaseClientManager.instance;
      final userId = client.auth.currentUser?.id;

      if (userId == null) throw "User not logged in";

      final response = await client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      final role = response?['role'] as String? ?? 'student';

      if (role == 'admin' || role == 'super_admin') {
        if (mounted) setState(() => _isAuthorized = true);
      } else {
        if (mounted) setState(() => _isAuthorized = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isAuthorized = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _ink)),
      );
    }

    if (!_isAuthorized) {
      return _buildAccessDenied();
    }

    final currentUser = SupabaseClientManager.instance.auth.currentUser;
    final displayName = currentUser?.userMetadata?['full_name'] ?? currentUser?.userMetadata?['name'] ?? 'Admin';

    final List<_TabItem> tabs = [
      _TabItem(Icons.grid_view_rounded, "Overview"),
      _TabItem(Icons.people_outline_rounded, "Users"),
    ];

    return MainLayout(
      titleWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF43A047),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                displayName,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "ADMIN",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E88E5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Tab navigation ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isActive = _currentTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? _ink : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 18,
                            color: isActive ? _ink : _muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? _ink : _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(height: 0.6, color: _border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                        child: Row(
                          children: [
                            Icon(Icons.show_chart_rounded, size: 14, color: _muted),
                            SizedBox(width: 6),
                            Text(
                              "QUICK STATS",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _muted,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DashboardSummaryGrid(service: _service, onNavigate: (i) {
                        if (i < 2) _navigateToTab(i);
                      }),
                    ],
                  ),
                ),
                // Users (read-only)
                UserManagementTab(service: _service, readOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFF1E88E5)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Access Restricted",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Admin privileges required",
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Go Back",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  _TabItem(this.icon, this.label);
}
