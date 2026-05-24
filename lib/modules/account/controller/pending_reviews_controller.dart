import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/my_order_repository.dart';
import '../model/my_order_details_model.dart';

class PendingReviewsController extends GetxController {
  PendingReviewsController({OrderRepository? repository})
      : _repo = repository ?? OrderRepository(api: ApiService());

  final OrderRepository _repo;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<OrderProductItem> products = <OrderProductItem>[].obs;
  final Map<int, int> productOrderMap = {};

  @override
  void onInit() {
    super.onInit();
    loadPendingReviews();
  }

  Future<void> loadPendingReviews() async {
    isLoading.value = true;
    error.value = '';

    try {
      final orderResponse = await _repo.fetchOrders(page: 1, perPage: 100);

      final List<OrderProductItem> deliveredProducts = [];

      for (final order in orderResponse.data) {
        try {
          final detailsResponse =
              await _repo.fetchOrderDetails(orderId: order.id);
          final orderData = detailsResponse.data;

          for (final product in orderData.products) {
            if (product.deliveryStatus == '1') {
              deliveredProducts.add(product);
              productOrderMap[product.productId] = orderData.id;
            }
          }
        } catch (_) {}
      }

      products.assignAll(deliveredProducts);
    } catch (e) {
      error.value = 'Failed to load reviews'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  int getOrderIdForProduct(int productId) {
    return productOrderMap[productId] ?? 0;
  }

  void removeProduct(int productId) {
    products.removeWhere((p) => p.productId == productId);
  }
}
