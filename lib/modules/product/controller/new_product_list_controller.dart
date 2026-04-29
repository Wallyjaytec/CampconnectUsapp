import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/currency_service.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../model/brand_model.dart';
import '../model/product_model.dart';

enum ProductSorting { newest, popular, lowToHigh, highToLow }

class NewProductListController extends GetxController {
  NewProductListController(this._repo);
  final ProductRepository _repo;

  int categoryId = 0;
  String? categoryName;
  int? subcategoryId;
  String? subcategoryName;
  int? leafId;
  String? leafName;

  final RxString titleRx = 'All Products'.obs;

  final Rx<ProductSorting> sortingP = ProductSorting.newest.obs;
  final RxString sorting = 'newest'.obs;
  String? customTitle;

  final List<ProductModel> _all = [];
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;

  final int perPage = 20;
  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final RxSet<int> _favIds = <int>{}.obs;
  bool isFav(int id) => _favIds.contains(id);
  void toggleFavorite(int id) =>
      _favIds.contains(id) ? _favIds.remove(id) : _favIds.add(id);

  final RxSet<String> quickSelectedCategories = <String>{}.obs;

  final BrandRepository _brandRepo = BrandRepository();
  final RxList<Brand> brands = <Brand>[].obs;
  final RxInt selectedBrandId = 0.obs;

  final RxSet<String> fCategories = <String>{}.obs;
  final RxSet<int> fBrandIds = <int>{}.obs;
  final RxSet<String> fBrands = <String>{}.obs;
  final RxSet<int> fRatings = <int>{}.obs;

  final RxDouble fMinPrice = 0.0.obs;
  final RxDouble fMaxPrice = double.infinity.obs;

  int _epoch = 0;
  String _activeQueryKey = '';

  void clearOnlyFilters({bool resetSorting = true}) {
    if (resetSorting) {
      sortingP.value = ProductSorting.newest;
      sorting.value = 'newest';
    }
    selectedBrandId.value = 0;
    fBrandIds.clear();
    fBrands.clear();
    fRatings.clear();
    fMinPrice.value = 0.0;
    fMaxPrice.value = double.infinity;
  }

  void prepareForReentry() {
    clearOnlyFilters(resetSorting: true);
    _all.clear();
    products.clear();
    _page = 1;
    _hasMore = true;
    error.value = '';
    _epoch++;
  }

  void setSorting(ProductSorting s, {bool triggerReload = false}) {
    if (sortingP.value == s) return;
    sortingP.value = s;
    sorting.value = _sortingKeyForApi();
    if (triggerReload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(loadInitial);
      });
    }
  }

  void overrideTitle(String title) {
    customTitle = title;
    _recomputeTitle();
  }

  void openForCategory({
    required int categoryId,
    String? categoryName,
    int? subcategoryId,
    String? subcategoryName,
    int? leafId,
    String? leafName,
  }) {
    final changed =
        this.categoryId != categoryId ||
        this.subcategoryId != subcategoryId ||
        this.leafId != leafId;

    this.categoryId = categoryId;
    this.categoryName = categoryName;
    this.subcategoryId = subcategoryId;
    this.subcategoryName = subcategoryName;
    this.leafId = leafId;
    this.leafName = leafName;

    _recomputeTitle();

    if (changed) {
      _loadBrands();
      WidgetsBinding.instance.addPostFrameCallback((_) => loadInitial());
    }
  }

  bool _hasAnyFilterActive() {
    return selectedBrandId.value > 0 ||
        fBrandIds.isNotEmpty ||
        fBrands.isNotEmpty ||
        fRatings.isNotEmpty ||
        fMinPrice.value > 0 ||
        (fMaxPrice.value.isFinite && fMaxPrice.value < 999999);
  }

  Future<void> loadInitial() async {
    if (categoryId == 0 &&
        (subcategoryId == null || subcategoryId == 0) &&
        (leafId == null || leafId == 0) &&
        !_hasAnyFilterActive()) {
      error.value = 'Invalid category'.tr;
      products.clear();
      _all.clear();
      _hasMore = false;
      return;
    }

    _epoch++;

    _page = 1;
    _hasMore = true;
    error.value = '';
    _all.clear();
    products.clear();

    await _load(page: _page, isMore: false, epoch: _epoch);
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;
    await _load(page: _page, isMore: true, epoch: _epoch);
  }

  void pickBrand(int brandId) {
    if (selectedBrandId.value == brandId) {
      selectedBrandId.value = 0;
    } else {
      selectedBrandId.value = brandId;
    }
    loadInitial();
  }

  void applyFilter(Map result) {
    final String s = (result['sorting'] ?? '').toString().trim();
    if (s.isNotEmpty) {
      sorting.value = s;
      sortingP.value = parseProductSorting(s);
    }

    final dynamic catRaw = result['categoryId'];
    final int catFromModal = (catRaw is num)
        ? catRaw.toInt()
        : int.tryParse('${catRaw ?? ''}') ?? 0;
    if (catFromModal > 0) {
      categoryId = catFromModal;
      _recomputeTitle();
    }

    final List bids = (result['brandIds'] ?? []) as List;
    fBrandIds
      ..clear()
      ..addAll(
        bids
            .map((e) => (e is num) ? e.toInt() : int.tryParse('$e') ?? -1)
            .where((e) => e > 0),
      );
    fBrands.clear();
    if (fBrandIds.isNotEmpty && brands.isNotEmpty) {
      final names = brands
          .where((b) => fBrandIds.contains(b.id))
          .map((b) => b.name);
      fBrands.addAll(names);
    }

    final List rts = (result['ratings'] ?? []) as List;
    fRatings
      ..clear()
      ..addAll(
        rts
            .map((e) => (e is num) ? e.toInt() : int.tryParse('$e') ?? 0)
            .where((e) => e > 0),
      );

    final double? pMin = (result['priceMin'] is num)
        ? (result['priceMin'] as num).toDouble()
        : double.tryParse('${result['priceMin'] ?? ''}');
    final double? pMax = (result['priceMax'] is num)
        ? (result['priceMax'] as num).toDouble()
        : double.tryParse('${result['priceMax'] ?? ''}');

    fMinPrice.value = pMin ?? 0.0;
    fMaxPrice.value = pMax ?? double.infinity;

    _recomputeView();
    selectedBrandId.value = 0;
    loadInitial();
  }

  Future<void> _load({
    required int page,
    required bool isMore,
    required int epoch,
  }) async {
    final int deepId = (leafId != null && leafId! > 0)
        ? leafId!
        : (subcategoryId != null && subcategoryId! > 0)
        ? subcategoryId!
        : categoryId;

    String brandIdParam = '';
    if (selectedBrandId.value > 0) {
      brandIdParam = selectedBrandId.value.toString();
    } else if (fBrandIds.isNotEmpty) {
      brandIdParam = fBrandIds.map((e) => e.toString()).join(',');
    } else if (fBrands.isNotEmpty && brands.isNotEmpty) {
      final ids = brands
          .where((b) => fBrands.contains(b.name))
          .map((b) => b.id.toString())
          .toList();
      if (ids.isNotEmpty) brandIdParam = ids.join(',');
    }

    final bool hasMinDisplay = fMinPrice.value > 0;
    final bool hasMaxDisplay =
        fMaxPrice.value.isFinite && fMaxPrice.value < 999999;

    double? minPriceBase = hasMinDisplay
        ? _toBaseCurrency(fMinPrice.value.toDouble())
        : null;
    double? maxPriceBase = hasMaxDisplay
        ? _toBaseCurrency(fMaxPrice.value.toDouble())
        : null;

    if (minPriceBase == null && maxPriceBase != null) {
      minPriceBase = 0.0;
    }

    String ratingParam = '';
    if (fRatings.isNotEmpty) {
      ratingParam = fRatings.reduce((a, b) => a > b ? a : b).toString();
    }

    final String queryKey = [
      'deep:$deepId',
      'sort:${sorting.value}',
      'brand:$brandIdParam',
      'min:${minPriceBase ?? 0}',
      'max:${maxPriceBase ?? -1}',
      'rating:$ratingParam',
    ].join('|');

    try {
      if (isMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        error.value = '';
        _activeQueryKey = queryKey;
      }

      final resp = await _repo.fetchByCategoryPaged(
        categoryIdToSend: deepId,
        subcategoryIdToSend: null,
        leafIdToSend: null,
        page: page,
        perPage: perPage,
        sorting: sorting.value,
        brandId: brandIdParam,
        minPrice: minPriceBase,
        maxPrice: maxPriceBase,
        rating: ratingParam,
      );

      if (epoch != _epoch || queryKey != _activeQueryKey) {
        return;
      }

      final exist = _all.map((e) => e.id).toSet();
      final incoming = resp.items.where((e) => !exist.contains(e.id)).toList();
      _all.addAll(incoming);

      _recomputeView();

      _hasMore = resp.hasMore;
      _page = resp.nextPage;
    } catch (e) {
      if (epoch != _epoch) {
        return;
      }
      error.value = 'Something went wrong'.tr;
      if (!isMore) {
        _all.clear();
        products.clear();
      }
      _hasMore = false;
    } finally {
      if (epoch == _epoch) {
        if (isMore) {
          isLoadingMore.value = false;
        } else {
          isLoading.value = false;
        }
      }
    }
  }

  double _toBaseCurrency(double displayValue) {
    try {
      if (Get.isRegistered<CurrencyService>()) {
        final svc = Get.find<CurrencyService>();
        final cur = svc.current;
        if (cur != null && cur.conversionRate > 0) {
          final base = displayValue / cur.conversionRate;
          final fixed = double.parse(base.toStringAsFixed(cur.numberOfDecimal));
          return fixed;
        }
      }
    } catch (_) {}
    return displayValue;
  }

  String _sortingKeyForApi() {
    switch (sortingP.value) {
      case ProductSorting.popular:
        return 'popular';
      case ProductSorting.lowToHigh:
        return 'lowToHigh';
      case ProductSorting.highToLow:
        return 'highToLow';
      case ProductSorting.newest:
        return 'newest';
    }
  }

  void _recomputeView() {
    products.assignAll(_all);
  }

  Future<void> _loadBrands() async {
    try {
      final b = await _brandRepo.fetchAll();
      brands.assignAll(b);
    } catch (_) {
      brands.clear();
    }
  }

  void _recomputeTitle() {
    final t = (customTitle ?? '').trim();
    if (t.isNotEmpty) {
      titleRx.value = t;
      return;
    }
    final leaf = (leafName ?? '').trim();
    if (leaf.isNotEmpty) {
      titleRx.value = leaf;
      return;
    }
    final sub = (subcategoryName ?? '').trim();
    if (sub.isNotEmpty) {
      titleRx.value = sub;
      return;
    }
    final cat = (categoryName ?? '').trim();
    if (cat.isNotEmpty) {
      titleRx.value = cat;
      return;
    }
    titleRx.value = 'All Products'.tr;
  }

  String get titleText {
    if ((customTitle ?? '').trim().isNotEmpty) return customTitle!.trim();
    if ((leafName ?? '').trim().isNotEmpty) return leafName!.trim();
    if ((subcategoryName ?? '').trim().isNotEmpty) {
      return subcategoryName!.trim();
    }
    if ((categoryName ?? '').trim().isNotEmpty) return categoryName!.trim();
    return 'All Products'.tr;
  }

  ProductSorting parseProductSorting(String? s) {
    switch ((s ?? '').trim()) {
      case 'popular':
        return ProductSorting.popular;
      case 'lowToHigh':
        return ProductSorting.lowToHigh;
      case 'highToLow':
        return ProductSorting.highToLow;
      case 'newest':
      default:
        return ProductSorting.newest;
    }
  }
}
