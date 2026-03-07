import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global default timeout for Supabase queries
const kDefaultQueryTimeout = Duration(seconds: 8);

class SupabaseClientManager {
  static bool _initialized = false;

  /// Dedicated SupabaseClient for realtime subscriptions.
  /// Points directly to Supabase Cloud to bypass the Cloudflare proxy
  /// which does not support WebSocket upgrades.
  static SupabaseClient? _realtimeClient;

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
      try {
        Supabase.instance;
        _initialized = true;
        debugPrint('[INIT] Supabase SDK is initialized despite timeout');
      } catch (_) {
        debugPrint('[INIT] Supabase SDK NOT initialized - app will show error');
      }
    } catch (e) {
      debugPrint('[INIT] Supabase initialize failed: $e');
      try {
        Supabase.instance;
        _initialized = true;
        debugPrint('[INIT] Supabase SDK is initialized despite error');
      } catch (_) {
        debugPrint('[INIT] Supabase SDK NOT initialized - app will show error');
      }
    }

    // Set up realtime client pointing directly to Supabase Cloud
    if (_initialized) {
      _initRealtimeClient();
    }
  }

  /// Creates a dedicated SupabaseClient for realtime, pointing to the
  /// Supabase Cloud URL. Auth token is synced from the main client.
  static void _initRealtimeClient() {
    final realtimeBaseUrl = dotenv.env['SUPABASE_REALTIME_URL'] ??
        'https://hmcxfkirqqifahhbipdt.supabase.co';
    // Convert wss:// to https:// if needed (SupabaseClient expects https://)
    final httpsUrl = realtimeBaseUrl
        .replaceFirst('wss://', 'https://')
        .replaceFirst('ws://', 'http://');
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    debugPrint('[INIT] Creating realtime client → $httpsUrl');

    _realtimeClient = SupabaseClient(
      httpsUrl,
      anonKey,
      realtimeClientOptions: RealtimeClientOptions(
        eventsPerSecond: 2,
        logLevel: RealtimeLogLevel.info,
      ),
    );

    // Sync auth token from main client to realtime client
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _realtimeClient!.realtime.setAuth(session.accessToken);
      debugPrint('[INIT] Realtime auth token set');
    }

    // Keep realtime auth token in sync on auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final newSession = data.session;
      if (newSession != null && _realtimeClient != null) {
        _realtimeClient!.realtime.setAuth(newSession.accessToken);
        debugPrint('[INIT] Realtime auth token refreshed');
      }
    });
  }

  static bool get isInitialized => _initialized;

  /// Main client for REST and Auth (via Cloudflare proxy).
  static SupabaseClient get instance => Supabase.instance.client;

  /// Dedicated client for realtime subscriptions (direct to Supabase Cloud).
  /// Falls back to main client if realtime client is not available.
  static SupabaseClient get realtimeInstance =>
      _realtimeClient ?? Supabase.instance.client;
}
