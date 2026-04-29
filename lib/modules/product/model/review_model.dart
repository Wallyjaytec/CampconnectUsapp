import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';

class ProductReview {
  final int id;
  final String review;
  final double rating;
  final ReviewCustomer customer;
  final List<String> images;
  final String? variant;
  final DateTime? time;

  ProductReview({
    required this.id,
    required this.review,
    required this.rating,
    required this.customer,
    required this.images,
    required this.variant,
    required this.time,
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

  static DateTime? _parseTime(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return DateFormat('dd MMM yyyy hh:mm:ss a').parse(t);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return <String, dynamic>{};
  }

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] is List)
        ? (json['images'] as List)
              .map((e) => AppConfig.assetUrl(_s(e)))
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    return ProductReview(
      id: _i(json['id']),
      review: _s(json['review']),
      rating: _d(json['rating']),
      customer: ReviewCustomer.fromJson(_asMap(json['customer'])),
      images: imgs,
      variant: _s(json['variant']).isEmpty ? null : _s(json['variant']),
      time: _parseTime(_s(json['time'])),
    );
  }
}

class ReviewCustomer {
  final String name;
  final String avatarUrl;
  final int verified;

  ReviewCustomer({
    required this.name,
    required this.avatarUrl,
    required this.verified,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static int _i(dynamic v) {
    if (v is int) return v;
    return int.tryParse(_s(v)) ?? 0;
  }

  factory ReviewCustomer.fromJson(Map<String, dynamic> json) {
    return ReviewCustomer(
      name: _s(json['name']),
      avatarUrl: AppConfig.assetUrl(_s(json['image'])),
      verified: _i(json['valified']),
    );
  }
}

class ProductReviewsPage {
  final List<ProductReview> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ProductReviewsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  static int _i(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return <String, dynamic>{};
  }

  factory ProductReviewsPage.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] is List) ? (json['data'] as List) : const [];
    final items = dataList
        .whereType<Map>()
        .map((e) => ProductReview.fromJson(_asMap(e)))
        .toList();

    final meta = _asMap(json['meta']);

    return ProductReviewsPage(
      items: items,
      currentPage: _i(meta['current_page']),
      lastPage: _i(meta['last_page']),
      perPage: _i(meta['per_page']),
      total: _i(meta['total']),
    );
  }
}
