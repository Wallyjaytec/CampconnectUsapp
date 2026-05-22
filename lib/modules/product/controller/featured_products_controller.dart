import 'package:get/get.dart';
import '../../../core/controllers/currency_controller.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../model/product_model.dart';

class FeaturedProductsController extends GetxController {
  final ProductRepository _repo = ProductRepository(ApiService());

  final RxBool isLoading = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFeatured();
    
    ever(Get.find<CurrencyController>().selectedCurrency, (_) {
      products.refresh();
    });
  }

  Future<void> loadFeatured() async {
    try {
      isLoading.value = true;
      final page = await _repo.fetchFeaturedPaged(page: 1, perPage: 8);
      products.assignAll(page.items);
    } catch (e) {
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
