import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // Accessing Supabase client. ensuring it is initialized in main.dart before this service is used.
  SupabaseClient get _supabase => Supabase.instance.client;

  final _notificationStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

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
      if (initialMessage.data.isNotEmpty) {
        _notificationStreamController.add(initialMessage.data);
      }
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
      if (message.data.isNotEmpty) {
        _notificationStreamController.add(message.data);
      }
    });
  }
}
