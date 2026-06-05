import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/modules/product/controller/new_product_controller.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/widgets/star_row.dart';
import '../../wishlist/controller/wishlist_controller.dart';

class NewProductView extends StatefulWidget {
  const NewProductView({super.key});

  @override
  State<NewProductView> createState() => _NewProductViewState();
}

class _NewProductViewState extends State<NewProductView> {
  final _scrollCtrl = ScrollController();
  late final NewProductController controller;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<NewProductController>()) {
      Get.delete<NewProductController>(force: true);
    }
    controller = Get.put(
      NewProductController(suppressInitialFetch: true),
      permanent: false,
    );

    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      final String titleOverride = (args is Map && args['title'] != null)
          ? args['title'].toString()
          : 'New Products';
      final int? catId = (args is Map && args['categoryId'] != null)
          ? int.tryParse(args['categoryId'].toString())
          : null;

      controller.open(categoryId: catId, titleOverride: titleOverride);
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  Future<void> _openFilter() async {
    final res = await Get.toNamed(
      AppRoutes.productSearchFilter,
      arguments: {
        'currentSorting': controller.currentSorting,
        'currentBrandId': controller.currentBrandId.isEmpty
            ? null
            : int.tryParse(controller.currentBrandId),
        'currentCategoryId': controller.categoryId,
        'currentMinPrice': controller.minPrice,
        'currentMaxPrice': controller.maxPrice,
        'currentRating': controller.currentRating,
      },
    );

    if (res is Map) {
      controller.isLoading.value = true;
      controller.items.clear();
      controller.applyFilter(res);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();

    if (Get.isRegistered<NewProductController>()) {
      Get.delete<NewProductController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
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
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
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

          if (!controller.isLoading.value &&
              controller.error.isEmpty &&
              controller.products.isEmpty &&
              !controller.hasMore) {
            return Center(child: Text('There is no item to show'.tr));
          }

          return RefreshIndicator(
            onRefresh: controller.refreshFirstPage,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: Obx(() {
                      final brandModels = controller.brands;
                      final selectedBrandId = controller.selectedBrandId.value;

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: 1 + brandModels.length,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return _CategoryChip(
                              label: 'Filter',
                              selected: false,
                              leading: const Icon(Iconsax.filter_copy),
                              trailing: const Icon(Iconsax.arrow_down_1_copy),
                              onTap: _openFilter,
                            );
                          }
                          final b = brandModels[i - 1];
                          final on = (b.id == selectedBrandId);
                          return _CategoryChip(
                            label: b.name,
                            selected: on,
                            onTap: () => controller.pickBrand(b.id),
                          );
                        },
                      );
                    }),
                  ),
                ),

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
                      (context, i) =>
                          _ListCard(index: i, controller: controller),
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
  final NewProductController controller;
  const _ListCard({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
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
              arguments: {'permalink': permalink, 'product_id': p.id.toString()},
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
                                  const Icon(Iconsax.gallery_remove_copy),
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
                          child: InkWell(
                            onTap: () => wish.toggle(p),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = selected
        ? AppColors.primaryColor
        : (isDark ? AppColors.darkCardColor : AppColors.lightCardColor);
    final Color fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : const Color(0xFF333333));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 18),
                  child: leading!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                IconTheme(
                  data: IconThemeData(color: fg, size: 14),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
