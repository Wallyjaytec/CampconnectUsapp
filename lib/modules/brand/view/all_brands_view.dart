import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/modules/brand/controller/brand_controller.dart';
import 'package:kartly_e_commerce/modules/product/model/brand_model.dart';

class AllBrandsView extends StatelessWidget {
  const AllBrandsView({super.key, this.onTapBrand});
  final void Function(Brand brand)? onTapBrand;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrandController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Brands'.tr),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        if (controller.brands.isEmpty) {
          return Center(child: Text('No brands found'.tr));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: controller.brands.length,
          itemBuilder: (context, index) {
            final brand = controller.brands[index];
            return InkWell(
              onTap: () => onTapBrand?.call(brand),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: brand.logo.isEmpty
                            ? const Icon(Icons.store, size: 40, color: AppColors.primaryColor)
                            : CachedNetworkImage(
                                imageUrl: brand.logoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.store, size: 40, color: AppColors.primaryColor),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      brand.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
