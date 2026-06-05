import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:get/get.dart';

class RouteNames {
  static const categoryProducts = '/category-products';
  static const productDetails = '/product-details';
}

class SearchNavHelper {
  static void goToCategory({
    required int id,
    required String name,
    required String slug,
  }) {
    Get.toNamed(
      AppRoutes.newProductListView,
      arguments: {'categoryId': id, 'name': name, 'slug': slug},
    );
  }

  static void goToProductDetails({required String slug, required int id}) {
    Get.toNamed(
      AppRoutes.productDetailsView,
      arguments: {'slug': slug, 'productId': id},
    );
  }

  static void goToSearchResults({required String query}) {
    if (query.trim().isEmpty) return;
    Get.toNamed(
      AppRoutes.searchResultsListView,
      arguments: {'query': query.trim()},
    );
  }
}
