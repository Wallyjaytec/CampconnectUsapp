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
  }

  void setMode(ThemeMode mode) {
    themeMode.value = mode;

    _box.write(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });

    Get.changeThemeMode(mode);
  }

  void toggle() {
    setMode(
      themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
