import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/devcard/devcard_model.dart';
import '../models/opportunity_model.dart';
import '../utils/proxy_url.dart';

/// Centralizes all Supabase queries for the Home Screen.
/// Every query has a 5-second timeout and fails gracefully.
/// FIX 7: Cache-first pattern — show cached data instantly, refresh in background.
class HomeDataService {
  static final HomeDataService _instance = HomeDataService._internal();
  factory HomeDataService() => _instance;
  HomeDataService._internal();

  final SupabaseClient _client = SupabaseClientManager.instance;

  // FIX 7: Cache keys and duration
  static const _closingSoonKey = 'home_closing_soon_v1';
  static const _elitePicksKey = 'home_elite_picks_v1';
  static const _newThisWeekKey = 'home_new_this_week_v1';
  static const _collegePulseKey = 'home_college_pulse_v1';
  static const _leaderboardKey = 'home_leaderboard_v1';
  static const _homeCacheDuration = Duration(hours: 2);

  // ── Generic cache helpers ──
  Future<void> _saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[HomeDataService] Cache save error for $key: $e');
    }
  }

  Future<dynamic> _loadCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('${key}_time');
      if (cacheTime == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (age > _homeCacheDuration.inMilliseconds) return null;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('[HomeDataService] Cache load error for $key: $e');
      return null;
    }
  }

  // ── Closing Soon (deadlines within 7 days) ──
  Future<List<Map<String, dynamic>>> fetchClosingSoon() async {
    // Try cache first
    final cached = await _loadCache(_closingSoonKey);
    if (cached != null) {
      debugPrint('[HomeDataService] Closing soon: cache hit');
      unawaited(_refreshClosingSoonInBackground());
      return (cached as List).cast<Map<String, dynamic>>();
    }
    return _fetchClosingSoonFromNetwork();
  }

  Future<void> _refreshClosingSoonInBackground() async {
    try { await _fetchClosingSoonFromNetwork(); } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchClosingSoonFromNetwork() async {
    try {
      final today = DateTime.now();
      final nowDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final sevenDaysLater = today.add(const Duration(days: 7));
      final sevenDate =
          '${sevenDaysLater.year}-${sevenDaysLater.month.toString().padLeft(2, '0')}-${sevenDaysLater.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _client
            .from('internship_details')
            .select('opportunity_id, title, company, deadline')
            .gte('deadline', nowDate)
            .lte('deadline', sevenDate)
            .order('deadline', ascending: true)
            .limit(4)
            .timeout(const Duration(seconds: 5)),
        _client
            .from('hackathon_details')
            .select('opportunity_id, title, company, deadline')
            .gte('deadline', nowDate)
            .lte('deadline', sevenDate)
            .order('deadline', ascending: true)
            .limit(4)
            .timeout(const Duration(seconds: 5)),
        _client
            .from('event_details')
            .select('opportunity_id, title, organiser, apply_deadline')
            .gte('apply_deadline', nowDate)
            .lte('apply_deadline', sevenDate)
            .order('apply_deadline', ascending: true)
            .limit(4)
            .timeout(const Duration(seconds: 5)),
      ]);

      final List<Map<String, dynamic>> merged = [];

      for (final item in results[0] as List) {
        merged.add({
          'id': item['opportunity_id'],
          'type': 'internship',
          'title': item['title'] ?? '',
          'company': item['company'] ?? '',
          'deadline': item['deadline'],
        });
      }
      for (final item in results[1] as List) {
        merged.add({
          'id': item['opportunity_id'],
          'type': 'hackathon',
          'title': item['title'] ?? '',
          'company': item['company'] ?? '',
          'deadline': item['deadline'],
        });
      }
      for (final item in results[2] as List) {
        merged.add({
          'id': item['opportunity_id'],
          'type': 'event',
          'title': item['title'] ?? '',
          'company': item['organiser'] ?? '',
          'deadline': item['apply_deadline'],
        });
      }

      merged.sort((a, b) {
        final da = DateTime.tryParse(a['deadline'] ?? '') ?? DateTime(2099);
        final db = DateTime.tryParse(b['deadline'] ?? '') ?? DateTime(2099);
        return da.compareTo(db);
      });
      final result = merged.take(6).toList();
      await _saveCache(_closingSoonKey, result);
      return result;
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchClosingSoon error: $e');
      return [];
    }
  }

  // ── Elite Picks ──
  Future<List<Map<String, dynamic>>> fetchElitePicks() async {
    final cached = await _loadCache(_elitePicksKey);
    if (cached != null) {
      debugPrint('[HomeDataService] Elite picks: cache hit');
      unawaited(_refreshElitePicksInBackground());
      return (cached as List).cast<Map<String, dynamic>>();
    }
    return _fetchElitePicksFromNetwork();
  }

  Future<void> _refreshElitePicksInBackground() async {
    try { await _fetchElitePicksFromNetwork(); } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchElitePicksFromNetwork() async {
    try {
      final today = DateTime.now();
      final nowDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      var response = await _client
          .from('internship_details')
          .select(
              'opportunity_id, title, company, stipend, deadline, emp_type, tags, duration, location')
          .eq('is_elite', true)
          .gte('deadline', nowDate)
          .order('deadline', ascending: true)
          .limit(5)
          .timeout(const Duration(seconds: 5));

      if ((response as List).isEmpty) {
        response = await _client
            .from('internship_details')
            .select(
                'opportunity_id, title, company, stipend, deadline, emp_type, tags, duration')
            .gte('deadline', nowDate)
            .order('deadline', ascending: true)
            .limit(3)
            .timeout(const Duration(seconds: 5));
      }

      final result = (response as List).cast<Map<String, dynamic>>();
      await _saveCache(_elitePicksKey, result);
      return result;
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchElitePicks error: $e');
      return [];
    }
  }

  // ── New This Week (4 most recent) ──
  Future<List<Opportunity>> fetchNewThisWeek() async {
    final cached = await _loadCache(_newThisWeekKey);
    if (cached != null) {
      debugPrint('[HomeDataService] New this week: cache hit');
      unawaited(_refreshNewThisWeekInBackground());
      try {
        return (cached as List)
            .map((json) => Opportunity.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // If parse fails, fall through to network
      }
    }
    return _fetchNewThisWeekFromNetwork();
  }

  Future<void> _refreshNewThisWeekInBackground() async {
    try { await _fetchNewThisWeekFromNetwork(); } catch (_) {}
  }

  Future<List<Opportunity>> _fetchNewThisWeekFromNetwork() async {
    try {
      final response = await _client
          .from('opportunities')
          .select('*, internship_details(*), hackathon_details(*), event_details(*)')
          .order('created_at', ascending: false)
          .limit(4)
          .timeout(const Duration(seconds: 5));

      final result = (response as List)
          .map((json) => Opportunity.fromJson(json))
          .toList();
      // Cache the raw JSON for faster restore
      await _saveCache(_newThisWeekKey, response);
      return result;
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
    // Try cache first
    final cached = await _loadCache('${_collegePulseKey}_$collegeId');
    if (cached != null) {
      debugPrint('[HomeDataService] College pulse: cache hit');
      unawaited(_refreshCollegePulseInBackground(collegeId));
      return cached as Map<String, dynamic>;
    }
    return _fetchCollegePulseFromNetwork(collegeId);
  }

  Future<void> _refreshCollegePulseInBackground(String collegeId) async {
    try { await _fetchCollegePulseFromNetwork(collegeId); } catch (_) {}
  }

  Future<Map<String, dynamic>> _fetchCollegePulseFromNetwork(String collegeId) async {
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

      final userProfile = await _client
          .from('profiles')
          .select('college')
          .eq('id', _client.auth.currentUser?.id ?? '')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      final result = {
        'count': countResult.count,
        'students': students as List,
        'collegeName': userProfile?['college'] ?? '',
      };
      await _saveCache('${_collegePulseKey}_$collegeId', result);
      return result;
    } catch (e) {
      debugPrint('❌ [HomeDataService] fetchCollegePulse error: $e');
      return {'count': 0, 'students': [], 'collegeName': ''};
    }
  }

  // ── College Leaderboard (top 3 by GitHub score) ──
  Future<List<Map<String, dynamic>>> fetchCollegeLeaderboard(
      String? collegeId) async {
    if (collegeId == null || collegeId.isEmpty) return [];
    // Try cache first
    final cached = await _loadCache('${_leaderboardKey}_$collegeId');
    if (cached != null) {
      debugPrint('[HomeDataService] Leaderboard: cache hit');
      unawaited(_refreshLeaderboardInBackground(collegeId));
      return (cached as List).cast<Map<String, dynamic>>();
    }
    return _fetchLeaderboardFromNetwork(collegeId);
  }

  Future<void> _refreshLeaderboardInBackground(String collegeId) async {
    try { await _fetchLeaderboardFromNetwork(collegeId); } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboardFromNetwork(String collegeId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id ?? '';

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

      final devcards = await _client
          .from('devcard_cache')
          .select('user_id, analyzed_data')
          .inFilter('user_id', userIds)
          .timeout(const Duration(seconds: 5));

      final devcardMap = <String, Map<String, dynamic>>{};
      for (final dc in devcards as List) {
        final uid = dc['user_id']?.toString() ?? '';
        final data = dc['analyzed_data'];
        if (uid.isNotEmpty && data is Map) {
          devcardMap[uid] = Map<String, dynamic>.from(data);
        }
      }

      final students = <Map<String, dynamic>>[];
      for (final p in profileList) {
        final uid = p['id']?.toString() ?? '';
        final ad = devcardMap[uid];
        final sb = ad?['scoreBreakdown'] as Map<String, dynamic>?;

        final score = (sb?['total'] as num?)?.toInt() ?? 0;
        final rankInfo = DevScoreBreakdown.rankInfoFromScore((score / 10).round());

        students.add({
          'id': uid,
          'isCurrentUser': uid == currentUserId,
          'name': (p['name'] as String?) ?? 'Unknown',
          'branch': (p['branch'] as String?) ?? '',
          'year': (p['year'] as String?) ?? '',
          'avatarUrl': proxyUrl(p['avatar_url'] as String?),
          'score': score,
          'commits': (ad?['totalCommitsLastYear'] as num?)?.toInt() ?? 0,
          'repos': (ad?['totalPublicRepos'] as num?)?.toInt() ?? 0,
          'rank': rankInfo['rank']!,
          'topLanguages': _extractTopLanguages(ad),
        });
      }

      students.sort(
          (a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final top3 = students.take(3).toList();

      for (int i = 0; i < top3.length; i++) {
        top3[i]['collegeRank'] = i + 1;
      }

      await _saveCache('${_leaderboardKey}_$collegeId', top3);
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
