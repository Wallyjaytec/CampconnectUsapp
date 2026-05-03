import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../home/widgets/banner_carousel.dart';
import '../controller/discount_sales_controller.dart';
import '../widgets/star_row.dart';

class DiscountSalesSection extends StatelessWidget {
  const DiscountSalesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiscountSalesController());
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const _DiscountShimmer();
      }

      if (controller.products.isEmpty) {
        return const SizedBox.shrink();
      }

      final show = controller.products.take(6).toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.discountSalesView),
              child: Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primaryColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icons/discount_banner.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Discount Sales'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.discountSalesView),
                  child: Text('View All'.tr),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (show.isEmpty)
              const _ItemsRowShimmer()
            else
              BannerCarousel(
                height: 180,
                viewportFraction: 0.34,
                padEnds: true,
                itemSpacing: 8,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                items: List.generate(show.length, (i) {
                  final p = show[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (p.slug.isNotEmpty) {
                        Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug});
                      }
                    },
                    child: _DiscountCardItem(
                      title: p.title,
                      imageUrl: p.imageUrl,
                      price: p.price,
                      oldPrice: p.oldPrice,
                      rating: p.rating,
                    ),
                  );
                }),
              ),
          ],
        ),
      );
    });
  }
}

class _DiscountCardItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double price;
  final double? oldPrice;
  final double rating;

  const _DiscountCardItem({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.oldPrice,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 20, offset: Offset(0, 10), color: Color(0x146A7EC8))],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.normal, height: 1)),
          ),
          const SizedBox(height: 6),
          StarRow(rating: rating),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(formatCurrency(price, applyConversion: true), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? AppColors.whiteColor : AppColors.primaryColor)),
                if (oldPrice != null && oldPrice! > price)
                  _CenterStrike(text: formatCurrency(oldPrice!, applyConversion: true), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.55), decoration: TextDecoration.none)),
              ],
            ),
          ),
        ],
      ),
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
        Positioned.fill(child: Align(alignment: Alignment.center, child: Container(height: h, color: (s.color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.6)))),
      ],
    );
  }
}

class _DiscountShimmer extends StatelessWidget {
  const _DiscountShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 150, borderRadius: 10),
          SizedBox(height: 6),
          _HeaderShimmer(),
          SizedBox(height: 6),
          _ItemsRowShimmer(),
        ],
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(height: 16, width: 120, borderRadius: 6),
        Spacer(),
        ShimmerBox(height: 14, width: 140, borderRadius: 6),
      ],
    );
  }
}

class _ItemsRowShimmer extends StatelessWidget {
  const _ItemsRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(child: ShimmerBox(borderRadius: 10)),
          SizedBox(width: 8),
          Expanded(child: ShimmerBox(borderRadius: 10)),
          SizedBox(width: 8),
          Expanded(child: ShimmerBox(borderRadius: 10)),
          SizedBox(width: 8),
          Expanded(child: ShimmerBox(borderRadius: 10)),
        ],
      ),
    );
  }
}
