import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/shimmer_widgets.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../controller/visual_search_controller.dart';
import '../model/search_model.dart';

class VisualSearchResultsView extends StatefulWidget {
  const VisualSearchResultsView({super.key});

  @override
  State<VisualSearchResultsView> createState() => _VisualSearchResultsViewState();
}

class _VisualSearchResultsViewState extends State<VisualSearchResultsView> {
  final List<ProductModel> _products = [];
  bool _loadingProducts = false;

  VisualSearchController get _controller => Get.find<VisualSearchController>();

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    final results = _controller.results;
    if (results.isEmpty) return;

    setState(() => _loadingProducts = true);

    final repo = ProductRepository(api: ApiService());
    for (final r in results) {
      final id = int.tryParse(r.productId) ?? 0;
      if (id > 0) {
        try {
          final res = await repo.fetchProductDetails(id: id, slug: '');
          if (res.data != null) {
            _products.add(res.data!);
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() => _loadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        title: Text('Image Search'.tr),
      ),
      body: Obx(() {
        if (_controller.isLoading.value || _loadingProducts) {
          return const _GridShimmer();
        }

        if (_controller.error.value.isNotEmpty && _products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.camera_copy, size: 80, color: AppColors.primaryColor),
                  const SizedBox(height: 16),
                  Text(_controller.error.value, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.searchFromCamera(),
                        icon: const Icon(Iconsax.camera_copy, size: 18),
                        label: Text('Camera'.tr),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _controller.searchFromGallery(),
                        icon: const Icon(Iconsax.gallery_copy, size: 18),
                        label: Text('Gallery'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        if (_products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.camera_copy, size: 80, color: AppColors.primaryColor),
                  const SizedBox(height: 16),
                  Text('Search by image'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Take a photo or choose from gallery to find similar products'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.searchFromCamera(),
                        icon: const Icon(Iconsax.camera_copy, size: 18),
                        label: Text('Camera'.tr),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _controller.searchFromGallery(),
                        icon: const Icon(Iconsax.gallery_copy, size: 18),
                        label: Text('Gallery'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('${_products.length} ${'products found'.tr}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _controller.searchFromGallery(),
                    icon: const Icon(Iconsax.gallery_copy, size: 16),
                    label: Text('New Search'.tr),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 96),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 240,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return _ProductCard(product: p, isDark: isDark);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;

  const _ProductCard({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(blurRadius: 20, offset: Offset(0, 10), color: Color(0x146A7EC8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Navigate to product details using the same method as text search
            Get.toNamed('/product_details_view', arguments: {'id': product.id, 'slug': product.slug});
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: product.thumbnailImage.isEmpty
                      ? Container(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))
                      : CachedNetworkImage(
                          imageUrl: AppConfig.assetUrl(product.thumbnailImage),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => const ShimmerBox(height: double.infinity, width: double.infinity, borderRadius: 0),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.normal, height: 1),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatCurrency(product.price.toDouble(), applyConversion: true),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.whiteColor : AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 240,
      ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            children: [
              Expanded(child: ShimmerBox(borderRadius: 10)),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ShimmerBox(height: 12, borderRadius: 6),
              ),
              SizedBox(height: 8),
              ShimmerBox(height: 12, borderRadius: 6, width: 80),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
