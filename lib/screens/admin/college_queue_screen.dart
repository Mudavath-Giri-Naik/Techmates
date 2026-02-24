import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';

class CollegeQueueScreen extends StatefulWidget {
  const CollegeQueueScreen({super.key});

  @override
  State<CollegeQueueScreen> createState() => _CollegeQueueScreenState();
}

class _CollegeQueueScreenState extends State<CollegeQueueScreen> {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _green = Color(0xFF059669);
  static const Color _red = Color(0xFFEF4444);
  static const Color _border = Color(0xFFE8EAED);
  static const Color _fieldBg = Color(0xFFF9FAFB);

  final _client = SupabaseClientManager.instance;
  List<Map<String, dynamic>> _queueItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    try {
      setState(() => _isLoading = true);
      final response = await _client
          .from('college_domain_queue')
          .select()
          .eq('status', 'pending')
          .order('user_count', ascending: false);
      setState(() {
        _queueItems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [CollegeQueueScreen] Load error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getUsersForDomain(String domain) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, name, email, college_email, avatar_url')
          .eq('college_email_domain', domain);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [CollegeQueueScreen] Users fetch error: $e');
      return [];
    }
  }

  void _showApprovalSheet(Map<String, dynamic> item) {
    final nameController =
        TextEditingController(text: item['submitted_name'] ?? '');
    final codeController = TextEditingController();
    final stateController = TextEditingController();
    final domain = item['domain'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 18, color: _blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review Domain',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          Text(
                            domain,
                            style: const TextStyle(
                                fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // College name field
                _fieldLabel('OFFICIAL COLLEGE NAME'),
                const SizedBox(height: 6),
                _textField(nameController, 'e.g. VIT University'),
                const SizedBox(height: 16),

                // Code field
                _fieldLabel('COLLEGE CODE'),
                const SizedBox(height: 6),
                _textField(codeController, 'e.g. VIT_TN'),
                const SizedBox(height: 16),

                // State field
                _fieldLabel('STATE'),
                const SizedBox(height: 6),
                _textField(stateController, 'e.g. Tamil Nadu'),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Reject
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _rejectDomain(domain);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _red.withOpacity(0.3)),
                          ),
                          child: const Center(
                            child: Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Approve
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          final name = nameController.text.trim();
                          final code = codeController.text.trim();
                          final state = stateController.text.trim();

                          if (name.isEmpty || code.isEmpty || state.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('All fields are required'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          await _approveDomain(domain, name, code, state);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Approve & Map',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
      },
    );
  }

  Future<void> _approveDomain(
      String domain, String name, String code, String state) async {
    try {
      await _client.rpc('approve_college_domain', params: {
        'p_domain': domain,
        'p_name': name,
        'p_code': code,
        'p_state': state,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $domain approved as $name'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadQueue();
    } catch (e) {
      debugPrint('❌ [CollegeQueueScreen] Approve error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectDomain(String domain) async {
    try {
      await _client
          .from('college_domain_queue')
          .update({'status': 'rejected'})
          .eq('domain', domain);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$domain rejected'),
            backgroundColor: _muted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadQueue();
    } catch (e) {
      debugPrint('❌ [CollegeQueueScreen] Reject error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
        ),
      );
    }

    if (_queueItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 36, color: _green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Queue is clear',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No pending college domains',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQueue,
      color: _blue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _queueItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _queueItems[index];
          return _QueueItemTile(
            item: item,
            onTap: () => _showApprovalSheet(item),
            onExpand: () async =>
                await _getUsersForDomain(item['domain'] as String),
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _muted,
        letterSpacing: 1,
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        style:
            const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  QUEUE ITEM TILE — expandable to show users from that domain
// ────────────────────────────────────────────────────────────────

class _QueueItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final Future<List<Map<String, dynamic>>> Function() onExpand;

  const _QueueItemTile({
    required this.item,
    required this.onTap,
    required this.onExpand,
  });

  @override
  State<_QueueItemTile> createState() => _QueueItemTileState();
}

class _QueueItemTileState extends State<_QueueItemTile> {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _border = Color(0xFFE8EAED);

  bool _expanded = false;
  List<Map<String, dynamic>>? _users;
  bool _loadingUsers = false;

  Future<void> _toggleExpand() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _loadingUsers = true);
    final users = await widget.onExpand();
    setState(() {
      _users = users;
      _expanded = true;
      _loadingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final domain = item['domain'] as String? ?? '';
    final submittedName = item['submitted_name'] as String? ?? '';
    final userCount = item['user_count'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.domain_rounded,
                        size: 20, color: _blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Submitted as: $submittedName',
                          style:
                              const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$userCount user${userCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Expand button
                  GestureDetector(
                    onTap: _toggleExpand,
                    child: _loadingUsers
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: _muted),
                          )
                        : Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 22,
                            color: _muted,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded user list
          if (_expanded && _users != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFC),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(
                  top: BorderSide(color: _border.withOpacity(0.6)),
                ),
              ),
              child: _users!.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'No users found with this domain.',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      itemCount: _users!.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 16, color: _border.withOpacity(0.5)),
                      itemBuilder: (context, i) {
                        final user = _users![i];
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _blue.withOpacity(0.1),
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? Text(
                                      (user['name'] as String? ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _blue,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                  Text(
                                    user['college_email'] ?? user['email'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 10, color: _muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
