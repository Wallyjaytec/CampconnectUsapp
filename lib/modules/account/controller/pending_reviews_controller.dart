import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/my_order_repository.dart';
import '../model/my_order_details_model.dart';

class PendingReviewsController extends GetxController {
  PendingReviewsController({OrderRepository? repository})
      : _repo = repository ?? OrderRepository(api: ApiService());

  final OrderRepository _repo;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingReviewed = false.obs;
  final RxString error = ''.obs;
  final RxList<OrderProductItem> products = <OrderProductItem>[].obs;
  final RxList<Map<String, dynamic>> reviewedProducts = <Map<String, dynamic>>[].obs;
  final Map<int, int> productOrderMap = {};
  final Map<int, String> productOrderCodeMap = {};
  final Set<int> _reviewedIds = {};

  @override
  void onInit() {
    super.onInit();
    loadPendingReviews();
    loadReviewedReviews();
  }

  Future<void> loadPendingReviews() async {
    isLoading.value = true;
    error.value = '';

    try {
      await _loadReviewedIds();

      final orderResponse = await _repo.fetchOrders(page: 1, perPage: 100);
      final List<OrderProductItem> deliveredProducts = [];
      final seenCombos = <String>{};

      for (final order in orderResponse.data) {
        try {
          final detailsResponse = await _repo.fetchOrderDetails(orderId: order.id);
          final orderData = detailsResponse.data;

          for (final product in orderData.products) {
            final comboKey = '${product.productId}_${orderData.id}';
            if (product.deliveryStatus == '1' 
                && !_reviewedIds.contains(product.productId)
                && !seenCombos.contains(comboKey)) {
              seenCombos.add(comboKey);
              deliveredProducts.add(product);
              productOrderMap[product.productId] = orderData.id;
              productOrderCodeMap[product.productId] = orderData.orderCode;
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

  Future<void> loadReviewedReviews() async {
    isLoadingReviewed.value = true;
    try {
      final data = await _repo.fetchMyReviews();
      reviewedProducts.assignAll(data);
    } catch (_) {
    } finally {
      isLoadingReviewed.value = false;
    }
  }

  Future<void> _loadReviewedIds() async {
    try {
      final ids = await _repo.fetchReviewedProductIds();
      _reviewedIds.clear();
      _reviewedIds.addAll(ids);
      
      final myReviews = await _repo.fetchMyReviews();
      for (final review in myReviews) {
        final productId = review['product_id'];
        if (productId is int) {
          _reviewedIds.add(productId);
        } else if (productId is String) {
          _reviewedIds.add(int.tryParse(productId) ?? 0);
        }
      }
    } catch (_) {}
  }

  int getOrderIdForProduct(int productId) {
    return productOrderMap[productId] ?? 0;
  }

  String getOrderCodeForProduct(int productId) {
    return productOrderCodeMap[productId] ?? '';
  }

  void removeProduct(int productId) async {
    final orderId = getOrderIdForProduct(productId);
    _reviewedIds.add(productId);
    products.removeWhere((p) => p.productId == productId);

    try {
      await _repo.markReviewedFromList(productId: productId, orderId: orderId);
    } catch (_) {}
  }
}
