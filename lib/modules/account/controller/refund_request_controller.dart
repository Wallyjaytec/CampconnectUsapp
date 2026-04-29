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

  final int _perPage = 10;
  int _page = 1;
  int _lastPage = 1;
  bool get canLoadMore => _page < _lastPage;

  @override
  void onInit() {
    super.onInit();
    fetchFirstPage();
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
