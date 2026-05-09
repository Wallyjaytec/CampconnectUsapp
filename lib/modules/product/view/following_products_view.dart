import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/product/controller/following_products_controller.dart';
import 'package:kartly_e_commerce/modules/product/widgets/star_row.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/search_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/shimmer_widgets.dart';

class FollowingProductsView extends StatefulWidget {
  const FollowingProductsView({super.key});

  @override
  State<FollowingProductsView> createState() => _FollowingProductsViewState();
}

class _FollowingProductsViewState extends State<FollowingProductsView> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;
  late final FollowingProductsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<FollowingProductsController>(tag: 'followingSection');
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
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
          leadingWidth: 44,
          titleSpacing: 0,
          leading: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
              splashRadius: 20,
            ),
          ),
          centerTitle: false,
          title: Text('Following'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
        ),
        body: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const _GridShimmer();
              }
              if (controller.error.isNotEmpty && controller.products.isEmpty) {
                return Center(child: Text(controller.error.value));
              }
              if (controller.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.heart_circle_copy, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Follow a seller to see products here'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: GridView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240,
                  ),
                  itemCount: controller.products.length + (controller.isLoadingMore.value ? 2 : 0),
                  itemBuilder: (_, i) {
                    if (i >= controller.products.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final p = controller.products[i];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug}),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: CachedNetworkImage(
                                  imageUrl: p.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorWidget: (_, __, ___) => const Icon(Iconsax.gallery_remove_copy),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  StarRow(rating: p.rating),
                                  Text(formatCurrency(p.price, applyConversion: true),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
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
        ),
      ),
    );
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          children: [
            Expanded(child: ShimmerBox(borderRadius: 10)),
            SizedBox(height: 10),
            ShimmerBox(height: 12, borderRadius: 6, width: 80),
          ],
        ),
      ),
    );
  }
}
