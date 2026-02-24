import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../services/college_service.dart';

class CollegesManagementScreen extends StatefulWidget {
  const CollegesManagementScreen({super.key});

  @override
  State<CollegesManagementScreen> createState() =>
      _CollegesManagementScreenState();
}

class _CollegesManagementScreenState extends State<CollegesManagementScreen> {
  // ── Palette (matches admin dashboard) ─────────────────────────────────
  static const Color _ink     = Color(0xFF1A1A2E);
  static const Color _muted   = Color(0xFF78909C);
  static const Color _blue    = Color(0xFF2563EB);
  static const Color _green   = Color(0xFF059669);
  static const Color _orange  = Color(0xFFF59E0B);
  static const Color _red     = Color(0xFFEF4444);
  static const Color _border  = Color(0xFFE8EAED);
  static const Color _fieldBg = Color(0xFFF9FAFB);

  final _college = CollegeService();
  final _client  = SupabaseClientManager.instance;

  List<Map<String, dynamic>> _allColleges      = [];
  List<Map<String, dynamic>> _filteredColleges  = [];
  bool _loading         = true;
  bool _showPendingOnly = false;
  String _searchQuery   = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _college.getAllColleges();
    if (!mounted) return;
    setState(() {
      _allColleges = data;
      _loading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> list = _allColleges;
    if (_showPendingOnly) {
      list = list.where((c) => c['is_verified'] != true).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final name   = (c['name']   as String? ?? '').toLowerCase();
        final domain = (c['domain'] as String? ?? '').toLowerCase();
        return name.contains(q) || domain.contains(q);
      }).toList();
    }
    _filteredColleges = list;
  }

  int get _totalCount    => _allColleges.length;
  int get _verifiedCount => _allColleges.where((c) => c['is_verified'] == true).length;
  int get _pendingCount  => _allColleges.where((c) => c['is_verified'] != true).length;

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Stats + search + filter ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              _statsRow(),
              const SizedBox(height: 12),
              _searchBar(),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── List ───────────────────────────────────────────────────────
        Expanded(child: _body()),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────

  Widget _statsRow() => Row(children: [
    _chip('Total: $_totalCount', _ink.withOpacity(0.06), _ink),
    const SizedBox(width: 8),
    _chip('Verified: $_verifiedCount', _green.withOpacity(0.08), _green),
    const SizedBox(width: 8),
    GestureDetector(
      onTap: () {
        setState(() { _showPendingOnly = !_showPendingOnly; _applyFilters(); });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _showPendingOnly ? _orange.withOpacity(0.15) : _orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: _showPendingOnly
            ? Border.all(color: _orange.withOpacity(0.5), width: 1.2)
            : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_showPendingOnly)
            Padding(padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.filter_alt_rounded, size: 11, color: _orange.withOpacity(0.8))),
          Text('Pending: $_pendingCount',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _orange)),
        ]),
      ),
    ),
    const Spacer(),
    // FAB-like add button
    GestureDetector(
      onTap: () => _openAddSheet(),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
      ),
    ),
  ]);

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
  );

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _searchBar() => Container(
    decoration: BoxDecoration(
      color: _fieldBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _border, width: 0.8),
    ),
    child: TextField(
      onChanged: (v) { setState(() { _searchQuery = v; _applyFilters(); }); },
      style: const TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w500),
      decoration: const InputDecoration(
        hintText: 'Search by name or domain…',
        hintStyle: TextStyle(color: Color(0xFFB0B7C3), fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: _muted),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );

  // ── Body list ─────────────────────────────────────────────────────────

  Widget _body() {
    if (_loading) {
      return const Center(
        child: SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: _ink)));
    }
    if (_filteredColleges.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 36, color: _muted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('No colleges found',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _muted)),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _blue,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        itemCount: _filteredColleges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _collegeCard(_filteredColleges[i]),
      ),
    );
  }

  // ── College card ──────────────────────────────────────────────────────

  Widget _collegeCard(Map<String, dynamic> c) {
    final name      = c['name']     as String? ?? '—';
    final domain    = c['domain']   as String? ?? '';
    final location  = c['location'] as String? ?? '';
    final state     = c['state']    as String? ?? '';
    final students  = c['no_of_students'] as int? ?? 0;
    final verified  = c['is_verified'] == true;
    final locStr    = [location, state].where((s) => s.isNotEmpty).join(', ');

    return GestureDetector(
      onTap: () => _showPendingOnly && !verified
          ? _openApproveSheet(c)
          : _openEditSheet(c),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.8),
          boxShadow: [BoxShadow(
            color: _ink.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: verified ? _green.withOpacity(0.08) : _orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.school_rounded, size: 20,
              color: verified ? _green : _orange)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
            if (domain.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2),
                child: Text(domain,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _muted))),
            if (locStr.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2),
                child: Text(locStr, style: const TextStyle(fontSize: 11, color: _muted))),
            const SizedBox(height: 6),
            Row(children: [
              _smallChip('$students student${students != 1 ? 's' : ''}',
                _blue.withOpacity(0.08), _blue),
              const SizedBox(width: 6),
              _smallChip(verified ? 'Verified' : 'Pending',
                verified ? _green.withOpacity(0.08) : _orange.withOpacity(0.1),
                verified ? _green : _orange),
              if (_showPendingOnly && !verified) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Approve',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _smallChip(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );

  // ═════════════════════════════════════════════════════════════════════════
  //  EDIT BOTTOM SHEET
  // ═════════════════════════════════════════════════════════════════════════

  void _openEditSheet(Map<String, dynamic> c) {
    final nameCtrl     = TextEditingController(text: c['name']        as String? ?? '');
    final codeCtrl     = TextEditingController(text: c['code']        as String? ?? '');
    final domainCtrl   = TextEditingController(text: c['domain']      as String? ?? '');
    final stateCtrl    = TextEditingController(text: c['state']       as String? ?? '');
    final locationCtrl = TextEditingController(text: c['location']    as String? ?? '');
    final urlCtrl      = TextEditingController(text: c['college_url'] as String? ?? '');
    bool isVerified    = c['is_verified'] == true;
    final students     = c['no_of_students'] as int? ?? 0;
    final collegeId    = c['id'] as String;
    bool saving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              const SizedBox(height: 14),
              // Title row
              Row(children: [
                Expanded(child: Text(c['name'] as String? ?? 'Edit College',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
                GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded, size: 20, color: _muted)),
              ]),
              const SizedBox(height: 18),

              _label('COLLEGE NAME'), const SizedBox(height: 6),
              _field(nameCtrl, 'College name'),
              const SizedBox(height: 14),

              _label('CODE'), const SizedBox(height: 6),
              _field(codeCtrl, 'e.g. VIT_TN', capitalization: TextCapitalization.characters),
              const SizedBox(height: 14),

              _label('DOMAIN'), const SizedBox(height: 6),
              _field(domainCtrl, 'college.ac.in'),
              const SizedBox(height: 14),

              _label('STATE'), const SizedBox(height: 6),
              _field(stateCtrl, 'e.g. Tamil Nadu'),
              const SizedBox(height: 14),

              _label('LOCATION'), const SizedBox(height: 6),
              _field(locationCtrl, 'City, State'),
              const SizedBox(height: 14),

              _label('COLLEGE URL'), const SizedBox(height: 6),
              _field(urlCtrl, 'https://college.ac.in'),
              const SizedBox(height: 14),

              // Verified toggle
              Row(children: [
                const Expanded(child: Text('Mark as Verified',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink))),
                Switch.adaptive(
                  value: isVerified,
                  activeColor: _green,
                  onChanged: (v) => setSheetState(() => isVerified = v),
                ),
              ]),
              const SizedBox(height: 6),
              // Student count (read-only)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _fieldBg, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.people_outline_rounded, size: 15, color: _muted),
                  const SizedBox(width: 8),
                  Text('$students student${students != 1 ? 's' : ''} linked',
                    style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border)),
                    child: const Center(child: Text('Cancel',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted))),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: GestureDetector(
                  onTap: saving ? null : () async {
                    if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                      _snack(ctx, 'Name and Code are required.', _red); return;
                    }
                    setSheetState(() => saving = true);
                    try {
                      await _college.updateCollege(collegeId, {
                        'name': nameCtrl.text.trim(),
                        'code': codeCtrl.text.trim().toUpperCase(),
                        'domain': domainCtrl.text.trim(),
                        'state': stateCtrl.text.trim(),
                        'location': locationCtrl.text.trim(),
                        'college_url': urlCtrl.text.trim(),
                        'is_verified': isVerified,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack(context, 'College updated. All linked profiles synced.', _green);
                      _load();
                    } catch (_) {
                      setSheetState(() => saving = false);
                      _snack(ctx, 'Update failed. Please try again.', _red);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: saving ? _blue.withOpacity(0.5) : _blue,
                      borderRadius: BorderRadius.circular(10)),
                    child: Center(child: saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                )),
              ]),
            ],
          )),
        );
      }),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  ADD COLLEGE SHEET
  // ═════════════════════════════════════════════════════════════════════════

  void _openAddSheet() {
    final nameCtrl     = TextEditingController();
    final codeCtrl     = TextEditingController();
    final domainCtrl   = TextEditingController();
    final stateCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final urlCtrl      = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              const SizedBox(height: 14),
              Row(children: [
                const Expanded(child: Text('Add College',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
                GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded, size: 20, color: _muted)),
              ]),
              const SizedBox(height: 18),

              _label('COLLEGE NAME *'), const SizedBox(height: 6),
              _field(nameCtrl, 'College name'),
              const SizedBox(height: 14),

              _label('CODE *'), const SizedBox(height: 6),
              _field(codeCtrl, 'e.g. VIT_TN', capitalization: TextCapitalization.characters),
              const SizedBox(height: 14),

              _label('DOMAIN *'), const SizedBox(height: 6),
              _field(domainCtrl, 'college.ac.in'),
              const SizedBox(height: 14),

              _label('STATE'), const SizedBox(height: 6),
              _field(stateCtrl, 'e.g. Tamil Nadu'),
              const SizedBox(height: 14),

              _label('LOCATION'), const SizedBox(height: 6),
              _field(locationCtrl, 'City, State'),
              const SizedBox(height: 14),

              _label('COLLEGE URL'), const SizedBox(height: 6),
              _field(urlCtrl, 'https://college.ac.in'),
              const SizedBox(height: 22),

              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border)),
                    child: const Center(child: Text('Cancel',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted))),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: GestureDetector(
                  onTap: saving ? null : () async {
                    final name   = nameCtrl.text.trim();
                    final code   = codeCtrl.text.trim();
                    final domain = domainCtrl.text.trim();
                    if (name.isEmpty || code.isEmpty || domain.isEmpty) {
                      _snack(ctx, 'Name, Code and Domain are required.', _red); return;
                    }
                    setSheetState(() => saving = true);
                    try {
                      // Check duplicate domain
                      final existing = await _client
                          .from('colleges').select('id')
                          .eq('domain', domain.toLowerCase())
                          .maybeSingle();
                      if (existing != null) {
                        setSheetState(() => saving = false);
                        _snack(ctx, 'This domain is already registered.', _red); return;
                      }
                      await _client.from('colleges').insert({
                        'name': name,
                        'code': code.toUpperCase(),
                        'domain': domain.toLowerCase(),
                        'state': stateCtrl.text.trim(),
                        'location': locationCtrl.text.trim(),
                        'college_url': urlCtrl.text.trim(),
                        'is_verified': true,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack(context, 'College added successfully.', _green);
                      _load();
                    } catch (_) {
                      setSheetState(() => saving = false);
                      _snack(ctx, 'Failed to add college.', _red);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: saving ? _green.withOpacity(0.5) : _green,
                      borderRadius: BorderRadius.circular(10)),
                    child: Center(child: saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add College',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                )),
              ]),
            ],
          )),
        );
      }),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  APPROVE (PENDING) SHEET
  // ═════════════════════════════════════════════════════════════════════════

  void _openApproveSheet(Map<String, dynamic> c) {
    final nameCtrl     = TextEditingController(text: c['name']        as String? ?? '');
    final codeCtrl     = TextEditingController(text: c['code']        as String? ?? '');
    final stateCtrl    = TextEditingController(text: c['state']       as String? ?? '');
    final locationCtrl = TextEditingController(text: c['location']    as String? ?? '');
    final urlCtrl      = TextEditingController(text: c['college_url'] as String? ?? '');
    final domain       = c['domain'] as String? ?? '';
    final students     = c['no_of_students'] as int? ?? 0;
    bool saving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school_rounded, size: 18, color: _orange),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Approve College',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                    Text(domain,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _muted)),
                  ],
                )),
                GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded, size: 20, color: _muted)),
              ]),
              const SizedBox(height: 4),
              Text('$students student${students != 1 ? 's' : ''} waiting',
                style: TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),

              _label('OFFICIAL NAME'), const SizedBox(height: 6),
              _field(nameCtrl, 'e.g. VIT University'),
              const SizedBox(height: 14),

              _label('CODE'), const SizedBox(height: 6),
              _field(codeCtrl, 'e.g. VIT_TN', capitalization: TextCapitalization.characters),
              const SizedBox(height: 14),

              _label('STATE'), const SizedBox(height: 6),
              _field(stateCtrl, 'e.g. Tamil Nadu'),
              const SizedBox(height: 14),

              _label('LOCATION'), const SizedBox(height: 6),
              _field(locationCtrl, 'City, State'),
              const SizedBox(height: 14),

              _label('COLLEGE URL'), const SizedBox(height: 6),
              _field(urlCtrl, 'https://college.ac.in'),
              const SizedBox(height: 22),

              GestureDetector(
                onTap: saving ? null : () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  if (name.isEmpty || code.isEmpty) {
                    _snack(ctx, 'Name and Code are required.', _red); return;
                  }
                  setSheetState(() => saving = true);
                  try {
                    await _client.rpc('approve_college_domain', params: {
                      'p_domain':      domain,
                      'p_college_name': name,
                      'p_college_code': code.toUpperCase(),
                      'p_state':       stateCtrl.text.trim(),
                      'p_location':    locationCtrl.text.trim(),
                      'p_college_url': urlCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _snack(context, 'Approved. $students student profile${students != 1 ? 's' : ''} updated.', _green);
                    _load();
                  } catch (_) {
                    setSheetState(() => saving = false);
                    _snack(ctx, 'Approval failed. Please try again.', _red);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: saving ? _green.withOpacity(0.5) : _green,
                    borderRadius: BorderRadius.circular(10)),
                  child: Center(child: saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Approve & Sync',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
            ],
          )),
        );
      }),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Shared helpers
  // ═════════════════════════════════════════════════════════════════════════

  Widget _handle() => Center(child: Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))));

  Widget _label(String t) => Text(t,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 1));

  Widget _field(TextEditingController ctrl, String hint,
      {TextCapitalization capitalization = TextCapitalization.none}) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8)),
      child: TextField(
        controller: ctrl,
        textCapitalization: capitalization,
        style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}
