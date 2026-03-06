import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        print('User granted permission');

        // Get FCM token
        try {
          String? token = await _messaging.getToken();
          if (token != null) {
            print('FCM Token: $token');
            // Save token to Firestore would happen here
          }
        } catch (e) {
          print('⚠️ Could not get FCM token (normal on iOS simulator): $e');
          // Continuar sin token - OK en simulador
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          print('FCM Token refreshed: $newToken');
          // Update token in Firestore
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
  
  // Save FCM token to user document
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
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

// Top-level function for background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
