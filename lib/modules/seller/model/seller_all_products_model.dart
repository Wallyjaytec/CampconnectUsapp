class SellerAllProductsResponse {
  final List<SellerAllProductItem> data;
  final SellerAllProductsMeta meta;
  final bool success;
  final int status;

  SellerAllProductsResponse({
    required this.data,
    required this.meta,
    required this.success,
    required this.status,
  });

  factory SellerAllProductsResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List? ?? [])
        .map((e) => SellerAllProductItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return SellerAllProductsResponse(
      data: list,
      meta: SellerAllProductsMeta.fromJson(j['meta'] ?? const {}),
      success: j['success'] == true || '${j['success']}' == 'true',
      status: (j['status'] is num) ? (j['status'] as num).toInt() : 0,
    );
  }
}

class SellerAllProductsMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  SellerAllProductsMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory SellerAllProductsMeta.fromJson(Map<String, dynamic> j) {
    return SellerAllProductsMeta(
      currentPage: _asInt(j['current_page']),
      lastPage: _asInt(j['last_page']),
      perPage: _asInt(j['per_page']),
      total: _asInt(j['total']),
    );
  }
}

class SellerAllProductItem {
  final int id;
  final int hasVariant;
  final String name;
  final String slug;
  final String thumbnailImage;
  final double basePrice;
  final double price;
  final int totalReviews;
  final double avgRating;

  SellerAllProductItem({
    required this.id,
    required this.hasVariant,
    required this.name,
    required this.slug,
    required this.thumbnailImage,
    required this.basePrice,
    required this.price,
    required this.totalReviews,
    required this.avgRating,
  });

  factory SellerAllProductItem.fromJson(Map<String, dynamic> j) {
    return SellerAllProductItem(
      id: _asInt(j['id']),
      hasVariant: _asInt(j['has_variant']),
      name: (j['name'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      thumbnailImage: (j['thumbnail_image'] ?? '').toString(),
      basePrice: _asDouble(j['base_price']),
      price: _asDouble(j['price']),
      totalReviews: _asInt(j['total_reviews']),
      avgRating: _asDouble(j['avg_rating']),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
