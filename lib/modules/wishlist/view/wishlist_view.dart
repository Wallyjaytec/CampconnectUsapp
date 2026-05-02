import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/product_details_repository.dart';
import 'package:kartly_e_commerce/data/repositories/product_repository.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../product/controller/add_to_cart_controller.dart';
import '../../product/controller/new_product_list_controller.dart';
import '../../product/controller/top_sales_controller.dart';
import '../../product/model/product_model.dart';
import '../../product/view/new_product_list_view.dart';
import '../../product/widgets/add_to_cart_sheet.dart';
import '../../product/widgets/star_row.dart';
import '../controller/wishlist_controller.dart';

class WishlistView extends GetView<WishlistController> {
  const WishlistView({super.key});

  ProductDetailsRepository get _detailsRepo => ProductDetailsRepository(ApiService());

  @override
  Widget build(BuildContext context) {
    final c = WishlistController.ensure();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, titleSpacing: 10, leadingWidth: 44, elevation: 0, leading: null, centerTitle: false,
          title: Text('Wishlist'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18), overflow: TextOverflow.ellipsis),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
        ),
        body: LoginService().isLoggedIn()
            ? Obx(() {
                if (c.isLoading.value && c.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.error.isNotEmpty && c.items.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(c.error.value, textAlign: TextAlign.center)));
                }

                if (c.items.isEmpty) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/icons/wishlist_user.png', width: 80, height: 80),
                              const SizedBox(height: 16),
                              Text("You haven't saved an item yet!".tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text("Found something you like? Tap on the heart shaped icon next to the item to add it to your wishlist! All your saved items will appear here.".tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity, height: 44,
                                child: ElevatedButton(
                                  onPressed: () => Get.offAllNamed(AppRoutes.bottomNavbarView),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: Text('Continue Shopping'.tr, style: const TextStyle(fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _RecommendedSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: c.items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    if (i == c.items.length) {
                      if (c.hasMore) { c.loadMore(); return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator())); }
                      return const SizedBox.shrink();
                    }
                    final p = c.items[i];
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    return GestureDetector(
                      onTap: () {
                        final slug = p.slug;
                        if (slug.isNotEmpty) { Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug}); }
                        else { Get.toNamed(AppRoutes.productDetailsView, arguments: {'id': p.id}); }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: (p.imageUrl.isEmpty) ? const SizedBox(width: 56, height: 56) : CachedNetworkImage(imageUrl: p.imageUrl, width: 56, height: 56, fit: BoxFit.cover)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                GestureDetector(onTap: () => _openDetails(p), child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                StarRow(rating: p.rating),
                                Text(formatCurrency(p.price, applyConversion: true), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryColor)),
                                if (p.oldPrice != null && p.oldPrice! > p.price) Text(formatCurrency(p.oldPrice!, applyConversion: true), style: Theme.of(context).textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.55))),
                              ]),
                            ),
                            const SizedBox(width: 10),
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              GestureDetector(onTap: () => c.remove(p.id), child: const Icon(Iconsax.heart, color: AppColors.favColor)),
                              const SizedBox(height: 10),
                              GestureDetector(onTap: () => _onCartTap(p), child: const Icon(Iconsax.shopping_cart_copy)),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              })
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/icons/wishlist_guest.png', width: 120, height: 120),
                    const SizedBox(height: 24),
                    Text('Please sign in to access your wishlist'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('One step away from accessing your wishlist'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.loginView),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text('Login'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }

  void _openDetails(ProductModel p) {
    final slug = p.slug;
    if (slug.isNotEmpty) { Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug}); }
    else { Get.toNamed(AppRoutes.productDetailsView, arguments: {'id': p.id}); }
  }

  Future<void> _onCartTap(ProductModel pm) async {
    final slug = (pm.slug).trim();
    if (slug.isEmpty) { _openDetails(pm); return; }
    try {
      final details = await _detailsRepo.fetchByPermalink(slug);
      final safeName = (details.name).toString();
      final safePrice = details.price;
      final safeRating = details.rating;
      final safeQty = details.quantity;
      final String img = (details.galleryImages.isNotEmpty) ? (details.galleryImages.first.imageUrl) : '';
      final attrs = details.attributes;
      final groups = attrs.map((g) {
        final backendKey = (g.id).toString().trim();
        return VariationGroup(name: g.name, backendKey: backendKey, required: g.required, options: g.options.map((o) {
          final String? hex = (o.valueHex?.isNotEmpty == true) ? o.valueHex : null;
          return VariationOption(id: o.id, label: o.label, hex: hex, price: o.price, oldPrice: o.oldPrice);
        }).toList());
      }).toList();
      final tag = 'add-to-cart-${details.id}';
      if (Get.isRegistered<AddToCartController>(tag: tag)) { Get.delete<AddToCartController>(tag: tag, force: true); }
      final cartUi = CartUiProduct(id: details.id, title: safeName, imageUrl: img, price: safePrice, rating: safeRating);
      Get.put(AddToCartController(cartUi, details: details, stock: safeQty, groups: groups), tag: tag);
      Get.bottomSheet(AddToCartSheet(controllerTag: tag, p: details), isScrollControlled: true, backgroundColor: Get.theme.scaffoldBackgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))));
    } catch (_) { _openDetails(pm); }
  }
}

class _RecommendedSection extends StatefulWidget {
  const _RecommendedSection();
  @override
  State<_RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<_RecommendedSection> {
  final TopSalesController _ctrl = Get.put(TopSalesController(), tag: 'recommended_wishlist');

  @override
  void initState() {
    super.initState();
    _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: Text('Recommended for you'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              TextButton(
                onPressed: () {
                  final ctrl = Get.put(NewProductListController(ProductRepository(ApiService())), tag: 'recommended_all');
                  ctrl.overrideTitle('Recommended for you'.tr);
                  Get.to(() => const NewProductListView(), arguments: {'title': 'Recommended for you'.tr, 'sorting': 'popular'});
                },
                child: Text('View All'.tr),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: Obx(() {
            if (_ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
            if (_ctrl.products.isEmpty) return const SizedBox.shrink();
            final items = _ctrl.products.take(10).toList();
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = items[i];
                return SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () { if (p.slug.isNotEmpty) Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug}); },
                    child: _RecProductCard(product: p),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _RecProductCard extends StatelessWidget {
  final dynamic product;
  const _RecProductCard({required this.product});
  @override
  Widget build(BuildContext context) {
    final p = product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: CachedNetworkImage(imageUrl: p.imageUrl, fit: BoxFit.cover, width: double.infinity, errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined)))),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              StarRow(rating: p.rating),
              Text(formatCurrency(p.price, applyConversion: true), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.whiteColor : AppColors.primaryColor)),
            ]),
          ),
        ],
      ),
    );
  }
}
