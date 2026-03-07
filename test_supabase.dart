import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Standalone script to test Supabase directly
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final proxyUrl = dotenv.env['SUPABASE_URL'] ?? 'https://api.girinaik.in';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  print('🚀 Init Supabase with URL: $proxyUrl');
  
  await Supabase.initialize(
    url: proxyUrl,
    anonKey: anonKey,
  );
  
  final client = Supabase.instance.client;
  
  try {
    print('🚀 Running query...');
    final response = await client
          .from('opportunities')
          .select(
            '*, internship_details(*), hackathon_details(*), event_details(*), profiles!opportunities_posted_by_fkey(id, full_name, username, avatar_url, role)',
          )
          .order('created_at', ascending: false)
          .range(0, 9);
          
    print('✅ SUCCESS - got ${response.length} rows.');
    for (var row in response) {
      print('- ${row['id']} | type: ${row['type']}');
      final hack = row['hackathon_details'];
      print('  hackathon_details: $hack');
      final p = row['profiles'];
      if (p != null) {
          print('  poster: ${p['username']}');
      }
    }
  } catch (e) {
    print('❌ QUERY FAILED');
    print(e.toString());
  }
}
