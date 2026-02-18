import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/dashboard_service.dart';

class UserManagementTab extends StatefulWidget {
  final DashboardService service;
  final bool readOnly;

  const UserManagementTab({super.key, required this.service, this.readOnly = false});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _border = Color(0xFFE8EAED);
  static const Color _surface = Color(0xFFF8F9FA);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isActionLoading = false;

  String _roleFilter = 'all';
  bool? _statusFilter;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await widget.service.fetchUsers(
        searchQuery: _searchController.text,
        roleFilter: _roleFilter,
        statusFilter: _statusFilter,
        page: 0,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _updateRole(String userId, String email, String oldRole, String newRole) async {
    if (oldRole == newRole) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: _ink),
            SizedBox(width: 8),
            Text("Role Change", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ),
        content: Text(
          "Change $email\nfrom $oldRole → $newRole?",
          style: const TextStyle(fontSize: 13, color: _muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: _muted)),
          ),
          Container(
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await widget.service.updateUserRole(
        userId: userId,
        email: email,
        oldRole: oldRole,
        newRole: newRole,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Role updated successfully"), backgroundColor: Color(0xFF2E7D32)),
      );
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _toggleStatus(String userId, bool currentStatus) async {
    setState(() => _isActionLoading = true);
    try {
      await widget.service.toggleUserStatus(userId, !currentStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(currentStatus ? "User deactivated" : "User activated"),
        backgroundColor: currentStatus ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
      ));
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + Filters ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13, color: _ink),
                  decoration: InputDecoration(
                    hintText: "Search users…",
                    hintStyle: const TextStyle(color: _muted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _fetchUsers();
                            },
                            child: const Icon(Icons.close_rounded, size: 16, color: _muted),
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _fetchUsers(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chipGroup([
                      _chip("All", _roleFilter == 'all', () => setState(() { _roleFilter = 'all'; _fetchUsers(); })),
                      _chip("Students", _roleFilter == 'student', () => setState(() { _roleFilter = 'student'; _fetchUsers(); })),
                      _chip("Admins", _roleFilter == 'admin', () => setState(() { _roleFilter = 'admin'; _fetchUsers(); })),
                      _chip("Super", _roleFilter == 'super_admin', () => setState(() { _roleFilter = 'super_admin'; _fetchUsers(); })),
                    ]),
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: _border,
                    ),
                    _chipGroup([
                      _chip("All Status", _statusFilter == null, () => setState(() { _statusFilter = null; _fetchUsers(); })),
                      _chip("Active", _statusFilter == true, () => setState(() { _statusFilter = true; _fetchUsers(); }), activeColor: const Color(0xFF2E7D32)),
                      _chip("Inactive", _statusFilter == false, () => setState(() { _statusFilter = false; _fetchUsers(); }), activeColor: const Color(0xFFE53935)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Count bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _surface,
          child: Row(
            children: [
              Text(
                "${_users.length} user${_users.length != 1 ? 's' : ''}",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.3),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchUsers,
                child: const Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: _muted),
                    SizedBox(width: 4),
                    Text("Refresh", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── User list ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _ink))
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 48, color: _border),
                          const SizedBox(height: 12),
                          const Text("No users found", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _muted)),
                          const SizedBox(height: 4),
                          const Text("Try adjusting your filters", style: TextStyle(fontSize: 12, color: _muted)),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          itemCount: _users.length,
                          padding: const EdgeInsets.only(top: 4, bottom: 20),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return _buildUserTile(user);
                          },
                        ),
                        if (_isActionLoading)
                          Container(
                            color: Colors.white.withOpacity(0.6),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final role = user['role'] ?? 'student';
    final isActive = user['is_active'] ?? true;
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '';

    Color roleColor = _muted;
    IconData roleIcon = Icons.person_rounded;
    if (role == 'admin') {
      roleColor = const Color(0xFF1E88E5);
      roleIcon = Icons.shield_rounded;
    } else if (role == 'super_admin') {
      roleColor = const Color(0xFFE53935);
      roleIcon = Icons.admin_panel_settings_rounded;
    } else {
      roleColor = const Color(0xFF43A047);
      roleIcon = Icons.school_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "INACTIVE",
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53935),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 11.5, color: _muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Role badge
                  Row(
                    children: [
                      Icon(roleIcon, size: 11, color: roleColor),
                      const SizedBox(width: 4),
                      Text(
                        role.toString().toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (!widget.readOnly)
              PopupMenuButton<String>(
                elevation: 2,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: const Icon(Icons.more_horiz_rounded, color: _muted, size: 18),
                onSelected: (value) {
                  if (value == 'toggle_status') {
                    _toggleStatus(user['id'], isActive);
                  } else if (value.startsWith('role_')) {
                    _updateRole(user['id'], email, role, value.substring(5));
                  }
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      enabled: false,
                      height: 28,
                      child: Text("CHANGE ROLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.8)),
                    ),
                    if (role != 'student')
                      const PopupMenuItem(
                        value: 'role_student',
                        child: Row(children: [
                          Icon(Icons.school_rounded, color: Color(0xFF43A047), size: 16),
                          SizedBox(width: 8),
                          Text("Student", style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                    if (role != 'admin')
                      const PopupMenuItem(
                        value: 'role_admin',
                        child: Row(children: [
                          Icon(Icons.shield_rounded, color: Color(0xFF1E88E5), size: 16),
                          SizedBox(width: 8),
                          Text("Admin", style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                    if (role != 'super_admin')
                      const PopupMenuItem(
                        value: 'role_super_admin',
                        child: Row(children: [
                          Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE53935), size: 16),
                          SizedBox(width: 8),
                          Text("Super Admin", style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                              color: isActive ? const Color(0xFFE53935) : const Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 8),
                          Text(isActive ? "Deactivate" : "Activate", style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _chipGroup(List<Widget> chips) {
    return Row(
      children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: c)).toList(),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final color = activeColor ?? _ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : _border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _muted,
          ),
        ),
      ),
    );
  }
}
