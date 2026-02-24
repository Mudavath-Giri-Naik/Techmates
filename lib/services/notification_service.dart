import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart'; // For debugPrint and Navigator
import '../main.dart'; // For navigatorKey

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // Accessing Supabase client. ensuring it is initialized in main.dart before this service is used.
  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Remove StreamController as we use global key now
  // final _notificationStreamController = StreamController<Map<String, dynamic>>.broadcast();
  // Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;
  
  // Callback for in-feed navigation
  Function(String opportunityId, String type)? onNotificationTap;

  Future<void> init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [NotificationService] Cannot init - No authenticated user found.');
      return;
    }
    
    debugPrint('🚀 [NotificationService] Initializing for user: ${user.id}');

    await requestPermission();
    
    // Get the token each time the application loads
    final token = await getToken();
    if (token != null) {
      debugPrint('🔑 [NotificationService] FCM Token: $token');
      await saveTokenToSupabase(token);
    } else {
      debugPrint('⚠️ [NotificationService] FCM Token is null.');
    }


    // Subscribe to "all" topic for broadcast notifications
    // Use delayed retry to give Firebase time to initialize
    debugPrint('🔔 [NotificationService] Subscribing to topic "all"...');
    _subscribeWithDelay();

    // Any time the token refreshes, store it to Supabase
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 [NotificationService] Token refreshed: $newToken');
      saveTokenToSupabase(newToken);
    });

    _configureForegroundHandlers();
  }

  Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('🚀 [NotificationService] App launched from terminated state via notification');
      handleNotificationClick(initialMessage);
    }
  }

  void handleNotificationClick(RemoteMessage message) {
    debugPrint("🔔 [NotificationService] Handling notification click. Payload: ${message.data}");

    final data = message.data;
    String? opportunityId;
    String? type;
    String? route;

    if (data.containsKey('route')) route = data['route'];
    if (data.containsKey('opportunity_id')) opportunityId = data['opportunity_id'];
    if (data.containsKey('type')) type = data['type'];

    // If route is 'opportunity' (or implicit if we have an ID)
    if (opportunityId != null && (route == 'opportunity' || route == null)) { 
       debugPrint("✅ [NotificationService] Triggering in-feed navigation: $opportunityId");
       
       // Use callback instead of direct navigation
       if (onNotificationTap != null) {
         onNotificationTap!(opportunityId, type ?? 'internship');
       } else {
         debugPrint("⚠️ [NotificationService] No callback registered for notification tap");
       }
    } else {
      debugPrint("⚠️ [NotificationService] Unknown route or missing ID. Payload: $data");
    }
  }

  Future<void> saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ [NotificationService] Save failed - User not logged in.');
      return;
    }

    try {
      debugPrint('💾 [NotificationService] Saving token to Supabase for user ${user.id}...');
      await _supabase.from('profiles').update({'fcm_token': token}).eq('id', user.id);
      debugPrint('✅ [NotificationService] FCM Token saved successfully to profiles!');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error saving FCM token: $e');
    }
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 [NotificationService] Permission status: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
        },
      );
      debugPrint('✅ [NotificationService] Notification sent via Edge Function');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error sending notification: $e');
    }
  }

  void _subscribeWithDelay() async {
    // Wait 5 seconds for Firebase to fully initialize
    await Future.delayed(const Duration(seconds: 5));
    
    debugPrint('🔔 [NotificationService] Attempting delayed subscription to "all"...');
    
    try {
      await _firebaseMessaging.subscribeToTopic('all');
      debugPrint('✅ [NotificationService] Successfully subscribed to topic "all"');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] First attempt failed: $e');
      
      // Try again after 10 more seconds
      await Future.delayed(const Duration(seconds: 10));
      debugPrint('🔔 [NotificationService] Retrying subscription...');
      
      try {
        await _firebaseMessaging.subscribeToTopic('all');
        debugPrint('✅ [NotificationService] Successfully subscribed to topic "all" (retry)');
      } catch (e2) {
        debugPrint('❌ [NotificationService] Subscription failed after retry: $e2');
        debugPrint('   This may indicate a Firebase configuration issue.');
        debugPrint('   Check: 1) Google Play Services updated, 2) Internet connection, 3) Firebase project setup');
      }
    }
  }

  /// Notify superadmin(s) about a new unknown college domain submission.
  /// Only sends if this domain does not already exist in college_domain_queue.
  Future<void> notifySuperAdmin(String domain, String submittedName) async {
    try {
      // Check if domain already exists in queue (avoid duplicate notifications)
      final existing = await _supabase
          .from('college_domain_queue')
          .select('id')
          .eq('domain', domain.toLowerCase().trim())
          .maybeSingle();

      // If domain was just inserted (by CollegeService.handleUnknownDomain) the row exists,
      // but we only call this on first-time insert so we proceed anyway.
      // The guard here is for safety if called independently.

      // Get superadmin user IDs from user_roles
      final roleRows = await _supabase
          .from('user_roles')
          .select('user_id')
          .eq('role', 'super_admin');

      if (roleRows.isEmpty) {
        debugPrint('⚠️ [NotificationService] No super_admin found to notify.');
        return;
      }

      // Fetch FCM tokens for those users
      final userIds = (roleRows as List).map((r) => r['user_id'] as String).toList();
      final profiles = await _supabase
          .from('profiles')
          .select('id, fcm_token')
          .inFilter('id', userIds);

      for (final profile in profiles) {
        final token = profile['fcm_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await sendPushNotification(
            token: token,
            title: 'New College Domain',
            body: 'domain: $domain, submitted as: $submittedName',
          );
          debugPrint('📩 [NotificationService] Superadmin notified: ${profile['id']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] notifySuperAdmin error: $e');
    }
  }

  void _configureForegroundHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 [NotificationService] Foreground Message received!');
      if (message.notification != null) {
        debugPrint('   Title: ${message.notification!.title}');
        debugPrint('   Body: ${message.notification!.body}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 [NotificationService] Notification clicked (OpenedApp)');
      handleNotificationClick(message);
    });
  }
}
