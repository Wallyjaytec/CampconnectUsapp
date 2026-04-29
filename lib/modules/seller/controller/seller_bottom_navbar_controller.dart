import 'package:get/get.dart';

import '../view/reviews_view.dart';
import '../view/seller_all_products_view.dart';
import '../view/seller_view.dart';

class SellerBottomNavbarController extends GetxController {
  var currentIndex = 0.obs;
  var screens = [
    const SellerView(),
    const SellerAllProductsView(),
    const ReviewsView(),
  ].obs;
}
