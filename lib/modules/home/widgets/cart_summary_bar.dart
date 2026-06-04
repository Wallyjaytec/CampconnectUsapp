import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/product/controller/cart_controller.dart';

class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCtrl = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(Get.find()));

    return Obx(() {
      final items = cartCtrl.items;
      if (items.isEmpty) return const SizedBox.shrink();

      final count = items.length;
      final total = items.fold<double>(0, (sum, item) => sum + (double.tryParse(item.unitPrice.toString()) ?? 0) * item.quantity);

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.cartView),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.shopping_cart_copy, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '$count ${'items'.tr}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const Text('  |  ', style: TextStyle(color: Colors.white70)),
              Text(
                formatCurrency(total, applyConversion: true),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${'Checkout'.tr} →',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    });
  }
}
