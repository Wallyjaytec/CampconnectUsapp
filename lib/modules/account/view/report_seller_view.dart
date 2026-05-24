import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../controller/report_seller_controller.dart';
import '../model/follow_seller_model.dart';
import '../widgets/report_seller_dialog.dart';

class ReportSellerView extends StatelessWidget {
  const ReportSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportSellerController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchCtrl = TextEditingController();
    final query = ''.obs;

    return SafeArea(
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
            'Report a Seller'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
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

          final filtered = query.value.isEmpty
              ? controller.allSellers
              : controller.allSellers
                  .where((s) => s.name.toLowerCase().contains(query.value.toLowerCase()))
                  .toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (v) => query.value = v,
                  decoration: InputDecoration(
                    hintText: 'Search sellers...'.tr,
                    prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18),
                    suffixIcon: query.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Iconsax.close_circle_copy, size: 18),
                            onPressed: () {
                              searchCtrl.clear();
                              query.value = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? RefreshIndicator(
                        onRefresh: controller.loadSellers,
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (query.value.isNotEmpty)
                                    const Icon(Iconsax.search_normal_1_copy, size: 80, color: Colors.grey)
                                  else
                                    Image.asset('assets/icons/empty_follow.png', width: 120, height: 120),
                                  const SizedBox(height: 16),
                                  Text(
                                    query.value.isNotEmpty
                                        ? 'No sellers found'.tr
                                        : 'No sellers available'.tr,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.loadSellers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final seller = filtered[index];
                            return _ReportSellerCard(
                              seller: seller,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => ReportSellerDialog(
                                    sellerId: seller.id,
                                    sellerName: seller.name,
                                    sellerLogo: AppConfig.assetUrl(seller.logo),
                                  ),
                                );
                              },
                            );
                          },
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

class _ReportSellerCard extends StatelessWidget {
  const _ReportSellerCard({required this.seller, required this.onTap});
  final FollowSellerModel seller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (seller.isVerified) ...[
                      const SizedBox(width: 4),
                      Image.asset('assets/images/verifybadge.png', height: 16, width: 16),
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
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              foregroundColor: AppColors.redColor,
              side: const BorderSide(color: AppColors.redColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text('Report'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
