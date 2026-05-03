import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/product_repository.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/widgets/star_row.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/new_product_list_controller.dart';

class NewProductListView extends StatefulWidget {
  const NewProductListView({super.key});

  @override
  State<NewProductListView> createState() => _NewProductListViewState();
}

class _NewProductListViewState extends State<NewProductListView> {
  final _scrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;
  late final NewProductListController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<NewProductListController>()) {
      Get.delete<NewProductListController>(force: true);
    }
    controller = Get.put(
      NewProductListController(ProductRepository(ApiService())),
    );
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int toInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        return int.tryParse(v.toString()) ?? 0;
      }

      final args = Get.arguments;
      final params = Get.parameters;

      final String sortingStr = (args is Map && args['sorting'] != null)
          ? args['sorting'].toString()
          : (params['sorting'] ?? 'newest');
      controller.setSorting(
        controller.parseProductSorting(sortingStr),
        triggerReload: false,
      );

      final String? customTitle = (args is Map && args['title'] != null)
          ? args['title'].toString()
          : null;
      if (customTitle != null && customTitle.isNotEmpty) {
        controller.overrideTitle(customTitle);
      }

      final int argCatId = (args is Map)
          ? toInt(args['categoryId'] ?? args['category_id'] ?? args['cat'] ?? args['id'])
          : 0;
      final String? argCatName = (args is Map)
          ? (args['categoryName'] ?? args['name'])?.toString()
          : null;

      final int? argSubId = (args is Map)
          ? toInt(args['subcategoryId'] ?? args['sub'] ?? args['subId'])
          : null;
      final String? argSubName = (args is Map)
          ? args['subcategoryName']?.toString()
          : null;

      final int? argLeafId = (args is Map) ? toInt(args['leafId']) : null;
      final String? argLeafName = (args is Map)
          ? args['leafTag']?.toString()
          : null;

      final int qCatId = toInt(params['categoryId'] ?? params['category_id'] ?? params['cat'] ?? params['id']);
      final String? qCatName = params['categoryName'] ?? params['name'];

      final int qSubId = toInt(params['subcategoryId'] ?? params['sub'] ?? params['subId']);
      final String? qSubName = params['subcategoryName'];

      final int qLeafId = toInt(params['leafId']);
      final String? qLeafName = params['leafTag'];

      final int pickedCatId = (argCatId != 0) ? argCatId : qCatId;
      final String? pickedCatName =
          (argCatName != null && argCatName.toString().isNotEmpty) ? argCatName : qCatName;

      final int? pickedSubId = (argSubId != null && argSubId > 0) ? argSubId : (qSubId > 0 ? qSubId : null);
      final String? pickedSubName =
          (argSubName != null && argSubName.toString().isNotEmpty) ? argSubName : (qSubName?.toString());

      final int? pickedLeafId = (argLeafId != null && argLeafId > 0) ? argLeafId : (qLeafId > 0 ? qLeafId : null);
      final String? pickedLeafName =
          (argLeafName != null && argLeafName.toString().isNotEmpty) ? argLeafName : (qLeafName?.toString());

      controller.clearOnlyFilters(resetSorting: true);

      final int brandId = (args is Map) ? toInt(args['brandId']) : 0;
      final String? brandName = (args is Map) ? args['brandName']?.toString() : null;

      if (brandId > 0) {
        controller.openForBrand(brandId: brandId, brandName: brandName);
      } else {
        controller.openForCategory(
          categoryId: pickedCatId,
          categoryName: pickedCatName?.toString(),
          subcategoryId: pickedSubId,
          subcategoryName: pickedSubName,
          leafId: pickedLeafId,
          leafName: pickedLeafName,
        );
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      controller.loadMore();
    }
    if (!_showBackToTop) setState(() => _showBackToTop = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showBackToTop) setState(() => _showBackToTop = false);
    });
  }

  void _scrollToTop() {
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
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
          titleSpacing: 0,
          leadingWidth: 44,
          elevation: 0,
          leading: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () {
                if (Get.isRegistered<NewProductListController>()) {
                  Get.delete<NewProductListController>(force: true);
                }
                Get.back();
              },
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
              splashRadius: 20,
            ),
          ),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
          title: Obx(() => Text(controller.titleRx.value, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18), overflow: TextOverflow.ellipsis)),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.products.isEmpty) {
            return const _GridShimmer();
          }
          if (controller.error.isNotEmpty && controller.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(controller.error.value, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: controller.loadInitial, child: Text('Retry'.tr)),
                ]),
              ),
            );
          }

          if (!controller.isLoading.value && controller.error.isEmpty && controller.products.isEmpty && !controller.hasMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/categories_empty.png', width: 100, height: 100),
                    const SizedBox(height: 16),
                    Text('No products found under this brand'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Browse later or check other brands'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: controller.loadInitial,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 36, child: Obx(() {
                        final brandModels = controller.brands;
                        final selectedBrandId = controller.selectedBrandId.value;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: 1 + brandModels.length,
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return controller.products.isEmpty ? const SizedBox.shrink() : _CategoryChip(
                                label: 'Filter'.tr, selected: false,
                                leading: const Icon(Iconsax.filter_copy), trailing: const Icon(Iconsax.arrow_down_1_copy),
                                onTap: () async { final res = await Get.toNamed(AppRoutes.productFilterView); if (res is Map) controller.applyFilter(res); },
                              );
                            }
                            final b = brandModels[i - 1];
                            final on = (b.id == selectedBrandId);
                            return _CategoryChip(label: b.name, selected: on, onTap: () => controller.pickBrand(b.id));
                          },
                        );
                      })),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240),
                        delegate: SliverChildBuilderDelegate((context, i) => _ListCard(index: i), childCount: controller.products.length),
                      ),
                    ),
                    SliverToBoxAdapter(child: Obx(() => controller.isLoadingMore.value ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink())),
                    SliverToBoxAdapter(child: (!controller.hasMore && controller.products.isNotEmpty) ? Padding(padding: const EdgeInsets.only(bottom: 24), child: Center(child: Text('No more products'.tr))) : const SizedBox.shrink()),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: _showBackToTop ? 20 : -60,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _showBackToTop ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: AppColors.primaryColor,
                    onPressed: _scrollToTop,
                    child: const Icon(Iconsax.arrow_up_2_copy, color: Colors.white),
                  ),
                ),
              ),
            ],
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
    final controller = Get.put(NewProductListController(ProductRepository(ApiService())));
    final p = controller.products[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias, padding: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(blurRadius: 20, offset: Offset(0, 10), color: Color(0x146A7EC8))]),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(10),
        onTap: () { final permalink = p.slug; Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': permalink}); },
        child: Column(children: [
          Expanded(child: Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: p.imageUrl.isEmpty ? Container(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)) : CachedNetworkImage(imageUrl: p.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity, placeholder: (_, __) => const _ImageShimmer(), errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined))),
            Positioned(right: 4, top: 4, child: Obx(() {
              final wish = WishlistController.ensure(); final inWish = wish.ids.contains(p.id);
              return ClipRRect(borderRadius: BorderRadius.circular(18), child: InkWell(onTap: () => wish.toggle(p), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle), child: Icon(inWish ? Iconsax.heart : Iconsax.heart_copy, size: 20, color: inWish ? AppColors.favColor : AppColors.whiteColor))));
            })),
          ])),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.normal, height: 1))),
          const SizedBox(height: 6), StarRow(rating: p.rating),
          Column(children: [
            Text(formatCurrency(p.price, applyConversion: true), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? AppColors.whiteColor : AppColors.primaryColor)),
            if (p.oldPrice != null) _CenterStrike(text: formatCurrency(p.oldPrice!, applyConversion: true), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.55), decoration: TextDecoration.none)),
          ]),
          const SizedBox(height: 6),
        ]),
      )),
    );
  }
}

class _ImageShimmer extends StatelessWidget {
  const _ImageShimmer();
  @override
  Widget build(BuildContext context) => const ShimmerBox(height: double.infinity, width: double.infinity, borderRadius: 0);
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(padding: const EdgeInsets.fromLTRB(10, 10, 10, 96), itemCount: 8, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240), itemBuilder: (_, __) {
      return Container(decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: const Column(children: [Expanded(child: ShimmerBox(borderRadius: 10)), SizedBox(height: 10), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: ShimmerBox(height: 12, borderRadius: 6)), SizedBox(height: 8), ShimmerBox(height: 12, borderRadius: 6, width: 80), SizedBox(height: 10)]));
    });
  }
}

class _CategoryChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap; final Widget? leading; final Widget? trailing;
  const _CategoryChip({required this.label, required this.selected, required this.onTap, this.leading, this.trailing});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = selected ? AppColors.primaryColor : (isDark ? AppColors.darkCardColor : AppColors.lightCardColor);
    final Color fg = selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF333333));
    return Material(color: bg, borderRadius: BorderRadius.circular(8), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (leading != null) ...[IconTheme(data: IconThemeData(color: fg, size: 18), child: leading!), const SizedBox(width: 6)],
      Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      if (trailing != null) ...[const SizedBox(width: 4), IconTheme(data: IconThemeData(color: fg, size: 14), child: trailing!)],
    ]))));
  }
}

class _CenterStrike extends StatelessWidget {
  const _CenterStrike({required this.text, required this.style}); final String text; final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style; final double h = s.fontSize != null ? s.fontSize! * 0.07 : 1;
    return Stack(alignment: Alignment.center, children: [
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: s),
      Positioned.fill(child: Align(alignment: Alignment.center, child: Container(height: h, color: (s.color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.6)))),
    ]);
  }
}
