import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../home/widgets/banner_carousel.dart';
import '../controller/flash_deals_controller.dart';
import '../widgets/star_row.dart';

class FlashDealsSection extends StatelessWidget {
  const FlashDealsSection({super.key});

  static FlashDealsController sectionController() {
    if (Get.isRegistered<FlashDealsController>()) {
      return Get.find<FlashDealsController>();
    }
    return Get.put(FlashDealsController(), permanent: true);
  }

  static Future<void> refreshSection() async {
    final c = sectionController();
    await c.refreshSection();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final controller = sectionController();
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isSectionLoading.value) {
        return const _SectionShimmer();
      }

      if (!controller.hasActive) {
        return const SizedBox.shrink();
      }

      final deal = controller.sectionDeal.value!;
      final products = controller.sectionProducts;
      final show = products.take(4).toList();

      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flash Sale Banner Image
            if (deal.backgroundImage != null && deal.backgroundImage!.isNotEmpty)
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.flashDealsView),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: deal.backgroundImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Text(
                  deal.title.isNotEmpty ? deal.title.tr : 'Flash Deals'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Obx(() {
                  final d = controller.remaining.value;
                  final days = d.inDays;
                  final hours = d.inHours % 24;
                  final mins = d.inMinutes % 60;
                  final secs = d.inSeconds % 60;

                  TextStyle big = theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  );
                  TextStyle small = theme.textTheme.labelSmall!.copyWith();

                  Widget block(String v, String lbl) => Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(v, style: big),
                      Text(lbl, style: small),
                    ],
                  );

                  return Row(
                    children: [
                      block(_two(days), 'day'.tr),
                      const SizedBox(width: 12),
                      Text(':', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 12),
                      block(_two(hours), 'hour'.tr),
                      const SizedBox(width: 12),
                      Text(':', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 12),
                      block(_two(mins), 'minute'.tr),
                      const SizedBox(width: 12),
                      Text(':', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 12),
                      block(_two(secs), 'second'.tr),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed(AppRoutes.flashDealsView),
                child: Text('View All'.tr),
              ),
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
                      final slug = p.slug;
                      if (slug.isNotEmpty) {
                        Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug});
                      }
                    },
                    child: _FlashCardItem(
                      title: p.name,
                      imageUrl: p.image,
                      price: p.price,
                      basePrice: p.basePrice,
                      rating: (p.rating),
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

class _FlashCardItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double price;
  final double basePrice;
  final double rating;

  const _FlashCardItem({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.basePrice,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.normal, height: 1),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: StarRow(rating: rating),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatCurrency(price, applyConversion: true),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.whiteColor
                        : AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                if (basePrice > price)
                  _CenterStrike(
                    text: formatCurrency(basePrice, applyConversion: true),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.55),
                      decoration: TextDecoration.none,
                    ),
                  ),
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

class _SectionShimmer extends StatelessWidget {
  const _SectionShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_HeaderShimmer(), SizedBox(height: 6), _ItemsRowShimmer()],
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
