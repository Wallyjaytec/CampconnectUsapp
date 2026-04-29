import 'package:get/get.dart';

import '../../account/view/account_view.dart';
import '../../category/view/all_category_view.dart';
import '../../compare/view/compare_view.dart';
import '../../home/view/home_view.dart';
import '../../wishlist/view/wishlist_view.dart';

class BottomNavbarController extends GetxController {
  var currentIndex = 0.obs;
  var screens = [
    const HomeView(),
    const AllCategoriesView(showBackButton: false),
    const CompareView(),
    const WishlistView(),
    const AccountView(),
  ].obs;
}
