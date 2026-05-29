import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/appbar_icon_badge.dart';
import '../../core/services/login_service.dart';
import '../../modules/account/controller/notifications_controller.dart';

class NotificationIconWidget extends StatelessWidget {
  const NotificationIconWidget({super.key});

  bool get _isLoggedIn => LoginService().isLoggedIn();

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return AppBarIconBadge(
        icon: Iconsax.notification_copy,
        size: 20,
        count: 0,
        onTap: () => Get.toNamed(AppRoutes.loginView),
        iconColor: AppColors.whiteColor,
      );
    }

    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return Obx(
      () => AppBarIconBadge(
        icon: Iconsax.notification_copy,
        size: 20,
        count: controller.notificationCount.value,
        onTap: () {
          controller.refreshList();
          Get.toNamed(AppRoutes.notificationsView);
        },
        iconColor: AppColors.whiteColor,
      ),
    );
  }
}
