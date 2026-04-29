import 'package:get/get.dart';

import '../../../data/repositories/collection_repository.dart';
import '../model/collection_model.dart';

class CollectionController extends GetxController {
  final CollectionRepository repo;

  CollectionController({CollectionRepository? repository})
    : repo = repository ?? CollectionRepository();

  final RxString title = ''.obs;
  final RxString error = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  final RxList<CollectionGridItem> items = <CollectionGridItem>[].obs;
  final RxString headerImageUrl = ''.obs;

  int _page = 1;
  int _lastPage = 1;
  int _perPage = 10;
  bool get hasMore => _page < _lastPage;

  int? _collectionId;

  Future<void> open({
    required int collectionId,
    String? titleOverride,
    int perPage = 10,
  }) async {
    _collectionId = collectionId;
    _perPage = perPage;
    if (titleOverride != null && titleOverride.isNotEmpty) {
      title.value = titleOverride;
    }

    await _loadFirstPageWithHeader();
  }

  Future<void> _loadFirstPageWithHeader() async {
    if (_collectionId == null) return;
    isLoading.value = true;
    error.value = '';
    items.clear();
    headerImageUrl.value = '';

    try {
      final details = await repo.fetchDetails(id: _collectionId!);
      title.value = details.name.isNotEmpty ? details.name : title.value;
      headerImageUrl.value = details.image;

      _page = 1;
      final res = await repo.fetchProducts(
        id: _collectionId!,
        page: _page,
        perPage: _perPage,
      );

      _lastPage = res.lastPage;
      final mapped = res.data.map(CollectionGridItem.fromProduct).toList();
      items.assignAll(mapped);
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFirstPage() async {
    await _loadFirstPageWithHeader();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore || _collectionId == null) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final res = await repo.fetchProducts(
        id: _collectionId!,
        page: next,
        perPage: _perPage,
      );
      _page = next;
      _lastPage = res.lastPage;
      items.addAll(res.data.map(CollectionGridItem.fromProduct));
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }
}
