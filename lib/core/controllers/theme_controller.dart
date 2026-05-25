import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final themeMode = ThemeMode.system.obs;

  static const _key = 'theme_mode';

  @override
  void onInit() {
    super.onInit();
    final saved = _box.read<String>(_key);
    switch (saved) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }

    Get.changeThemeMode(themeMode.value);

    // Listen to system brightness changes for system theme mode
    if (themeMode.value == ThemeMode.system) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
        if (themeMode.value == ThemeMode.system) {
          update(); // Triggers GetBuilder rebuild when system theme changes
        }
      };
    }
  }

  void setMode(ThemeMode mode) {
    themeMode.value = mode;

    _box.write(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });

    Get.changeThemeMode(mode);

    // Re-register listener if switching back to system mode
    if (mode == ThemeMode.system) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
        if (themeMode.value == ThemeMode.system) {
          update();
        }
      };
    }
  }

  void toggle() {
    setMode(
      themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
