import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import 'dashboard_summary_card.dart';

class DashboardSummaryGrid extends StatefulWidget {
  final DashboardService service;
  final Function(int tabIndex) onNavigate;

  const DashboardSummaryGrid({super.key, required this.service, required this.onNavigate});

  @override
  State<DashboardSummaryGrid> createState() => _DashboardSummaryGridState();
}

class _DashboardSummaryGridState extends State<DashboardSummaryGrid> {
  static const Color _ink = Color(0xFF0D0D1A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  Map<String, int> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.service.getStudentCount(),
        widget.service.getAdminCount(),
        widget.service.getSuperAdminCount(),
        widget.service.getOpportunityCount(),
        widget.service.getInternshipCount(),
        widget.service.getHackathonCount(),
        widget.service.getEventCount(),
        widget.service.getInactiveUserCount(),
        widget.service.getRoleChangesCount(),
      ]);

      if (mounted) {
        setState(() {
          _stats = {
            'students': results[0],
            'admins': results[1],
            'super_admins': results[2],
            'opportunities': results[3],
            'internships': results[4],
            'hackathons': results[5],
            'events': results[6],
            'inactive_users': results[7],
            'role_changes': results[8],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _ink)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red))),
      );
    }

    final totalUsers = (_stats['students'] ?? 0) + (_stats['admins'] ?? 0) + (_stats['super_admins'] ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HERO: Total Users ──
          GestureDetector(
            onTap: () => widget.onNavigate(1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ink, width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 14, color: _ink),
                            const SizedBox(width: 6),
                            const Text(
                              "TOTAL USERS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _muted,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "LIVE",
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$totalUsers",
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Role breakdown column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _roleStat("STU", _stats['students'] ?? 0, const Color(0xFF10B981)),
                      const SizedBox(height: 6),
                      _roleStat("ADM", _stats['admins'] ?? 0, const Color(0xFF3B82F6)),
                      const SizedBox(height: 6),
                      _roleStat("SA", _stats['super_admins'] ?? 0, const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Content stats: 2 columns ──
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Live Opps",
                  "${_stats['opportunities']}",
                  Icons.rocket_launch_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  "Internships",
                  "${_stats['internships']}",
                  Icons.laptop_mac_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Hackathons",
                  "${_stats['hackathons']}",
                  Icons.code_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  "Events",
                  "${_stats['events']}",
                  Icons.event_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Inactive",
                  "${_stats['inactive_users']}",
                  Icons.person_off_outlined,
                  const Color(0xFFEF4444),
                  onTap: () => widget.onNavigate(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  "Role Changes",
                  "${_stats['role_changes']}",
                  Icons.swap_horiz_rounded,
                  const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Role stat with colored tag
  Widget _roleStat(String tag, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4), width: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "$value",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Individual stat card — no bg fill, just border + icon accent
  Widget _statCard(String label, String value, IconData icon, Color accent, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: accent),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _muted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
