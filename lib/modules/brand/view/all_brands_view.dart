import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/modules/brand/controller/brand_controller.dart';
import 'package:kartly_e_commerce/modules/product/model/brand_model.dart';

class AllBrandsView extends StatefulWidget {
  const AllBrandsView({super.key, this.onTapBrand});
  final void Function(Brand brand)? onTapBrand;

  @override
  State<AllBrandsView> createState() => _AllBrandsViewState();
}

class _AllBrandsViewState extends State<AllBrandsView> {
  final BrandController _controller = Get.put(BrandController());
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  List<Brand> get _filtered {
    if (_query.isEmpty) return _controller.brands;
    return _controller.brands
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Brands'.tr),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search brands...'.tr,
                prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle_copy, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
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
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.error.isNotEmpty) {
                return Center(child: Text(_controller.error.value));
              }
              if (_filtered.isEmpty) {
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
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final brand = _filtered[index];
                  return InkWell(
                    onTap: () => widget.onTapBrand?.call(brand),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              brand.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
