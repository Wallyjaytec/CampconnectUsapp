import 'package:get/get.dart';

import '../../../core/controllers/currency_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../model/product_model.dart';

class TopSalesController extends GetxController {
  TopSalesController({ProductRepository? repository})
    : repo = repository ?? ProductRepository(ApiService());

  final ProductRepository repo;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<ProductModel> items = <ProductModel>[].obs;

  int? categoryId;

  @override
  void onInit() {
    super.onInit();
    fetchTopSales();
    
    ever(Get.find<CurrencyController>().selectedCurrency, (_) {
      items.refresh();
    });
  }

  @override
  Future<void> refresh() async {
    items.clear();
    error.value = '';
    isLoading.value = true;

    await fetchTopSales();
  }

  Future<void> retry() => fetchTopSales();

  void openViewAll() {
    Get.toNamed(
      AppRoutes.topSaleProductView,
      arguments: <String, dynamic>{
        'mode': 'popular',
        'sorting': 'popular',
        'title': 'Top Sales',
        if (categoryId != null && categoryId! > 0) 'categoryId': categoryId,
      },
    );
  }

  Future<void> fetchTopSales() async {
    try {
      isLoading.value = true;
      error.value = '';

      PaginatedProducts page;

      try {
        page = await repo.fetchPaged(
          page: 1,
          perPage: 4,
          sorting: 'popular',
          categoryId: (categoryId != null && categoryId! > 0)
              ? categoryId
              : null,
        );
      } catch (_) {
        final int idToSend = (categoryId != null && categoryId! > 0)
            ? categoryId!
            : 0;

        page = await repo.fetchByCategoryPaged(
          categoryIdToSend: idToSend,
          page: 1,
          perPage: 4,
          sorting: 'popular',
        );
      }

      items.assignAll(page.items);
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  String formatPrice(double value) {
    String symbol = '\$';
    try {
      final svc = Get.find<CurrencyService>();
      symbol = (svc.current?.symbol ?? '\$').trim();
    } catch (_) {}
    return '$symbol${value.toStringAsFixed(2)}';
  }
}
