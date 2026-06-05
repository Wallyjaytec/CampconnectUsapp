import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/modules/brand/controller/brand_controller.dart';
import 'package:campconnectus_marketplace/modules/product/model/brand_model.dart';
import 'package:campconnectus_marketplace/shared/widgets/shimmer_widgets.dart';

class BrandView extends StatelessWidget {
  const BrandView({super.key, this.onViewAll, this.onTapBrand});
  final VoidCallback? onViewAll;
  final void Function(Brand brand)? onTapBrand;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrandController());
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkCardColor
        : AppColors.lightCardColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Brands'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onViewAll, child: Text('View All'.tr)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 105,
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, __) => _shimmerItem(cardColor),
                );
              }
              if (controller.error.isNotEmpty) {
                return Center(child: Text(controller.error.value));
              }
              if (controller.brands.isEmpty) {
                return Center(child: Text('No brands found'.tr));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 5),
                itemBuilder: (_, i) {
                  final b = controller.brands[i];
                  return InkWell(
                    onTap: () => onTapBrand?.call(b),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: b.logo.isEmpty
                                  ? const Icon(Icons.store, size: 30)
                                  : CachedNetworkImage(
                                      imageUrl: b.logoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.store, size: 30),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              b.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _shimmerItem(Color cardColor) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const ShimmerCircle(diameter: 48),
          const SizedBox(height: 8),
          const ShimmerBox(width: 48, height: 10, borderRadius: 6),
        ],
      ),
    );
  }
} 
