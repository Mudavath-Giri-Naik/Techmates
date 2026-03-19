import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leaderboard_entry.dart';
import '../core/supabase_client.dart';

class LeaderboardService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  Future<int> _computeRankDelta(String userId, String scope, int newRank) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'prev_rank_${userId}_$scope';
    final prevRank = prefs.getInt(key) ?? newRank;
    final delta = prevRank - newRank; // +ve = improved rank
    await prefs.setInt(key, newRank);
    return delta;
  }

  /// Fetch class leaderboard: all profiles with same college + branch + year.
  /// Includes users who haven't played yet (brain_score = 0).
  /// If branch is 'All' or year is 0, it skips that filter.
  Future<List<LeaderboardEntry>> fetchClassLeaderboard({
    required String collegeId,
    required String branch,
    required int year,
    required String currentUserId,
  }) async {
    debugPrint('[Leaderboard] fetchClassLeaderboard: college=$collegeId branch=$branch year=$year');

    // Query from profiles so ALL users appear, even those without a brain_score
    var query = _client
        .from('profiles')
        .select('id, full_name, username, avatar_url, streak_days, user_brain_score(brain_score)')
        .eq('college_id', collegeId);

    if (branch != 'All') {
      // Techmates branch names are sometimes uppercase or mixed, ilike makes it safer
      query = query.ilike('branch', branch);
    }
    if (year != 0) {
      query = query.eq('year', year);
    }

    final response = await query;

    debugPrint('[Leaderboard] fetchClassLeaderboard rows=${(response as List).length}');

    return _buildEntries(response, currentUserId, 'class');
  }

  /// Fetch college leaderboard: all profiles with same college_id.
  Future<List<LeaderboardEntry>> fetchCollegeLeaderboard({
    required String collegeId,
    required String currentUserId,
  }) async {
    debugPrint('[Leaderboard] fetchCollegeLeaderboard: college=$collegeId');

    final response = await _client
        .from('profiles')
        .select('id, full_name, username, avatar_url, streak_days, branch, year, user_brain_score(brain_score)')
        .eq('college_id', collegeId);

    debugPrint('[Leaderboard] fetchCollegeLeaderboard rows=${(response as List).length}');

    return _buildEntries(response, currentUserId, 'college');
  }

  /// Helper to convert raw profile+brain_score rows into sorted LeaderboardEntry list.
  Future<List<LeaderboardEntry>> _buildEntries(
    dynamic response,
    String currentUserId,
    String scope,
  ) async {
    final List<dynamic> data = response;
    
    // Parse and sort by brain_score DESC
    final parsed = <_ParsedRow>[];
    for (var row in data) {
      final userId = row['id'] as String;
      final fullName = row['full_name'] as String? ?? 'User';
      final username = row['username'] as String?;
      final avatarUrl = row['avatar_url'] as String?;
      final streakDays = (row['streak_days'] as num?)?.toInt() ?? 0;

      // user_brain_score is a related table — Supabase returns it as a list or null
      int brainScore = 0;
      final brainScoreData = row['user_brain_score'];
      if (brainScoreData is List && brainScoreData.isNotEmpty) {
        brainScore = (brainScoreData[0]['brain_score'] as num?)?.toInt() ?? 0;
      } else if (brainScoreData is Map) {
        brainScore = (brainScoreData['brain_score'] as num?)?.toInt() ?? 0;
      }
      debugPrint('[Leaderboard] user=$fullName brainScoreRaw=$brainScoreData parsed=$brainScore');

      final branch = row['branch'] as String?;
      final year = (row['year'] as num?)?.toInt();

      parsed.add(_ParsedRow(
        userId: userId,
        fullName: fullName,
        username: username,
        avatarUrl: avatarUrl,
        brainScore: brainScore,
        streakDays: streakDays,
        branch: branch,
        year: year,
      ));
    }

    // Sort by brain_score descending, then by name for tie-breaking
    parsed.sort((a, b) {
      final cmp = b.brainScore.compareTo(a.brainScore);
      if (cmp != 0) return cmp;
      return a.fullName.compareTo(b.fullName);
    });

    final entries = <LeaderboardEntry>[];
    int rank = 1;
    for (var row in parsed) {
      final delta = await _computeRankDelta(row.userId, scope, rank);
      entries.add(LeaderboardEntry(
        userId: row.userId,
        fullName: row.fullName,
        username: row.username,
        avatarUrl: row.avatarUrl,
        brainScore: row.brainScore,
        rank: rank,
        rankDelta: delta,
        topDomain: null,
        totalSessions: null,
        streakDays: row.streakDays,
        isCurrentUser: row.userId == currentUserId,
        branch: row.branch,
        year: row.year,
      ));
      rank++;
    }

    debugPrint('[Leaderboard] _buildEntries: ${entries.length} entries, scope=$scope');
    return entries;
  }

  /// Domain leaderboard using the get_domain_leaderboard RPC.
  Future<List<LeaderboardEntry>> fetchDomainLeaderboard({
    required String collegeId,
    required String domainKey,
    required String scope,
    required String branch,
    required int year,
    required String currentUserId,
  }) async {
    debugPrint('[Leaderboard] fetchDomainLeaderboard: college=$collegeId domain=$domainKey scope=$scope');

    final response = await _client.rpc('get_domain_leaderboard', params: {
      'p_college_id': collegeId,
      'p_domain_key': domainKey,
      'p_limit': 100,
    });

    debugPrint('[Leaderboard] fetchDomainLeaderboard RPC rows=${(response as List).length}');

    final List<dynamic> data = response;
    List<LeaderboardEntry> entries = [];
    int displayRank = 1;

    if (data.isEmpty) return entries;

    // For class scope filtering, fetch branch/year info
    final userIds = data.map((e) => e['user_id'] as String).toList();

    final profilesResponse = await _client
      .from('profiles')
      .select('id, branch, year, streak_days')
      .inFilter('id', userIds);

    final profileLookup = {
      for (var item in (profilesResponse as List).cast<Map<String, dynamic>>())
        item['id'] as String: item
    };

    for (var row in data) {
      final userId = row['user_id'] as String;
      final profile = profileLookup[userId];

      if (profile == null) continue;

      // Filter for class scope
      if (scope == 'class') {
        if (profile['branch'] != branch || profile['year'] != year) {
          continue;
        }
      }

      final delta = await _computeRankDelta(userId, 'domain_${domainKey}_$scope', displayRank);

      entries.add(LeaderboardEntry(
        userId: userId,
        fullName: row['full_name'] as String? ?? 'User',
        username: row['username'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        brainScore: (row['domain_score'] as num?)?.toInt() ?? 0,
        rank: displayRank,
        rankDelta: delta,
        topDomain: domainKey,
        totalSessions: null,
        streakDays: profile['streak_days'] as int? ?? 0,
        isCurrentUser: userId == currentUserId,
      ));

      displayRank++;
    }

    return entries;
  }
}

/// Internal helper class for sorting leaderboard data.
class _ParsedRow {
  final String userId;
  final String fullName;
  final String? username;
  final String? avatarUrl;
  final int brainScore;
  final int streakDays;
  final String? branch;
  final int? year;

  _ParsedRow({
    required this.userId,
    required this.fullName,
    this.username,
    this.avatarUrl,
    required this.brainScore,
    required this.streakDays,
    this.branch,
    this.year,
  });
}
