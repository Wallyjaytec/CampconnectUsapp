import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/api_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../../product/model/product_model.dart';

class ForYouController extends GetxController {
  ForYouController();

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  final RxList<ProductModel> suggestions = <ProductModel>[].obs;

  static const _storeName = 'for_you_signals';
  final _box = GetStorage(_storeName);

  static const _kKeywordScore = 'keywordScore';
  static const _kTargetPrice = 'targetPrice';
  static const _kRecentViewed = 'recentViewed';
  static const _kViewCounts = 'viewCounts';

  final Map<String, int> _keywordScore = {};
  double? _targetPrice;
  final List<int> _recentViewed = [];
  final Map<int, int> _viewCounts = {};

  static const int _kPageSize = 10;

  bool _didAutoLoadRandom = false;
  int _randomPage = 1;
  int get nextRandomPage => _randomPage;

  @override
  Future<void> onInit() async {
    await _ensureStorage();
    _loadSignals();

    _autoLoadRandomOnce();

    super.onInit();
  }

  Future<void> _ensureStorage() async {
    if (!GetStorage().hasData(_storeName)) {
      await GetStorage.init(_storeName);
    }
  }

  void setCandidates(Iterable<ProductModel> items) {
    suggestions
      ..clear()
      ..addAll(items);

    isLoading.value = false;
  }

  void addCandidates(Iterable<ProductModel> more) {
    if (more.isEmpty) return;

    suggestions.addAll(more);
  }

  void logView(ProductModel p) {
    final id = _safeId(p);
    if (id == null) return;

    for (final w in _words(p.title)) {
      _keywordScore.update(w, (v) => v + 2, ifAbsent: () => 2);
    }

    _bumpTargetPrice(p.price);

    _viewCounts[id] = (_viewCounts[id] ?? 0) + 1;

    _recentViewed.remove(id);
    _recentViewed.insert(0, id);
    if (_recentViewed.length > 40) _recentViewed.removeLast();

    _persistSignals();
  }

  void logSearch(String q) {
    for (final w in _words(q)) {
      _keywordScore.update(w, (v) => v + 2, ifAbsent: () => 2);
    }
    _persistSignals();
  }

  int? _safeId(ProductModel p) {
    try {
      return p.id;
    } catch (_) {
      return null;
    }
  }

  Iterable<String> _words(String t) =>
      t.toLowerCase().split(RegExp(r'[^a-z0-9]+'));

  void _bumpTargetPrice(dynamic price) {
    final p = (price is num) ? price.toDouble() : 0.0;
    if (p <= 0) return;
    _targetPrice = _targetPrice == null ? p : (_targetPrice! * .8 + p * .2);
  }

  void _loadSignals() {
    try {
      final kw = _box.read(_kKeywordScore);
      final tp = _box.read(_kTargetPrice);
      final rv = _box.read(_kRecentViewed);
      final vc = _box.read(_kViewCounts);

      if (kw is String && kw.isNotEmpty) {
        final m = Map<String, dynamic>.from(jsonDecode(kw));
        _keywordScore
          ..clear()
          ..addAll(m.map((k, v) => MapEntry(k, v as int)));
      }

      if (tp is num) _targetPrice = tp.toDouble();

      if (rv is String && rv.isNotEmpty) {
        final raw = List<dynamic>.from(jsonDecode(rv));
        final parsed = raw
            .map((e) => int.tryParse(e.toString()) ?? -1)
            .where((e) => e >= 0)
            .toList();
        _recentViewed
          ..clear()
          ..addAll(parsed);
      }

      if (vc is String && vc.isNotEmpty) {
        final m = Map<String, dynamic>.from(jsonDecode(vc));
        _viewCounts
          ..clear()
          ..addAll(m.map((k, v) => MapEntry(int.parse(k), v as int)));
      }
    } catch (_) {}
  }

  void _persistSignals() {
    _box.write(_kKeywordScore, jsonEncode(_keywordScore));
    if (_targetPrice != null) _box.write(_kTargetPrice, _targetPrice);
    _box.write(_kRecentViewed, jsonEncode(_recentViewed));
    _box.write(
      _kViewCounts,
      jsonEncode(_viewCounts.map((k, v) => MapEntry('$k', v))),
    );
  }

  Future<void> _autoLoadRandomOnce() async {
    if (_didAutoLoadRandom) return;
    _didAutoLoadRandom = true;

    try {
      isLoading.value = true;
      error.value = '';

      final repo = ProductRepository(ApiService());
      const pageSize = _kPageSize;

      final pg = await repo.fetchRandomPaged(
        page: _randomPage,
        perPage: pageSize,
      );

      _randomPage = pg.nextPage;
      hasMore.value = pg.hasMore;

      setCandidates(pg.items);
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      suggestions.clear();
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreRandom() async {
    if (isLoadingMore.value) return;
    if (!hasMore.value) return;

    try {
      isLoadingMore.value = true;

      final repo = ProductRepository(ApiService());
      const pageSize = _kPageSize;

      final pg = await repo.fetchRandomPaged(
        page: _randomPage,
        perPage: pageSize,
      );

      _randomPage = pg.nextPage;
      hasMore.value = pg.hasMore;

      if (pg.items.isNotEmpty) {
        addCandidates(pg.items);
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  static ForYouController ensure() {
    if (Get.isRegistered<ForYouController>()) {
      return Get.find<ForYouController>();
    }
    return Get.put(ForYouController(), permanent: true);
  }

  Future<void> refreshRandom() async {
    suggestions.clear();
    error.value = '';
    hasMore.value = true;
    _randomPage = 1;
    _didAutoLoadRandom = false;

    isLoading.value = true;

    await _autoLoadRandomOnce();
  }
}
