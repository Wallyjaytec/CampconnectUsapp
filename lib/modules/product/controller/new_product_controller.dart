import 'dart:math';

import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../product/model/brand_model.dart';
import '../model/product_model.dart';
import 'for_you_controller.dart';

class NewProductController extends GetxController {
  NewProductController({
    ProductRepository? repository,
    this.suppressInitialFetch = false,
  }) : repo = repository ?? ProductRepository(ApiService());

  final ProductRepository repo;

  final bool suppressInitialFetch;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<ProductModel> items = <ProductModel>[].obs;

  int? categoryId;

  final RxString title = 'New Products'.obs;

  String currentSorting = 'newest';
  String currentBrandId = '';
  double? minPrice;
  double? maxPrice;
  int? currentRating;

  bool avoidDefaultCategoryIfNotProvided = true;

  void resetFiltersToDefault() {
    currentSorting = 'newest';
    currentBrandId = '';
    minPrice = null;
    maxPrice = null;
    currentRating = null;
  }

  @override
  void onInit() {
    super.onInit();
    if (!suppressInitialFetch) {
      fetchTopSales();
    }
    _ensureBrandsLoaded();
  }

  @override
  Future<void> refresh() async {
    items.clear();
    error.value = '';
    isLoading.value = true;

    await fetchTopSales();
  }

  Future<void> retry() => fetchTopSales();

  void openViewAll() {
    Get.toNamed(
      AppRoutes.newProductView,
      arguments: <String, dynamic>{
        'mode': 'newest',
        'sorting': 'newest',
        'title': 'New Products',
        if (categoryId != null && categoryId! > 0) 'categoryId': categoryId,
      },
    );
  }

  Future<void> fetchTopSales() async {
    try {
      isLoading.value = true;
      error.value = '';

      PaginatedProducts page;

      try {
        page = await repo.fetchPaged(
          page: 1,
          perPage: 20,
          sorting: 'newest',
          categoryId: (categoryId != null && categoryId! > 0)
              ? categoryId
              : null,
        );
      } catch (_) {
        final int idToSend = (categoryId != null && categoryId! > 0)
            ? categoryId!
            : 0;

        page = await repo.fetchByCategoryPaged(
          categoryIdToSend: idToSend,
          page: 1,
          perPage: 20,
          sorting: 'newest',
        );
      }

      items.assignAll(page.items);
    } catch (e) {
      error.value = 'Something went wrong';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  String formatPrice(double value) {
    String symbol = '\$';
    try {
      final svc = Get.find<CurrencyService>();
      symbol = (svc.current?.symbol ?? '\$').trim();
    } catch (_) {}
    return '$symbol${value.toStringAsFixed(2)}';
  }

  final RxBool isLoadingMore = false.obs;
  int _page = 1;
  int _perPage = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Future<void> _loadPage({required bool isMore}) async {
    try {
      if (isMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        error.value = '';
      }

      PaginatedProducts page;

      try {
        page = await repo.fetchPaged(
          page: _page,
          perPage: _perPage,
          sorting: currentSorting.isEmpty ? 'newest' : currentSorting,
          categoryId: (categoryId != null && categoryId! > 0)
              ? categoryId
              : null,
          brandId: currentBrandId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          rating: currentRating == null ? '' : currentRating.toString(),
        );
      } catch (_) {
        final int idToSend = (categoryId != null && categoryId! > 0)
            ? categoryId!
            : 0;

        page = await repo.fetchByCategoryPaged(
          categoryIdToSend: idToSend,
          page: _page,
          perPage: _perPage,
          sorting: currentSorting.isEmpty ? 'newest' : currentSorting,
          brandId: currentBrandId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          rating: currentRating == null ? '' : currentRating.toString(),
        );
      }

      final exist = items.map((e) => e.id).toSet();
      final incoming = page.items.where((e) => !exist.contains(e.id)).toList();

      if (isMore) {
        items.addAll(incoming);
        ForYouController.ensure().addCandidates(incoming);
      } else {
        items.assignAll(incoming);
        ForYouController.ensure().addCandidates(items);
      }

      _hasMore = incoming.isNotEmpty;
      if (_hasMore) _page += 1;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      if (!isMore) items.clear();
      _hasMore = false;
    } finally {
      if (isMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  Future<void> openFullList({
    int? categoryId,
    int perPage = 20,
    String? titleOverride,
  }) async {
    if ((categoryId == null || categoryId <= 0) &&
        avoidDefaultCategoryIfNotProvided) {
      this.categoryId = null;
    } else if (categoryId != null && categoryId > 0) {
      this.categoryId = categoryId;
    }

    if (titleOverride != null && titleOverride.trim().isNotEmpty) {
      title.value = titleOverride.trim();
    }

    _page = 1;
    _perPage = perPage;
    _hasMore = true;

    items.clear();
    await _loadPage(isMore: false);

    _ensureBrandsLoaded();
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;
    await _loadPage(isMore: true);
  }

  Future<void> open({
    int? categoryId,
    String? titleOverride,
    int perPage = 20,
  }) {
    return openFullList(
      categoryId: categoryId,
      perPage: perPage,
      titleOverride: titleOverride,
    );
  }

  Future<void> refreshFirstPage() {
    return openFullList(
      categoryId: categoryId,
      perPage: _perPage,
      titleOverride: title.value,
    );
  }

  void applyFilter(Map data) {
    final String pickedSort = (data['sorting'] ?? 'newest').toString().trim();
    currentSorting = pickedSort.isEmpty ? 'newest' : pickedSort;

    final int? bId = _asIntOrNull(data['brandId']);
    currentBrandId = (bId == null || bId <= 0) ? '' : bId.toString();
    selectedBrandId.value = bId;

    final int? cId = _asIntOrNull(data['categoryId']);
    categoryId = (cId != null && cId > 0) ? cId : categoryId;

    final List rs = (data['ratings'] as List?) ?? const [];
    currentRating = rs.isNotEmpty ? rs.fold<int>(0, (p, n) => max(p, n)) : null;

    minPrice = _asDoubleOrNull(data['priceMin']);
    maxPrice = _asDoubleOrNull(data['priceMax']);

    _page = 1;
    _hasMore = true;
    items.clear();
    _loadPage(isMore: false);
  }

  int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final d = v.toDouble();
      return (d <= 0) ? null : d;
    }
    final parsed = double.tryParse(v.toString());
    if (parsed == null) return null;
    return (parsed <= 0) ? null : parsed;
  }

  final BrandRepository _brandRepo = BrandRepository();
  final RxList<Brand> brands = <Brand>[].obs;
  final Rx<int?> selectedBrandId = Rx<int?>(null);
  bool _brandsLoaded = false;

  List<ProductModel> get products => items;

  Future<void> _ensureBrandsLoaded() async {
    if (_brandsLoaded) return;
    try {
      final list = await _brandRepo.fetchAll();
      brands.assignAll(list);
      _brandsLoaded = true;
    } catch (_) {}
  }

  void pickBrand(int id) {
    selectedBrandId.value = id;
    currentBrandId = id > 0 ? id.toString() : '';
    _page = 1;
    _hasMore = true;
    items.clear();
    _loadPage(isMore: false);
  }
}
