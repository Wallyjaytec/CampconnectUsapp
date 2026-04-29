class ShopReviewsResponse {
  final List<ShopReviewItem> data;
  final ReviewsMeta meta;
  final bool success;
  final int status;

  ShopReviewsResponse({
    required this.data,
    required this.meta,
    required this.success,
    required this.status,
  });

  factory ShopReviewsResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List? ?? [])
        .map((e) => ShopReviewItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ShopReviewsResponse(
      data: list,
      meta: ReviewsMeta.fromJson(j['meta'] ?? const {}),
      success: j['success'] == true || '${j['success']}' == 'true',
      status: (j['status'] is num) ? (j['status'] as num).toInt() : 0,
    );
  }
}

class ReviewsMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ReviewsMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ReviewsMeta.fromJson(Map<String, dynamic> j) {
    return ReviewsMeta(
      currentPage: _asInt(j['current_page']),
      lastPage: _asInt(j['last_page']),
      perPage: _asInt(j['per_page']),
      total: _asInt(j['total']),
    );
  }
}

class ShopReviewItem {
  final int id;
  final String review;
  final double rating;
  final String time;
  final ReviewCustomer customer;
  final List<String> images;

  ShopReviewItem({
    required this.id,
    required this.review,
    required this.rating,
    required this.time,
    required this.customer,
    required this.images,
  });

  factory ShopReviewItem.fromJson(Map<String, dynamic> j) {
    final imgs =
        (j['images'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return ShopReviewItem(
      id: _asInt(j['id']),
      review: (j['review'] ?? '').toString(),
      rating: _asDouble(j['rating']),
      time: (j['time'] ?? '').toString(),
      customer: ReviewCustomer.fromJson(j['customer'] ?? const {}),
      images: imgs,
    );
  }
}

class ReviewCustomer {
  final String name;
  final String image;
  final int verified;

  ReviewCustomer({
    required this.name,
    required this.image,
    required this.verified,
  });

  factory ReviewCustomer.fromJson(Map<String, dynamic> j) {
    return ReviewCustomer(
      name: (j['name'] ?? '').toString(),
      image: (j['image'] ?? '').toString(),
      verified: _asInt(j['verified']),
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
