class CompareSuggestionItem {
  final int id;
  final String name;
  final String? thumbnail;

  CompareSuggestionItem({required this.id, required this.name, this.thumbnail});
}

class CompareDiscountModel {
  final num? discountAmount;
  final String? discountType;

  CompareDiscountModel({this.discountAmount, this.discountType});

  static num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    final s = v.toString();
    return num.tryParse(s);
  }

  factory CompareDiscountModel.fromJson(Map<String, dynamic> json) {
    return CompareDiscountModel(
      discountAmount: _toNum(json['discount_amount']),
      discountType: json['discountType']?.toString(),
    );
  }
}

class CompareShopModel {
  final int? id;
  final String? sellerId;
  final String? shopSlug;
  final String? shopName;

  CompareShopModel({this.id, this.sellerId, this.shopSlug, this.shopName});

  factory CompareShopModel.fromJson(Map<String, dynamic> json) {
    return CompareShopModel(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}'),
      sellerId: json['seller_id']?.toString(),
      shopSlug: json['shop_slug']?.toString(),
      shopName: json['shop_name']?.toString(),
    );
  }
}

class CompareItemModel {
  final int id;
  final int hasVariant;
  final String name;
  final String slug;
  final String? thumbnailImage;
  final num basePrice;
  final num price;
  final CompareDiscountModel? discount;
  final String? discountAmountType;
  final int quantity;
  final String? unit;
  final int minQty;
  final int maxQty;
  final num avgRating;
  final String? summary;
  final String? isAuthentic;
  final String? isActiveCod;
  final String? isRefundable;
  final String? hasWarranty;
  final String? category;
  final String? brand;
  final String? seller;
  final CompareShopModel? shop;

  CompareItemModel({
    required this.id,
    required this.hasVariant,
    required this.name,
    required this.slug,
    required this.thumbnailImage,
    required this.basePrice,
    required this.price,
    required this.discount,
    this.discountAmountType,
    required this.quantity,
    required this.unit,
    required this.minQty,
    required this.maxQty,
    required this.avgRating,
    required this.summary,
    required this.isAuthentic,
    required this.isActiveCod,
    required this.isRefundable,
    required this.hasWarranty,
    required this.category,
    required this.brand,
    this.seller,
    this.shop,
  });

  static int _toInt(dynamic v, {int def = 0}) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? def;
  }

  static num _toNum(dynamic v, {num def = 0}) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? def;
  }

  static num _toNumNullable(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  factory CompareItemModel.fromJson(Map<String, dynamic> json) {
    return CompareItemModel(
      id: _toInt(json['id']),
      hasVariant: _toInt(json['has_variant']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      thumbnailImage: json['thumbnail_image']?.toString(),
      basePrice: _toNum(json['base_price']),
      price: _toNum(json['price']),
      discount: (json['discount'] is Map<String, dynamic>)
          ? CompareDiscountModel.fromJson(
              json['discount'] as Map<String, dynamic>,
            )
          : null,
      discountAmountType: json['discount_amount_type']?.toString(),
      quantity: _toInt(json['quantity']),
      unit: json['unit']?.toString(),
      minQty: _toInt(json['min_qty']),
      maxQty: _toInt(json['max_qty']),
      avgRating: _toNumNullable(json['avg_rating']),
      summary: json['summary']?.toString(),
      isAuthentic: json['is_authentic']?.toString(),
      isActiveCod: json['is_active_cod']?.toString(),
      isRefundable: json['is_refundable']?.toString(),
      hasWarranty: json['has_warranty']?.toString(),
      category: json['category']?.toString(),
      brand: json['brand']?.toString(),
      seller: json['seller']?.toString(),
      shop: (json['shop'] is Map<String, dynamic>)
          ? CompareShopModel.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
    );
  }
}
