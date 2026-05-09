import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/product_model.dart';

class RecentlyViewedController extends GetxController {
  final box = GetStorage();
  static const String _key = 'recently_viewed_products';
  static const int maxProducts = 20;

  final RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
  }

  void loadFromStorage() {
    final raw = box.read<List>(_key) ?? [];
    final list = <ProductModel>[];
    for (final item in raw) {
      if (item is Map) {
        try {
          list.add(ProductModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }
    products.assignAll(list);
  }

  void addProduct(ProductModel product) {
    // Remove if already exists
    products.removeWhere((p) => p.id == product.id);
    // Add to front
    products.insert(0, product);
    // Keep only max
    if (products.length > maxProducts) {
      products.removeRange(maxProducts, products.length);
    }
    products.refresh();
    _saveToStorage();
  }

  void _saveToStorage() {
    final jsonList = products.map((p) => p.toJson()).toList();
    box.write(_key, jsonList);
  }

  void clearAll() {
    products.clear();
    box.remove(_key);
    Future.delayed(const Duration(milliseconds: 100), () {
      products.refresh();
    });
  }
}
