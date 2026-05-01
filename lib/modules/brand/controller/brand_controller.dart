import 'package:get/get.dart';
import 'package:kartly_e_commerce/data/repositories/brand_repository.dart';
import 'package:kartly_e_commerce/modules/product/model/brand_model.dart';

class BrandController extends GetxController {
  final BrandRepository _repo = BrandRepository();

  final RxList<Brand> brands = <Brand>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await _repo.fetchAll();
      brands.assignAll(data);
      if (brands.isEmpty) error.value = 'No brands found'.tr;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      brands.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
