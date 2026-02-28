import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/student_network_model.dart';

/// Information about a college as shown in the Network screen.
class CollegeNetworkInfo {
  final String id;
  final String? code;
  final String name;
  final String? state;
  final String? location;
  final String? domain;
  final String? collegeUrl;
  final bool isVerified;
  final int studentCount;

  CollegeNetworkInfo({
    required this.id,
    required this.name,
    this.code,
    this.state,
    this.location,
    this.domain,
    this.collegeUrl,
    this.isVerified = false,
    this.studentCount = 0,
  });

  factory CollegeNetworkInfo.fromJson(Map<String, dynamic> json) {
    return CollegeNetworkInfo(
      id: json['id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String? ?? 'Unknown College',
      state: json['state'] as String?,
      location: json['location'] as String?,
      domain: json['domain'] as String?,
      collegeUrl: json['college_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      studentCount: (json['no_of_students'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Service for fetching network-related data (colleges & students).
class NetworkService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  /// Fetch all colleges with student count, ordered by student count desc.
  Future<List<CollegeNetworkInfo>> getColleges() async {
    try {
      final response = await _client
          .from('colleges_with_student_count')
          .select()
          .order('no_of_students', ascending: false);

      return (response as List)
          .map((json) => CollegeNetworkInfo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [NetworkService] getColleges error: $e');
      rethrow;
    }
  }

  /// Fetch students for a specific college via the RPC.
  Future<List<StudentNetworkModel>> getCollegeStudents(
      String collegeId) async {
    try {
      final viewerId = _client.auth.currentUser?.id ??
          '00000000-0000-0000-0000-000000000000';

      final response = await _client.rpc('get_college_students', params: {
        'p_college_id': collegeId,
        'p_viewer_id': viewerId,
      });

      return (response as List)
          .map((json) =>
              StudentNetworkModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [NetworkService] getCollegeStudents error: $e');
      rethrow;
    }
  }

  /// Get the current user's college_id from profiles.
  Future<String?> getCurrentUserCollegeId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('college_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['college_id'] as String?;
    } catch (e) {
      debugPrint('❌ [NetworkService] getCurrentUserCollegeId error: $e');
      return null;
    }
  }

  /// Group students by their year tab label.
  Map<String, List<StudentNetworkModel>> groupByYear(
      List<StudentNetworkModel> students) {
    final map = <String, List<StudentNetworkModel>>{};
    for (final s in students) {
      final key = s.yearTabLabel;
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  /// Extract unique branch names from the student list, sorted.
  List<String> extractBranches(List<StudentNetworkModel> students) {
    final branches = <String>{};
    for (final s in students) {
      if (s.branch != null && s.branch!.isNotEmpty) {
        branches.add(s.branch!);
      }
    }
    final sorted = branches.toList()..sort();
    return sorted;
  }
}
