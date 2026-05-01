import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/brand_repository.dart';
import 'package:kartly_e_commerce/modules/product/model/brand_model.dart';
import 'package:kartly_e_commerce/shared/widgets/shimmer_widgets.dart';

class BrandView extends StatefulWidget {
  const BrandView({super.key, this.onViewAll, this.onTapBrand});
  final VoidCallback? onViewAll;
  final void Function(Brand brand)? onTapBrand;

  @override
  State<BrandView> createState() => _BrandViewState();
}

class _BrandViewState extends State<BrandView> {
  final _repo = BrandRepository();
  final _brands = <Brand>[].obs;
  final _isLoading = true.obs;
  final _error = ''.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _isLoading.value = true;
    _error.value = '';
    try {
      final list = await _repo.fetchAll();
      _brands.assignAll(list);
      if (_brands.isEmpty) _error.value = 'No brands found';
    } catch (e) {
      _error.value = 'Failed to load brands';
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkCardColor
        : AppColors.lightCardColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Brands', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              TextButton(onPressed: widget.onViewAll, child: Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 105,
            child: Obx(() {
              if (_isLoading.value) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, __) => _shimmerItem(cardColor),
                );
              }
              if (_error.isNotEmpty) return Center(child: Text(_error.value));
              if (_brands.isEmpty) return Center(child: const Text('No brands found'));

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 5),
                itemBuilder: (_, i) {
                  final b = _brands[i];
                  return InkWell(
                    onTap: () => widget.onTapBrand?.call(b),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: b.logo.isEmpty
                                  ? const Icon(Icons.store, size: 30)
                                  : CachedNetworkImage(imageUrl: b.logoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.store, size: 30)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(child: Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center)),
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

  Widget _shimmerItem(Color cardColor) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          const ShimmerCircle(diameter: 48),
          const SizedBox(height: 8),
          const ShimmerBox(width: 48, height: 10, borderRadius: 6),
        ],
      ),
    );
  }
} 
