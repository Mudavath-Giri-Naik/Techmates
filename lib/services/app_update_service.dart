import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();

  factory AppUpdateService() {
    return _instance;
  }

  AppUpdateService._internal();

  bool _hasChecked = false;

  Future<void> checkForUpdate(BuildContext context) async {
    if (_hasChecked) {
      print("⚪ [UPDATE] Skipped (already checked)");
      return;
    }

    _hasChecked = true;
    print("🔵 [UPDATE] Checking for update...");

    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('🔵 [UPDATE] Current app version: $currentVersion');
      
      // 2. Fetch min_version from Supabase
      print('🔵 [UPDATE] Fetching app_update row...');
      final response = await Supabase.instance.client
          .from('app_update')
          .select('min_version')
          .eq('id', 1)
          .single();
      print('🔵 [UPDATE] Raw Supabase response: $response');

      final minVersion = response['min_version'] as String;

      print("🔵 [UPDATE] Min version from DB: $minVersion");

      // 3. Compare versions
      if (_isUpdateRequired(currentVersion, minVersion)) {
        print("🔴 [UPDATE] FORCE UPDATE TRIGGERED");
        
        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          useSafeArea: false, // Covers status bar/notch
          builder: (context) {
            return WillPopScope(
              onWillPop: () async => true, // Allow system back button to dismiss
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
                            const Icon(Icons.system_update, size: 80, color: Colors.deepPurple),
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
                                backgroundColor: Colors.deepPurple,
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
        print("🟢 [UPDATE] App up to date");
      }
    } on PostgrestException catch (e, st) {
      print('🟡 [UPDATE][ERROR] PostgrestException while checking update');
      print('🟡 [UPDATE][ERROR] code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      print('🟡 [UPDATE][STACK] $st');
    } catch (e, st) {
      print("🟢 [UPDATE] Error checking update, skipping: $e");
      print('🟢 [UPDATE][STACK] $st');
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
    } catch (e) {
      print("Error parsing version: $e");
      return false; // Safe default
    }
  }

  static void _launchStore() async {
    final url = Uri.parse("https://play.google.com/store/apps/details?id=com.techmates.app");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }
}
