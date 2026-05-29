import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final themeMode = ThemeMode.system.obs;
  final isDarkMode = false.obs;

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

    isDarkMode.value = themeMode.value == ThemeMode.dark || 
        (themeMode.value == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    Get.changeThemeMode(themeMode.value);

    if (themeMode.value == ThemeMode.system) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
        if (themeMode.value == ThemeMode.system) {
          isDarkMode.value = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          update();
        }
      };
    }
  }

  void setMode(ThemeMode mode) {
    themeMode.value = mode;
    isDarkMode.value = mode == ThemeMode.dark || 
        (mode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    _box.write(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });

    Get.changeThemeMode(mode);

    if (mode == ThemeMode.system) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
        if (themeMode.value == ThemeMode.system) {
          isDarkMode.value = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
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
