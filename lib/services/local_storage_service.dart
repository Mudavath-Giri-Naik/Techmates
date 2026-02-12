
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_model.dart';
import 'cache_service.dart';

class LocalStorageService {
  // Singleton pattern for easy access if needed, 
  // though we can also just instantiate it since SharedPreferences handles its own singleton internally.
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  static const String _filterKeyPrefix = 'filter_prefs_';

  // Save filters for a specific category
  Future<void> saveFilters(String category, FilterModel filters) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_filterKeyPrefix$category';
    final String jsonString = jsonEncode(filters.toJson());
    await prefs.setString(key, jsonString);
  }

  // Load filters for a specific category
  Future<FilterModel> loadFilters(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_filterKeyPrefix$category';
    final String? jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return FilterModel.fromJson(jsonMap);
      } catch (e) {
        // Fallback if corrupt
        return FilterModel();
      }
    }
    return FilterModel(); // Default fresh filters
  }

  // Clear filters for a category (Reset)
  Future<void> clearFilters(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_filterKeyPrefix$category';
    await prefs.remove(key);
  }
}
