import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../controller/coupon_controller.dart';
import '../model/coupon_model.dart';

class CouponsView extends StatelessWidget {
  const CouponsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CouponController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      Tab(height: 38, text: 'Active'.tr),
      Tab(height: 38, text: 'Inactive'.tr),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
              splashRadius: 20,
            ),
          ),
          titleSpacing: 0,
          title: Text(
            'Coupons'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          bottom: TabBar(
            padding: EdgeInsets.zero,
            indicatorColor: AppColors.whiteColor,
            labelColor: AppColors.whiteColor,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelColor: AppColors.greyColor,
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: tabs,
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.error.value, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.loadCoupons,
                      child: Text('Retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            children: [
              _CouponList(
                coupons: controller.activeCoupons,
                isEmptyMessage: 'No active coupons available'.tr,
                isActive: true,
              ),
              _CouponList(
                coupons: controller.inactiveCoupons,
                isEmptyMessage: 'No inactive coupons'.tr,
                isActive: false,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CouponList extends StatelessWidget {
  const _CouponList({
    required this.coupons,
    required this.isEmptyMessage,
    required this.isActive,
  });

  final List<CouponModel> coupons;
  final String isEmptyMessage;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/empty_coupon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              isEmptyMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return _CouponCard(coupon: coupon, isActive: isActive);
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.isActive});
  final CouponModel coupon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.ticket_discount_copy, color: AppColors.primaryColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              if (isActive)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: coupon.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coupon code copied'.tr),
                        backgroundColor: AppColors.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Copy Code'.tr,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            coupon.description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Discount'.tr, coupon.discountText),
                if (coupon.minSpend != null && coupon.minSpend! > 0)
                  _infoRow('Min Spend'.tr, '₦${coupon.minSpend!.toStringAsFixed(0)}'),
                if (coupon.maxSpend != null && coupon.maxSpend! > 0)
                  _infoRow('Max Spend'.tr, '₦${coupon.maxSpend!.toStringAsFixed(0)}'),
                if (coupon.applicableOn != null && coupon.applicableOn!.isNotEmpty)
                  _infoRow('Applies To'.tr, coupon.applicableOn!),
                if (coupon.expiryDate != null && coupon.expiryDate!.isNotEmpty)
                  _infoRow(
                    isActive ? 'Expires'.tr : 'Expired'.tr,
                    coupon.expiryDate!,
                    valueColor: isActive ? null : Colors.red,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
