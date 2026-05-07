class SellerNavArgs {
  final String title;
  final String logo;
  final String slug;
  final int ratingPercent;
  final int followers;
  final String? shopBanner;
  final bool isFollowing;

  const SellerNavArgs({
    required this.title,
    required this.logo,
    required this.slug,
    this.ratingPercent = 0,
    this.followers = 0,
    this.shopBanner,
    this.isFollowing = false,
  });
}

class SellerShopModel {
  final int id;
  final String sellerId;
  final String shopSlug;
  final String shopName;
  final String? sellerPhone;
  final String? shopPhone;
  final String? logo;
  final String? shopBanner;
  final String? shopAddress;

  SellerShopModel({
    required this.id,
    required this.sellerId,
    required this.shopSlug,
    required this.shopName,
    this.sellerPhone,
    this.shopPhone,
    this.logo,
    this.shopBanner,
    this.shopAddress,
  });

  factory SellerShopModel.fromMap(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return SellerShopModel(
      id: toInt(json['id']),
      sellerId: json['seller_id']?.toString() ?? '',
      shopSlug: json['shop_slug']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? '',
      sellerPhone: json['seller_phone']?.toString(),
      shopPhone: json['shop_phone']?.toString(),
      logo: json['logo']?.toString(),
      shopBanner: json['shop_banner']?.toString(),
      shopAddress: json['shop_address']?.toString(),
    );
  }
}

class SellerDiscountModel {
  final String discountAmount;
  final String discountType;

  SellerDiscountModel({
    required this.discountAmount,
    required this.discountType,
  });

  factory SellerDiscountModel.fromMap(Map<String, dynamic> json) {
    return SellerDiscountModel(
      discountAmount: json['discount_amount']?.toString() ?? '0',
      discountType: json['discountType']?.toString() ?? '0',
    );
  }
}

class SellerProductModel {
  final int id;
  final int hasVariant;
  final String name;
  final String slug;
  final String thumbnailImage;
  final num basePrice;
  final num price;
  final SellerDiscountModel? discount;
  final int quantity;
  final String unit;
  final String minQty;
  final String maxQty;
  final int totalReviews;
  final num avgRating;
  final String seller;
  final SellerShopModel? shop;

  SellerProductModel({
    required this.id,
    required this.hasVariant,
    required this.name,
    required this.slug,
    required this.thumbnailImage,
    required this.basePrice,
    required this.price,
    required this.discount,
    required this.quantity,
    required this.unit,
    required this.minQty,
    required this.maxQty,
    required this.totalReviews,
    required this.avgRating,
    required this.seller,
    required this.shop,
  });

  String get image => thumbnailImage;
  double get rating => avgRating.toDouble();
  bool get isVariant => hasVariant == 1;

  factory SellerProductModel.fromMap(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    num toNum(dynamic v) =>
        v is num ? v : num.tryParse(v?.toString() ?? '0') ?? 0;

    return SellerProductModel(
      id: toInt(json['id']),
      hasVariant: toInt(json['has_variant']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      thumbnailImage: json['thumbnail_image']?.toString() ?? '',
      basePrice: toNum(json['base_price']),
      price: toNum(json['price']),
      discount: (json['discount'] is Map<String, dynamic>)
          ? SellerDiscountModel.fromMap(json['discount'])
          : null,
      quantity: toInt(json['quantity']),
      unit: json['unit']?.toString() ?? '',
      minQty: json['min_qty']?.toString() ?? '1',
      maxQty: json['max_qty']?.toString() ?? '0',
      totalReviews: toInt(json['total_reviews']),
      avgRating: toNum(json['avg_rating']),
      seller: json['seller']?.toString() ?? '',
      shop: (json['shop'] is Map<String, dynamic>)
          ? SellerShopModel.fromMap(json['shop'])
          : null,
    );
  }
}

class SellerPagedProducts {
  final List<SellerProductModel> data;

  SellerPagedProducts({required this.data});

  factory SellerPagedProducts.fromMap(Map<String, dynamic> json) {
    final raw = json['data'];
    if (raw is List) {
      return SellerPagedProducts(
        data: raw
            .whereType<Map<String, dynamic>>()
            .map(SellerProductModel.fromMap)
            .toList(),
      );
    }
    return SellerPagedProducts(data: const []);
  }
}

class FollowShopResponse {
  final int status;
  final bool success;
  final bool duplicate;

  FollowShopResponse({
    required this.status,
    required this.success,
    required this.duplicate,
  });

  factory FollowShopResponse.fromJson(Map<String, dynamic> json) {
    return FollowShopResponse(
      status: (json['status'] is num) ? (json['status'] as num).toInt() : 0,
      success: json['success'] == true || '${json['success']}' == 'true',
      duplicate: json['duplicate'] == true || '${json['duplicate']}' == 'true',
    );
  }
}

class ShopProductSummaryResponse {
  final bool success;
  final SellerPagedProducts newItems;
  final SellerPagedProducts featuredItems;
  final SellerPagedProducts topSellingItems;

  ShopProductSummaryResponse({
    required this.success,
    required this.newItems,
    required this.featuredItems,
    required this.topSellingItems,
  });

  factory ShopProductSummaryResponse.fromMap(Map<String, dynamic> json) {
    bool toBool(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    return ShopProductSummaryResponse(
      success: toBool(json['success']),
      newItems: (json['new_items'] is Map<String, dynamic>)
          ? SellerPagedProducts.fromMap(json['new_items'])
          : SellerPagedProducts(data: const []),
      featuredItems: (json['featured_items'] is Map<String, dynamic>)
          ? SellerPagedProducts.fromMap(json['featured_items'])
          : SellerPagedProducts(data: const []),
      topSellingItems: (json['top_selling_items'] is Map<String, dynamic>)
          ? SellerPagedProducts.fromMap(json['top_selling_items'])
          : SellerPagedProducts(data: const []),
    );
  }
}
