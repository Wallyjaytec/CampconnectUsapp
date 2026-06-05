import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';

import '../../../data/repositories/search_repository.dart';
import '../model/search_model.dart';

class SearchResultsController extends GetxController {
  late final SearchRepository repo;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final errorText = ''.obs;

  int _page = 1;
  final int _perPage = 20;
  String _currentQuery = '';

  final Rx<SearchSuggestionsResponse?> suggestions =
      Rx<SearchSuggestionsResponse?>(null);
  final isSuggesting = false.obs;

  @override
  void onInit() {
    super.onInit();
    repo = SearchRepository(api: ApiService());
  }

  Future<void> runSearch(String query) async {
    _currentQuery = query.trim();
    _page = 1;
    products.clear();
    errorText.value = '';
    isLoading.value = true;
    try {
      final res = await repo.searchProducts(
        page: _page,
        perPage: _perPage,
        searchKey: _currentQuery,
      );
      products.assignAll(res.data.reversed.toList());
      hasMore.value = (res.meta.lastPage == null)
          ? false
          : (_page < (res.meta.lastPage!));
    } catch (e) {
      errorText.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    errorText.value = '';
    try {
      _page += 1;
      final res = await repo.searchProducts(
        page: _page,
        perPage: _perPage,
        searchKey: _currentQuery,
      );
      products.addAll(res.data.reversed.toList());
      hasMore.value = (res.meta.lastPage == null)
          ? false
          : (_page < (res.meta.lastPage!));
    } catch (e) {
      _page -= 1;
      errorText.value = 'Something went wrong'.tr;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchSuggestions(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      suggestions.value = null;
      return;
    }
    isSuggesting.value = true;
    try {
      suggestions.value = await repo.getSuggestions(q);
    } catch (_) {
    } finally {
      isSuggesting.value = false;
    }
  }
}
