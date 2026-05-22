import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/product/controller/latest_collection_controller.dart';
import 'package:kartly_e_commerce/modules/product/widgets/star_row.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/search_icon_widget.dart';

class LatestCollectionView extends StatelessWidget {
  const LatestCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LatestCollectionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Latest Collection'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
        actionsPadding: const EdgeInsetsDirectional.only(end: 10),
        actions: const [
          SearchIconWidget(),
          CartIconWidget(),
          NotificationIconWidget(),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.products.isEmpty) {
          return Center(
            child: Text('No products found'.tr),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 240,
          ),
          itemCount: controller.products.length,
          itemBuilder: (_, i) {
            final p = controller.products[i];
            return GestureDetector(
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
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: p.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) =>
                              const Icon(Iconsax.gallery_remove_copy),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          StarRow(rating: p.rating),
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
            );
          },
        );
      }),
    );
  }
}
