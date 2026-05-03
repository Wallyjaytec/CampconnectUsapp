import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/controller/new_product_list_controller.dart';
import '../../product/widgets/star_row.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/category_controller.dart';

class AllCategoriesView extends StatefulWidget {
  final bool showBackButton;
  const AllCategoriesView({super.key, this.showBackButton = true});

  @override
  State<AllCategoriesView> createState() => _AllCategoriesViewState();
}

class _AllCategoriesViewState extends State<AllCategoriesView> {
  final CategoryController _catCtrl = Get.find<CategoryController>();
  NewProductListController? _productCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  final ScrollController _rightScrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _rightScrollCtrl.addListener(_onScrollDetected);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _rightScrollCtrl.removeListener(_onScrollDetected);
    _scrollCtrl.dispose();
    _rightScrollCtrl.dispose();
    super.dispose();
  }

  void _onScrollDetected() {
    if (!_rightScrollCtrl.hasClients) return;
    if (!_showBackToTop) {
      setState(() => _showBackToTop = true);
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showBackToTop) setState(() => _showBackToTop = false);
    });
  }

  void _scrollToTop() {
    _rightScrollCtrl.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _loadProducts() {
    final cat = _catCtrl.categories[_catCtrl.selectedIndex.value];
    if (Get.isRegistered<NewProductListController>(tag: 'catProducts')) {
      Get.delete<NewProductListController>(tag: 'catProducts', force: true);
    }
    _productCtrl = Get.put(
      NewProductListController(ProductRepository(ApiService())),
      tag: 'catProducts',
    );
    _productCtrl!.openForCategory(categoryId: cat.id, categoryName: cat.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leftPaneWidth = MediaQuery.of(context).size.width >= 600 ? 140.0 : 100.0;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          titleSpacing: widget.showBackButton ? 0 : 10,
          leading: widget.showBackButton
              ? Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
                    splashRadius: 20,
                  ),
                )
              : null,
          centerTitle: false,
          title: Text('All Categories'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
        ),
        body: Obx(() {
          if (_catCtrl.isLoading.value) {
            return _ShimmerBody(leftPaneWidth: leftPaneWidth, isDark: isDark);
          }
          if (_catCtrl.error.isNotEmpty) {
            return Center(child: Text(_catCtrl.error.value, textAlign: TextAlign.center));
          }
          final cats = _catCtrl.categories;
          if (cats.isEmpty) return Center(child: Text('No categories'.tr));

          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: leftPaneWidth,
                    height: double.infinity,
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        final selected = index == _catCtrl.selectedIndex.value;
                        return InkWell(
                          onTap: () {
                            _catCtrl.selectCategory(index);
                            _loadProducts();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            color: selected ? (isDark ? AppColors.darkCardColor : AppColors.lightCardColor) : AppColors.transparentColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 42, width: 42,
                                  child: cat.imageUrl.isEmpty
                                      ? const Icon(Icons.image_not_supported_outlined)
                                      : CachedNetworkImage(
                                          imageUrl: cat.imageUrl, fit: BoxFit.cover,
                                          placeholder: (_, __) => const ShimmerCircle(diameter: 42),
                                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(cat.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, height: 1.0,
                                    color: selected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                      child: _productCtrl == null
                          ? const Center(child: CircularProgressIndicator())
                          : Obx(() {
                              final ctrl = _productCtrl!;
                              if (ctrl.isLoading.value && ctrl.products.isEmpty) {
                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 220,
                                  ),
                                  itemCount: 6,
                                  itemBuilder: (_, __) => Container(
                                    decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                                    child: const Column(children: [
                                      Expanded(child: ShimmerBox(borderRadius: 10)),
                                      SizedBox(height: 8),
                                      ShimmerBox(height: 12, borderRadius: 6, width: 80),
                                    ]),
                                  ),
                                );
                              }
                              if (ctrl.error.isNotEmpty && ctrl.products.isEmpty) {
                                return Center(child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(ctrl.error.value, textAlign: TextAlign.center),
                                ));
                              }
                              if (ctrl.products.isEmpty && !ctrl.hasMore) {
                                return Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/icons/categories_empty.png', width: 100, height: 100),
        const SizedBox(height: 16),
        Text(
          'No products in this category yet'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'Wait for sellers to add products and browse here later'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    ),
  ),
);
                              return GridView.builder(
                                controller: _rightScrollCtrl,
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 220,
                                ),
                                itemCount: ctrl.products.length + (ctrl.isLoadingMore.value ? 2 : 0),
                                itemBuilder: (context, i) {
                                  if (i >= ctrl.products.length) {
                                    return Container(
                                      decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  }
                                  final p = ctrl.products[i];
                                  return _ProductCard(product: p);
                                },
                              );
                            }),
                    ),
                  ),
                ],
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

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final slug = p.slug;
            if (slug.isNotEmpty) {
              Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug});
            }
          },
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: p.imageUrl.isEmpty
                          ? Container(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))
                          : CachedNetworkImage(imageUrl: p.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                    ),
                    Positioned(
                      right: 4, top: 4,
                      child: Obx(() {
                        final wish = WishlistController.ensure();
                        final inWish = wish.ids.contains(p.id);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => wish.toggle(p),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                              child: Icon(inWish ? Iconsax.heart : Iconsax.heart_copy, size: 16, color: inWish ? AppColors.favColor : AppColors.whiteColor),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12)),
              ),
              StarRow(rating: p.rating),
              Text(formatCurrency(p.price, applyConversion: true),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.whiteColor : AppColors.primaryColor),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody({required this.leftPaneWidth, required this.isDark});
  final double leftPaneWidth;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: leftPaneWidth,
          child: ListView.separated(itemCount: 8, separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (_, __) => const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(children: [ShimmerCircle(diameter: 42), SizedBox(height: 8), ShimmerBox(width: 60, height: 10, borderRadius: 6)]),
            ),
          ),
        ),
        Expanded(child: Container(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor)),
      ],
    );
  }
}
