import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../model/product_model.dart';

class DiscountSalesController extends GetxController {
  final ProductRepository _repo = ProductRepository(ApiService());

  final RxBool isLoading = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDiscountProducts();
  }

  Future<void> loadDiscountProducts() async {
    try {
      isLoading.value = true;
      final page = await _repo.fetchPaged(page: 1, perPage: 10, sorting: 'popular');
      products.assignAll(page.items.where((p) => p.oldPrice != null && p.oldPrice! > p.price).toList());
    } catch (e) {
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
