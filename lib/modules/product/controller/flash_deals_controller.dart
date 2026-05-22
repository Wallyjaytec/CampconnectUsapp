import 'dart:async';

import 'package:get/get.dart';

import '../../../core/controllers/currency_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../data/repositories/flash_deal_repository.dart';
import '../model/flash_deal_models.dart';
import '../model/product_model.dart';

class FlashDealsController extends GetxController {
  FlashDealsController({FlashDealRepository? repo})
    : repository = repo ?? FlashDealRepository(ApiService());

  final FlashDealRepository repository;

  final RxList<FlashDealSummary> activeDeals = <FlashDealSummary>[].obs;
  final RxList<ProductModel> items = <ProductModel>[].obs;

  final Rx<FlashDealSummary?> sectionDeal = Rx<FlashDealSummary?>(null);
  final Rx<Duration> remaining = const Duration().obs;
  DateTime? _endsAt;
  Timer? _ticker;

  final RxList<FDProduct> sectionProducts = <FDProduct>[].obs;

  final Map<int, RxList<FDProduct>> _dealProducts = {};
  final Map<int, int> _currentPage = {};
  final Map<int, bool> _hasMore = {};
  final int perPage = 20;

  final RxBool isSectionLoading = false.obs;
  final RxString sectionError = ''.obs;

  final FavoritesService favService = FavoritesService();
  final RxSet<int> favIds = <int>{}.obs;
  bool isFav(int id) => favIds.contains(id);
  void toggleFav(int id) {
    favIds.contains(id) ? favIds.remove(id) : favIds.add(id);
    favService.write(favIds.toSet());
    favIds.refresh();
  }

  bool _isFuture(String iso) {
    try {
      return DateTime.parse(iso).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  List<FlashDealSummary> get visibleDeals =>
      activeDeals.where((d) => _isFuture(d.endDate)).toList();

  bool get hasActive => visibleDeals.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    favIds
      ..clear()
      ..addAll(favService.read());
    _loadForSection();
    
    ever(Get.find<CurrencyController>().selectedRx, (_) {
      sectionProducts.refresh();
      for (final list in _dealProducts.values) {
        list.refresh();
      }
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> _loadForSection() async {
    try {
      isSectionLoading.value = true;
      sectionError.value = '';
      sectionProducts.clear();
      sectionDeal.value = null;

      final list = await repository.fetchActiveDeals();

      final filtered = list.where((d) => _isFuture(d.endDate)).toList();
      activeDeals.assignAll(filtered);

      if (filtered.isEmpty) {
        _cancelTicker();
        return;
      }

      final first = filtered.first;
      sectionDeal.value = first;

      try {
        final d = await repository.fetchDealDetails(first.id);
        _startCountdown(d.endDate);
      } catch (_) {
        _startCountdown(first.endDate);
      }

      await _loadSectionProductsFor(first.id);
    } catch (e) {
      sectionError.value = 'Something went wrong'.tr;
      activeDeals.clear();
      sectionDeal.value = null;
      sectionProducts.clear();
      _cancelTicker();
    } finally {
      isSectionLoading.value = false;
    }
  }

  Future<void> _loadSectionProductsFor(int dealId) async {
    final page = await repository.fetchDealProducts(
      id: dealId,
      page: 1,
      perPage: 10,
    );
    sectionProducts.assignAll(page.items);
  }

  void _startCountdown(String endDateStr) {
    _cancelTicker();
    DateTime? end;
    try {
      end = DateTime.parse(endDateStr);
    } catch (_) {}
    _endsAt = end;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_endsAt == null) {
      remaining.value = Duration.zero;
      _ticker?.cancel();
      return;
    }
    final diff = _endsAt!.difference(DateTime.now());
    remaining.value = diff.isNegative ? Duration.zero : diff;

    if (diff.isNegative) {
      _ticker?.cancel();
      final expiredId = sectionDeal.value?.id;
      if (expiredId != null) onDealExpired(expiredId);
    }
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
    remaining.value = Duration.zero;
  }

  void openViewAll() {
    Get.toNamed(AppRoutes.flashDealsView);
  }

  RxList<FDProduct> productsFor(int dealId) {
    return _dealProducts.putIfAbsent(dealId, () => <FDProduct>[].obs);
  }

  bool hasMoreFor(int dealId) => _hasMore[dealId] ?? true;

  Future<void> loadFirstPageFor(int dealId) async {
    _currentPage[dealId] = 1;
    _hasMore[dealId] = true;
    productsFor(dealId).clear();

    final page = await repository.fetchDealProducts(
      id: dealId,
      page: 1,
      perPage: perPage,
    );
    productsFor(dealId).assignAll(page.items);
    _currentPage[dealId] = page.currentPage;
    _hasMore[dealId] = page.hasMore;
  }

  final RxMap<int, bool> _isLoadingMore = <int, bool>{}.obs;

  bool isLoadingMoreFor(int dealId) => _isLoadingMore[dealId] == true;

  Future<void> loadMoreFor(int dealId) async {
    if (isLoadingMoreFor(dealId)) return;

    _isLoadingMore[dealId] = true;
    try {} catch (_) {
    } finally {
      _isLoadingMore[dealId] = false;
    }
  }

  void openProduct(FDProduct p) {
    Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': p.slug});
  }

  void onDealExpired(int dealId) {
    activeDeals.removeWhere((d) => d.id == dealId);

    _dealProducts.remove(dealId);
    _currentPage.remove(dealId);
    _hasMore.remove(dealId);
    _isLoadingMore.remove(dealId);

    if (sectionDeal.value?.id == dealId) {
      sectionDeal.value = null;
      sectionProducts.clear();
      _cancelTicker();

      final next = visibleDeals.isNotEmpty ? visibleDeals.first : null;
      if (next != null) {
        sectionDeal.value = next;
        _startCountdown(next.endDate);
        _loadSectionProductsFor(next.id);
      }
    }
  }

  Future<void> refreshSection() async {
    sectionProducts.clear();
    sectionDeal.value = null;
    sectionError.value = '';
    isSectionLoading.value = true;

    await _loadForSection();
  }
}
