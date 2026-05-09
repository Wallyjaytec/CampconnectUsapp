import '../../../core/config/app_config.dart';

class ProductModel {
  final int id;
  final String title;
  final String slug;
  final String image;
  final double price;
  final double? oldPrice;
  final String currency;
  final double rating;
  final int totalReviews;
  final bool hasVariant;
  final int quantity;
  final String unit;
  final String? shopName;

  const ProductModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.image,
    required this.price,
    this.oldPrice,
    required this.currency,
    required this.rating,
    required this.totalReviews,
    required this.hasVariant,
    required this.quantity,
    required this.unit,
    this.shopName,
  });

  String get imageUrl => AppConfig.assetUrl(image);
  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'slug': slug,
      'thumbnail_image': image,
      'price': price,
      'base_price': oldPrice,
      'currency': currency,
      'avg_rating': rating,
      'total_reviews': totalReviews,
      'has_variant': hasVariant ? 1 : 0,
      'quantity': quantity,
      'unit': unit,
    };
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _asStr(dynamic v) => v?.toString() ?? '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final name = _asStr(json['name']);
    final slug = _asStr(json['slug']);
    final thumb = _asStr(json['thumbnail_image']);

    final price = _asDouble(json['price']);
    final basePrice = _asDouble(json['base_price']);
    final oldPrice = (basePrice > price) ? basePrice : null;

    final r = _asDouble(json['avg_rating']);
    final double rating = r.clamp(0.0, 5.0).toDouble();
    final totalReviews = _asInt(json['total_reviews']);

    final hv = _asInt(json['has_variant']);
    final hasVariant = hv == 1 || hv == 2;

    final quantity = _asInt(json['quantity']);
    final unit = _asStr(json['unit']);

    final currencyFromApi = _asStr(json['currency']).trim();
    final currency = currencyFromApi.isEmpty ? r'$' : currencyFromApi;

    String? shopName;
    final shop = json['shop'];
    if (shop is Map) {
      final s = _asStr(shop['shop_name']).trim();
      shopName = s.isEmpty ? null : s;
    }

    return ProductModel(
      id: id,
      title: name,
      slug: slug,
      image: thumb,
      price: price,
      oldPrice: oldPrice,
      currency: currency,
      rating: rating,
      totalReviews: totalReviews,
      hasVariant: hasVariant,
      quantity: quantity,
      unit: unit,
      shopName: shopName,
    );
  }
}

class CartUiProduct {
  final int id;
  final String title;
  final String imageUrl;
  final double rating;
  final double price;

  CartUiProduct({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.price,
  });

  @override
  String toString() =>
      'CartUiProduct(id: $id, title: $title, price: $price, img: $imageUrl)';
}
