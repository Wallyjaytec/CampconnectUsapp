class FlashDealSummary {
  final int id;
  final String title;
  final String permalink;
  final String? startDate;
  final String endDate;
  final String? backgroundColor;
  final String? textColor;
  final String? backgroundImage;

  FlashDealSummary({
    required this.id,
    required this.title,
    required this.permalink,
    required this.endDate,
    this.startDate,
    this.backgroundColor,
    this.textColor,
    this.backgroundImage,
  });

  factory FlashDealSummary.fromJson(Map<String, dynamic> j) {
    return FlashDealSummary(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      permalink: (j['permalink'] ?? '').toString(),
      endDate: (j['end_date'] ?? '').toString(),
      startDate: j['start_date']?.toString(),
      backgroundColor: j['background_color']?.toString(),
      textColor: j['text_color']?.toString(),
      backgroundImage: j['background_image']?.toString(),
    );
  }
}

class FlashDealDetails {
  final int id;
  final String title;
  final String permalink;
  final String endDate;
  final String? textColor;
  final String? backgroundImage;

  FlashDealDetails({
    required this.id,
    required this.title,
    required this.permalink,
    required this.endDate,
    this.textColor,
    this.backgroundImage,
  });

  factory FlashDealDetails.fromJson(Map<String, dynamic> j) {
    return FlashDealDetails(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      permalink: (j['permalink'] ?? '').toString(),
      endDate: (j['end_date'] ?? '').toString(),
      textColor: j['text_color']?.toString(),
      backgroundImage: j['background_image']?.toString(),
    );
  }
}

class FDProduct {
  final int id;
  final String name;
  final String slug;
  final String image;
  final double price;
  final double basePrice;
  final double rating;

  FDProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    required this.price,
    required this.basePrice,
    required this.rating,
  });

  factory FDProduct.fromJson(Map<String, dynamic> j) {
    double toD(v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0.0;
    return FDProduct(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      image: (j['thumbnail_image'] ?? '').toString(),
      price: toD(j['price']),
      basePrice: toD(j['base_price']),
      rating: toD(j['avg_rating']),
    );
  }
}

class FDPaginated {
  final List<FDProduct> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
  int get nextPage => hasMore ? currentPage + 1 : currentPage;

  FDPaginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory FDPaginated.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => FDProduct.fromJson(e.cast<String, dynamic>()))
        .toList();
    final meta = (j['meta'] as Map?) ?? const {};
    int toI(v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return FDPaginated(
      items: data,
      currentPage: toI(meta['current_page']),
      lastPage: toI(meta['last_page']),
      perPage: toI(meta['per_page']),
      total: toI(meta['total']),
    );
  }
}
