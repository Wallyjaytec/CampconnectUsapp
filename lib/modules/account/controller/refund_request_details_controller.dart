import 'package:get/get.dart';

import '../../../data/repositories/refund_repository.dart';
import '../model/refund_request_details_model.dart';

class RefundRequestDetailsController extends GetxController {
  final RefundRepository _repo;

  RefundRequestDetailsController({RefundRepository? repository})
    : _repo = repository ?? RefundRepository();

  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final Rxn<RefundRequestDetailsData> details = Rxn<RefundRequestDetailsData>();

  final RxBool trackingExpanded = false.obs;

  Future<void> load(int id) async {
    error.value = null;
    isLoading.value = true;
    try {
      final res = await _repo.fetchRefundRequestDetails(id: id);
      details.value = res.data;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNow(int id) => load(id);

  int currentStepByLabel(String returnStatus, String paymentStatus) {
    final rs = returnStatus.toLowerCase().trim();
    final ps = paymentStatus.toLowerCase().trim();

    if (ps == 'refunded') {
      return 4;
    }

    if (rs == 'return approved' || rs == 'approved') {
      return 3;
    }
    if (rs == 'product received') {
      return 2;
    }
    if (rs == 'processing') {
      return 2;
    }
    return 1;
  }

  void toggleTracking() => trackingExpanded.toggle();
}
