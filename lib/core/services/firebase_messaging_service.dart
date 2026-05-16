import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      // Show alert that init started
      _showAlert('Firebase Init', 'Starting...');
      
      // Request notification permission manually
      PermissionStatus status = await Permission.notification.request();
      
      _showAlert('Permission Status', status.toString());
      
      if (status.isGranted) {
        // Get FCM token
        String? token = await _fcm.getToken();
        
        _showAlert('FCM TOKEN', token ?? 'NO TOKEN');
        
      } else {
        _showAlert('Permission Denied', 'Please enable notifications');
      }
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
    } catch (e) {
      _showAlert('Error', e.toString());
    }
  }
  
  void _showAlert(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
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
