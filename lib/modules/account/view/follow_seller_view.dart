import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import '../controller/follow_seller_controller.dart';
import '../model/follow_seller_model.dart';
import '../../seller/model/seller_shop_model.dart';
import '../../seller/controller/seller_products_controller.dart';

class FollowSellerView extends StatelessWidget {
  const FollowSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FollowSellerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      Tab(height: 38, text: 'Follow'.tr),
      Tab(height: 38, text: 'Following'.tr),
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
            'Follow Sellers'.tr,
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
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.error.value, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.loadSellers,
                      child: Text('Retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            children: [
              _SellerList(
                sellers: controller.followList,
                isEmptyMessage: 'No sellers to follow'.tr,
                isFollowTab: true,
                onRefresh: controller.loadSellers,
                onToggle: (seller) => controller.followShop(seller),
                onTap: (seller) => _navigateToShop(seller),
              ),
              _SellerList(
                sellers: controller.followingList,
                isEmptyMessage: "You haven't followed any seller".tr,
                isFollowTab: false,
                onRefresh: controller.loadSellers,
                onToggle: (seller) => controller.unfollowShop(seller),
                onTap: (seller) => _navigateToShop(seller),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _navigateToShop(FollowSellerModel seller) {
    final slug = seller.slug;
    final tag = 'seller_bottom_$slug';
    
    final sellerCtrl = Get.isRegistered<SellerProductsController>(tag: tag)
        ? Get.find<SellerProductsController>(tag: tag)
        : Get.put(
            SellerProductsController(slug: slug, autoLoad: false),
            tag: tag,
          );
    
    sellerCtrl.seedHeaderMeta(
      followersCount: seller.totalFollowers,
      alreadyFollowing: seller.isFollowing,
    );

    final args = SellerNavArgs(
      title: seller.name,
      logo: AppConfig.assetUrl(seller.logo),
      slug: slug,
      ratingPercent: seller.positiveRating,
      followers: sellerCtrl.followers.value,
      shopBanner: seller.shopBanner != null
          ? AppConfig.assetUrl(seller.shopBanner!)
          : null,
      isFollowing: seller.isFollowing,
      isVerified: seller.isVerified,
    );
    Get.toNamed(AppRoutes.sellerBottomNavbar, arguments: args);
  }
}

class _SellerList extends StatelessWidget {
  const _SellerList({
    required this.sellers,
    required this.isEmptyMessage,
    required this.isFollowTab,
    required this.onRefresh,
    required this.onToggle,
    required this.onTap,
  });

  final List<FollowSellerModel> sellers;
  final String isEmptyMessage;
  final bool isFollowTab;
  final Future<void> Function() onRefresh;
  final void Function(FollowSellerModel) onToggle;
  final void Function(FollowSellerModel) onTap;

  @override
  Widget build(BuildContext context) {
    if (sellers.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.25,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/empty_follow.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEmptyMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: sellers.length,
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return _SellerCard(
            seller: seller,
            isFollowTab: isFollowTab,
            onToggle: () => onToggle(seller),
            onTap: () => onTap(seller),
          );
        },
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({
    required this.seller,
    required this.isFollowTab,
    required this.onToggle,
    required this.onTap,
  });

  final FollowSellerModel seller;
  final bool isFollowTab;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: AppConfig.assetUrl(seller.logo),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.store, size: 28, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          seller.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (seller.isVerified) ...[
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/verifybadge.png',
                          height: 16,
                          width: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${seller.positiveRating}% Seller Ratings',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${seller.followersText}  •  Verified: ${seller.isVerified ? "Yes" : "No"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                backgroundColor: isFollowTab
                    ? AppColors.primaryColor
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: isFollowTab
                    ? AppColors.whiteColor
                    : Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                isFollowTab ? 'Follow +'.tr : 'Following'.tr,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
