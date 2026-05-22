import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/product_model.dart';

class ProductRepository {
  final ApiService api;
  ProductRepository(this.api);

  Future<PaginatedProducts> fetchPaged({
    int? categoryId,
    int? subcategoryId,
    int? leafId,
    required int page,
    required int perPage,
    String sorting = 'newest',
    String brandId = '',
    double? minPrice,
    double? maxPrice,
    String rating = '',
  }) async {
    final url = AppConfig.productsUrl();

    const allowedSorts = {'newest', 'popular', 'lowToHigh', 'highToLow'};
    final sortingSafe = allowedSorts.contains(sorting) ? sorting : 'newest';

    double? minP = (minPrice != null && minPrice > 0) ? minPrice : null;
    double? maxP = (maxPrice != null && maxPrice > 0) ? maxPrice : null;

    if (minP != null && maxP != null && minP > maxP) {
      final tmp = minP;
      minP = maxP;
      maxP = tmp;
    }

    dynamic brandField;
    if (brandId.trim().isNotEmpty) {
      final bInt = int.tryParse(brandId.trim());
      brandField = (bInt != null && bInt > 0) ? bInt : brandId.trim();
    }

    final payload = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'sorting': sortingSafe,
      if ((categoryId ?? 0) > 0) 'category_id': categoryId,
      if (brandField != null) 'brand_id': brandField,
      if (minP != null) 'min_price': double.parse(minP.toStringAsFixed(2)),
      if (maxP != null) 'max_price': double.parse(maxP.toStringAsFixed(2)),
      if (rating.trim().isNotEmpty) 'rating': rating.trim(),
    };

    final res = await api.postJson(url, body: payload);

    final list = (res['data'] as List?) ?? const [];

    final items = list
        .whereType<Map>()
        .map((e) => ProductModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    final bool hasMore = items.length == perPage;

    return PaginatedProducts(
      items: items,
      hasMore: hasMore,
      nextPage: page + 1,
    );
  }

  Future<PaginatedProducts> fetchByCategoryPaged({
    required int categoryIdToSend,
    int? subcategoryIdToSend,
    int? leafIdToSend,
    required int page,
    required int perPage,
    String sorting = 'newest',
    String brandId = '',
    double? minPrice,
    double? maxPrice,
    String rating = '',
  }) {
    return fetchPaged(
      categoryId: categoryIdToSend > 0 ? categoryIdToSend : null,
      subcategoryId: subcategoryIdToSend,
      leafId: leafIdToSend,
      page: page,
      perPage: perPage,
      sorting: sorting,
      brandId: brandId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rating: rating,
    );
  }

  Future<PaginatedProducts> fetchPopularPaged({
    required int page,
    required int perPage,
    String sorting = 'popular',
  }) async {
    final url = AppConfig.productsUrl();

    final payload = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'sorting': 'popular',
    };

    final res = await api.postJson(url, body: payload);

    final list = (res['data'] as List?) ?? const [];

    final items = list
        .whereType<Map>()
        .map((e) => ProductModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    final bool hasMore = items.length == perPage;

    return PaginatedProducts(
      items: items,
      hasMore: hasMore,
      nextPage: page + 1,
    );
  }

  Future<PaginatedProducts> fetchRandomPaged({
    required int page,
    required int perPage,
  }) async {
    final url = AppConfig.randomProductsUrl();

    final res = await api.postMultipart(
      url,
      fields: {'page': '$page', 'per_page': '$perPage'},
    );

    final list = (res['data'] as List?) ?? const [];
    final items = list
        .whereType<Map>()
        .map((e) => ProductModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    final bool hasMore = items.length == perPage;

    return PaginatedProducts(
      items: items,
      hasMore: hasMore,
      nextPage: page + 1,
    );
  }

  Future<PaginatedProducts> fetchFeaturedPaged({
    required int page,
    required int perPage,
  }) async {
    final url = AppConfig.productsUrl();

    final payload = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'is_featured': '1',
    };

    final res = await api.postJson(url, body: payload);

    final list = (res['data'] as List?) ?? [];

    final items = list
        .whereType<Map>()
        .map((e) => ProductModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    final bool hasMore = items.length == perPage;

    return PaginatedProducts(
      items: items,
      hasMore: hasMore,
      nextPage: page + 1,
    );
  }
}

class PaginatedProducts {
  final List<ProductModel> items;
  final bool hasMore;
  final int nextPage;
  PaginatedProducts({
    required this.items,
    required this.hasMore,
    required this.nextPage,
  });
}
