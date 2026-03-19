import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/opportunity_feed_item.dart';
import '../models/hackathon_details_model.dart';
import '../models/internship_details_model.dart';
import '../models/event_details_model.dart';
import '../utils/proxy_url.dart';

/// Service that fetches a unified, chronological feed of opportunities
/// with poster profile data for the Home tab.
///
/// Supports local caching via SharedPreferences:
/// - On first load of a session → serves cached data instantly, then
///   refreshes from network in the background.
/// - Pull-to-refresh → forces a fresh network fetch.
/// - App restart → always fetches fresh from network, then caches.
class HomeFeedService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  // ── Cache keys ──────────────────────────────────────────────────
  static const _cacheKey = 'home_feed_cache_v1';

  // ── In-memory session cache ─────────────────────────────────────
  /// Holds the feed items that have been loaded during this app session.
  /// Cleared when the app process is killed.
  static List<OpportunityFeedItem>? _sessionCache;

  /// Whether we have already fetched fresh data from the network
  /// during this app session.
  static bool _hasRefreshedThisSession = false;

  // ── Public API ──────────────────────────────────────────────────

  /// Fetches a page of opportunities (all types merged) sorted by
  /// `created_at DESC`, joined with the poster's profile.
  ///
  /// [page] is 0-indexed. Each page contains [pageSize] items.
  /// If [forceRefresh] is true, skips all caches and fetches from network.
  Future<List<OpportunityFeedItem>> fetchHomeFeed({
    int page = 0,
    int pageSize = 10,
    bool forceRefresh = false,
  }) async {
    // ── Force refresh (pull-to-refresh) ──
    if (forceRefresh) {
      debugPrint('🔄 [HomeFeedService] Force refresh requested');
      final items = await _fetchFromNetwork(page: page, pageSize: pageSize);
      if (page == 0) {
        _sessionCache = items;
        _hasRefreshedThisSession = true;
        await _saveToLocalCache(items);
      }
      return items;
    }

    // ── Session cache hit (tab switch) ──
    if (page == 0 && _sessionCache != null && _sessionCache!.isNotEmpty) {
      debugPrint('⚡ [HomeFeedService] Serving from session cache '
          '(${_sessionCache!.length} items)');

      // Trigger a background network refresh if we haven't done one yet
      if (!_hasRefreshedThisSession) {
        _refreshInBackground(pageSize: pageSize);
      }
      return _sessionCache!;
    }

    // ── Local disk cache (app just opened) ──
    if (page == 0 && !_hasRefreshedThisSession) {
      final cached = await _loadFromLocalCache();
      if (cached != null && cached.isNotEmpty) {
        debugPrint('💾 [HomeFeedService] Serving from local cache '
            '(${cached.length} items), refreshing in background');
        _sessionCache = cached;
        _refreshInBackground(pageSize: pageSize);
        return cached;
      }
    }

    // ── No cache — fetch from network ──
    debugPrint('🌐 [HomeFeedService] Fetching from network (page $page)');
    final items = await _fetchFromNetwork(page: page, pageSize: pageSize);
    if (page == 0) {
      _sessionCache = items;
      _hasRefreshedThisSession = true;
      await _saveToLocalCache(items);
    }
    return items;
  }

  /// Returns the current session cache synchronously (may be null).
  /// Use this to pre-populate UI without showing a loading spinner.
  List<OpportunityFeedItem>? get cachedFeed => _sessionCache;

  /// Call this when the user triggers a manual refresh so the next
  /// `fetchHomeFeed` call will hit the network.
  void clearSessionCache() {
    _sessionCache = null;
    _hasRefreshedThisSession = false;
  }

  // ── Private: network fetch ──────────────────────────────────────

  Future<List<OpportunityFeedItem>> _fetchFromNetwork({
    required int page,
    required int pageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    try {
      final response = await _client
          .from('opportunities')
          .select(
            '*, internship_details(*), hackathon_details(*), event_details(*), postedProfile:profiles!opportunities_posted_by_fkey(id, full_name, username, avatar_url, role, branch, year, college_id, colleges!profiles_college_id_fkey(short_name, name)), createdProfile:profiles!opportunities_created_by_fkey(id, full_name, username, avatar_url, role, branch, year, college_id, colleges!profiles_college_id_fkey(short_name, name))',
          )
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> rows = response as List<dynamic>;
      final List<OpportunityFeedItem> items = [];

      for (final json in rows) {
        final item = _parseRow(json);
        if (item != null) items.add(item);
      }

      return items;
    } catch (e) {
      debugPrint('❌ [HomeFeedService] fetchHomeFeed error: $e');
      rethrow;
    }
  }

  /// Refreshes data from the network in the background without
  /// blocking the UI. Updates both session cache and local cache.
  Future<void> _refreshInBackground({required int pageSize}) async {
    try {
      final items = await _fetchFromNetwork(page: 0, pageSize: pageSize);
      _sessionCache = items;
      _hasRefreshedThisSession = true;
      await _saveToLocalCache(items);
      debugPrint('✅ [HomeFeedService] Background refresh complete '
          '(${items.length} items)');
    } catch (e) {
      debugPrint('⚠️ [HomeFeedService] Background refresh failed: $e');
      // Silently fail — cached data is already showing
    }
  }

  // ── Private: local cache (SharedPreferences) ────────────────────

  Future<void> _saveToLocalCache(List<OpportunityFeedItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      debugPrint('💾 [HomeFeedService] Saved ${items.length} items to local cache');
    } catch (e) {
      debugPrint('⚠️ [HomeFeedService] Cache save error: $e');
    }
  }

  Future<List<OpportunityFeedItem>?> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((e) =>
              OpportunityFeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [HomeFeedService] Cache load error: $e');
      return null;
    }
  }

  // ── Private: row parsing ────────────────────────────────────────

  /// Parse a single Supabase row into an [OpportunityFeedItem].
  OpportunityFeedItem? _parseRow(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.toLowerCase() ?? '';
    final opportunityId = json['id']?.toString() ?? '';

    // ── Determine type & build typed model ──
    OpportunityType? type;
    HackathonDetailsModel? hackathon;
    InternshipDetailsModel? internship;
    EventDetailsModel? event;
    bool isElite = false;
    String? postLink;
    String? applyLink;

    if (rawType.contains('hackathon')) {
      type = OpportunityType.hackathon;
      try {
        hackathon = HackathonDetailsModel.fromJson(json);
        postLink = hackathon.link;
        applyLink = hackathon.link;
      } catch (e) {
        debugPrint('⚠️ [HomeFeedService] Failed to parse hackathon: $e');
        return null;
      }
    } else if (rawType.contains('internship')) {
      type = OpportunityType.internship;
      try {
        internship = InternshipDetailsModel.fromJson(json);
        isElite = internship.isElite;
        postLink = internship.link;
        applyLink = internship.link;
      } catch (e) {
        debugPrint('⚠️ [HomeFeedService] Failed to parse internship: $e');
        return null;
      }
    } else if (rawType.contains('event')) {
      type = OpportunityType.event;
      try {
        event = EventDetailsModel.fromJson(json);
        postLink = event.locationLink;
        applyLink = event.applyLink;
      } catch (e) {
        debugPrint('⚠️ [HomeFeedService] Failed to parse event: $e');
        return null;
      }
    } else {
      // Unknown type — skip
      return null;
    }

    // ── Poster profile ──
    Map<String, dynamic>? profileData = json['postedProfile'] as Map<String, dynamic>?;
    if (profileData == null || profileData['id'] == null) {
      profileData = json['createdProfile'] as Map<String, dynamic>?;
    }
    final posterUserId = profileData?['id'] as String?;
    final posterName = profileData?['full_name'] as String?;
    final posterUsername = profileData?['username'] as String?;
    final posterAvatarUrl = proxyUrl(profileData?['avatar_url'] as String?);
    final posterRole = profileData?['role'] as String?;
    
    // Parse the nested college object if it exists
    final collegeData = profileData?['colleges'] as Map<String, dynamic>?;
    final posterCollege = collegeData?['short_name'] as String? ?? collegeData?['name'] as String?;
    
    final posterBranch = profileData?['branch'] as String?;
    final posterStudyYear = profileData?['year']?.toString();

    // ── Created at ──
    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
            DateTime.now();

    return OpportunityFeedItem(
      opportunityId: opportunityId,
      type: type,
      hackathon: hackathon,
      internship: internship,
      event: event,
      isElite: isElite,
      createdAt: createdAt,
      posterUserId: posterUserId,
      posterName: posterName,
      posterUsername: posterUsername,
      posterAvatarUrl: posterAvatarUrl,
      posterRole: posterRole,
      posterCollege: posterCollege,
      posterBranch: posterBranch,
      posterStudyYear: posterStudyYear,
      postLink: postLink,
      applyLink: applyLink,
    );
  }
}
