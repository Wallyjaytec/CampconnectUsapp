import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/core/utils/currency_formatters.dart';
import 'package:campconnectus_marketplace/modules/product/controller/discount_sales_controller.dart';
import 'package:campconnectus_marketplace/modules/product/widgets/star_row.dart';
import 'package:campconnectus_marketplace/shared/widgets/cart_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/notification_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/search_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/shimmer_widgets.dart';

class DiscountSalesView extends StatefulWidget {
  const DiscountSalesView({super.key});

  @override
  State<DiscountSalesView> createState() => _DiscountSalesViewState();
}

class _DiscountSalesViewState extends State<DiscountSalesView> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
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
    final controller = Get.put(DiscountSalesController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Discount Sales'.tr),
        centerTitle: true,
        actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
      ),
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Discount Sales'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 240,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            children: [
                              Expanded(child: ShimmerBox(borderRadius: 10)),
                              SizedBox(height: 10),
                              ShimmerBox(height: 12, borderRadius: 6),
                            ],
                          ),
                        ),
                        childCount: 6,
                      ),
                    ),
                  ),
                ],
              );
            }

            if (controller.products.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.primaryColor,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icons/discount_banner.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Discount Sales'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No discounted products available'),
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Discount Sales'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 240,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final p = controller.products[i];
                        return GestureDetector(
                          onTap: () {
                            if (p.slug.isNotEmpty) {
                              Get.toNamed(
                                AppRoutes.productDetailsView,
                                arguments: {'permalink': p.slug},
                              );
                            }
                          },
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
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Text(
                                        p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      StarRow(rating: p.rating),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatCurrency(p.price, applyConversion: true),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? AppColors.whiteColor : AppColors.primaryColor,
                                        ),
                                      ),
                                      if (p.oldPrice != null && p.oldPrice! > p.price)
                                        Text(
                                          formatCurrency(p.oldPrice!, applyConversion: true),
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: controller.products.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
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
    );
  }
}
