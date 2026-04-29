import '../../../core/config/app_config.dart';
import '../../product/model/product_model.dart';

class RelatedProduct {
  final int id;
  final String name;
  final String slug;
  final String imageUrl;

  final double price;
  final double? basePrice;

  double? get oldPrice =>
      (basePrice != null && basePrice! > price) ? basePrice : null;

  final int totalReviews;
  final double rating;
  final bool hasVariant;

  RelatedProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.price,
    required this.basePrice,
    required this.totalReviews,
    required this.rating,
    required this.hasVariant,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static int _i(dynamic v) {
    if (v is int) return v;
    return int.tryParse(_s(v)) ?? 0;
  }

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(_s(v)) ?? 0.0;
  }

  static double? _dn(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = _s(v).trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return double.tryParse(s);
  }

  factory RelatedProduct.fromJson(Map<String, dynamic> json) {
    final thumb = _s(json['thumbnail_image']);
    final hasVar = _i(json['has_variant']);
    return RelatedProduct(
      id: _i(json['id']),
      name: _s(json['name']),
      slug: _s(json['slug']),
      imageUrl: AppConfig.assetUrl(thumb),
      price: _d(json['price']),
      basePrice: _dn(json['base_price']),
      totalReviews: _i(json['total_reviews']),
      rating: _d(json['avg_rating']),
      hasVariant: hasVar == 1 || hasVar == 2,
    );
  }
}

extension RelatedProductX on RelatedProduct {
  ProductModel asProductModel() {
    final int pid = (id);
    final String nm = (name).trim();
    final String sl = (slug).trim();
    final String imgUrl = (imageUrl).trim();

    final double p = (price).toDouble();
    final double op = (oldPrice ?? 0).toDouble();
    final double? opFinal = op > p ? op : null;

    final double r = ((rating).toDouble()).clamp(0.0, 5.0);

    return ProductModel(
      id: pid,
      title: nm.isNotEmpty ? nm : sl,
      slug: sl,
      image: imgUrl,
      price: p,
      oldPrice: opFinal,
      currency: r'$',
      rating: r,
      totalReviews: 0,
      hasVariant: false,
      quantity: 0,
      unit: '',
      shopName: null,
    );
  }
}
