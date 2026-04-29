import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/compare_repository.dart';
import 'package:kartly_e_commerce/data/repositories/search_repository.dart';

import '../../product/model/product_model.dart' as pm;
import '../../search/model/search_model.dart' as search;
import '../model/compare_model.dart';

class CompareController extends GetxController {
  CompareController(this._compareRepo, ApiService api)
    : _searchRepo = SearchRepository(api: api);

  final CompareRepository _compareRepo;
  final SearchRepository _searchRepo;

  final box = GetStorage();
  static const _kCompareIds = 'compare_ids';

  var compareList = <CompareItemModel>[].obs;
  final isLoadingTable = false.obs;

  final suggestions = <int, List<search.ProductModel>>{}.obs;
  final isSuggestLoading = <int, bool>{}.obs;

  final _debouncers = <int, Timer>{};
  Timer? _persistDebounce;

  final pickedId0 = RxnInt();
  final pickedId1 = RxnInt();

  @override
  void onInit() {
    super.onInit();
    _restoreFromStorage();
  }

  @override
  void onClose() {
    for (final t in _debouncers.values) {
      t.cancel();
    }
    _persistDebounce?.cancel();
    super.onClose();
  }

  Future<void> addToCompareByProduct(pm.ProductModel product) async {
    await addToCompareByIds([product.id]);
  }

  Future<void> addToCompareByIds(List<int> ids) async {
    final currentIds = compareList.map((e) => e.id).toSet();
    final uniqueNew = ids.where((id) => !currentIds.contains(id)).toList();
    if (uniqueNew.isEmpty) return;

    final incoming = await _compareRepo.fetchCompareItems(uniqueNew);
    if (incoming.isEmpty) return;

    compareList.addAll(incoming);
    compareList.refresh();
    _persistIdsDebounced();
  }

  Future<void> loadCompareByIds(List<int> ids) async {
    isLoadingTable.value = true;
    try {
      if (ids.isEmpty) {
        compareList.clear();
      } else {
        final items = await _compareRepo.fetchCompareItems(ids);
        compareList.assignAll(items);
      }
    } finally {
      isLoadingTable.value = false;
      _persistIdsDebounced();
    }
  }

  void removeFromCompareByIndex(int index) {
    if (index >= 0 && index < compareList.length) {
      compareList.removeAt(index);
      suggestions.remove(index);
      isSuggestLoading.remove(index);
      compareList.refresh();
      _persistIdsDebounced();
    }
  }

  void removeFromCompare(CompareItemModel product) {
    compareList.removeWhere((e) => e.id == product.id);
    compareList.refresh();
    _persistIdsDebounced();
  }

  Future<void> replaceAt(int columnIndex, int productId) async {
    final items = await _compareRepo.fetchCompareItems([productId]);
    if (items.isEmpty) return;
    if (columnIndex < 0 || columnIndex >= compareList.length) return;

    compareList[columnIndex] = items.first;
    compareList.refresh();

    suggestions[columnIndex] = const [];
    suggestions.refresh();

    _persistIdsDebounced();
  }

  Future<void> refreshAll() async {
    final ids = _currentIds();
    if (ids.isEmpty) return;
    isLoadingTable.value = true;
    try {
      final items = await _compareRepo.fetchCompareItems(ids);
      compareList.assignAll(items);
    } finally {
      isLoadingTable.value = false;
    }
  }

  void selectSuggestionFor(int slot, search.ProductModel item) {
    if (slot == 0) {
      pickedId0.value = item.id;
    } else {
      pickedId1.value = item.id;
    }
    suggestions[slot] = const [];
    suggestions.refresh();
  }

  void clearPick(int slot) {
    if (slot == 0) {
      pickedId0.value = null;
    } else {
      pickedId1.value = null;
    }
  }

  Future<void> comparePicked() async {
    final id0 = pickedId0.value;
    final id1 = pickedId1.value;
    if (id0 == null || id1 == null) return;
    if (id0 == id1) {
      Get.snackbar(
        'Compare'.tr,
        'The same product cannot be given twice'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }
    await loadCompareByIds([id0, id1]);
  }

  void querySuggestions(int columnIndex, String q) {
    _debouncers[columnIndex]?.cancel();
    final query = q.trim();

    if (query.isEmpty) {
      isSuggestLoading[columnIndex] = false;
      suggestions[columnIndex] = const [];
      isSuggestLoading.refresh();
      suggestions.refresh();
      return;
    }

    isSuggestLoading[columnIndex] = true;
    suggestions[columnIndex] = const [];
    isSuggestLoading.refresh();
    suggestions.refresh();

    _debouncers[columnIndex] = Timer(
      const Duration(milliseconds: 280),
      () async {
        try {
          final search.SearchSuggestionsResponse res = await _searchRepo
              .getSuggestions(query)
              .timeout(const Duration(seconds: 10));
          suggestions[columnIndex] = res.products;
        } catch (_) {
          suggestions[columnIndex] = const [];
        } finally {
          isSuggestLoading[columnIndex] = false;
          isSuggestLoading.refresh();
          suggestions.refresh();
        }
      },
    );
  }

  List<int> _currentIds() => compareList.map((e) => e.id).toList();

  void _persistIdsDebounced() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 250), () {
      try {
        final ids = _currentIds();
        box.write(_kCompareIds, ids);
      } catch (_) {}
    });
  }

  Future<void> _restoreFromStorage() async {
    try {
      final raw = box.read<List<dynamic>>(_kCompareIds);
      final ids = (raw ?? const [])
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
      if (ids.isNotEmpty) {
        await loadCompareByIds(ids);
      }
    } catch (_) {}
  }
}
