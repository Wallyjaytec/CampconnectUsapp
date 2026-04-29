import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../controller/category_controller.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({
    super.key,
    this.onViewAll,
    this.onTapCategory,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.itemExtent = 48,
  });

  final VoidCallback? onViewAll;
  final void Function(int categoryId)? onTapCategory;
  final EdgeInsetsGeometry padding;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkCardColor
        : AppColors.lightCardColor;

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Categories'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    padding: const EdgeInsets.only(right: 16),
                    itemBuilder: (_, __) => _ShimmerCategoryItem(
                      extent: itemExtent,
                      cardColor: cardColor,
                    ),
                  );
                }

                if (controller.error.isNotEmpty) {
                  return Center(
                    child: Text(
                      controller.error.value,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (controller.categories.isEmpty) {
                  return Center(child: Text('No categories found'.tr));
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 5),
                  padding: const EdgeInsets.only(right: 16),
                  itemBuilder: (context, index) {
                    final cat = controller.categories[index];
                    return _CategoryItem(
                      name: cat.name,
                      imageUrl: cat.imageUrl,
                      extent: itemExtent,
                      onTap: () => onTapCategory?.call(cat.id),
                      cardColor: cardColor,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.name,
    required this.imageUrl,
    required this.extent,
    required this.cardColor,
    this.onTap,
  });

  final String name;
  final String imageUrl;
  final double extent;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 80,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          children: [
            ClipRRect(
              child: SizedBox(
                width: extent,
                height: extent,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.image_not_supported_outlined)
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            ShimmerCircle(diameter: extent),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                name,
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
  }
}

class _ShimmerCategoryItem extends StatelessWidget {
  const _ShimmerCategoryItem({required this.extent, required this.cardColor});
  final double extent;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final radius = extent / 2;

    return Container(
      padding: const EdgeInsets.all(8),
      width: 80,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ShimmerBox(
              width: extent,
              height: extent,
              borderRadius: radius,
            ),
          ),
          const SizedBox(height: 8),
          const ShimmerBox(width: 48, height: 10, borderRadius: 6),
        ],
      ),
    );
  }
}
