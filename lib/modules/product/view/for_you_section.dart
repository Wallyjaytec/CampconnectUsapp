import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/model/product_model.dart';
import '../../product/widgets/star_row.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/for_you_controller.dart';

class ForYouSection extends StatelessWidget {
  ForYouSection({super.key});

  static ForYouController sectionController() => ForYouController.ensure();

  static Future<void> refreshSection() async {
    await sectionController().refreshRandom();
  }

  final ForYouController controller = ForYouController.ensure();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "For You".tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Obx(() {
            if (controller.isLoading.value && controller.suggestions.isEmpty) {
              return const _GridShimmer();
            }
            if (controller.error.isNotEmpty && controller.suggestions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(controller.error.value)),
              );
            }

            final list = controller.suggestions.toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No suggestions yet'.tr)),
              );
            }

            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 240,
                  ),
                  itemBuilder: (_, i) => _ProductCard(
                    product: list[i],
                    onTap: () => _openDetails(list[i]),
                  ),
                ),

                _buildLoadMoreIndicator(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      if (!controller.hasMore.value && controller.suggestions.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              "You have reached the end".tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  void _openDetails(ProductModel p) {
    controller.logView(p);

    final slug = p.slug.toString();
    if (slug.isNotEmpty) {
      Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug});
    } else {
      Get.toNamed(AppRoutes.productDetailsView, arguments: {'id': p.id});
    }
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  const _ProductCard({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkProductCardColor
            : AppColors.lightProductCardColor,
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
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: product.imageUrl.isEmpty
                          ? Container(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                            )
                          : CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) => const _ImageShimmer(),
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Obx(() {
                        final wish = WishlistController.ensure();
                        final inWish = wish.ids.contains(product.id);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: InkWell(
                              onTap: () => wish.toggle(product),
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  product.title,
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
              StarRow(rating: product.rating),
              const SizedBox(height: 6),
              Column(
                children: [
                  Text(
                    formatCurrency(product.price, applyConversion: true),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.whiteColor
                          : AppColors.primaryColor,
                    ),
                  ),
                  if (product.oldPrice != null)
                    _CenterStrike(
                      text: formatCurrency(
                        product.oldPrice,
                        applyConversion: true,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.55),
                        decoration: TextDecoration.none,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageShimmer extends StatelessWidget {
  const _ImageShimmer();
  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(
      height: double.infinity,
      width: double.infinity,
      borderRadius: 0,
    );
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 240,
      ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            children: [
              Expanded(child: ShimmerBox(borderRadius: 10)),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ShimmerBox(height: 12, borderRadius: 6),
              ),
              SizedBox(height: 8),
              ShimmerBox(height: 12, borderRadius: 6, width: 80),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _CenterStrike extends StatelessWidget {
  const _CenterStrike({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style;
    final double h = s.fontSize != null ? s.fontSize! * 0.07 : 1;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: s),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              height: h,
              color: (s.color ?? Theme.of(context).colorScheme.onSurface)
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
