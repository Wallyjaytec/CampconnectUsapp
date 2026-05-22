import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/product/controller/popular_items_controller.dart';
import 'package:kartly_e_commerce/modules/product/widgets/star_row.dart';

class PopularItemsSection extends StatelessWidget {
  const PopularItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PopularItemsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      if (controller.products.isEmpty) {
        return const SizedBox.shrink();
      }

      final displayList = controller.products.length > 8
          ? controller.products.sublist(0, 8)
          : controller.products;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  'Popular Items'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(AppRoutes.popularItemsView);
                  },
                  child: Text(
                    'View All'.tr,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = displayList[i];
                return SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(
                      AppRoutes.productDetailsView,
                      arguments: {'permalink': p.slug},
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkProductCardColor
                            : AppColors.lightProductCardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Iconsax.gallery_remove_copy),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                StarRow(rating: p.rating),
                                const SizedBox(height: 4),
                                Text(
                                  formatCurrency(p.price, applyConversion: true),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
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
