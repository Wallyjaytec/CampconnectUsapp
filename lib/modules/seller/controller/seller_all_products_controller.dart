import 'dart:math';

import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/repositories/seller_repository.dart';
import '../../product/model/brand_model.dart';
import '../../product/model/product_model.dart';
import '../model/seller_all_products_model.dart';

class SellerAllProductsController extends GetxController {
  SellerAllProductsController({
    required this.slug,
    required String title,
    SellerRepository? repository,
  }) : repo = repository ?? SellerRepository(apiService: ApiService()) {
    screenTitle.value = title;
  }

  final SellerRepository repo;
  final String slug;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxString screenTitle = ''.obs;

  final RxList<VM> items = <VM>[].obs;

  final RxList<ProductModel> wItems = <ProductModel>[].obs;

  int _page = 1;
  final int _perPage = 24;
  int _lastPage = 1;
  bool get hasMore => _page <= _lastPage;

  String currentSorting = 'newest';
  int? selectedBrandId;
  int? selectedCategoryId;
  double? minPrice;
  double? maxPrice;
  int? currentRating;

  @override
  void onInit() {
    super.onInit();
    _loadPage(isMore: false);
    _ensureBrandsLoaded();
  }

  Future<void> refreshFirstPage() async {
    _page = 1;
    await _loadPage(isMore: false);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value || isLoading.value) return;
    await _loadPage(isMore: true);
  }

  final Rx<int?> selectedBrandIdRx = Rx<int?>(null);

  void pickBrand(int id) {
    selectedBrandId = id > 0 ? id : null;
    selectedBrandIdRx.value = selectedBrandId;
    _page = 1;
    _lastPage = 1;
    items.clear();
    wItems.clear();
    _loadPage(isMore: false);
  }

  Future<void> applyFilter(Map<String, dynamic> data) async {
    final String pickedSort = (data['sorting'] ?? 'newest').toString().trim();
    currentSorting = pickedSort.isEmpty ? 'newest' : pickedSort;

    final int? bId = _asIntOrNull(data['brandId']);
    selectedBrandId = (bId != null && bId > 0) ? bId : null;

    final int? cId = _asIntOrNull(data['categoryId']);
    if (cId != null && cId > 0) {
      selectedCategoryId = cId;
    }

    final List rs = (data['ratings'] as List?) ?? const [];
    currentRating = rs.isNotEmpty ? rs.fold<int>(0, (p, n) => max(p, n)) : null;

    minPrice = _asDoublePositiveOrNull(data['priceMin']);
    maxPrice = _asDoublePositiveOrNull(data['priceMax']);
    if (minPrice != null && maxPrice != null && minPrice! > maxPrice!) {
      final t = minPrice!;
      minPrice = maxPrice!;
      maxPrice = t;
    }

    _page = 1;
    _lastPage = 1;
    items.clear();
    wItems.clear();
    await _loadPage(isMore: false);
  }

  Map<String, dynamic> toDetailsArgs(VM p) => {'permalink': p.slug};

  Future<void> _loadPage({required bool isMore}) async {
    try {
      if (isMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        error.value = '';
      }

      final SellerAllProductsResponse res = await repo.fetchShopAllProducts(
        slug: slug,
        page: _page,
        perPage: _perPage,
        sorting: currentSorting,
        categoryId: selectedCategoryId,
        brandId: selectedBrandId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        rating: currentRating,
      );

      _lastPage = (res.meta.lastPage <= 0) ? 1 : res.meta.lastPage;

      final normalized = _normalizeBySorting(res.data, currentSorting);

      final vms = normalized.map(_toVM).toList(growable: false);
      final ws = normalized.map(_toWishProduct).toList(growable: false);

      if (isMore) {
        items.addAll(vms);
        wItems.addAll(ws);
      } else {
        items.assignAll(vms);
        wItems.assignAll(ws);
      }

      _page = (_page < _lastPage) ? (_page + 1) : (_lastPage + 1);
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      if (!isMore) {
        items.clear();
        wItems.clear();
      }
    } finally {
      if (isMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  List<SellerAllProductItem> _normalizeBySorting(
    List<SellerAllProductItem> src,
    String sorting,
  ) {
    final list = List<SellerAllProductItem>.from(src);
    final key = sorting.isEmpty ? 'newest' : sorting;

    switch (key) {
      case 'lowToHigh':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'highToLow':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
        list.sort((a, b) {
          final byRate = b.avgRating.compareTo(a.avgRating);
          if (byRate != 0) return byRate;
          final byReviews = b.totalReviews.compareTo(a.totalReviews);
          if (byReviews != 0) return byReviews;
          return b.id.compareTo(a.id);
        });
        break;
      case 'newest':
      default:
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
    }
    return list;
  }

  VM _toVM(SellerAllProductItem it) => VM(
    id: it.id,
    slug: it.slug,
    title: it.name,
    imageUrl: it.thumbnailImage,
    price: it.price,
    oldPrice: (it.basePrice > it.price) ? it.basePrice : null,
    rating: it.avgRating,
  );

  ProductModel _toWishProduct(SellerAllProductItem it) => ProductModel(
    id: it.id,
    title: it.name,
    slug: it.slug,
    image: it.thumbnailImage,
    price: it.price,
    oldPrice: (it.basePrice > it.price) ? it.basePrice : null,
    rating: it.avgRating,
    hasVariant: false,
    quantity: 0,
    unit: '',
    totalReviews: 0,
    currency: '',
  );

  final BrandRepository _brandRepo = BrandRepository();
  final RxList<Brand> brands = <Brand>[].obs;
  bool _brandsLoaded = false;

  Future<void> _ensureBrandsLoaded() async {
    if (_brandsLoaded) return;
    try {
      final list = await _brandRepo.fetchAll();
      brands.assignAll(list);
      _brandsLoaded = true;
    } catch (_) {}
  }

  int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  double? _asDoublePositiveOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final d = v.toDouble();
      return (d > 0) ? d : null;
    }
    final p = double.tryParse(v.toString());
    if (p == null) return null;
    return (p > 0) ? p : null;
  }
}

class VM {
  final int id;
  final String slug;
  final String title;
  final String imageUrl;
  final double price;
  final double? oldPrice;
  final double rating;

  VM({
    required this.id,
    required this.slug,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.oldPrice,
    required this.rating,
  });
}
