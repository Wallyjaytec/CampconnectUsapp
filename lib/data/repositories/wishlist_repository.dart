import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/product_model.dart';

class WishlistRepository {
  WishlistRepository(this._api);
  final ApiService _api;

  Future<WishlistPage> fetchWishlist({
    required int page,
    required int perPage,
  }) async {
    final url = AppConfig.customerWishlistUrl();

    final res = await _api.postJson(
      url,
      body: {'page': page, 'perPage': perPage},
    );

    final dynamic rootData = res['data'] ?? res;

    final items = <ProductModel>[];

    if (rootData is List) {
      for (final e in rootData) {
        _mapWishlistRowToProduct(e, items);
      }
    } else if (rootData is Map<String, dynamic>) {
      final rows = rootData['data'];
      if (rows is List) {
        for (final e in rows) {
          _mapWishlistRowToProduct(e, items);
        }
      }
    }

    int next = page + 1;
    bool hasMore = true;

    final meta = res['meta'] ?? (rootData is Map ? rootData['meta'] : null);
    if (meta is Map) {
      final cur = _toInt(meta['current_page'], fallback: page);
      final last = _toInt(meta['last_page'], fallback: cur);
      next = cur + 1;
      hasMore = cur < last;
    } else {
      hasMore = items.length >= perPage;
      next = hasMore ? (page + 1) : page;
    }

    return WishlistPage(items: items, nextPage: next, hasMore: hasMore);
  }

  Future<void> addToWishlist({required int productId}) async {
    final url = AppConfig.customerWishlistAddUrl();
    await _api.postJson(url, body: {'product_id': productId});
  }

  Future<void> removeFromWishlist({required int productId}) async {
    final url = AppConfig.customerWishlistRemoveUrl();
    await _api.postJson(url, body: {'product_id': productId});
  }

  void _mapWishlistRowToProduct(dynamic e, List<ProductModel> out) {
    if (e is! Map) return;
    final map = e;

    final int id = _toInt(map['id'], fallback: 0);

    final String name =
        (map['name'] ?? map['title'] ?? map['product_name'] ?? '').toString();

    final String slug =
        (map['slug'] ?? map['permalink'] ?? map['product_slug'] ?? '')
            .toString();

    final String thumb =
        (map['thumbnail_image'] ?? map['image'] ?? map['thumbnail'] ?? '')
            .toString();

    final double basePrice = _toDouble(map['base_price']);
    final double price = _toDouble(map['price']);
    final double rating = _toDouble(map['avg_rating'] ?? map['rating']);

    out.add(
      ProductModel(
        id: id,
        title: name,
        slug: slug,
        image: thumb,
        price: price,
        oldPrice: (basePrice > price && basePrice > 0) ? basePrice : null,
        rating: rating,
        currency: '',
        totalReviews: _toInt(map['total_reviews'], fallback: 0),
        hasVariant: _toInt(map['has_variant'], fallback: 0) == 1,
        quantity: _toInt(map['quantity'], fallback: 0),
        unit: (map['unit'] ?? '').toString(),
      ),
    );
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    return int.tryParse('$v') ?? fallback;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}

class WishlistPage {
  final List<ProductModel> items;
  final int nextPage;
  final bool hasMore;
  WishlistPage({
    required this.items,
    required this.nextPage,
    required this.hasMore,
  });
}
