import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/core/utils/currency_formatters.dart';
import 'package:campconnectus_marketplace/modules/product/controller/recently_viewed_controller.dart';
import 'package:campconnectus_marketplace/modules/product/widgets/star_row.dart';
import 'package:campconnectus_marketplace/shared/widgets/cart_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/notification_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/search_icon_widget.dart';

class RecentlyViewedView extends StatefulWidget {
  const RecentlyViewedView({super.key});

  @override
  State<RecentlyViewedView> createState() => _RecentlyViewedViewState();
}

class _RecentlyViewedViewState extends State<RecentlyViewedView> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;
  late final RecentlyViewedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<RecentlyViewedController>();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
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
              onPressed: () {
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                }
              },
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
              splashRadius: 20,
            ),
          ),
          centerTitle: false,
          title: Text('Recently Viewed'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: [
            IconButton(
              onPressed: () {
                controller.clearAll();
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Recently viewed history cleared'.tr),
                        backgroundColor: AppColors.primaryColor,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(top: 50, left: 10, right: 10),
                      ),
                    );
                  }
                });
              },
              icon: const Icon(Iconsax.trash_copy, size: 20),
            ),
            const SearchIconWidget(),
            const CartIconWidget(),
            const NotificationIconWidget(),
          ],
        ),
        body: Stack(
          children: [
            Obx(() {
              if (controller.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.clock_copy, size: 64, color: AppColors.primaryColor),
                        const SizedBox(height: 16),
                        Text('View a product to see your recent viewed products'.tr, 
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240,
                ),
                itemCount: controller.products.length,
                itemBuilder: (_, i) {
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
