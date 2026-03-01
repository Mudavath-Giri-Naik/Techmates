import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';
import 'internship_service.dart';
import 'hackathon_service.dart';
import 'event_service.dart';

class OpportunityStore {
  // Singleton
  static final OpportunityStore instance = OpportunityStore._privateConstructor();
  OpportunityStore._privateConstructor();

  final InternshipService _internshipService = InternshipService();
  final HackathonService _hackathonService = HackathonService();
  final EventService _eventService = EventService();

  // ValueNotifiers for UI updates
  final ValueNotifier<List<InternshipDetailsModel>> internships = ValueNotifier([]);
  final ValueNotifier<List<HackathonDetailsModel>> hackathons = ValueNotifier([]);
  final ValueNotifier<List<EventDetailsModel>> events = ValueNotifier([]);

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  // FIX 4: Guard against duplicate concurrent fetches
  bool _isFetching = false;

  // FIX 6: Persistent cache keys
  static const _cacheKey = 'opportunity_cache_v1';
  static const _cacheTimeKey = 'opportunity_cache_time_v1';
  static const _cacheDuration = Duration(hours: 6);

  Future<void> fetchAll({bool forceRefresh = false}) async {
    // FIX 4: Prevent duplicate concurrent calls
    if (_isFetching && !forceRefresh) return;
    _isFetching = true;
    isLoading.value = true;
    error.value = null;

    try {
      // FIX 6: Load from cache first if not force refresh
      if (!forceRefresh) {
        final cached = await _loadFromCache();
        if (cached != null) {
          _applyData(cached);
          debugPrint('[OpportunityStore] Loaded from cache, refreshing in background');
          isLoading.value = false;
          // Refresh from network in background
          unawaited(_fetchFromNetworkInBackground());
          return;
        }
      }

      // No cache or force refresh — fetch from network
      await _fetchFromNetwork();
    } catch (e) {
      debugPrint("Error fetching all opportunities: $e");
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      _isFetching = false;
    }
  }

  Future<void> _fetchFromNetwork() async {
    try {
      await Future.wait([
        _fetchInternships(false),
        _fetchHackathons(false),
        _fetchEvents(false),
      ]);
      // Save to cache after successful network fetch
      await _saveToCache();
      debugPrint('[OpportunityStore] Network fetch complete, cache updated');
    } catch (e) {
      debugPrint("Error fetching from network: $e");
      error.value = e.toString();
    }
  }

  Future<void> _fetchFromNetworkInBackground() async {
    try {
      await Future.wait([
        _fetchInternships(false),
        _fetchHackathons(false),
        _fetchEvents(false),
      ]);
      await _saveToCache();
      debugPrint('[OpportunityStore] Background refresh complete');
    } catch (_) {
      // Silently fail — cache is already showing
    } finally {
      _isFetching = false;
    }
  }

  void _applyData(Map<String, dynamic> data) {
    try {
      if (data['internships'] != null) {
        internships.value = (data['internships'] as List)
            .map((e) => InternshipDetailsModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['hackathons'] != null) {
        hackathons.value = (data['hackathons'] as List)
            .map((e) => HackathonDetailsModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['events'] != null) {
        events.value = (data['events'] as List)
            .map((e) => EventDetailsModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[OpportunityStore] Error applying cached data: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'internships': internships.value.map((e) => e.toJson()).toList(),
        'hackathons': hackathons.value.map((e) => e.toJson()).toList(),
        'events': events.value.map((e) => e.toJson()).toList(),
      };
      await prefs.setString(_cacheKey, jsonEncode(data));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[OpportunityStore] Cache save error: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimeKey);
      if (cacheTime == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (age > _cacheDuration.inMilliseconds) return null;
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[OpportunityStore] Cache load error: $e');
      return null;
    }
  }

  Future<void> _fetchInternships(bool forceRefresh) async {
    try {
      final items = await _internshipService.fetchInternships(page: 0, limit: 100, forceRefresh: forceRefresh);
      internships.value = items;
    } catch (e) {
      debugPrint("Error fetching internships: $e");
    }
  }

  Future<void> _fetchHackathons(bool forceRefresh) async {
    try {
      final items = await _hackathonService.fetchHackathons(page: 0, limit: 100, forceRefresh: forceRefresh);
      hackathons.value = items;
    } catch (e) {
      debugPrint("Error fetching hackathons: $e");
    }
  }

  Future<void> _fetchEvents(bool forceRefresh) async {
    try {
      final items = await _eventService.fetchEvents(page: 0, limit: 100, forceRefresh: forceRefresh);
      events.value = items;
    } catch (e) {
      debugPrint("Error fetching events: $e");
    }
  }
}
