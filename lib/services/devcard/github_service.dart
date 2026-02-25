import 'package:supabase_flutter/supabase_flutter.dart';

class GitHubService {
  static String extractUsername(String githubUrl) {
    String username = githubUrl.trim();
    if (username.endsWith('/')) {
      username = username.substring(0, username.length - 1);
    }
    if (username.contains('github.com/')) {
      username = username.split('github.com/').last.replaceAll('/', '').trim();
    }
    return username;
  }

  static Future<Map<String, dynamic>> fetchDevCardData(
      String githubUrl) async {
    final username = extractUsername(githubUrl);
    final response = await Supabase.instance.client.functions.invoke(
      'github-devcard',
      body: {'github_username': username},
    );

    if (response.data == null) {
      throw Exception('No data returned from edge function');
    }

    final body = response.data as Map<String, dynamic>;
    if (body.containsKey('error')) {
      throw Exception(body['error']);
    }

    return body['data'] as Map<String, dynamic>;
  }
}
