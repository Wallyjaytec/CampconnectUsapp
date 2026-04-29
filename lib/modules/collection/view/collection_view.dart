import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/model/product_model.dart';
import '../../product/widgets/star_row.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/collection_controller.dart';
import '../model/collection_model.dart';

class CollectionView extends StatefulWidget {
  const CollectionView({super.key});

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  final _scrollCtrl = ScrollController();
  late final CollectionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CollectionController(), permanent: false);
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      final int? collectionId = (args is Map && args['collectionId'] != null)
          ? int.tryParse(args['collectionId'].toString())
          : null;

      final String? titleOverride = (args is Map && args['title'] != null)
          ? args['title'].toString()
          : null;

      final int perPage = (args is Map && args['perPage'] != null)
          ? int.tryParse(args['perPage'].toString()) ?? 10
          : 10;

      if (collectionId != null) {
        controller.open(
          collectionId: collectionId,
          titleOverride: titleOverride,
          perPage: perPage,
        );
      } else {
        controller.title.value = 'Collection'.tr;
        controller.error.value = 'Collection ID not provided'.tr;
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          elevation: 0,
          title: Obx(
            () => Text(
              controller.title.value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.items.isEmpty) {
            return const _GridShimmer();
          }
          if (controller.error.isNotEmpty && controller.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.error.value, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.refreshFirstPage,
                      child: Text('Retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshFirstPage,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Obx(() {
                    final url = controller.headerImageUrl.value;
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 3.6,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const _ImageShimmer(),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 240,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ListCard(index: i),
                      childCount: controller.items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: controller.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink(),
                ),
                SliverToBoxAdapter(
                  child: (!controller.hasMore && controller.items.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Center(child: Text('No more products'.tr)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final int index;
  const _ListCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionController>();
    final p = controller.items[index];
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
          onTap: () {
            final permalink = p.slug;
            Get.toNamed(
              AppRoutes.productDetailsView,
              arguments: {'permalink': permalink},
            );
          },
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: p.imageUrl.isEmpty
                          ? Container(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                            )
                          : CachedNetworkImage(
                              imageUrl: p.imageUrl,
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
                        final inWish = wish.ids.contains(p.id ?? -1);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => wish.toggle(_toProductModel(p)),
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
                  p.title,
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
              StarRow(rating: p.rating),
              Column(
                children: [
                  Text(
                    formatCurrency(p.price, applyConversion: true),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.whiteColor
                          : AppColors.primaryColor,
                    ),
                  ),
                  if (p.oldPrice != null)
                    _CenterStrike(
                      text: formatCurrency(p.oldPrice, applyConversion: true),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
      itemCount: 8,
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

ProductModel _toProductModel(CollectionGridItem g) {
  return ProductModel(
    id: g.id ?? -1,
    title: g.title,
    slug: g.slug,
    image: g.imageUrl,
    price: g.price.toDouble(),
    oldPrice: g.oldPrice?.toDouble(),
    currency: '',
    rating: g.rating.toDouble(),
    totalReviews: 0,
    hasVariant: false,
    quantity: 0,
    unit: '',
    shopName: null,
  );
}
