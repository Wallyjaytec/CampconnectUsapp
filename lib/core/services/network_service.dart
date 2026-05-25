import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../constants/app_colors.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  final RxBool isConnected = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<NetworkService> init() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();

    _updateConnectionStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

    return this;
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool nowConnected = results.any((r) => r != ConnectivityResult.none);

    isConnected.value = nowConnected;

    if (!nowConnected) {
      _showNoInternetDialog();
    } else {
      _hideNoInternetDialog();
      Get.forceAppUpdate();
    }
  }

  void _showNoInternetDialog() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      PopScope(
        canPop: false,
        child: ValueListenableBuilder<Brightness>(
          valueListenable: WidgetsBinding.instance.platformDispatcher.platformBrightness,
          builder: (context, brightness, _) {
            final isDark = brightness == Brightness.dark;
            return Dialog(
              backgroundColor: isDark
                  ? AppColors.darkProductCardColor
                  : AppColors.lightBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                      ),
                      child: const Icon(Icons.wifi_off_rounded, size: 38, color: AppColors.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Internet Connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your Wi-Fi or mobile data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.greyColor, height: 1.3),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final List<ConnectivityResult> results =
                              await Connectivity().checkConnectivity();
                          final nowConnected = results.any((r) => r != ConnectivityResult.none);
                          if (nowConnected && Get.isDialogOpen == true) {
                            Get.back();
                          }
                        },
                        icon: const Icon(Iconsax.refresh_copy, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _hideNoInternetDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void showNoInternetDialog() {
    _showNoInternetDialog();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
