import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/controllers/theme_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MediaPermissionState {
  unknown,
  granted,
  limited,
  denied,
  permanentlyDenied,
}

class PermissionService extends GetxService {
  static PermissionService get I => Get.find<PermissionService>();

  static const _askedKey = 'perm_home_asked_once_v1';
  final _state = MediaPermissionState.unknown.obs;
  bool _askedOnce = false;

  MediaPermissionState get state => _state.value;
  bool get isAllowed =>
      _state.value == MediaPermissionState.granted ||
      _state.value == MediaPermissionState.limited;

  Future<PermissionService> init() async {
    final sp = await SharedPreferences.getInstance();
    _askedOnce = sp.getBool(_askedKey) ?? false;
    await refreshStatus();
    return this;
  }

  Future<void> requestOnceOnHome() async {
    if (_askedOnce) return;
    _askedOnce = true;
    (await SharedPreferences.getInstance()).setBool(_askedKey, true);

    final proceed = await _preAskDialog();
    if (proceed != true) {
      await refreshStatus();
      return;
    }

    final cam = await Permission.camera.request();
    PermissionStatus photos = await Permission.photos.request();
    if (!Platform.isIOS && (photos.isDenied || photos.isRestricted)) {
      final storage = await Permission.storage.request();
      if (storage.isGranted) photos = PermissionStatus.granted;
    }

    _updateFromStatuses(cam, photos);

    if (_state.value == MediaPermissionState.permanentlyDenied) {
      await _settingsDialog(
        title: 'Permission required'.tr,
        message:
            'Camera or Photos permission is set to Do not ask again Open Settings to enable'
                .tr,
      );
    }
  }

  Future<void> refreshStatus() async {
    final cam = await Permission.camera.status;
    PermissionStatus photos = await Permission.photos.status;
    if (!Platform.isIOS && (photos.isDenied || photos.isRestricted)) {
      final storage = await Permission.storage.status;
      if (storage.isGranted) photos = PermissionStatus.granted;
    }
    _updateFromStatuses(cam, photos);
  }

  Future<bool> canUseMediaOrExplain() async {
    if (_state.value == MediaPermissionState.unknown) {
      await refreshStatus();
    }

    if (isAllowed) return true;

    if (_state.value == MediaPermissionState.denied) {
      Get.snackbar(
        'Permission blocked'.tr,
        'Please allow Camera and Photos from Home or App Settings to continue'
            .tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
      return false;
    }

    if (_state.value == MediaPermissionState.permanentlyDenied) {
      await _settingsDialog(
        title: 'Permission required'.tr,
        message:
            'Camera or Photos permission is permanently denied Open Settings to enable'
                .tr,
      );
      return false;
    }

    Get.snackbar(
      'Permission not granted'.tr,
      'Please allow permissions on Home to continue'.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primaryColor,
      colorText: AppColors.whiteColor,
    );
    return false;
  }

  Future<void> askAgainFromSettingsLikeEntry() async {
    final cam = await Permission.camera.request();
    PermissionStatus photos = await Permission.photos.request();
    if (!Platform.isIOS && (photos.isDenied || photos.isRestricted)) {
      final storage = await Permission.storage.request();
      if (storage.isGranted) photos = PermissionStatus.granted;
    }
    _updateFromStatuses(cam, photos);

    if (_state.value == MediaPermissionState.permanentlyDenied) {
      await _settingsDialog(
        title: 'Permission required'.tr,
        message:
            'Permission is set to Do not ask again Open Settings to enable'.tr,
      );
    }
  }

  void _updateFromStatuses(PermissionStatus cam, PermissionStatus photos) {
    if (cam.isPermanentlyDenied || photos.isPermanentlyDenied) {
      _state.value = MediaPermissionState.permanentlyDenied;
      return;
    }
    if (cam.isGranted && (photos.isGranted || photos.isLimited)) {
      _state.value = photos.isLimited
          ? MediaPermissionState.limited
          : MediaPermissionState.granted;
      return;
    }
    if (cam.isDenied ||
        photos.isDenied ||
        cam.isRestricted ||
        photos.isRestricted) {
      _state.value = MediaPermissionState.denied;
      return;
    }
    _state.value = MediaPermissionState.unknown;
  }

  Future<bool?> _preAskDialog() async {
    return await Get.dialog<bool>(
      GetBuilder<ThemeController>(
        builder: (ctrl) {
          final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          return Dialog(
            backgroundColor: isDark ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${'Allow camera and gallery'.tr}?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We use your camera and photo library so you can take or pick photos while shopping'
                        .tr,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: Text('Not now'.tr),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Get.back(result: true),
                        child: Text('Continue'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _settingsDialog({
    required String title,
    required String message,
  }) async {
    await Get.dialog(
      GetBuilder<ThemeController>(
        builder: (ctrl) {
          final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          return Dialog(
            backgroundColor: isDark ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(message, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Later'.tr),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          await openAppSettings();
                          Get.back();
                        },
                        child: Text('Open Settings'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }
}
