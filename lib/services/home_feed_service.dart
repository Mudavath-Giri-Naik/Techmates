import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/opportunity_feed_item.dart';
import '../models/hackathon_details_model.dart';
import '../models/internship_details_model.dart';
import '../models/event_details_model.dart';
import '../utils/proxy_url.dart';

/// Service that fetches a unified, chronological feed of opportunities
/// with poster profile data for the Home tab.
class HomeFeedService {
  final SupabaseClient _client = SupabaseClientManager.instance;

  /// Fetches a page of opportunities (all types merged) sorted by
  /// `created_at DESC`, joined with the poster's profile.
  ///
  /// [page] is 0-indexed. Each page contains [pageSize] items.
  Future<List<OpportunityFeedItem>> fetchHomeFeed({
    int page = 0,
    int pageSize = 10,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    try {
      final response = await _client
          .from('opportunities')
          .select(
            '*, internship_details(*), hackathon_details(*), event_details(*), profiles!opportunities_posted_by_fkey(id, full_name, username, avatar_url, role, branch, year, college_id, colleges!profiles_college_id_fkey(short_name, name))',
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
    final profileData = json['profiles'] as Map<String, dynamic>?;
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
