import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/shared/widgets/currency_select.dart';
import 'package:kartly_e_commerce/shared/widgets/language_select.dart';
import 'package:app_settings/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/theme_switch.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _appVersion = '';
  double _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _calculateCacheSize();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  void _calculateCacheSize() {
    final box = GetStorage();
    final keys = box.getKeys();
    double size = 0;
    for (final key in keys) {
      if (key.startsWith('i18n_')) {
        final value = box.read(key);
        if (value is String) {
          size += value.length;
        }
      }
    }
    setState(() {
      _cacheSize = size;
    });
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Settings'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 10,
            left: 12,
            right: 12,
            bottom: 10,
          ),
          child: Column(
            children: [
              const ThemeSwitch(),
              const SizedBox(height: 8),
              LanguageSelect(),
              const SizedBox(height: 8),
              CurrencySelect(),
              const SizedBox(height: 8),
              // Push Notifications
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    AppSettings.openAppSettings(type: AppSettingsType.notification);
                  },
                  child: Row(
                    children: [
                      const Icon(Iconsax.notification, color: AppColors.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Push Notifications'.tr,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Iconsax.arrow_right_3_copy, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // App Permissions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    AppSettings.openAppSettings();
                  },
                  child: Row(
                    children: [
                      const Icon(Iconsax.shield_tick, color: AppColors.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'App Permissions'.tr,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Iconsax.arrow_right_3_copy, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Cache
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.trash, color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cache : ${_formatBytes(_cacheSize)}'.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final box = GetStorage();
                        final keys = box.getKeys();
                        for (final key in keys) {
                          if (key.startsWith('i18n_')) {
                            box.remove(key);
                          }
                        }
                        PaintingBinding.instance.imageCache.clear();
                        PaintingBinding.instance.imageCache.clearLiveImages();
                        setState(() { _cacheSize = 0; });
                        Get.snackbar(
                          'Cache'.tr,
                          'Cache cleared successfully'.tr,
                          backgroundColor: AppColors.primaryColor,
                          colorText: AppColors.whiteColor,
                        );
                      },
                      child: Text('CLEAR'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // App Version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.information, color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'App Version'.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      _appVersion,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
