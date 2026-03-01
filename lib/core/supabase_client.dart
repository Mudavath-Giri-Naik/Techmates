import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global default timeout for Supabase queries
const kDefaultQueryTimeout = Duration(seconds: 8);

class SupabaseClientManager {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('[INIT] Supabase initialize started');

    final proxyUrl = dotenv.env['SUPABASE_URL'] ?? 'https://api.girinaik.in';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    debugPrint('[INIT] Using URL: $proxyUrl');

    try {
      await Supabase.initialize(
        url: proxyUrl,
        anonKey: anonKey,
        realtimeClientOptions: RealtimeClientOptions(
          eventsPerSecond: 2,
          logLevel: RealtimeLogLevel.info,
        ),
        authOptions: FlutterAuthClientOptions(
          localStorage: SharedPreferencesLocalStorage(
            persistSessionKey: 'supabase.auth.token',
          ),
          autoRefreshToken: true,
        ),
      ).timeout(const Duration(seconds: 8));

      _initialized = true;
      debugPrint('[INIT] Supabase initialize success with proxy URL');
    } on TimeoutException {
      debugPrint('[INIT] Supabase initialize TIMED OUT');
      // Check if SDK actually initialized despite the timeout
      try {
        Supabase.instance;
        _initialized = true;
        debugPrint('[INIT] Supabase SDK is initialized despite timeout');
      } catch (_) {
        debugPrint('[INIT] Supabase SDK NOT initialized - app will show error');
      }
    } catch (e) {
      debugPrint('[INIT] Supabase initialize failed: $e');
      // Check if SDK actually initialized despite the error
      try {
        Supabase.instance;
        _initialized = true;
        debugPrint('[INIT] Supabase SDK is initialized despite error');
      } catch (_) {
        debugPrint('[INIT] Supabase SDK NOT initialized - app will show error');
      }
    }
  }

  static bool get isInitialized => _initialized;

  static SupabaseClient get instance => Supabase.instance.client;
}
