import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/controllers/theme_controller.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Theme Mode'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final mode = controller.themeMode.value;
            String label;
            IconData icon;
            
            switch (mode) {
              case ThemeMode.light:
                label = '${'Light'.tr}';
                icon = Icons.light_mode;
                break;
              case ThemeMode.dark:
                label = '${'Dark'.tr}';
                icon = Icons.dark_mode;
                break;
              case ThemeMode.system:
              default:
                label = '${'System'.tr}';
                icon = Icons.settings_brightness;
                break;
            }

            return GestureDetector(
              onTap: () {
                // Cycle: system → light → dark → system
                switch (mode) {
                  case ThemeMode.system:
                    controller.setMode(ThemeMode.light);
                    break;
                  case ThemeMode.light:
                    controller.setMode(ThemeMode.dark);
                    break;
                  case ThemeMode.dark:
                    controller.setMode(ThemeMode.system);
                    break;
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
