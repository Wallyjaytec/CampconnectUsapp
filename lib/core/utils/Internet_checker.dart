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

  void startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final bool hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (!hasInternet) {
        _showNoInternetDialog();
      } else {
        _hideNoInternetDialog();
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

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 10),
              Text('No Internet'),
            ],
          ),
          content: const Text('Please check your connection and try again.'),
          actions: [
            TextButton(
              onPressed: () async {
                final hasInternet = await checkInternet();
                if (hasInternet) {
                  if (Get.isDialogOpen == true) Get.back();
                  Get.forceAppUpdate();
                } else {
                  Get.snackbar('No Internet', 'Still no connection',
                      backgroundColor: Colors.red, colorText: Colors.white);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _hideNoInternetDialog() {
    if (Get.isDialogOpen == true && _isDialogShowing) {
      Get.back();
      _isDialogShowing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
