
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/opportunity_model.dart';
import '../models/internship_details_model.dart';
import '../models/hackathon_details_model.dart';
import '../models/event_details_model.dart';

class StatusService {
  static final StatusService _instance = StatusService._internal();

  factory StatusService() {
    return _instance;
  }

  StatusService._internal();

  static const String _statusKey = 'opportunity_statuses';
  static const String _dataKey = 'opportunity_data_cache';

  // ID -> Status ('applied', 'must_apply')
  Map<String, String> _statusMap = {};
  
  // ID -> generic object (Opportunity or InternshipDetailsModel)
  Map<String, dynamic> _dataCache = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Load Status Map
    final String? statusString = prefs.getString(_statusKey);
    if (statusString != null) {
      try {
        _statusMap = Map<String, String>.from(jsonDecode(statusString));
      } catch (e) {
        _statusMap = {};
      }
    }

    // Load Data Cache
    final String? dataString = prefs.getString(_dataKey);
    if (dataString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(dataString);
        _dataCache = jsonMap.map((key, value) {
          // Determine type from json
          final map = value as Map<String, dynamic>;
          if (map['type'] == 'internship') {
             try {
               return MapEntry(key, InternshipDetailsModel.fromJson(map));
             } catch (e) {
               print("Error parsing cached internship: $e");
               return MapEntry(key, null);
             }
          } else if (map['type'] == 'hackathon') {
             try {
                // Hackathons can be Opportunity or HackathonDetailsModel?
                // If we cache full object, we need fromJson.
                // Assuming json has all fields. 
                // Wait, HackathonDetailsModel.fromJson expects 'opportunity_id'.
                // If we store it, it should be fine.
                // But we need to ensure toJson adds 'type': 'hackathon'.
                return MapEntry(key, HackathonDetailsModel.fromJson(map));
             } catch (e) {
               print("Error parsing cached hackathon: $e");
               return MapEntry(key, null);
             }
          } else if (map['type'] == 'event') {
             try {
                return MapEntry(key, EventDetailsModel.fromJson(map));
             } catch (e) {
                print("Error parsing cached event: $e");
                return MapEntry(key, null);
             }
          } else {
             return MapEntry(key, Opportunity.fromJson(map));
          }
        });
        _dataCache.removeWhere((key, value) => value == null);
      } catch (e) {
        _dataCache = {};
      }
    }
    
    _initialized = true;
  }

  String? getStatus(String id) {
    return _statusMap[id];
  }

  Future<void> mark(dynamic item, String status) async {
    if (!_initialized) await init();
    
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
      throw "Unknown item type for StatusService";
    }
    
    _statusMap[id] = status;
    _dataCache[id] = item;
    
    await _save();
  }

  Future<void> unmark(String id) async {
    if (!_initialized) await init();
    
    _statusMap.remove(id);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, jsonEncode(_statusMap));
    
    // Serialize data cache
    final Map<String, dynamic> serializedData = _dataCache.map(
      (key, value) {
        if (value is Opportunity) {
          return MapEntry(key, value.toJson());
        } else if (value is InternshipDetailsModel) {
          var json = value.toJson();
          json['type'] = 'internship'; 
          return MapEntry(key, json);
        } else if (value is HackathonDetailsModel) {
          var json = value.toJson();
          json['type'] = 'hackathon';
          return MapEntry(key, json);
        } else if (value is EventDetailsModel) {
          var json = value.toJson();
          json['type'] = 'event';
          return MapEntry(key, json);
        }
        return MapEntry(key, {});
      }
    );
    await prefs.setString(_dataKey, jsonEncode(serializedData));
  }

  // Get list of opportunities/internships for a specific status
  List<dynamic> getItemsByStatus(String status) {
    final ids = _statusMap.entries
        .where((entry) => entry.value == status)
        .map((entry) => entry.key)
        .toList();
        
    final List<dynamic> results = [];
    for (var id in ids) {
      if (_dataCache.containsKey(id)) {
        results.add(_dataCache[id]);
      }
    }
    return results;
  }
}
