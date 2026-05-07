import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../home/widgets/banner_carousel.dart';
import '../../product/controller/product_details_controller.dart';
import '../../product/widgets/star_row.dart';
import '../controller/seller_products_controller.dart';
import '../model/seller_shop_model.dart';

class SellerView extends StatelessWidget {
  const SellerView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as SellerNavArgs;

    final ctrl = Get.put<SellerProductsController>(
      SellerProductsController(slug: args.slug),
      permanent: false,
    );

    ctrl.seedHeaderMetaFromArgs(args);

    return Scaffold(
  body: SafeArea(
    top: true,
    bottom: false,
    child: RefreshIndicator(
      onRefresh: () => ctrl.load(),
      child: NestedScrollView(
  floatHeaderSlivers: true,
  physics: const BouncingScrollPhysics(),
  headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leadingWidth: 44,
              elevation: 0,
              leading: const BackIconWidget(),
              centerTitle: false,
              title: Text(
                args.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                ),
              ),
              actionsPadding: const EdgeInsetsDirectional.only(end: 10),
              actions: const [
                SearchIconWidget(),
                CartIconWidget(),
                NotificationIconWidget(),
              ],
              primary: false,
              floating: true,
              snap: true,
              pinned: false,
            ),
          ];
        },
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final banner = args.shopBanner ?? '';

                  if (banner.isEmpty) {
                    return const SizedBox();
                  }

                  return CachedNetworkImage(
                    imageUrl: banner,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const _ImageBoxShimmer(),
                    errorWidget: (_, __, ___) =>
                        const Icon(Iconsax.gallery_remove_copy),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: _SellerHeader(args: args)),
            SliverToBoxAdapter(child: _SectionHeader('Newest items'.tr)),
            const SliverToBoxAdapter(
              child: _SellerCarousel(section: _SellerSection.newItems),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: _SectionHeader('Top Selling Products'.tr),
            ),
            const SliverToBoxAdapter(
              child: _SellerCarousel(section: _SellerSection.topSelling),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _SectionHeader('Featured Items'.tr)),
            const SliverToBoxAdapter(
              child: _SellerCarousel(
                section: _SellerSection.featured,
                bottomPadding: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
class _SellerHeader extends GetView<SellerProductsController> {
  final SellerNavArgs args;
  const _SellerHeader({required this.args});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: args.logo,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.store_mall_directory_outlined),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() {
                final followers = controller.followers.value;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (args.ratingPercent > 0) const SizedBox(height: 0),
                    if (args.ratingPercent > 0)
                      Text(
                        '${args.ratingPercent}% ${'Seller Ratings'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          height: 1,
                        ),
                      ),
                    const SizedBox(height: 2),
           
                      Text(
                        '${_compactCount(followers)} ${'Followers'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(width: 10),
            Obx(() {
  final c = Get.find<SellerProductsController>();
  final following = c.isFollowing.value;
  final busy = c.followBusy;
  return TextButton(
    onPressed: busy
        ? null
        : following
            ? () => c.unfollowShop()
            : () => c.followShop(),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: following
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : AppColors.primaryColor,
      foregroundColor: following
          ? Theme.of(context).colorScheme.onSurface
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    child: Text(following ? 'Following'.tr : 'Follow'.tr),
  );
}),
          ],
        ),
      ),
    );
  }
}

String _compactCount(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}M';
  } else if (n >= 1000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}k';
  }
  return n.toString();
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum _SellerSection { newItems, topSelling, featured }

class _SellerCarousel extends GetView<SellerProductsController> {
  final _SellerSection section;
  final double bottomPadding;
  const _SellerCarousel({required this.section, this.bottomPadding = 0});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW * 0.34;
    const cardH = 180.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottomPadding),
      child: GetX<SellerProductsController>(
        builder: (c) {
          final List<SellerProductModel> list = switch (section) {
            _SellerSection.newItems => c.newItems,
            _SellerSection.topSelling => c.topSellingItems,
            _SellerSection.featured => c.featuredItems,
          };

          if (c.isLoading.value && list.isEmpty) {
            return SizedBox(
              height: cardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, __) =>
                    _CardShimmer(width: cardW, height: cardH),
              ),
            );
          }
          if (c.isError.value) {
            return SizedBox(
              height: 80,
              child: Center(
                child: Text('${'Failed to load'.tr}: ${c.errorMessage}'),
              ),
            );
          }
          if (list.isEmpty) {
            return SizedBox(
              height: 60,
              child: Center(child: Text('No items found'.tr)),
            );
          }

          return BannerCarousel(
            height: cardH,
            viewportFraction: 0.34,
            padEnds: true,
            itemSpacing: 8,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            items: List.generate(list.length, (i) {
              final p = list[i];
              final img = AppConfig.assetUrl(p.thumbnailImage);
              final price = p.price.toDouble();
              final base = p.basePrice.toDouble();
              final rat = p.avgRating.toDouble();

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (Get.isRegistered<ProductDetailsController>()) {
                    Get.delete<ProductDetailsController>(force: true);
                  }
                  Get.toNamed(
                    AppRoutes.productDetailsView,
                    arguments: {'permalink': p.slug},
                  );
                },
                child: _SellerFlashCardItem(
                  title: p.name,
                  imageUrl: img,
                  price: price,
                  basePrice: base,
                  rating: rat,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SellerFlashCardItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double price;
  final double basePrice;
  final double rating;

  const _SellerFlashCardItem({
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
              child: (imageUrl.isEmpty)
                  ? const _ImageBoxShimmer()
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => const _ImageBoxShimmer(),
                      errorWidget: (_, __, ___) =>
                          const Icon(Iconsax.gallery_remove_copy),
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

class _ImageBoxShimmer extends StatelessWidget {
  const _ImageBoxShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).dividerColor.withValues(alpha: 0.08),
      highlightColor: Theme.of(context).dividerColor.withValues(alpha: 0.18),
      child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  final double width;
  final double height;
  const _CardShimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        highlightColor: Theme.of(context).dividerColor.withValues(alpha: 0.18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
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
              const Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox.expand(
                    child: ColoredBox(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterStrike extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _CenterStrike({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).textTheme.bodySmall;
    final tp = TextPainter(
      text: TextSpan(text: text, style: effectiveStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    final w = tp.size.width;
    final h = tp.size.height;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color:
                  (effectiveStyle?.color ??
                          Theme.of(context).textTheme.bodySmall?.color)
                      ?.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

