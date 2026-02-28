import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static Future<void> initialize() async {
    debugPrint('[INIT] Supabase initialize started');
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        authOptions: FlutterAuthClientOptions(
          localStorage: SharedPreferencesLocalStorage(
            persistSessionKey: 'supabase.auth.token',
          ),
        ),
      ).timeout(const Duration(seconds: 5));
      debugPrint('[INIT] Supabase initialize done');
    } on TimeoutException {
      debugPrint('[INIT] Supabase initialize TIMED OUT - proceeding anyway');
    } catch (e) {
      debugPrint('[INIT] Supabase initialize failed - proceeding anyway: $e');
    }
  }

  static SupabaseClient get instance => Supabase.instance.client;
}
