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
    final platformBrightness = MediaQuery.of(context).platformBrightness;

    // Auto-reset to system when phone brightness changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.themeMode.value != ThemeMode.system) {
        controller.setMode(ThemeMode.system);
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          Obx(() {
            final isSystem = controller.themeMode.value == ThemeMode.system;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Default'.tr,
                  style: const TextStyle(fontSize: 14),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isSystem,
                    onChanged: (v) {
                      if (v) {
                        controller.setMode(ThemeMode.system);
                      } else {
                        controller.setMode(ThemeMode.light);
                      }
                    },
                  ),
                ),
              ],
            );
          }),
          
          const SizedBox(height: 4),
          
          Obx(() {
            final isSystem = controller.themeMode.value == ThemeMode.system;
            final isDarkOn = isSystem
                ? platformBrightness == Brightness.dark
                : controller.themeMode.value == ThemeMode.dark;

            return Opacity(
              opacity: isSystem ? 0.4 : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'Light'.tr} / ${'Dark'.tr}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.light_mode, size: 18, color: isSystem ? Colors.grey : null),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: isDarkOn,
                          onChanged: isSystem
                              ? null
                              : (v) {
                                  controller.setMode(v ? ThemeMode.dark : ThemeMode.light);
                                },
                        ),
                      ),
                      Icon(Icons.dark_mode, size: 18, color: isSystem ? Colors.grey : null),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
