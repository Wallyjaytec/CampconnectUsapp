import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:campconnectus_marketplace/data/repositories/search_repository.dart';
import 'package:campconnectus_marketplace/modules/search/model/search_model.dart';

import '../../../data/repositories/brand_repository.dart';
import '../../product/model/brand_model.dart';

class SearchQueryListController extends GetxController {
  final SearchRepository repo;
  SearchQueryListController(this.repo);

  static SearchQueryListController create() =>
      SearchQueryListController(SearchRepository(api: ApiService()));

  final titleRx = 'Search'.obs;

  final RxList<ProductModel> products = <ProductModel>[].obs;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final error = ''.obs;
  final firstLoadDone = false.obs;

  int _page = 1;
  final int _perPage = 20;
  String _query = '';
  String _sorting = 'newest';
  int? _brandId;
  int? _ratingPick;
  double? _minPrice, _maxPrice;
  int? _categoryId;

  final RxList<Brand> brands = <Brand>[].obs;
  final selectedBrandId = Rx<int?>(null);

  Future<void> bootstrap(String query) async {
    _query = query.trim();
    titleRx.value = _query;

    _sorting = 'newest';

    isLoading.value = true;
    products.clear();
    firstLoadDone.value = false;

    await _loadBrands();
    await _loadInitial();
  }

  Future<void> reload() => _loadInitial(resetPage: true);

  Future<void> _loadInitial({bool resetPage = true}) async {
    if (resetPage) _page = 1;

    isLoading.value = true;
    error.value = '';
    try {
      final res = await repo.searchProducts(
        page: _page,
        perPage: _perPage,
        searchKey: _query,
        sorting: _sorting,
        brandId: (_brandId ?? '').toString(),
        categoryId: (_categoryId ?? '').toString(),
        rating: _ratingPick?.toString() ?? '',
        priceRange: _buildPriceRange(),
      );
      products
        ..clear()
        ..addAll(res.data.reversed.toList());

      hasMore.value = (res.meta.lastPage == null)
          ? false
          : (_page < (res.meta.lastPage!));
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
      firstLoadDone.value = true;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    error.value = '';
    try {
      _page += 1;
      final res = await repo.searchProducts(
        page: _page,
        perPage: _perPage,
        searchKey: _query,
        sorting: _sorting,
        brandId: (_brandId ?? '').toString(),
        categoryId: (_categoryId ?? '').toString(),
        rating: _ratingPick?.toString() ?? '',
        priceRange: _buildPriceRange(),
      );
      products.addAll(res.data.reversed.toList());
      hasMore.value = (res.meta.lastPage == null)
          ? false
          : (_page < (res.meta.lastPage!));
    } catch (e) {
      _page -= 1;
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> openFilter() async {
    final res = await Get.toNamed(
      AppRoutes.productSearchFilter,
      arguments: {
        'currentSorting': _sorting,
        'currentBrandId': _brandId,
        'currentCategoryId': _categoryId,
        'currentMinPrice': _minPrice,
        'currentMaxPrice': _maxPrice,
        'currentRating': _ratingPick,
      },
    );
    if (res is Map) {
      final pickedSort = (res['sorting'] ?? 'newest').toString().trim();
      _sorting = pickedSort.isEmpty ? 'newest' : pickedSort;

      final int? brandPicked = _asIntOrNull(res['brandId']);
      _brandId = brandPicked;
      selectedBrandId.value = brandPicked;

      final int? catPicked = _asIntOrNull(res['categoryId']);
      _categoryId = catPicked;

      final List rs = (res['ratings'] as List?) ?? const [];
      _ratingPick = (rs.isNotEmpty)
          ? rs.fold<int>(0, (p, n) => (p > n) ? p : n)
          : null;

      _minPrice = _asDoubleOrNull(res['priceMin']);
      _maxPrice = _asDoubleOrNull(res['priceMax']);

      isLoading.value = true;
      products.clear();
      firstLoadDone.value = false;

      await _loadInitial();
    }
  }

  void pickBrand(int id) async {
    selectedBrandId.value = id;
    _brandId = id;

    isLoading.value = true;
    products.clear();
    firstLoadDone.value = false;

    await _loadInitial();
  }

  String _buildPriceRange() {
    if (_minPrice == null && _maxPrice == null) return '';
    final min = (_minPrice ?? 0).round();
    final max = (_maxPrice ?? 0).round();
    if (_minPrice != null && _maxPrice != null) return '$min-$max';
    if (_minPrice != null) return '$min-';
    if (_maxPrice != null) return '-$max';
    return '';
  }

  Future<void> _loadBrands() async {
    try {
      final repo = BrandRepository();
      final list = await repo.fetchAll();
      brands.assignAll(list);
    } catch (_) {
      brands.clear();
    }
  }

  void openDetails(String slug) {
    Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug});
  }

  int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
