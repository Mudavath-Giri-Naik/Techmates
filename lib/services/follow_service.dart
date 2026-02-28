import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/follow_model.dart';

/// Service for all follow/unfollow operations.
class FollowService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Send a follow request. Returns the resulting status.
  Future<FollowStatus> follow(String targetUserId) async {
    try {
      final result = await _client.rpc('follow_user', params: {
        'p_follower_id': _currentUserId,
        'p_following_id': targetUserId,
      });

      return FollowStatus.fromString(result as String?);
    } catch (e) {
      debugPrint('❌ [FollowService] follow error: $e');
      rethrow;
    }
  }

  /// Remove a follow (unfollow or cancel request).
  Future<void> unfollow(String targetUserId) async {
    try {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', _currentUserId!)
          .eq('following_id', targetUserId);
    } catch (e) {
      debugPrint('❌ [FollowService] unfollow error: $e');
      rethrow;
    }
  }

  /// Toggle follow state: none→follow, pending/following→unfollow.
  Future<FollowStatus> toggleFollow({
    required String targetUserId,
    required FollowStatus currentStatus,
  }) async {
    switch (currentStatus) {
      case FollowStatus.none:
        return await follow(targetUserId);
      case FollowStatus.pending:
      case FollowStatus.following:
        await unfollow(targetUserId);
        return FollowStatus.none;
      case FollowStatus.self:
        return FollowStatus.self;
    }
  }

  /// Accept an incoming follow request.
  Future<void> acceptRequest(String followId) async {
    try {
      await _client
          .from('follows')
          .update({'status': 'accepted'}).eq('id', followId);
    } catch (e) {
      debugPrint('❌ [FollowService] acceptRequest error: $e');
      rethrow;
    }
  }

  /// Reject (delete) an incoming follow request.
  Future<void> rejectRequest(String followId) async {
    try {
      await _client.from('follows').delete().eq('id', followId);
    } catch (e) {
      debugPrint('❌ [FollowService] rejectRequest error: $e');
      rethrow;
    }
  }

  /// Fetch pending incoming follow requests for the current user.
  Future<List<FollowRequestModel>> getPendingRequests() async {
    try {
      final response = await _client.rpc('get_pending_requests', params: {
        'p_user_id': _currentUserId,
      });

      return (response as List)
          .map((json) =>
              FollowRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [FollowService] getPendingRequests error: $e');
      rethrow;
    }
  }

  /// Get just the count of pending incoming requests.
  Future<int> getPendingRequestCount() async {
    try {
      final response = await _client
          .from('follows')
          .select('id')
          .eq('following_id', _currentUserId!)
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ [FollowService] getPendingRequestCount error: $e');
      return 0;
    }
  }

  /// Get follower count for a user via RPC.
  Future<int> getFollowerCount(String userId) async {
    try {
      final result = await _client.rpc('get_follower_count', params: {
        'p_user_id': userId,
      });
      return (result as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('❌ [FollowService] getFollowerCount error: $e');
      return 0;
    }
  }

  /// Get following count for a user via RPC.
  Future<int> getFollowingCount(String userId) async {
    try {
      final result = await _client.rpc('get_following_count', params: {
        'p_user_id': userId,
      });
      return (result as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('❌ [FollowService] getFollowingCount error: $e');
      return 0;
    }
  }

  /// Get list of people who follow [userId].
  Future<List<FollowUserItem>> getFollowersList(String userId) async {
    try {
      final result = await _client.rpc('get_followers_list', params: {
        'p_user_id': userId,
      });
      return (result as List)
          .map((e) =>
              FollowUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('❌ [FollowService] getFollowersList error: $e');
      rethrow;
    }
  }

  /// Get list of people [userId] is following.
  Future<List<FollowUserItem>> getFollowingList(String userId) async {
    try {
      final result = await _client.rpc('get_following_list', params: {
        'p_user_id': userId,
      });
      return (result as List)
          .map((e) =>
              FollowUserItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('❌ [FollowService] getFollowingList error: $e');
      rethrow;
    }
  }
}
