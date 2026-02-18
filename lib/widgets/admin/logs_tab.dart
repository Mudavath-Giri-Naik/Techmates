import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/dashboard_service.dart';

class LogsTab extends StatefulWidget {
  final DashboardService service;

  const LogsTab({super.key, required this.service});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _border = Color(0xFFE8EAED);
  static const Color _surface = Color(0xFFF8F9FA);

  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Segment control ──
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border, width: 0.6),
            ),
            child: Row(
              children: [
                _segment(0, Icons.swap_horiz_rounded, "Role Changes"),
                const SizedBox(width: 4),
                _segment(1, Icons.work_outline_rounded, "Opportunities"),
              ],
            ),
          ),
        ),
        // ── Content ──
        Expanded(
          child: _selectedSegment == 0
              ? _RoleLogsList(service: widget.service)
              : _OpportunityLogsList(service: widget.service),
        ),
      ],
    );
  }

  Widget _segment(int index, IconData icon, String label) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? _ink : _muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _ink : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────
// ROLE LOGS
// ────────────────────────────────────

class _RoleLogsList extends StatelessWidget {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _border = Color(0xFFE8EAED);

  final DashboardService service;
  const _RoleLogsList({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.fetchRoleLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _ink));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 40, color: _border),
                const SizedBox(height: 10),
                const Text("No role changes recorded", style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final targetName = log['target']?['name'] ?? 'Unknown User';
            final oldRole = log['old_role'] ?? '';
            final newRole = log['new_role'] ?? '';
            final actorName = log['actor']?['name'] ?? 'System';
            final timestamp = log['created_at'];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 0.6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFF6D00), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          targetName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _rolePill(oldRole, isOld: true),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded, size: 12, color: _muted),
                            ),
                            _rolePill(newRole, isOld: false),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "by $actorName · ${_formatDate(timestamp)}",
                          style: const TextStyle(fontSize: 10.5, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rolePill(String role, {required bool isOld}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOld ? const Color(0xFFE53935).withOpacity(0.06) : const Color(0xFF2E7D32).withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOld ? const Color(0xFFE53935).withOpacity(0.15) : const Color(0xFF2E7D32).withOpacity(0.15),
          width: 0.6,
        ),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOld ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
          letterSpacing: 0.3,
          decoration: isOld ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return "";
    // If timestamp doesn't have offset info, treat it as UTC
    final timeStr = (timestamp.endsWith('Z') || timestamp.contains('+')) 
        ? timestamp 
        : '$timestamp\Z';
    final dt = DateTime.parse(timeStr).toLocal();
    print("🕑 [DEBUG] LogsTab Role: Input='$timestamp' -> Parsed='$timeStr' -> Local='$dt'");
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

// ────────────────────────────────────
// OPPORTUNITY LOGS
// ────────────────────────────────────

class _OpportunityLogsList extends StatelessWidget {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _border = Color(0xFFE8EAED);

  final DashboardService service;
  const _OpportunityLogsList({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.fetchOpportunityLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _ink));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline_rounded, size: 40, color: _border),
                const SizedBox(height: 10),
                const Text("No opportunity logs", style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final title = log['opportunity']?['title'] ?? 'Unknown Opportunity';
            final action = log['action'] ?? 'Unknown';
            final role = log['role'] ?? '';
            final actorName = log['actor']?['name'] ?? 'Unknown';
            final timestamp = log['created_at'];

            Color actionColor = const Color(0xFF1E88E5);
            IconData actionIcon = Icons.edit_rounded;
            String actionLabel = "Updated";
            if (action == 'INSERT') {
              actionColor = const Color(0xFF2E7D32);
              actionIcon = Icons.add_circle_outline_rounded;
              actionLabel = "Created";
            } else if (action == 'DELETE') {
              actionColor = const Color(0xFFE53935);
              actionIcon = Icons.remove_circle_outline_rounded;
              actionLabel = "Deleted";
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 0.6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(actionIcon, color: actionColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                actionLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: actionColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "by $actorName ($role) · ${_formatDate(timestamp)}",
                          style: const TextStyle(fontSize: 10.5, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return "";
    // If timestamp doesn't have offset info, treat it as UTC
    final timeStr = (timestamp.endsWith('Z') || timestamp.contains('+')) 
        ? timestamp 
        : '$timestamp\Z';
    final dt = DateTime.parse(timeStr).toLocal();
    print("🕑 [DEBUG] LogsTab Opp: Input='$timestamp' -> Parsed='$timeStr' -> Local='$dt'");
    return DateFormat('MMM d, y h:mm a').format(dt);
  }
}
