import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InternetChecker {
  static final InternetChecker _instance = InternetChecker._internal();
  factory InternetChecker() => _instance;
  InternetChecker._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogShowing = false;
  Timer? _periodicCheck;

  void startMonitoring() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final bool hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (!hasInternet) {
        _showNoInternetDialog();
      } else {
        _hideNoInternetDialog();
      }
    });

    // Periodic check every 30 seconds as backup
    _periodicCheck?.cancel();
    _periodicCheck = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isDialogShowing) {
        final hasInternet = await checkInternet();
        if (hasInternet) {
          _hideNoInternetDialog();
        }
      }
    });
  }

  Future<bool> checkInternet() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _showNoInternetDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    final context = Get.context;
    if (context == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                'No Internet'.tr,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          content: Text(
            'Please check your connection and try again.'.tr,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final hasInternet = await checkInternet();
                if (hasInternet) {
                  _hideNoInternetDialog();
                } else {
                  Get.snackbar('No Internet'.tr, 'Still no connection'.tr,
                      backgroundColor: Colors.red, colorText: Colors.white);
                }
              },
              child: Text('Retry'.tr),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _hideNoInternetDialog() {
    _isDialogShowing = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void dispose() {
    _subscription?.cancel();
    _periodicCheck?.cancel();
  }
}
