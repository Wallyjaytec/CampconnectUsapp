import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatters.dart';
import '../controller/top_sales_controller.dart';
import '../model/product_model.dart';
import '../widgets/star_row.dart';

class TopSalesSection extends StatelessWidget {
  TopSalesSection({super.key, this.limit = 4});

  final int limit;

  final TopSalesController controller = Get.put(
    TopSalesController(),
    tag: 'topSalesSection',
    permanent: false,
  );

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
                  "Top Sales".tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.openViewAll,
                child: Text('View All'.tr),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Obx(() {
            if (controller.isLoading.value) {
              return const _SkeletonList();
            }
            if (controller.error.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(controller.error.value)),
              );
            }
            final list = controller.items.take(limit).toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No top sales found'.tr)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 12),
                child: _ProductRow(
                  product: list[i],
                  formatPrice: controller.formatPrice,
                  onTap: () => _openDetails(list[i]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openDetails(ProductModel p) {
    final slug = p.slug.toString();
    if (slug.isNotEmpty) {
      Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug});
    } else {
      Get.toNamed(AppRoutes.productDetailsView, arguments: {'id': p.id});
    }
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.formatPrice,
    this.onTap,
  });

  final ProductModel product;
  final String Function(double) formatPrice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const double tileHeight = 92;
    const double imgWidth = 92;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        height: tileHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: imgWidth,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 6),
                  StarRow(rating: product.rating),
                  const SizedBox(height: 6),
                  Row(
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
                      const SizedBox(width: 8),
                      if (product.oldPrice != null)
                        _CenterStrike(
                          text: formatCurrency(
                            product.oldPrice!,
                            applyConversion: true,
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.55),
                                decoration: TextDecoration.none,
                              ),
                        ),
                    ],
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

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    const double imgWidth = 92;
    const double rowHeight = 92;

    Widget block({
      required double width,
      required double height,
      required BuildContext context,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    Widget row() => SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          Container(
            width: imgWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(width: 220, height: 12, context: context),
                const SizedBox(height: 8),
                Row(
                  children: [
                    block(width: 70, height: 14, context: context),
                    const SizedBox(width: 8),
                    block(width: 60, height: 12, context: context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        row(),
        const SizedBox(height: 12),
        row(),
        const SizedBox(height: 12),
        row(),
      ],
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
