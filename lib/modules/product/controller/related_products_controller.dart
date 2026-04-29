import 'package:get/get.dart';

import '../../../data/repositories/related_products_repository.dart';
import '../model/related_product_model.dart';

class RelatedProductsController extends GetxController {
  RelatedProductsController(this._repo);
  final RelatedProductsRepository _repo;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final RxList<RelatedProduct> products = <RelatedProduct>[].obs;

  int? _loadedForProductId;

  Future<void> loadFor(int productId) async {
    if (_loadedForProductId == productId && products.isNotEmpty) {
      return;
    }
    _loadedForProductId = productId;

    try {
      isLoading.value = true;
      error.value = '';
      final list = await _repo.fetchRelated(productId: productId);
      products.assignAll(list);
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void ensureLoaded(int? productId) {
    if (productId == null || productId <= 0) return;
    loadFor(productId);
  }
}
