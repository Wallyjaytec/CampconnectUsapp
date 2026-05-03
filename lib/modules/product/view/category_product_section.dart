import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/data/repositories/product_repository.dart';
import 'package:kartly_e_commerce/modules/product/controller/new_product_list_controller.dart';
import 'package:kartly_e_commerce/modules/product/view/new_product_list_view.dart' as product_list_view;
import 'package:kartly_e_commerce/modules/product/widgets/star_row.dart';
import 'package:kartly_e_commerce/shared/widgets/shimmer_widgets.dart';

class CategoryProductSection extends StatefulWidget {
  final int categoryId;
  final String title;
  const CategoryProductSection({super.key, required this.categoryId, required this.title});

  @override
  State<CategoryProductSection> createState() => _CategoryProductSectionState();
}

class _CategoryProductSectionState extends State<CategoryProductSection> {
  late NewProductListController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      NewProductListController(ProductRepository(ApiService())),
      tag: 'cat_section_${widget.categoryId}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.openForCategory(categoryId: widget.categoryId, categoryName: widget.title);
    });
  }

  void _viewAll() {
    final tag = 'view_all_${widget.categoryId}';
    if (Get.isRegistered<NewProductListController>(tag: tag)) {
      Get.delete<NewProductListController>(tag: tag, force: true);
    }
    final c = Get.put(NewProductListController(ProductRepository(ApiService())), tag: tag);
    c.openForCategory(categoryId: widget.categoryId, categoryName: widget.title);
    Get.to(() => const product_list_view.NewProductListView(), arguments: {'categoryId': widget.categoryId, 'categoryName': widget.title});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              TextButton(onPressed: _viewAll, child: Text('View All'.tr)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Obx(() {
              if (_ctrl.isLoading.value && _ctrl.products.isEmpty) {
                return ListView.separated(scrollDirection: Axis.horizontal, itemCount: 3, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, __) => const _ShimmerCard());
              }
              if (_ctrl.products.isEmpty) return const SizedBox.shrink();
              final items = _ctrl.products.take(5).toList();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return SizedBox(
                    width: 140,
                    child: GestureDetector(
                      onTap: () {
                        if (p.slug.isNotEmpty) Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug});
                      },
                      child: _ProductCard(product: p),
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

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});
  @override
  Widget build(BuildContext context) {
    final p = product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: CachedNetworkImage(imageUrl: p.imageUrl, fit: BoxFit.cover, width: double.infinity, errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined)))),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              StarRow(rating: p.rating),
              Text(formatCurrency(p.price, applyConversion: true), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.whiteColor : AppColors.primaryColor)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 140, child: Container(decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: const Column(children: [Expanded(child: ShimmerBox(borderRadius: 10)), SizedBox(height: 8), ShimmerBox(height: 12, borderRadius: 6), SizedBox(height: 8)])));
  }
}
