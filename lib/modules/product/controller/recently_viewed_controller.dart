import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/product_model.dart';

class RecentlyViewedController extends GetxController {
  final box = GetStorage();
  static const String _key = 'recently_viewed_products';
  static const int maxProducts = 20;

  List<ProductModel> products = [];

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
    products = list;
    update();
  }

  void addProduct(ProductModel product) {
    products.removeWhere((p) => p.id == product.id);
    products.insert(0, product);
    if (products.length > maxProducts) {
      products = products.sublist(0, maxProducts);
    }
    update();
    _saveToStorage();
  }

  void _saveToStorage() {
    final jsonList = products.map((p) => p.toJson()).toList();
    box.write(_key, jsonList);
  }

  void clearAll() {
    products = [];
    box.remove(_key);
    update();
  }
}
