import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();

  factory AppUpdateService() {
    return _instance;
  }

  AppUpdateService._internal();

  bool _hasChecked = false;

  Future<void> checkForUpdate(BuildContext context) async {
    if (_hasChecked) {
      debugPrint('[UPDATE] Check done: skipped (already checked)');
      return;
    }

    _hasChecked = true;
    debugPrint('[UPDATE] Check started');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await Supabase.instance.client
          .from('app_update')
          .select('min_version')
          .eq('id', 1)
          .single()
          .timeout(const Duration(seconds: 4));

      final minVersion = response['min_version'] as String;

      if (_isUpdateRequired(currentVersion, minVersion)) {
        debugPrint('[UPDATE] Check done: force update required');
        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          useSafeArea: false,
          builder: (context) {
            return WillPopScope(
              onWillPop: () async => true,
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.system_update, size: 80, color: Color(0xFF1565C0)),
                            const SizedBox(height: 24),
                            const Text(
                              "Update Required",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Please update Techmates to continue",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _launchStore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              child: const Text("Update Now"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        debugPrint('[UPDATE] Check done: up to date');
      }
    } on TimeoutException {
      debugPrint('[UPDATE] TIMED OUT - skipping');
    } catch (e) {
      debugPrint('[UPDATE] Check done: failed ($e)');
    }
  }

  bool _isUpdateRequired(String currentVersion, String minVersion) {
    try {
      List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
      List<int> minParts = minVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        int current = (i < currentParts.length) ? currentParts[i] : 0;
        int min = (i < minParts.length) ? minParts[i] : 0;

        if (current < min) {
          return true;
        }
        if (current > min) {
          return false;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _launchStore() async {
    final url = Uri.parse("https://play.google.com/store/apps/details?id=com.techmates.app");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
