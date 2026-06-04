import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';

class OrderRefundCards extends StatelessWidget {
  const OrderRefundCards({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatusCard(
              icon: Iconsax.box_copy,
              title: 'Latest Order'.tr,
              orderCode: '#CCU1012...',
              status: 'Processing',
              amount: 15000,
              onTap: () => Get.toNamed(AppRoutes.myOrderListView),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatusCard(
              icon: Iconsax.money_recive_copy,
              title: 'Refund'.tr,
              orderCode: '#5-120345',
              status: 'In Progress',
              amount: 5000,
              onTap: () => Get.toNamed(AppRoutes.refundRequestListView),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String orderCode;
  final String status;
  final double amount;
  final VoidCallback onTap;
  final bool isDark;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.orderCode,
    required this.status,
    required this.amount,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(orderCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            // Status bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: status == 'Processing' ? 0.4 : 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatCurrency(amount, applyConversion: true),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
