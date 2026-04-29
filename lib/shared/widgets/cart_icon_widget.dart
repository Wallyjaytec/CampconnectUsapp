import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/appbar_icon_badge.dart';
import '../../modules/product/controller/cart_controller.dart';

class CartIconWidget extends StatelessWidget {
  const CartIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController controller = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(Get.find()));

    return Obx(() {
      final count = controller.totalItemsCount;
      return AppBarIconBadge(
        icon: Iconsax.shopping_cart_copy,
        size: 20,
        count: count,
        onTap: () => Get.toNamed(AppRoutes.cartView),
        iconColor: AppColors.whiteColor,
      );
    });
  }
}
