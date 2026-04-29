import 'package:get/get.dart';

import '../../../data/repositories/guest_checkout_repository.dart';
import '../../account/model/my_order_details_model.dart';

class GuestOrderSummaryController extends GetxController {
  GuestOrderSummaryController({GuestCheckoutRepository? repository})
    : _repo = repository ?? GuestCheckoutRepository();

  final GuestCheckoutRepository _repo;

  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final Rxn<OrderDetailsData> order = Rxn<OrderDetailsData>();

  Future<void> load(int orderId) async {
    await _fetch(orderId, showSpinner: true);
  }

  Future<void> refreshNow(int orderId) async {
    await _fetch(orderId, showSpinner: false);
  }

  Future<void> _fetch(int orderId, {required bool showSpinner}) async {
    if (showSpinner) isLoading.value = true;
    error.value = null;

    try {
      final data = await _repo.getGuestOrderDetails(
        orderCode: orderId.toString(),
      );
      order.value = data;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      if (showSpinner) isLoading.value = false;
    }
  }

  bool isItemCancelledEffective(OrderProductItem p) {
    final s = p.deliveryStatus.trim().toLowerCase();
    const cancelCodes = {'0', '-1', '4', 'cancel', 'cancelled', 'canceled'};
    return cancelCodes.contains(s);
  }
}
