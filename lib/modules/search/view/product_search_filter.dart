import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../category/model/category_model.dart';
import '../../product/model/brand_model.dart';

class ProductSearchFilterController extends GetxController {
  final BrandRepository _brandRepo = BrandRepository();
  final CategoryRepository _catRepo = CategoryRepository(ApiService());

  final RxBool isLoadingBrands = true.obs;
  final RxBool isLoadingCats = true.obs;
  final RxString loadErrorBrands = ''.obs;
  final RxString loadErrorCats = ''.obs;

  final RxList<Brand> apiBrands = <Brand>[].obs;
  final RxList<CategoryModel> apiCategories = <CategoryModel>[].obs;

  final RxString selectedSorting = 'newest'.obs;
  final Rx<int?> selectedBrandId = Rx<int?>(null);
  final Rx<int?> selectedCategoryId = Rx<int?>(null);
  final RxSet<int> selectedRatings = <int>{}.obs;

  final minPriceCtrl = TextEditingController();
  final maxPriceCtrl = TextEditingController();

  final RxBool showAllBrands = false.obs;
  final RxBool showAllCats = false.obs;

  int get _brandCollapsedCount => 4;
  int get _catCollapsedCount => 4;

  List<Brand> get visibleBrandModels => showAllBrands.value
      ? apiBrands
      : apiBrands.take(_brandCollapsedCount).toList();

  List<CategoryModel> get visibleCategoryModels => showAllCats.value
      ? apiCategories
      : apiCategories.take(_catCollapsedCount).toList();

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    final String? currentSort = (args is Map)
        ? args['currentSorting']?.toString()
        : null;
    selectedSorting.value = (currentSort == null || currentSort.isEmpty)
        ? 'newest'
        : currentSort;

    final int? curBrand = (args is Map && args['currentBrandId'] != null)
        ? _asInt(args['currentBrandId'])
        : null;
    selectedBrandId.value = curBrand;

    final int? curCat = (args is Map && args['currentCategoryId'] != null)
        ? _asInt(args['currentCategoryId'])
        : null;
    selectedCategoryId.value = curCat;

    final double? curMin = (args is Map)
        ? _asDoubleOrNull(args['currentMinPrice'])
        : null;
    final double? curMax = (args is Map)
        ? _asDoubleOrNull(args['currentMaxPrice'])
        : null;
    if (curMin != null && curMin > 0) minPriceCtrl.text = curMin.toString();
    if (curMax != null && curMax > 0) maxPriceCtrl.text = curMax.toString();

    final int? curRating = (args is Map && args['currentRating'] != null)
        ? _asInt(args['currentRating'])
        : null;
    if (curRating != null) selectedRatings.add(curRating);

    _loadCats();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    isLoadingBrands.value = true;
    loadErrorBrands.value = '';
    try {
      final list = await _brandRepo.fetchAll();
      apiBrands.assignAll(list);
    } catch (e) {
      loadErrorBrands.value = e.toString();
      apiBrands.clear();
    } finally {
      isLoadingBrands.value = false;
    }
  }

  Future<void> _loadCats() async {
    isLoadingCats.value = true;
    loadErrorCats.value = '';
    try {
      final list = await _catRepo.fetchMegaCategories();
      apiCategories.assignAll(list);
    } catch (e) {
      loadErrorCats.value = e.toString();
      apiCategories.clear();
    } finally {
      isLoadingCats.value = false;
    }
  }

  void pickBrand(int id) => selectedBrandId.value = id;
  void pickCategory(int id) => selectedCategoryId.value = id;
  void toggleRating(int r) => selectedRatings.contains(r)
      ? selectedRatings.remove(r)
      : selectedRatings.add(r);
  void pickSorting(String key) =>
      selectedSorting.value = (key.isEmpty ? 'newest' : key);

  void reset() {
    selectedSorting.value = 'newest';
    selectedBrandId.value = null;
    selectedCategoryId.value = null;
    selectedRatings.clear();
    minPriceCtrl.clear();
    maxPriceCtrl.clear();
    showAllBrands.value = false;
    showAllCats.value = false;
  }

  Map<String, dynamic> toResult() {
    final double? minV = _parsePositive(minPriceCtrl.text);
    final double? maxV = _parsePositive(maxPriceCtrl.text);

    double? minOut = minV;
    double? maxOut = maxV;
    if (minOut != null && maxOut != null && minOut > maxOut) {
      final t = minOut;
      minOut = maxOut;
      maxOut = t;
    }

    return {
      'sorting': (selectedSorting.value.isEmpty
          ? 'newest'
          : selectedSorting.value),
      'brandId': selectedBrandId.value,
      'categoryId': selectedCategoryId.value,
      'ratings': selectedRatings.toList(),
      'priceMin': minOut,
      'priceMax': maxOut,
    };
  }

  @override
  void onClose() {
    minPriceCtrl.dispose();
    maxPriceCtrl.dispose();
    super.onClose();
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? _parsePositive(String s) {
    final v = double.tryParse(s.trim());
    if (v == null) return null;
    return (v > 0) ? v : null;
  }
}

class ProductSearchFilter extends StatelessWidget {
  const ProductSearchFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.put(ProductSearchFilterController());

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 20,
          leading: InkWell(
            onTap: () => Get.back(),
            splashColor: AppColors.transparentColor,
            radius: 0,
            highlightColor: AppColors.transparentColor,
            hoverColor: AppColors.transparentColor,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Iconsax.arrow_left_2_copy, size: 20),
            ),
          ),
          title: Text(
            'Filter'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                _SectionHeader(title: 'Sort By'.tr),
                const SizedBox(height: 8),
                Obx(() {
                  final sel = controller.selectedSorting.value;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChipSelectable(
                        label: 'Newest',
                        selected: sel == 'newest',
                        onTap: () => controller.pickSorting('newest'),
                      ),
                      _ChipSelectable(
                        label: 'Popular',
                        selected: sel == 'popular',
                        onTap: () => controller.pickSorting('popular'),
                      ),
                      _ChipSelectable(
                        label: 'Price low to high'.tr,
                        selected: sel == 'lowToHigh',
                        onTap: () => controller.pickSorting('lowToHigh'),
                      ),
                      _ChipSelectable(
                        label: 'Price high to low'.tr,
                        selected: sel == 'highToLow',
                        onTap: () => controller.pickSorting('highToLow'),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                Obx(() {
                  return _SectionHeader(
                    title: 'Category'.tr,
                    trailingText:
                        (controller.isLoadingCats.value ||
                            controller.apiCategories.length <=
                                controller._catCollapsedCount)
                        ? null
                        : (controller.showAllCats.value
                              ? 'See Less'
                              : 'See All'.tr),
                    onTrailingTap: () => controller.showAllCats.value =
                        !controller.showAllCats.value,
                  );
                }),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.isLoadingCats.value) {
                    return const _ShimmerChipsRow();
                  }
                  if (controller.apiCategories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final items = controller.visibleCategoryModels;
                  final picked = controller.selectedCategoryId.value;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items.map((c) {
                      final on = picked == c.id;
                      return _ChipSelectable(
                        label: c.name,
                        selected: on,
                        onTap: () => controller.pickCategory(c.id),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 16),

                Obx(() {
                  return _SectionHeader(
                    title: 'Brand'.tr,
                    trailingText:
                        (controller.isLoadingBrands.value ||
                            controller.apiBrands.length <=
                                controller._brandCollapsedCount)
                        ? null
                        : (controller.showAllBrands.value
                              ? 'See Less'
                              : 'See All'.tr),
                    onTrailingTap: () => controller.showAllBrands.value =
                        !controller.showAllBrands.value,
                  );
                }),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.isLoadingBrands.value) {
                    return const _ShimmerChipsRow();
                  }
                  if (controller.apiBrands.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final items = controller.visibleBrandModels;
                  final picked = controller.selectedBrandId.value;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items.map((b) {
                      final on = picked == b.id;
                      return _ChipSelectable(
                        label: b.name,
                        selected: on,
                        onTap: () => controller.pickBrand(b.id),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 16),

                _SectionHeader(title: 'Price'.tr),
                const SizedBox(height: 8),
                _PriceInputsNoLimit(controller: controller),
                const SizedBox(height: 16),

                _SectionHeader(title: 'Rating'.tr),
                const SizedBox(height: 10),
                Obx(() {
                  final picked = controller.selectedRatings.toSet();
                  return _RatingRowMulti(
                    selected: picked,
                    onToggle: controller.toggleRating,
                  );
                }),
              ],
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBottomNavBarColor
                      : AppColors.lightBottomNavBarColor,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.reset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          foregroundColor: isDark
                              ? Colors.white70
                              : const Color(0xFF555555),
                        ),
                        child: Text('Reset Filter'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.back(result: controller.toResult()),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Apply Filter'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  const _SectionHeader({
    required this.title,
    this.trailingText,
    this.onTrailingTap,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const Spacer(),
        if (trailingText != null)
          InkWell(
            onTap: onTrailingTap,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                trailingText!,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChipSelectable extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipSelectable({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = selected
        ? AppColors.primaryColor
        : (isDark ? AppColors.darkCardColor : AppColors.lightCardColor);
    final Color fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : const Color(0xFF333333));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _RatingRowMulti extends StatelessWidget {
  final Set<int> selected;
  final void Function(int) onToggle;
  const _RatingRowMulti({required this.selected, required this.onToggle});

  Widget _btn(int v) {
    final on = selected.contains(v);
    final isDark = Get.theme.brightness == Brightness.dark;
    return Material(
      color: on
          ? AppColors.primaryColor
          : isDark
          ? AppColors.darkCardColor
          : AppColors.lightCardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onToggle(v),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                v.toString(),
                style: TextStyle(
                  color: on
                      ? Colors.white
                      : isDark
                      ? AppColors.whiteColor
                      : AppColors.blackColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [5, 4, 3, 2].map(_btn).toList(),
    );
  }
}

class _PriceInputsNoLimit extends StatelessWidget {
  final ProductSearchFilterController controller;
  const _PriceInputsNoLimit({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    InputDecoration deco(String hint) {
      final radius = BorderRadius.circular(10);
      return InputDecoration(
        isDense: true,
        hintText: hint,
        filled: true,
        fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.2,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.minPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: deco('Min'),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '—',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller.maxPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: deco('Max'),
          ),
        ),
      ],
    );
  }
}

class _ShimmerChipsRow extends StatelessWidget {
  const _ShimmerChipsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          highlightColor: AppColors.greyColor,
          child: Container(
            height: 36,
            width: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 8,
      ),
    );
  }
}
