import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/refund_repository.dart';
import '../model/refund_request_model.dart';

class RefundRequestController extends GetxController {
  RefundRequestController({RefundRepository? repository})
    : _repo = repository ?? RefundRepository();

  final RefundRepository _repo;

  final RxList<RefundRequest> items = <RefundRequest>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  final RxString statusFilter = 'all'.obs;
  final RxString dateFrom = ''.obs;
  final RxString dateTo = ''.obs;
  final RxString searchKey = ''.obs;

  final int _perPage = 10;
  int _page = 1;
  int _lastPage = 1;
  bool get canLoadMore => _page < _lastPage;

  List<RefundRequest> get filteredItems {
    List<RefundRequest> result = items.toList();
    final filter = statusFilter.value;
    
    if (searchKey.value.isNotEmpty) {
      result = result.where((r) => r.refundCode.toLowerCase().contains(searchKey.value.toLowerCase())).toList();
    }
    
    if (filter == 'pending payment' || filter == 'approved refund') {
      result = result.where((r) => r.paymentStatusLabel.toLowerCase() == filter).toList();
    } else if (filter != 'all') {
      result = result.where((r) => r.returnStatusLabel.toLowerCase() == filter).toList();
    }
    
    if (dateFrom.value.isNotEmpty && dateTo.value.isNotEmpty) {
      try {
        final from = DateTime.parse(dateFrom.value);
        final to = DateTime.parse(dateTo.value).add(const Duration(days: 1));
        result = result.where((r) {
          try {
            final returnDate = DateTime.parse(r.returnDate);
            return returnDate.isAfter(from.subtract(const Duration(days: 1))) && returnDate.isBefore(to);
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
    fetchFirstPage();
  }

  void setStatusFilter(String status) {
    dateFrom.value = '';
    dateTo.value = '';
    if (statusFilter.value == status) {
      statusFilter.value = 'all';
    } else {
      statusFilter.value = status;
    }
    update();
  }

  void setDateRange(String from, String to) {
    statusFilter.value = 'all';
    if (dateFrom.value == from && dateTo.value == to) {
      dateFrom.value = '';
      dateTo.value = '';
    } else {
      dateFrom.value = from;
      dateTo.value = to;
    }
    update();
  }

  void setSearchKey(String key) {
    searchKey.value = key;
    update();
  }

  void clearFilters() {
    statusFilter.value = 'all';
    dateFrom.value = '';
    dateTo.value = '';
    searchKey.value = '';
    update();
  }

  Future<void> fetchFirstPage() async {
    error.value = '';
    isLoading.value = true;
    _page = 1;
    try {
      final res = await _repo.fetchRefundRequests(
        page: _page,
        perPage: _perPage,
      );
      items.assignAll(res.data);
      _lastPage = res.lastPage;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() async {
    isRefreshing.value = true;
    try {
      await fetchFirstPage();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore || isLoading.value) return;
    isLoading.value = true;
    try {
      _page += 1;
      final res = await _repo.fetchRefundRequests(
        page: _page,
        perPage: _perPage,
      );
      items.addAll(res.data);
      _lastPage = res.lastPage;
    } catch (e) {
      _page = (_page > 1) ? _page - 1 : 1;
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyRefundCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Copied'.tr,
      'Refund ID copied to clipboard'.tr,
      backgroundColor: AppColors.primaryColor,
      snackPosition: SnackPosition.TOP,
      colorText: AppColors.whiteColor,
    );
  }

  void onTapItem(RefundRequest r) {
    Get.toNamed(AppRoutes.refundRequestDetailsView, arguments: r.id);
  }
}
