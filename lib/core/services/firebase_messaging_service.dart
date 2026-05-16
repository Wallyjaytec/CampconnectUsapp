import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      // Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Permission not granted');
        return;
      }
      
      // Get FCM token
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
    } catch (e) {
      print('Firebase init error: $e');
    }
  }
  
  void _showNotification(RemoteMessage message) {
    Get.snackbar(
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
