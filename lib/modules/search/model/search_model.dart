class ShopModel {
  final int id;
  final String sellerId;
  final String? sellerPhone;
  final String shopSlug;
  final String? shopPhone;
  final String shopName;
  final String? logo;
  final String? shopBanner;
  final String? shopAddress;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaImage;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ShopModel({
    required this.id,
    required this.sellerId,
    required this.sellerPhone,
    required this.shopSlug,
    required this.shopPhone,
    required this.shopName,
    required this.logo,
    required this.shopBanner,
    required this.shopAddress,
    required this.metaTitle,
    required this.metaDescription,
    required this.metaImage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: (json['id'] ?? 0) is int
          ? json['id']
          : int.tryParse('${json['id']}') ?? 0,
      sellerId: json['seller_id']?.toString() ?? '',
      sellerPhone: json['seller_phone']?.toString(),
      shopSlug: json['shop_slug']?.toString() ?? '',
      shopPhone: json['shop_phone']?.toString(),
      shopName: json['shop_name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      shopBanner: json['shop_banner']?.toString(),
      shopAddress: json['shop_address']?.toString(),
      metaTitle: json['meta_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      metaImage: json['meta_image']?.toString(),
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}

class ProductModel {
  final int id;
  final int hasVariant;
  final String name;
  final String slug;
  final String thumbnailImage;
  final num basePrice;
  final num price;
  final String? discountAmount;
  final String? discountType;
  final int quantity;
  final String unit;
  final int? minQty;
  final int? maxQty;
  final int totalReviews;
  final num avgRating;
  final String seller;
  final ShopModel? shop;

  ProductModel({
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
    required this.seller,
    required this.shop,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final discount = json['discount'] as Map<String, dynamic>?;
    return ProductModel(
      id: (json['id'] ?? 0) is int
          ? json['id']
          : int.tryParse('${json['id']}') ?? 0,
      hasVariant: (json['has_variant'] ?? 0) is int
          ? json['has_variant']
          : int.tryParse('${json['has_variant']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      thumbnailImage: json['thumbnail_image']?.toString() ?? '',
      basePrice: (json['base_price'] is num)
          ? json['base_price']
          : num.tryParse('${json['base_price']}') ?? 0,
      price: (json['price'] is num)
          ? json['price']
          : num.tryParse('${json['price']}') ?? 0,
      discountAmount: discount?['discount_amount']?.toString(),
      discountType: discount?['discountType']?.toString(),
      quantity: (json['quantity'] ?? 0) is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 0,
      unit: json['unit']?.toString() ?? '',
      minQty: json['min_qty'] == null
          ? null
          : int.tryParse('${json['min_qty']}'),
      maxQty: json['max_qty'] == null
          ? null
          : int.tryParse('${json['max_qty']}'),
      totalReviews: (json['total_reviews'] ?? 0) is int
          ? json['total_reviews']
          : int.tryParse('${json['total_reviews']}') ?? 0,
      avgRating: (json['avg_rating'] is num)
          ? json['avg_rating']
          : num.tryParse('${json['avg_rating']}') ?? 0,
      seller: json['seller']?.toString() ?? '',
      shop: json['shop'] is Map<String, dynamic>
          ? ShopModel.fromJson(json['shop'])
          : null,
    );
  }
}

class PageLink {
  final String? url;
  final String label;
  final bool active;
  PageLink({this.url, required this.label, required this.active});
  factory PageLink.fromJson(Map<String, dynamic> json) => PageLink(
    url: json['url']?.toString(),
    label: json['label']?.toString() ?? '',
    active: json['active'] == true,
  );
}

class MetaInfo {
  final int currentPage;
  final int perPage;
  final int total;
  final int? lastPage;
  MetaInfo({
    required this.currentPage,
    required this.perPage,
    required this.total,
    this.lastPage,
  });
  factory MetaInfo.fromJson(Map<String, dynamic> json) => MetaInfo(
    currentPage: int.tryParse('${json['current_page'] ?? 1}') ?? 1,
    perPage: int.tryParse('${json['per_page'] ?? 20}') ?? 20,
    total: int.tryParse('${json['total'] ?? 0}') ?? 0,
    lastPage: json['last_page'] == null
        ? null
        : int.tryParse('${json['last_page']}'),
  );
}

class SearchProductsResponse {
  final List<ProductModel> data;
  final MetaInfo meta;

  SearchProductsResponse({required this.data, required this.meta});

  factory SearchProductsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
    return SearchProductsResponse(
      data: list,
      meta: MetaInfo.fromJson(metaJson),
    );
  }
}

class SuggestionCategory {
  final int id;
  final String name;
  final String slug;
  final String url;
  SuggestionCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.url,
  });
  factory SuggestionCategory.fromJson(Map<String, dynamic> json) =>
      SuggestionCategory(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
      );
}

class SuggestionTag {
  final String name;
  final String permalink;
  SuggestionTag({required this.name, required this.permalink});
  factory SuggestionTag.fromJson(Map<String, dynamic> j) => SuggestionTag(
    name: j['name']?.toString() ?? '',
    permalink: j['permalink']?.toString() ?? '',
  );
}

class SearchSuggestionsResponse {
  final List<SuggestionCategory> categories;
  final List<ProductModel> products;
  final List<SuggestionTag> tags;

  SearchSuggestionsResponse({
    required this.categories,
    required this.products,
    required this.tags,
  });

  factory SearchSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final List<dynamic> catsList;
    if (rawCats is List) {
      catsList = rawCats;
    } else if (rawCats is Map<String, dynamic>) {
      catsList = rawCats['data'] as List? ?? [];
    } else {
      catsList = const [];
    }

    final cats = catsList
        .whereType<Map<String, dynamic>>()
        .map(SuggestionCategory.fromJson)
        .toList();

    final rawProds = json['products'];
    final List<dynamic> prodsList;
    if (rawProds is List) {
      prodsList = rawProds;
    } else if (rawProds is Map<String, dynamic>) {
      prodsList = rawProds['data'] as List? ?? [];
    } else {
      prodsList = const [];
    }

    final prods = prodsList
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();

    final tags = (json['tags'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SuggestionTag.fromJson)
        .toList();

    return SearchSuggestionsResponse(
      categories: cats,
      products: prods,
      tags: tags,
    );
  }
}
