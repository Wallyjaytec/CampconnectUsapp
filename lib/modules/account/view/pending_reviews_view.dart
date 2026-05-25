import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import '../controller/pending_reviews_controller.dart';
import '../widgets/review_dialog.dart';
import '../widgets/review_detail_dialog.dart';
import '../../product/widgets/star_row.dart';

class PendingReviewsView extends StatelessWidget {
  const PendingReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PendingReviewsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      Tab(height: 38, text: 'Pending Reviews'.tr),
      Tab(height: 38, text: 'Reviewed'.tr),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
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
          titleSpacing: 0,
          title: Text(
            'Ratings & Reviews'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          bottom: TabBar(
            padding: EdgeInsets.zero,
            indicatorColor: AppColors.whiteColor,
            labelColor: AppColors.whiteColor,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelColor: AppColors.greyColor,
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: [
            _PendingTab(controller: controller, isDark: isDark),
            _ReviewedTab(controller: controller, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Tab ─────────────────────────────────────────────────
class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.controller, required this.isDark});
  final PendingReviewsController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.isNotEmpty && controller.products.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.error.value),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: controller.loadPendingReviews,
                child: Text('Retry'.tr),
              ),
            ],
          ),
        );
      }

      if (controller.products.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.loadPendingReviews,
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/empty_review.png', width: 120, height: 120),
                      const SizedBox(height: 24),
                      Text(
                        'You have no pending product\nrating & review',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Get.offAllNamed(AppRoutes.bottomNavbarView),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Continue Shopping'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadPendingReviews,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            final product = controller.products[index];
            final orderCode = controller.getOrderCodeForProduct(product.productId);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: CachedNetworkImage(
                        imageUrl: AppConfig.assetUrl(product.image),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Iconsax.gallery_remove_copy),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${'Delivered on'.tr} ${product.deliveredDate ?? ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${'Order ID'.tr}: ${orderCode}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => ReviewDialog(
                          orderId: controller.getOrderIdForProduct(product.productId),
                          productId: product.productId,
                          productName: product.name,
                          productImage: AppConfig.assetUrl(product.image),
                        ),
                      ).then((submitted) {
                        if (submitted == true) {
                          controller.removeProduct(product.productId);
                          controller.loadReviewedReviews();
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Review'.tr),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

// ─── Reviewed Tab ────────────────────────────────────────────────
class _ReviewedTab extends StatelessWidget {
  const _ReviewedTab({required this.controller, required this.isDark});
  final PendingReviewsController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingReviewed.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.reviewedProducts.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadReviewedReviews();
          },
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.star, size: 80, color: AppColors.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews submitted yet'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadReviewedReviews();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: controller.reviewedProducts.length,
          itemBuilder: (context, index) {
            final review = controller.reviewedProducts[index];
            return _ReviewedCard(review: review, isDark: isDark);
          },
        ),
      );
    });
  }
}

// ─── Reviewed Card ───────────────────────────────────────────────
class _ReviewedCard extends StatelessWidget {
  const _ReviewedCard({required this.review, required this.isDark});
  final Map<String, dynamic> review;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final productName = review['product_name']?.toString() ?? '';
    final productImage = review['product_image']?.toString() ?? '';
    final rating = (review['rating'] is num)
        ? (review['rating'] as num).toDouble()
        : double.tryParse(review['rating']?.toString() ?? '0') ?? 0.0;
    final createdAt = review['created_at']?.toString() ?? '';
    final orderCode = review['order_code']?.toString() ?? '';

    String formattedDate = '';
    try {
      final dt = DateTime.parse(createdAt);
      formattedDate = DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      formattedDate = createdAt;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: CachedNetworkImage(
                imageUrl: AppConfig.assetUrl(productImage),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Iconsax.gallery_remove_copy),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                StarRow(rating: rating),
                const SizedBox(height: 4),
                Text(
                  '${'Reviewed on'.tr}: $formattedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${'Order'.tr}: $orderCode',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ReviewDetailDialog(review: review),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('See Review'.tr),
          ),
        ],
      ),
    );
  }
}
