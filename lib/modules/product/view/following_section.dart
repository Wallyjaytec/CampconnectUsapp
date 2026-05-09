import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/product/controller/following_products_controller.dart';
import 'package:kartly_e_commerce/shared/widgets/shimmer_widgets.dart';

class FollowingSection extends StatefulWidget {
  const FollowingSection({super.key});

  @override
  State<FollowingSection> createState() => _FollowingSectionState();
}

class _FollowingSectionState extends State<FollowingSection> {
  late final FollowingProductsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FollowingProductsController(), tag: 'followingSection');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: ShimmerBox(height: 16, width: 100, borderRadius: 8),
            ),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => const ShimmerBox(height: 220, width: 140, borderRadius: 10),
              ),
            ),
          ],
        );
      }

      if (controller.error.isNotEmpty) {
        return const SizedBox.shrink();
      }

      if (controller.products.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.heart_circle_copy, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Follow a seller to see products under this section'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Row(
              children: [
                Text('Following'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.followingProductsView),
                  child: Text('View All'.tr, style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: controller.products.length > 10 ? 10 : controller.products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = controller.products[i];
                return SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug}),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Iconsax.gallery_remove_copy),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(formatCurrency(p.price, applyConversion: true), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
