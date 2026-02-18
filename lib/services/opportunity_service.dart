import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/opportunity_model.dart';
import '../core/supabase_client.dart';
import 'cache_service.dart';
import 'internship_service.dart'; // Added import

class FetchResult {
  final List<Opportunity> items;
  final int newItemsCount;
  
  FetchResult(this.items, this.newItemsCount);
}

class OpportunityService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  final CacheService _cacheService = CacheService();
  final InternshipService _internshipService = InternshipService(); // Added instance

  // Categories map to DB types
  String _mapCategoryToType(String category) {
    final lower = category.toLowerCase().trim();
    if (lower.endsWith('s')) {
      return lower.substring(0, lower.length - 1);
    }
    return lower;
  }

  Future<FetchResult> fetchOpportunities(String category, {bool forceRefresh = false}) async {
    try {
      final dbType = _mapCategoryToType(category);
      
      // 1. Load Local Cache
      final cachedItems = await _cacheService.getOpportunities(category);
      
      // 2. If not forcing refresh and cache exists, return cache
      if (!forceRefresh && cachedItems.isNotEmpty) {
        return FetchResult(cachedItems, 0);
      }

      // 3. Network Fetch
      // If forcing refresh, define 'since' timestamp.
      DateTime? since;
      if (forceRefresh) {
        since = await _cacheService.getLastFetchTime(category);
      }

      var query = _client
          .from('opportunities')
          .select('*, internship_details(*), hackathon_details(*), event_details(*)')
          .eq('type', dbType);
      
      if (since != null) {
        query = query.gt('created_at', since.toIso8601String());
      }
      
      // Order by created_at desc to get newest first? 
      // User Req originally: order by deadline ascending.
      // But for "fetching new items", we just want the items. 
      // The final list presentation order should be deadline asc (implied by previous req).
      // So when we merge, we should re-sort relevantly.
      // Let's just fetch.
      
      final response = await query;
      final List<dynamic> data = response as List<dynamic>;
      final List<Opportunity> newItems = data.map((json) => Opportunity.fromJson(json)).toList();
      
      if (newItems.isEmpty) {
        // No new data. If we were forcing refresh, return old cache.
        // If it was first load and empty, return empty.
        // Update timestamp anyway to say "we checked"? Yes.
        if (forceRefresh) {
             await _cacheService.saveLastFetchTime(category, DateTime.now());
             return FetchResult(cachedItems, 0);
        } else {
             // First load, empty
             return FetchResult([], 0);
        }
      }

      // 4. Merge
      // If forceRefresh, we append new items to old items.
      // Ideally we check de-duplication just in case (by ID).
      // New items might overlap if clock skew, so use Map.
      
      final Map<String, Opportunity> mergedMap = {};
      for (var item in cachedItems) {
        mergedMap[item.id] = item;
      }
      for (var item in newItems) {
        mergedMap[item.id] = item;
      }
      
      var mergedList = mergedMap.values.toList();
      
      // 5. Re-Sort (Newest first - by updatedAt descending)
      mergedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // 6. Save Cache
      await _cacheService.saveOpportunities(category, mergedList);
      await _cacheService.saveLastFetchTime(category, DateTime.now());

      return FetchResult(mergedList, newItems.length);

    } catch (e) {
      if (!forceRefresh) {
        // If first load fails, rethrow
        throw 'Failed to fetch opportunities: $e';
      } else {
         // If refresh fails, return cached items but rethrow/log so UI knows refresh failed?
         // Usually we construct a result with error, but simple throw is OK for FutureBuilder.
         // But for Pull-to-Refresh we catch the error in UI.
         rethrow;
      }
    }
  }
}
