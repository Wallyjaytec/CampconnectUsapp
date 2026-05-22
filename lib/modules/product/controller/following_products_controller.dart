import 'package:get/get.dart';
import '../../../core/controllers/currency_controller.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/seller_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../model/product_model.dart';

class FollowingProductsController extends GetxController {
  final SellerRepository _sellerRepo;
  final ProductRepository _productRepo;

  FollowingProductsController() 
    : _sellerRepo = SellerRepository(),
      _productRepo = ProductRepository(ApiService());

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxBool hasMore = true.obs;

  int _page = 1;
  static const int _perPage = 10;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
    
    ever(Get.find<CurrencyController>().selectedRx, (_) {
      products.refresh();
    });
  }

  Future<void> loadInitial() async {
    try {
      isLoading.value = true;
      error.value = '';
      _page = 1;

      final res = await _sellerRepo.fetchFollowedSellersProducts(page: _page, perPage: _perPage);
      
      final data = res['data'] as List? ?? [];
      products.assignAll(data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductModel.fromJson(e))
          .toList());

      hasMore.value = products.length >= _perPage;
    } catch (e) {
      error.value = 'Failed to load products';
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      _page++;

      final res = await _sellerRepo.fetchFollowedSellersProducts(page: _page, perPage: _perPage);
      
      final data = res['data'] as List? ?? [];
      final newProducts = data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductModel.fromJson(e))
          .toList();

      products.addAll(newProducts);
      hasMore.value = newProducts.length >= _perPage;
    } catch (e) {
      _page--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}
