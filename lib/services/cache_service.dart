import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _keyPrefix = 'opportunities_cache_';
  static const String _timeKeyPrefix = 'opportunities_last_fetch_';

  // Save list to cache
  Future<void> saveOpportunities(String category, List<Opportunity> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_keyPrefix$category';
    
    // Convert list of objects to list of JSON strings (or just one big JSON string)
    // We'll store as a JSON List string
    final List<Map<String, dynamic>> jsonList = items.map((e) => e.toJson()).toList();
    final String encoded = jsonEncode(jsonList);
    
    await prefs.setString(key, encoded);
    
    // If saving the full list, we might update last fetch time to "now"?
    // Or let the caller handle timestamp?
    // Usually "Last Sync" implies when we last talked to server.
    // We'll expose a separate method for timestamp.
  }

  // Get list from cache
  Future<List<Opportunity>> getOpportunities(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_keyPrefix$category';
    final String? encoded = prefs.getString(key);

    if (encoded == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((e) => Opportunity.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error decoding cache for $category: $e");
      return [];
    }
  }

  // Save last fetch timestamp
  Future<void> saveLastFetchTime(String category, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_timeKeyPrefix$category';
    await prefs.setString(key, time.toIso8601String());
  }

  // Get last fetch timestamp
  Future<DateTime?> getLastFetchTime(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_timeKeyPrefix$category';
    final String? timeStr = prefs.getString(key);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // --- Internships ---
  Future<void> saveInternships(List<InternshipDetailsModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${_keyPrefix}Internships';
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<List<InternshipDetailsModel>> getInternships() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${_keyPrefix}Internships';
    final String? encoded = prefs.getString(key);
    if (encoded == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((e) => InternshipDetailsModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error decoding internships cache: $e");
      return [];
    }
  }

  // --- Hackathons ---
  Future<void> saveHackathons(List<HackathonDetailsModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${_keyPrefix}Hackathons';
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<List<HackathonDetailsModel>> getHackathons() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${_keyPrefix}Hackathons';
    final String? encoded = prefs.getString(key);
    if (encoded == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((e) => HackathonDetailsModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error decoding hackathons cache: $e");
      return [];
    }
  }

  // --- Events ---
  Future<void> saveEvents(List<EventDetailsModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${_keyPrefix}Events';
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<List<EventDetailsModel>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${_keyPrefix}Events';
    final String? encoded = prefs.getString(key);
    if (encoded == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((e) => EventDetailsModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error decoding events cache: $e");
      return [];
    }
  }
}
