import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/core/services/passcode_service.dart';
import 'package:campconnectus_marketplace/main.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService instance = AppLifecycleService._internal();
  factory AppLifecycleService() => instance;
  AppLifecycleService._internal();

  final box = GetStorage();

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      box.write('_last_active_time', DateTime.now().millisecondsSinceEpoch);
      box.write('_passcode_verified', false);
    }

    if (state == AppLifecycleState.resumed) {
      _checkAndShowPasscode();
    }
  }

  void _checkAndShowPasscode() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final passcodeEnabled = await PasscodeService.checkPasscodeOnServer();
    if (!passcodeEnabled) return;

    final lastActive = box.read<int>('_last_active_time');
    if (lastActive == null) return;

    final autoLockMinutes = PasscodeService.autoLockMinutes;
    final diffMinutes = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastActive)).inMinutes;

    final shouldShowPasscode = autoLockMinutes == 0 || diffMinutes >= autoLockMinutes;

    if (shouldShowPasscode && !isLockScreenShowing) {
      isLockScreenShowing = true;
      Get.offAllNamed(AppRoutes.passcodeLockScreen);
    }
  }

  void onPasscodeVerified() {
    box.write('_passcode_verified', true);
    box.write('_last_active_time', DateTime.now().millisecondsSinceEpoch);
    isLockScreenShowing = false;
  }
}
