import 'package:get/get.dart';

import '../../../core/services/currency_service.dart';
import '../../../core/services/widget_data_service.dart';
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
  final RxString deliveryFilter = 'all'.obs;
  final RxString dateFrom = ''.obs;
  final RxString dateTo = ''.obs;

  int _page = 1;
  final int _perPage = 10;
  int _lastPage = 1;

  bool get hasMore => _page < _lastPage;

  List<OrderItem> get filteredOrders {
    List<OrderItem> result = orders.toList();
    final filter = deliveryFilter.value;
    
    if (filter == 'paid') {
      result = result.where((o) => o.paymentStatus == '1').toList();
    } else if (filter == 'due') {
      result = result.where((o) => o.paymentStatus == '2').toList();
    } else if (filter != 'all') {
      result = result.where((o) => o.deliveryStatus == filter).toList();
    }
    
    if (dateFrom.value.isNotEmpty && dateTo.value.isNotEmpty) {
      try {
        final from = DateTime.parse(dateFrom.value);
        final to = DateTime.parse(dateTo.value).add(const Duration(days: 1));
        result = result.where((o) {
          try {
            final orderDate = DateTime.parse(o.orderDate);
            return orderDate.isAfter(from.subtract(const Duration(days: 1))) && orderDate.isBefore(to);
          } catch (_) {
            return true;
          }
        }).toList();
      } catch (_) {}
    }
    
    return result;
  }

  @override
  void onInit() {
    super.onInit();
    initLoad();
  }

  void setDeliveryFilter(String status) {
    dateFrom.value = '';
    dateTo.value = '';
    if (deliveryFilter.value == status) {
      deliveryFilter.value = 'all';
    } else {
      deliveryFilter.value = status;
    }
    update();
    initLoad();
  }

  void setDateRange(String from, String to) {
    deliveryFilter.value = 'all';
    if (dateFrom.value == from && dateTo.value == to) {
      dateFrom.value = '';
      dateTo.value = '';
    } else {
      dateFrom.value = from;
      dateTo.value = to;
    }
    update();
    initLoad();
  }

  void clearFilters() {
    deliveryFilter.value = 'all';
    dateFrom.value = '';
    dateTo.value = '';
    searchKey.value = '';
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
        dateFrom: dateFrom.value.isEmpty ? null : dateFrom.value,
        dateTo: dateTo.value.isEmpty ? null : dateTo.value,
      );
      orders.addAll(res.data);
      _lastPage = res.meta?.lastPage ?? 1;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
      _syncWidget();
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
        dateFrom: dateFrom.value.isEmpty ? null : dateFrom.value,
        dateTo: dateTo.value.isEmpty ? null : dateTo.value,
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

  void _syncWidget() {
    final latest = orders.isNotEmpty ? orders.first : null;
    if (latest != null) {
      final currency = Get.find<CurrencyService>();
      WidgetDataService.updateWidgetData(
        cartItems: null,
        cartTotal: null,
        currencySymbol: currency.current?.symbol ?? '₦',
        latestOrderId: '${latest.orderCode}',
        latestOrderAmount: '${currency.current?.symbol ?? '₦'}${latest.totalPayableAmount}',
        latestOrderProduct: _mapStatusText(latest.deliveryStatus),
      );
    }
  }

  String _mapStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': case '1': return 'Pending';
      case 'confirmed': case '2': return 'Confirmed';
      case 'processing': case '3': return 'Processing';
      case 'picked_up': case '4': return 'Picked Up';
      case 'on_the_way': case '5': return 'On the Way';
      case 'delivered': case '6': return 'Delivered';
      default: return status;
    }
  }
}
