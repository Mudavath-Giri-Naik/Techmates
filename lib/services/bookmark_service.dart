
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';

class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();

  factory BookmarkService() {
    return _instance;
  }

  BookmarkService._internal();

  final AuthService _authService = AuthService();
  
  // Cache for saved items (ID -> Object)
  final Map<String, dynamic> _savedItemsCache = {};

  // List of saved IDs
  final Set<String> _savedIds = {};

  bool _initialized = false;
  static const String _localBookmarksKey = 'techmates_bookmarks';

  Future<void> init() async {
    if (_initialized) return;

    // Load from Local Storage (for offline/faster startup)
    final prefs = await SharedPreferences.getInstance();
    final String? localData = prefs.getString(_localBookmarksKey);
    
    if (localData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(localData);
        for (var item in jsonList) {
          _parseAndCacheItem(item);
        }
      } catch (e) {
        debugPrint("❌ [BookmarkService] Error loading local bookmarks: $e");
      }
    }

    // Sync with User Metadata if logged in
    await _syncWithUserMetadata();

    _initialized = true;
  }

  Future<void> _syncWithUserMetadata() async {
    if (!_authService.isLoggedIn) return;

    // Fetch latest user data
    final user = _authService.user;
    if (user == null) return;

    // Supabase Metadata 'bookmarks' is list of IDs
    final List<dynamic>? metadataBookmarks = user.userMetadata?['bookmarks'] as List<dynamic>?;

    if (metadataBookmarks != null) {
      final serverIds = metadataBookmarks.map((e) => e.toString()).toSet();
      
      // Merge: If local has more (added offline), we might want to push? 
      // For now, let's treat Server as source of truth for IDs, 
      // BUT we need to keep the item details if we have them locally.
      
      // If we differ, should we update server? 
      // Let's just use server IDs for now.
      _savedIds.clear();
      _savedIds.addAll(serverIds);
      
      // Remove items from cache that are no longer bookmarked
      _savedItemsCache.removeWhere((key, value) => !_savedIds.contains(key));
    }
    
    await _saveLocal();
  }

  bool isBookmarked(String id) {
    return _savedIds.contains(id);
  }

  Future<void> toggleBookmark(dynamic item) async {
    String id;
    if (item is Opportunity) {
      id = item.id;
    } else if (item is InternshipDetailsModel) {
      id = item.opportunityId;
    } else if (item is HackathonDetailsModel) {
       id = item.opportunityId;
    } else if (item is EventDetailsModel) {
       id = item.opportunityId;
    } else {
      debugPrint("❌ [BookmarkService] Unknown item type: ${item.runtimeType}");
      return;
    }

    if (_savedIds.contains(id)) {
      _savedIds.remove(id);
      _savedItemsCache.remove(id);
    } else {
      _savedIds.add(id);
      _savedItemsCache[id] = item;
    }

    notifyListeners(); // If we used ChangeNotifier, but here we just persist.
    
    await _saveLocal();
    await _updateUserMetadata();
  }
  
  // Helper to notify UI? 
  // We can use a ValueNotifier or Stream, or just setState in UI.
  // For simplicity, let's add a listener mechanism.
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  Future<void> _updateUserMetadata() async {
    if (!_authService.isLoggedIn) return;
    
    try {
      // Update 'bookmarks' field in user_metadata
      await _authService.updateUserMetadata({
        'bookmarks': _savedIds.toList(),
      });
      debugPrint("✅ [BookmarkService] User metadata updated.");
    } catch (e) {
      debugPrint("❌ [BookmarkService] Failed to update user metadata: $e");
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    // We only need to save the full objects for offline viewing/listing
    // _savedIds is implicitly saved by _savedItemsCache keys
    
    final List<Map<String, dynamic>> jsonList = _savedItemsCache.values.map((item) {
       if (item is Opportunity) {
          var json = item.toJson();
          // Ensure type is preserved if generic
          return json;
       } else if (item is InternshipDetailsModel) {
          var json = item.toJson();
          json['type_discriminator'] = 'internship'; // Custom field to help restore
          return json;
       } else if (item is HackathonDetailsModel) {
          var json = item.toJson();
          json['type_discriminator'] = 'hackathon';
          return json;
       } else if (item is EventDetailsModel) {
          var json = item.toJson();
          json['type_discriminator'] = 'event';
          return json;
       }
       return <String, dynamic>{};
    }).toList();

    await prefs.setString(_localBookmarksKey, jsonEncode(jsonList));
  }
  
  void _parseAndCacheItem(Map<String, dynamic> json) {
    try {
      if (json['type_discriminator'] == 'internship') {
        final item = InternshipDetailsModel.fromJson(json);
        _savedItemsCache[item.opportunityId] = item;
        _savedIds.add(item.opportunityId);
      } else if (json['type_discriminator'] == 'hackathon') {
        final item = HackathonDetailsModel.fromJson(json);
        _savedItemsCache[item.opportunityId] = item;
        _savedIds.add(item.opportunityId);
      } else if (json['type_discriminator'] == 'event') {
        final item = EventDetailsModel.fromJson(json);
        _savedItemsCache[item.opportunityId] = item;
        _savedIds.add(item.opportunityId);
      } else {
        // Assume Generic Opportunity or based on type field
        final item = Opportunity.fromJson(json);
        _savedItemsCache[item.id] = item;
        _savedIds.add(item.id);
      }
    } catch (e) {
      debugPrint("⚠️ [BookmarkService] Parse error: $e");
    }
  }

  List<dynamic> getBookmarks() {
    return _savedItemsCache.values.toList();
  }
}
