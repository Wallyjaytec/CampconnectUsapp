class CollectionDetails {
  final int id;
  final String name;
  final String permalink;
  final String image;

  CollectionDetails({
    required this.id,
    required this.name,
    required this.permalink,
    required this.image,
  });

  factory CollectionDetails.fromJson(Map<String, dynamic> json) {
    final details = json['details'] ?? json;
    return CollectionDetails(
      id: (details['id'] as num).toInt(),
      name: details['name']?.toString() ?? '',
      permalink: details['permalink']?.toString() ?? '',
      image: details['image']?.toString() ?? '',
    );
  }
}

class CollectionProduct {
  final int id;
  final int hasVariant;
  final String name;
  final String slug;
  final String thumbnailImage;
  final num basePrice;
  final num price;
  final num? discountAmount;
  final String? discountType;
  final int quantity;
  final String unit;
  final num? minQty;
  final num? maxQty;
  final int totalReviews;
  final num avgRating;

  CollectionProduct({
    required this.id,
    required this.hasVariant,
    required this.name,
    required this.slug,
    required this.thumbnailImage,
    required this.basePrice,
    required this.price,
    required this.discountAmount,
    required this.discountType,
    required this.quantity,
    required this.unit,
    required this.minQty,
    required this.maxQty,
    required this.totalReviews,
    required this.avgRating,
  });

  factory CollectionProduct.fromJson(Map<String, dynamic> j) {
    return CollectionProduct(
      id: (j['id'] as num).toInt(),
      hasVariant: (j['has_variant'] as num?)?.toInt() ?? 0,
      name: j['name']?.toString() ?? '',
      slug: j['slug']?.toString() ?? '',
      thumbnailImage: j['thumbnail_image']?.toString() ?? '',
      basePrice: j['base_price'] as num? ?? 0,
      price: j['price'] as num? ?? 0,
      discountAmount: j['discount']?['discount_amount'] == null
          ? null
          : num.tryParse(j['discount']?['discount_amount']?.toString() ?? ''),
      discountType: j['discount']?['discountType']?.toString(),
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      unit: j['unit']?.toString() ?? '',
      minQty: j['min_qty'] is num
          ? j['min_qty'] as num
          : num.tryParse(j['min_qty']?.toString() ?? ''),
      maxQty: j['max_qty'] is num
          ? j['max_qty'] as num
          : num.tryParse(j['max_qty']?.toString() ?? ''),
      totalReviews: (j['total_reviews'] as num?)?.toInt() ?? 0,
      avgRating: j['avg_rating'] as num? ?? 0,
    );
  }
}

class CollectionGridItem {
  final int? id;
  final String slug;
  final String imageUrl;
  final String title;
  final double rating;
  final num price;
  final num? oldPrice;

  CollectionGridItem({
    required this.id,
    required this.slug,
    required this.imageUrl,
    required this.title,
    required this.rating,
    required this.price,
    this.oldPrice,
  });

  factory CollectionGridItem.fromProduct(CollectionProduct p) {
    final hasDiscount =
        (p.discountAmount != null) &&
        (p.discountAmount?.toString().isNotEmpty == true);
    final oldPrice = hasDiscount ? p.basePrice : null;

    return CollectionGridItem(
      id: p.id,
      slug: p.slug,
      imageUrl: p.thumbnailImage,
      title: p.name,
      rating: (p.avgRating).toDouble(),
      price: p.price,
      oldPrice: oldPrice,
    );
  }
}

class CollectionProductsResponse {
  final List<CollectionProduct> data;
  final bool success;
  final int status;

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  CollectionProductsResponse({
    required this.data,
    required this.success,
    required this.status,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory CollectionProductsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => CollectionProduct.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return CollectionProductsResponse(
      data: list,
      success: json['success'] == true,
      status: (json['status'] as num?)?.toInt() ?? 200,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] is String)
          ? int.tryParse(meta['per_page']) ?? 10
          : (meta['per_page'] as num?)?.toInt() ?? 10,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}
