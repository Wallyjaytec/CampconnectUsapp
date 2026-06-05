import 'dart:async';

import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/config/app_config.dart';

import '../../../data/repositories/seller_repository.dart';
import '../model/shop_review_model.dart';

enum ReviewSort { recent, ratingHigh, ratingLow }

class ReviewVM {
  final String userName;
  final String avatarUrl;
  final int verified;
  final double rating;
  final DateTime dateTime;
  final String comment;
  final List<String> images;

  ReviewVM({
    required this.userName,
    required this.avatarUrl,
    required this.verified,
    required this.rating,
    required this.dateTime,
    required this.comment,
    required this.images,
  });
}

class SellerRatingsController extends GetxController {
  final String slug;
  final String? shopTitle;
  final SellerRepository repo;

  SellerRatingsController({
    required this.slug,
    this.shopTitle,
    SellerRepository? repository,
  }) : repo = repository ?? SellerRepository();

  final RxList<ShopReviewItem> _reviews = <ShopReviewItem>[].obs;
  List<ShopReviewItem> get rawReviews => _reviews;

  final RxBool isLoading = false.obs;
  final RxString loadError = ''.obs;

  final Rx<ReviewSort> reviewSort = ReviewSort.recent.obs;
  final RxInt page = 1.obs;
  final RxInt perPage = 10.obs;
  final RxBool hasMore = false.obs;

  final RxMap<int, int> counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0}.obs;
  final RxInt _totalFromMeta = 0.obs;

  int get total => counts.values.fold(0, (a, b) => a + b);
  String get totalReviewsText => _totalFromMeta.value.toString();

  double get average {
    final t = total;
    if (t == 0) return 0;
    double sum = 0;
    counts.forEach((stars, c) => sum += stars * c);
    return sum / t;
  }

  double percentFor(int stars) {
    final t = total;
    if (t == 0) return 0;
    return (counts[stars] ?? 0) / t;
  }

  String _sortKey(ReviewSort s) {
    switch (s) {
      case ReviewSort.recent:
        return 'DESC';
      case ReviewSort.ratingHigh:
        return 'RDESC';
      case ReviewSort.ratingLow:
        return 'RASC';
    }
  }

  final RxBool isSorting = false.obs;

  @override
  void onReady() {
    super.onReady();
    if (slug.isEmpty) {
      return;
    }
    _loadList(reset: true);

    _loadStatsAllPages();
  }

  Future<void> setReviewSort(ReviewSort s) async {
    if (reviewSort.value == s) return;
    reviewSort.value = s;
    isSorting.value = true;
    await _loadList(reset: true);
    isSorting.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;
    await _loadList(reset: false);
  }

  Future<void> _loadList({required bool reset}) async {
    try {
      isLoading.value = true;
      loadError.value = '';
      final int nextPage = reset ? 1 : (page.value + 1);

      final res = await repo.fetchShopReviews(
        slug: slug,
        page: nextPage,
        perPage: perPage.value,
        sorting: _sortKey(reviewSort.value),
      );

      _totalFromMeta.value = res.meta.total;
      hasMore.value = res.meta.currentPage < res.meta.lastPage;

      if (reset) {
        _reviews.assignAll(res.data);
        page.value = 1;
      } else {
        _reviews.addAll(res.data);
        page.value = nextPage;
      }
    } catch (e) {
      loadError.value = 'Something went wrong'.tr;
      if (reset) _reviews.clear();
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStatsAllPages() async {
    try {
      final first = await repo.fetchShopReviews(
        slug: slug,
        page: 1,
        perPage: 50,
        sorting: 'DESC',
      );
      _totalFromMeta.value = first.meta.total;

      final Map<int, int> c = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      void addBatch(List<ShopReviewItem> batch) {
        for (final it in batch) {
          final stars = it.rating.round().clamp(1, 5);
          c[stars] = (c[stars] ?? 0) + 1;
        }
      }

      addBatch(first.data);

      final last = first.meta.lastPage;
      if (last > 1) {
        for (int p = 2; p <= last; p++) {
          final res = await repo.fetchShopReviews(
            slug: slug,
            page: p,
            perPage: 50,
            sorting: 'DESC',
          );
          addBatch(res.data);
        }
      }

      counts
        ..clear()
        ..addAll({5: c[5]!, 4: c[4]!, 3: c[3]!, 2: c[2]!, 1: c[1]!});
    } catch (_) {}
  }

  List<ReviewVM> get reviewsForView {
    final base = _reviews.map((it) {
      final avatar = _fixAvatar(it.customer.image);
      return ReviewVM(
        userName: it.customer.name,
        avatarUrl: avatar,
        verified: it.customer.verified,
        rating: it.rating,
        dateTime: _parseTime(it.time),
        comment: it.review,
        images: it.images,
      );
    }).toList();

    switch (reviewSort.value) {
      case ReviewSort.recent:
        base.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case ReviewSort.ratingHigh:
        base.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSort.ratingLow:
        base.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
    return base;
  }

  String _fixAvatar(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return AppConfig.baseUrl + raw;
  }

  DateTime _parseTime(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.now();
    }
  }
}
