import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/data/repositories/product_details_repository.dart';
import 'package:kartly_e_commerce/modules/product/model/related_product_model.dart';
import 'package:kartly_e_commerce/modules/product/widgets/single_price_tag.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/related_products_repository.dart';
import '../../product/controller/related_products_controller.dart';
import '../../product/view/product_details_view.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/product_details_controller.dart';
import '../widgets/star_row.dart';

class RelatedProductView extends StatelessWidget {
  const RelatedProductView({super.key});

  @override
  Widget build(BuildContext context) {
    final relController = Get.put(
      RelatedProductsController(RelatedProductsRepository(ApiService())),
      permanent: false,
    );

    final details = Get.find<ProductDetailsController>();
    relController.ensureLoaded(details.product.value?.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Related Products".tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Obx(() {
              if (relController.isLoading.value &&
                  relController.products.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (relController.error.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${'Failed to load related products'.tr}: ${relController.error}',
                  ),
                );
              }

              final items = relController.products;
              if (items.isEmpty) {
                return const SizedBox.shrink();
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 240,
                ),
                itemBuilder: (_, i) => _ProductCard(productIndex: i),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int productIndex;
  const _ProductCard({required this.productIndex});

  RelatedProductsController get controller =>
      Get.find<RelatedProductsController>();

  @override
  Widget build(BuildContext context) {
    final p = controller.products[productIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 10),
            color: Color(0x146A7EC8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            Get.to(
              () => ProductDetailsView(),
              arguments: {'permalink': p.slug},
              preventDuplicates: false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: p.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: (_, __, ___) => Container(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.06),
                              child: const Center(
                                child: Icon(Iconsax.gallery_remove_copy),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Obx(() {
                          final wish = WishlistController.ensure();
                          final inWish = wish.ids.contains(p.id);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: InkWell(
                                onTap: () => wish.toggle(p.asProductModel()),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    inWish ? Iconsax.heart : Iconsax.heart_copy,
                                    size: 20,
                                    color: inWish
                                        ? AppColors.favColor
                                        : AppColors.whiteColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(child: StarRow(rating: p.rating)),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.center,
                  child: SinglePriceTag.forRelated(p),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
