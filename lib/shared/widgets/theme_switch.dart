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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${'Light'.tr} / ${'Dark'.tr}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final isDark = controller.themeMode.value == ThemeMode.dark;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.light_mode, size: 18),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: isDark,
                        onChanged: (v) {
                          controller.setMode(
                            v ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ),
                    const Icon(Icons.dark_mode, size: 18),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
