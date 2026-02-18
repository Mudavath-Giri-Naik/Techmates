import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';

class AppSettingsTab extends StatefulWidget {
  final DashboardService service;

  const AppSettingsTab({super.key, required this.service});

  @override
  State<AppSettingsTab> createState() => _AppSettingsTabState();
}

class _AppSettingsTabState extends State<AppSettingsTab> {
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _muted = Color(0xFF78909C);
  static const Color _border = Color(0xFFE8EAED);
  static const Color _surface = Color(0xFFF8F9FA);

  final TextEditingController _versionController = TextEditingController();
  bool _isLoading = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await widget.service.fetchMinVersion();
    _versionController.text = v;
  }

  Future<void> _update() async {
    final value = _versionController.text.trim();
    debugPrint('[APP_SETTINGS][UPDATE] Tap detected with value="$value"');

    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    final isValid = value.isNotEmpty && regex.hasMatch(value);
    debugPrint('[APP_SETTINGS][UPDATE] Validation result: isValid=$isValid');

    if (!isValid) {
      if (mounted) {
        debugPrint('[APP_SETTINGS][UPDATE] Invalid version, showing snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid version like 1.0.0'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() { _isLoading = true; _saved = false; });
    try {
      await widget.service.updateMinVersion(value);
      if (mounted) {
        debugPrint('[APP_SETTINGS][UPDATE] Update succeeded, showing success snackbar');
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Version updated!"),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saved = false);
        });
      }
    } catch (e) {
      debugPrint('[APP_SETTINGS][UPDATE][ERROR] $e');
      if (mounted) {
        debugPrint('[APP_SETTINGS][UPDATE] Showing error snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          const Row(
            children: [
              Icon(Icons.settings_rounded, size: 16, color: _muted),
              SizedBox(width: 6),
              Text(
                "APP CONFIGURATION",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Version card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052CC).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.system_update_rounded, size: 16, color: Color(0xFF0052CC)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Minimum App Version",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Enforce update for older versions",
                          style: TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 0.8),
                  ),
                  child: TextField(
                    controller: _versionController,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      letterSpacing: 1,
                    ),
                    decoration: const InputDecoration(
                      hintText: "e.g. 1.0.0",
                      hintStyle: TextStyle(color: _muted, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _isLoading ? null : _update,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _saved ? const Color(0xFF2E7D32) : _ink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _saved ? Icons.check_rounded : Icons.save_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _saved ? "Saved!" : "Update Version",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Info section ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082), width: 0.6),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF57F17)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Users with app versions below the minimum will see a forced update screen and won't be able to use the app until they update.",
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
