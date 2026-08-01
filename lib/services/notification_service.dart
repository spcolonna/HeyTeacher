import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Persist the token for whoever is signed in right now (on a cold
        // start the auth listener in AuthProvider also calls syncToken()).
        await syncToken();

        // A refreshed token is useless unless it replaces the stored one.
        _messaging.onTokenRefresh.listen((newToken) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) await saveFCMToken(uid, newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      } else {
        print('User declined or has not granted permission');
      }
    } catch (e) {
      print('⚠️ Notification initialization failed (may be running on simulator): $e');
      // App continúa funcionando sin notificaciones
    }
  }

  /// Fetches the current FCM token and stores it on the signed-in user's
  /// document. Safe to call repeatedly — call it on every sign-in, since a
  /// token obtained before login would otherwise never be attached to anyone.
  Future<void> syncToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // On iOS the FCM token is only available once APNs has handed us its
      // own token; asking too early throws instead of returning null.
      if (!kIsWeb && Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) return;
      }

      final token = await _messaging.getToken();
      if (token != null) await saveFCMToken(uid, token);
    } catch (e) {
      // Expected on the iOS simulator, which has no APNs support.
      print('⚠️ Could not get FCM token: $e');
    }
  }

  // Save FCM token to user document
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Clears the stored token so a signed-out device stops receiving pushes
  /// meant for that account.
  Future<void> clearToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }
  
  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // Show local notification or update UI
    if (message.notification != null) {
      print('Title: ${message.notification!.title}');
      print('Body: ${message.notification!.body}');
    }
    
    // Handle data payload
    if (message.data.isNotEmpty) {
      print('Data: ${message.data}');
    }
  }
  
  // Handle background message tap
  void _handleBackgroundMessage(RemoteMessage message) {
    print('App opened from background notification');
    
    // Navigate to specific screen based on notification type
    if (message.data.containsKey('type')) {
      String type = message.data['type'];
      switch (type) {
        case 'new_job':
          // Navigate to job details
          print('Navigate to job: ${message.data['jobId']}');
          break;
        case 'application_update':
          // Navigate to applications
          print('Navigate to application: ${message.data['applicationId']}');
          break;
        default:
          print('Unknown notification type: $type');
      }
    }
  }
  
  // Subscribe to topic (e.g., for location-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
  
  // Create notification record in Firestore for user inbox
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
  
  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

// Top-level function for background message handler.
// @pragma keeps it alive in release builds — without it tree-shaking strips
// the entry point and background notifications silently stop working.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
