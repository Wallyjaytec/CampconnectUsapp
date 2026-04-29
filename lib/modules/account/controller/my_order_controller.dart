import 'package:get/get.dart';

import '../../../data/repositories/my_order_repository.dart';
import '../model/my_order_model.dart';

class OrderController extends GetxController {
  OrderController({OrderRepository? repository})
    : _repo = repository ?? OrderRepository();

  final OrderRepository _repo;

  final RxList<OrderItem> orders = <OrderItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();

  final RxString searchKey = ''.obs;

  int _page = 1;
  final int _perPage = 10;
  int _lastPage = 1;

  bool get hasMore => _page < _lastPage;

  @override
  void onInit() {
    super.onInit();
    initLoad();
  }

  Future<void> initLoad() async {
    if (isLoading.value) return;
    _page = 1;
    orders.clear();
    error.value = null;
    isLoading.value = true;

    try {
      final res = await _repo.fetchOrders(
        page: _page,
        perPage: _perPage,
        searchKey: searchKey.value.isEmpty ? null : searchKey.value,
      );
      orders.addAll(res.data);
      _lastPage = res.meta?.lastPage ?? 1;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() async {
    await initLoad();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    error.value = null;

    try {
      _page += 1;
      final res = await _repo.fetchOrders(
        page: _page,
        perPage: _perPage,
        searchKey: searchKey.value.isEmpty ? null : searchKey.value,
      );
      orders.addAll(res.data);
      _lastPage = res.meta?.lastPage ?? _lastPage;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      _page -= 1;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> searchOrders(String query) async {
    searchKey.value = query;
    await initLoad();
  }
}
