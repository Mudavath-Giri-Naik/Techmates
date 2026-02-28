import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/devcard/devcard_model.dart';
import '../models/opportunity_model.dart';

/// Centralizes all Supabase queries for the Home Screen.
/// Every query has a 5-second timeout and fails gracefully.
class HomeDataService {
  static final HomeDataService _instance = HomeDataService._internal();
  factory HomeDataService() => _instance;
  HomeDataService._internal();

  final SupabaseClient _client = SupabaseClientManager.instance;

  // ── Closing Soon (deadlines within 7 days) ──
  // Queries detail tables directly for reliability.
  Future<List<Map<String, dynamic>>> fetchClosingSoon() async {
    try {
      // deadline columns are `date` type → use YYYY-MM-DD format
      final today = DateTime.now();
      final nowDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final sevenDaysLater = today.add(const Duration(days: 7));
      final sevenDate =
          '${sevenDaysLater.year}-${sevenDaysLater.month.toString().padLeft(2, '0')}-${sevenDaysLater.day.toString().padLeft(2, '0')}';

      debugPrint('📅 [HomeDataService] Closing Soon range: $nowDate → $sevenDate');

      final results = await Future.wait([
        // Query 1 — Internships
        _client
            .from('internship_details')
            .select('opportunity_id, title, company, deadline')
            .gte('deadline', nowDate)
            .lte('deadline', sevenDate)
            .order('deadline', ascending: true)
            .limit(4)
            .timeout(const Duration(seconds: 5)),
        // Query 2 — Hackathons
        _client
            .from('hackathon_details')
            .select('opportunity_id, title, company, deadline')
            .gte('deadline', nowDate)
            .lte('deadline', sevenDate)
            .order('deadline', ascending: true)
            .limit(4)
            .timeout(const Duration(seconds: 5)),
        // Query 3 — Events
        _client
            .from('event_details')
            .select('opportunity_id, title, organiser, apply_deadline')
            .gte('apply_deadline', nowDate)
            .lte('apply_deadline', sevenDate)
            .order('apply_deadline', ascending: true)
            .limit(4)
            .timeout(const Duration(seconds: 5)),
      ]);

      debugPrint('📅 [HomeDataService] Internships: ${(results[0] as List).length}, Hackathons: ${(results[1] as List).length}, Events: ${(results[2] as List).length}');

      final List<Map<String, dynamic>> merged = [];

      // Internships
      for (final item in results[0] as List) {
        merged.add({
          'id': item['opportunity_id'],
          'type': 'internship',
          'title': item['title'] ?? '',
          'company': item['company'] ?? '',
          'deadline': item['deadline'],
        });
      }
      // Hackathons
      for (final item in results[1] as List) {
        merged.add({
          'id': item['opportunity_id'],
          'type': 'hackathon',
          'title': item['title'] ?? '',
          'company': item['company'] ?? '',
          'deadline': item['deadline'],
        });
      }
      // Events — map organiser→company, apply_deadline→deadline
      for (final item in results[2] as List) {
        merged.add({
          'id': item['opportunity_id'],
          'type': 'event',
          'title': item['title'] ?? '',
          'company': item['organiser'] ?? '',
          'deadline': item['apply_deadline'],
        });
      }

      // Sort by deadline ASC, take first 6
      merged.sort((a, b) {
        final da = DateTime.tryParse(a['deadline'] ?? '') ?? DateTime(2099);
        final db = DateTime.tryParse(b['deadline'] ?? '') ?? DateTime(2099);
        return da.compareTo(db);
      });
      debugPrint('📅 [HomeDataService] Total closing soon: ${merged.length}');
      return merged.take(6).toList();
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchClosingSoon error: $e');
      return [];
    }
  }

  // ── Elite Picks ──
  // Queries internship_details directly. Has fallback.
  Future<List<Map<String, dynamic>>> fetchElitePicks() async {
    try {
      // deadline is `date` type → use YYYY-MM-DD format
      final today = DateTime.now();
      final nowDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      debugPrint('🏆 [HomeDataService] Elite Picks query: deadline >= $nowDate, is_elite = true');

      var response = await _client
          .from('internship_details')
          .select(
              'opportunity_id, title, company, stipend, deadline, emp_type, tags, duration, location')
          .eq('is_elite', true)
          .gte('deadline', nowDate)
          .order('deadline', ascending: true)
          .limit(5)
          .timeout(const Duration(seconds: 5));

      debugPrint('🏆 [HomeDataService] Elite Picks response: ${(response as List).length} items');

      // Fallback: if no elite picks, fetch latest 3 internships
      if ((response as List).isEmpty) {
        debugPrint('🏆 [HomeDataService] No elite picks found, using fallback');
        response = await _client
            .from('internship_details')
            .select(
                'opportunity_id, title, company, stipend, deadline, emp_type, tags, duration')
            .gte('deadline', nowDate)
            .order('deadline', ascending: true)
            .limit(3)
            .timeout(const Duration(seconds: 5));
        debugPrint('🏆 [HomeDataService] Fallback response: ${(response as List).length} items');
      }

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchElitePicks error: $e');
      return [];
    }
  }

  // ── New This Week (4 most recent) ──
  Future<List<Opportunity>> fetchNewThisWeek() async {
    try {
      final response = await _client
          .from('opportunities')
          .select('*, internship_details(*), hackathon_details(*), event_details(*)')
          .order('created_at', ascending: false)
          .limit(4)
          .timeout(const Duration(seconds: 5));

      return (response as List)
          .map((json) => Opportunity.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchNewThisWeek error: $e');
      return [];
    }
  }

  // ── Count new ops since last visit ──
  Future<int> fetchNewOpsSince(DateTime lastVisit) async {
    try {
      final count = await _client
          .from('opportunities')
          .select()
          .gte('created_at', lastVisit.toUtc().toIso8601String())
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 5));
      return count.count;
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchNewOpsSince error: $e');
      return 0;
    }
  }

  // ── Total Ops Count ──
  Future<int> fetchTotalOpsCount() async {
    try {
      final count = await _client
          .from('opportunities')
          .select()
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 5));
      return count.count;
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchTotalOpsCount error: $e');
      return 0;
    }
  }

  // ── College Pulse ──
  Future<Map<String, dynamic>> fetchCollegePulse(String? collegeId) async {
    if (collegeId == null || collegeId.isEmpty) {
      return {'count': 0, 'students': [], 'collegeName': ''};
    }
    try {
      final countResult = await _client
          .from('profiles')
          .select()
          .eq('college_id', collegeId)
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 5));

      final students = await _client
          .from('profiles')
          .select('id, name, avatar_url')
          .eq('college_id', collegeId)
          .neq('id', _client.auth.currentUser?.id ?? '')
          .order('created_at')
          .limit(3)
          .timeout(const Duration(seconds: 5));

      // Get college name from current user's profile
      final userProfile = await _client
          .from('profiles')
          .select('college')
          .eq('id', _client.auth.currentUser?.id ?? '')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      return {
        'count': countResult.count,
        'students': students as List,
        'collegeName': userProfile?['college'] ?? '',
      };
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchCollegePulse error: $e');
      return {'count': 0, 'students': [], 'collegeName': ''};
    }
  }

  // ── College Leaderboard (top 3 by GitHub score) ──
  Future<List<Map<String, dynamic>>> fetchCollegeLeaderboard(
      String? collegeId) async {
    if (collegeId == null || collegeId.isEmpty) return [];
    try {
      final currentUserId = _client.auth.currentUser?.id ?? '';

      // Fetch college profiles (including current user)
      final profiles = await _client
          .from('profiles')
          .select('id, name, branch, year, avatar_url, github_url')
          .eq('college_id', collegeId)
          .eq('is_active', true)
          .limit(20)
          .timeout(const Duration(seconds: 5));

      final profileList = profiles as List;
      if (profileList.isEmpty) return [];

      final userIds = profileList.map((p) => p['id'].toString()).toList();

      // Fetch devcard_cache for those users
      final devcards = await _client
          .from('devcard_cache')
          .select('user_id, analyzed_data')
          .inFilter('user_id', userIds)
          .timeout(const Duration(seconds: 5));

      // Build lookup map: user_id -> analyzed_data
      final devcardMap = <String, Map<String, dynamic>>{};
      for (final dc in devcards as List) {
        final uid = dc['user_id']?.toString() ?? '';
        final data = dc['analyzed_data'];
        if (uid.isNotEmpty && data is Map) {
          devcardMap[uid] = Map<String, dynamic>.from(data);
        }
      }

      // Merge and build student list
      final students = <Map<String, dynamic>>[];
      for (final p in profileList) {
        final uid = p['id']?.toString() ?? '';
        final ad = devcardMap[uid]; // analyzed_data
        final sb = ad?['scoreBreakdown'] as Map<String, dynamic>?;

        final score = (sb?['total'] as num?)?.toInt() ?? 0;
        // Always compute rank from score — never trust cached strings
        final rankInfo = DevScoreBreakdown.rankInfoFromScore(score);

        students.add({
          'id': uid,
          'isCurrentUser': uid == currentUserId,
          'name': (p['name'] as String?) ?? 'Unknown',
          'branch': (p['branch'] as String?) ?? '',
          'year': (p['year'] as String?) ?? '',
          'avatarUrl': p['avatar_url'] as String?,
          'score': score,
          'commits': (ad?['totalCommitsLastYear'] as num?)?.toInt() ?? 0,
          'repos': (ad?['totalPublicRepos'] as num?)?.toInt() ?? 0,
          'rank': rankInfo['rank']!,
          'topLanguages': _extractTopLanguages(ad),
        });
      }

      // Sort by score DESC, take top 3
      students.sort(
          (a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final top3 = students.take(3).toList();

      // Assign college rank
      for (int i = 0; i < top3.length; i++) {
        top3[i]['collegeRank'] = i + 1;
      }

      debugPrint(
          '🏆 [HomeDataService] College leaderboard: ${top3.length} students');
      return top3;
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchCollegeLeaderboard error: $e');
      return [];
    }
  }

  List<String> _extractTopLanguages(Map<String, dynamic>? analyzedData) {
    if (analyzedData == null) return [];
    final langs = analyzedData['topLanguages'];
    if (langs == null || langs is! List) return [];
    return langs
        .take(3)
        .map((l) => (l is Map ? (l['name']?.toString() ?? '') : l.toString()))
        .where((s) => s.isNotEmpty)
        .toList()
        .cast<String>();
  }
}
