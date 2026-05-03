import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/product/controller/discount_sales_controller.dart';
import 'package:kartly_e_commerce/modules/product/widgets/star_row.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/search_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/shimmer_widgets.dart';

class DiscountSalesView extends StatelessWidget {
  const DiscountSalesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiscountSalesController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Discount Sales'.tr),
        centerTitle: true,
        actions: const [
          SearchIconWidget(),
          CartIconWidget(),
          NotificationIconWidget(),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 240),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: const Column(children: [Expanded(child: ShimmerBox(borderRadius: 10)), SizedBox(height: 10), ShimmerBox(height: 12, borderRadius: 6)]),
            ),
          );
        }

        if (controller.products.isEmpty) {
          return Center(child: Text('No discounted products available'.tr));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 240),
          itemCount: controller.products.length,
          itemBuilder: (_, i) {
            final p = controller.products[i];
            return GestureDetector(
              onTap: () {
                if (p.slug.isNotEmpty) {
                  Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug});
                }
              },
              child: Container(
                decoration: BoxDecoration(color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: CachedNetworkImage(imageUrl: p.imageUrl, fit: BoxFit.cover, width: double.infinity))),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(children: [
                        Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        StarRow(rating: p.rating),
                        const SizedBox(height: 4),
                        Text(formatCurrency(p.price, applyConversion: true), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.whiteColor : AppColors.primaryColor)),
                        if (p.oldPrice != null && p.oldPrice! > p.price)
                          Text(formatCurrency(p.oldPrice!, applyConversion: true), style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
