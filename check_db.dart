import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final file = File('lib/core/supabase_client.dart');
  final content = await file.readAsString();
  final urlMatch = RegExp(r"url\s*=\s*'([^']+)'").firstMatch(content);
  final keyMatch = RegExp(r"anonKey\s*=\s*'([^']+)'").firstMatch(content);
  
  if (urlMatch != null && keyMatch != null) {
    print('Please check the supabase dashboard to see if the RPC find_or_create_match is hardcoded to use game_type = "speed_match".');
  }
}
