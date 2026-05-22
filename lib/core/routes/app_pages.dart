import 'package:get/get.dart';
import 'package:kartly_e_commerce/modules/account/view/edit_address_view.dart';
import 'package:kartly_e_commerce/modules/account/view/my_address_view.dart';
import 'package:kartly_e_commerce/modules/account/view/my_order_details_view.dart';
import 'package:kartly_e_commerce/modules/account/view/my_order_list_view.dart';
import 'package:kartly_e_commerce/modules/account/view/my_wallet_view.dart';
import 'package:kartly_e_commerce/modules/account/view/privacy_policy_view.dart';
import 'package:kartly_e_commerce/modules/account/view/terms_conditions_view.dart';
import 'package:kartly_e_commerce/modules/product/view/discount_sales_view.dart';
import 'package:kartly_e_commerce/modules/product/view/featured_items_view.dart';
import 'package:kartly_e_commerce/modules/product/view/following_products_view.dart';
import 'package:kartly_e_commerce/modules/product/view/guest_checkout_view.dart';
import 'package:kartly_e_commerce/modules/product/view/guest_order_summary_view.dart';
import 'package:kartly_e_commerce/modules/product/view/latest_collection_view.dart';
import 'package:kartly_e_commerce/modules/product/view/new_product_list_view.dart';
import 'package:kartly_e_commerce/modules/product/view/order_summary_view.dart';
import 'package:kartly_e_commerce/modules/product/view/popular_items_view.dart';
import 'package:kartly_e_commerce/modules/product/view/product_filter_view.dart';
import 'package:kartly_e_commerce/modules/product/view/recently_viewed_view.dart';
import 'package:kartly_e_commerce/modules/product/view/top_sale_product_view.dart';
import 'package:kartly_e_commerce/modules/seller/view/seller_view.dart';
import 'package:kartly_e_commerce/modules/splash/view/splash_view.dart';

import '../../modules/account/model/my_order_model.dart';
import '../../modules/account/view/add_address_view.dart';
import '../../modules/account/view/contact_us_page.dart';
import '../../modules/account/view/edit_profile_view.dart';
import '../../modules/account/view/notifications_view.dart';
import '../../modules/account/view/recharge_wallet_view.dart';
import '../../modules/account/view/refund_request_details_view.dart';
import '../../modules/account/view/refund_request_list_view.dart';
import '../../modules/auth/view/login_view.dart';
import '../../modules/auth/view/password_reset_view.dart';
import '../../modules/auth/view/signup_view.dart';
import '../../modules/bottom_navbar/view/bottom_navbar_view.dart';
import '../../modules/category/view/all_category_view.dart';
import '../../modules/collection/view/collection_view.dart';
import '../../modules/product/binding/checkout_binding.dart';
import '../../modules/product/view/cart_view.dart';
import '../../modules/product/view/checkout_view.dart';
import '../../modules/product/view/flash_deals_view.dart';
import '../../modules/product/view/new_product_view.dart';
import '../../modules/product/view/product_details_view.dart';
import '../../modules/product/widgets/full_screen_image_view.dart';
import '../../modules/search/view/product_search_filter.dart';
import '../../modules/search/view/search_results_list_view.dart';
import '../../modules/search/view/search_view.dart';
import '../../modules/seller/widgets/seller_bottom_navbar.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.loginView;

  static final pages = [
    GetPage(name: AppRoutes.splashView, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.bottomNavbarView,
      page: () => const BottomNavbarView(),
    ),
    GetPage(name: AppRoutes.searchView, page: () => const SearchView()),
    GetPage(
      name: AppRoutes.allCategoriesView,
      page: () => const AllCategoriesView(showBackButton: true),
    ),
    GetPage(
      name: AppRoutes.productDetailsView,
      page: () => ProductDetailsView(),
    ),
    GetPage(
      name: AppRoutes.productFilterView,
      page: () => const ProductFilterView(),
    ),
    GetPage(
      name: AppRoutes.fullScreenImageView,
      page: () => const FullScreenImageView(),
    ),
    GetPage(
      name: AppRoutes.sellerBottomNavbar,
      page: () => const SellerBottomNavbar(),
    ),
    GetPage(name: AppRoutes.cartView, page: () => const CartView()),
    GetPage(
      name: AppRoutes.checkoutView,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
    ),
    GetPage(name: AppRoutes.loginView, page: () => const LoginView()),
    GetPage(name: AppRoutes.signupView, page: () => const SignupView()),
    GetPage(
      name: AppRoutes.editProfileView,
      page: () => const EditProfileView(),
    ),
    GetPage(
      name: AppRoutes.newProductListView,
      page: () => const NewProductListView(),
    ),
    GetPage(
      name: AppRoutes.topSaleProductView,
      page: () => const TopSaleProductView(),
    ),
    GetPage(name: AppRoutes.flashDealsView, page: () => const FlashDealsView()),
    GetPage(
      name: AppRoutes.discountSalesView,
      page: () => const DiscountSalesView(),
    ),
    GetPage(
      name: AppRoutes.featuredItemsView,
      page: () => const FeaturedItemsView(),
    ),
    GetPage(
      name: AppRoutes.latestCollectionView,
      page: () => const LatestCollectionView(),
    ),
    GetPage(
      name: AppRoutes.popularItemsView,
      page: () => const PopularItemsView(),
    ),
    GetPage(name: AppRoutes.newProductView, page: () => const NewProductView()),
    GetPage(name: AppRoutes.myAddressView, page: () => const MyAddressView()),
    GetPage(name: AppRoutes.addAddressView, page: () => const AddAddressView()),
    GetPage(
      name: AppRoutes.editAddressView,
      page: () => const EditAddressView(),
    ),
    GetPage(name: AppRoutes.myWalletView, page: () => MyWalletView()),
    GetPage(
      name: AppRoutes.rechargeWalletView,
      page: () => RechargeWalletView(),
    ),
    GetPage(name: AppRoutes.collectionView, page: () => const CollectionView()),
    GetPage(
      name: AppRoutes.searchResultsListView,
      page: () => const SearchResultsListView(),
    ),
    GetPage(
      name: AppRoutes.productSearchFilter,
      page: () => const ProductSearchFilter(),
    ),
    GetPage(
      name: AppRoutes.myOrderListView,
      page: () => const MyOrderListView(),
    ),
    GetPage(
      name: AppRoutes.myOrderDetailsView,
      page: () {
        final args = Get.arguments;
        int orderId = 0;
        bool fromSummary = false;
        bool fromNotification = false;
        if (args is Map) {
          if (args['order_id'] != null) {
            final raw = args['order_id'];
            orderId = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
          }
          if (args['from_summary'] == true) fromSummary = true;
          if (args['from_notification'] == true) fromNotification = true;
        } else if (args is OrderItem) {
          orderId = args.id;
        } else if (args is int) {
          orderId = args;
        }
        return MyOrderDetailsView(orderId: orderId, fromSummary: fromSummary, fromNotification: fromNotification);
      },
    ),
    GetPage(name: AppRoutes.sellerView, page: () => const SellerView()),
    GetPage(name: AppRoutes.refundRequestListView, page: () => const RefundRequestListView()),
    GetPage(name: AppRoutes.contactUsView, page: () => const ContactUsView()),
    GetPage(name: AppRoutes.guestCheckoutView, page: () => const GuestCheckoutView()),
    GetPage(
      name: AppRoutes.orderSummaryView,
      page: () {
        final args = Get.arguments;
        final orderId = args is int ? args : int.tryParse(args?.toString() ?? '') ?? 0;
        return OrderSummaryView(orderId: orderId);
      },
    ),
    GetPage(
      name: AppRoutes.guestOrderSummaryView,
      page: () {
        final args = Get.arguments;
        final orderId = args is int ? args : int.tryParse(args?.toString() ?? '') ?? 0;
        return GuestOrderSummaryView(orderId: orderId);
      },
    ),
    GetPage(name: AppRoutes.notificationsView, page: () => const NotificationsView()),
    GetPage(name: AppRoutes.privacyPolicyView, page: () => const PrivacyPolicyView()),
    GetPage(name: AppRoutes.termsConditionsView, page: () => const TermsConditionsView()),
    GetPage(
      name: AppRoutes.refundRequestDetailsView,
      page: () {
        final int id = Get.arguments as int;
        return RefundRequestDetailsView(refundId: id);
      },
    ),
    GetPage(
      name: AppRoutes.followingProductsView,
      page: () => const FollowingProductsView(),
    ),
    GetPage(
      name: AppRoutes.recentlyViewedView,
      page: () => const RecentlyViewedView(),
    ),
    GetPage(
      name: '/password-reset',
      page: () {
        final uri = Uri.base;
        final token = uri.queryParameters['u'] ?? '';
        return PasswordResetView(token: token);
      },
    ),
  ];
}
