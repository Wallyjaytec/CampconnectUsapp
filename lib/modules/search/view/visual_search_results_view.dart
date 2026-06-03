import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../controller/visual_search_controller.dart';

class VisualSearchResultsView extends StatelessWidget {
  const VisualSearchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisualSearchController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        title: Text('Visual Search'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const _LoadingGrid();
        }

        if (controller.error.value.isNotEmpty) {
          return _ErrorView(
            message: controller.error.value,
            onRetry: () => controller.searchFromGallery(),
            onCamera: () => controller.searchFromCamera(),
          );
        }

        if (controller.results.isEmpty) {
          return _EmptyView(
            onGallery: () => controller.searchFromGallery(),
            onCamera: () => controller.searchFromCamera(),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('${controller.results.length} ${'products found'.tr}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => controller.searchFromGallery(),
                    icon: const Icon(Iconsax.gallery_copy, size: 16),
                    label: Text('New Search'.tr),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: controller.results.length,
                itemBuilder: (context, index) {
                  final product = controller.results[index];
                  return _ProductCard(product: product, isDark: isDark);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final bool isDark;

  const _ProductCard({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details using product_id
        final id = int.tryParse(product.productId) ?? 0;
        if (id > 0) {
          Get.toNamed('/product_details_view', arguments: {'id': id, 'slug': ''});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: AppConfig.assetUrl(product.imageUrl),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price.isNotEmpty ? formatCurrency(double.tryParse(product.price) ?? 0, applyConversion: true) : '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _EmptyView({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.camera_copy, size: 80, color: AppColors.primaryColor),
            const SizedBox(height: 16),
            Text('Search by image'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Take a photo or choose from gallery to find similar products'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Iconsax.camera_copy, size: 18),
                  label: Text('Camera'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Iconsax.gallery_copy, size: 18),
                  label: Text('Gallery'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCamera;

  const _ErrorView({required this.message, required this.onRetry, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text('Retry'.tr),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Iconsax.camera_copy, size: 18),
                  label: Text('Camera'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white12 : Colors.black12;
    final highlight = isDark ? Colors.white24 : Colors.black26;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
