import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lib/core/supabase_client.dart';
import 'lib/services/home_feed_service.dart';

// A simple script to test the Supabase query
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseClientManager.initialize();

  try {
    print("Testing HomeFeedService query...");
    final service = HomeFeedService();
    final items = await service.fetchHomeFeed(page: 0, pageSize: 2);
    print("Successfully fetched ${items.length} items.");
    for (var item in items) {
      print("- ${item.type.name}: ${item.title} (Poster: ${item.posterName})");
    }
  } catch (e) {
    print("Error occurred while fetching data:");
    print(e);
  }
}
