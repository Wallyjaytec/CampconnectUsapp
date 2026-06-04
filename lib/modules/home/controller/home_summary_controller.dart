import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/core/services/login_service.dart';
import 'package:kartly_e_commerce/data/repositories/my_order_repository.dart';
import 'package:kartly_e_commerce/data/repositories/refund_repository.dart';
import 'package:kartly_e_commerce/modules/account/model/my_order_model.dart';
import 'package:kartly_e_commerce/modules/account/model/refund_request_model.dart';

class HomeSummaryController extends GetxController {
  final Rx<OrderItem?> latestOrder = Rxn<OrderItem>();
  final Rx<RefundRequest?> latestRefund = Rxn<RefundRequest>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (LoginService().isLoggedIn()) {
      loadSummary();
    }
  }

  Future<void> loadSummary() async {
    isLoading.value = true;
    try {
      final orderRepo = OrderRepository();
      final orderRes = await orderRepo.fetchOrders(page: 1, perPage: 1);
      if (orderRes.data.isNotEmpty) {
        latestOrder.value = orderRes.data.first;
      }

      final refundRepo = RefundRepository();
      final refundRes = await refundRepo.fetchRefundRequests(page: 1, perPage: 1);
      if (refundRes.data.isNotEmpty) {
        latestRefund.value = refundRes.data.first;
      }
    } catch (_) {}
    isLoading.value = false;
  }
}
