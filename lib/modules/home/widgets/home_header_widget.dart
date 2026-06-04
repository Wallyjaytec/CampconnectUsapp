import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/constants/app_assets.dart';
import 'package:kartly_e_commerce/modules/search/controller/visual_search_controller.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo row
          Row(
            children: [
              Image.asset(AppAssets.appLogo, width: 30, height: 30),
              const SizedBox(width: 8),
              Text(
                'CampConnectUs | ${'Shop on CCU'.tr}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar with camera
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.searchView),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackgroundColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.search_normal_1_copy, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search Products...'.tr,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.searchView);
                      Get.put(VisualSearchController()).searchFromGallery();
                    },
                    child: const Icon(Iconsax.camera_copy, size: 20, color: AppColors.primaryColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickActionButton(
                icon: Iconsax.user_copy,
                label: 'Account'.tr,
                onTap: () => Get.toNamed(AppRoutes.editProfileView),
                isDark: isDark,
              ),
              _QuickActionButton(
                icon: Iconsax.shopping_cart_copy,
                label: 'Cart'.tr,
                onTap: () => Get.toNamed(AppRoutes.cartView),
                isDark: isDark,
              ),
              _QuickActionButton(
                icon: Iconsax.box_copy,
                label: 'Orders'.tr,
                onTap: () => Get.toNamed(AppRoutes.myOrderListView),
                isDark: isDark,
              ),
              _QuickActionButton(
                icon: Iconsax.notification_copy,
                label: 'Notif'.tr,
                onTap: () => Get.toNamed(AppRoutes.notificationsView),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackgroundColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
