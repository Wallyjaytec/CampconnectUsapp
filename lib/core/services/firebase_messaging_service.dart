import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      // Request notification permission manually (works on all Android versions)
      PermissionStatus status = await Permission.notification.request();
      print('Manual permission status: $status');
      
      if (status.isGranted) {
        // Get FCM token
        String? token = await _fcm.getToken();
        print('FCM Token: $token');
        
        // Show token in app
        if (token != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(
              'FCM Token',
              token,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 10),
            );
          });
        }
      } else {
        print('Notification permission denied');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Permission Needed',
            'Please enable notifications in Settings',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
      }
      
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
