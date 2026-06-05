import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/follow_store_service.dart';
import '../../../core/services/login_service.dart';
import '../../../data/repositories/seller_repository.dart';
import '../../../shared/utils/dialog_utils.dart';
import '../../product/controller/product_details_controller.dart';
import '../model/seller_shop_model.dart';

class SellerProductsController extends GetxController {
  final String slug;
  final SellerRepository repo;
  final bool autoLoad;
  static final FollowStore _store = FollowStore();

  SellerProductsController({
    required this.slug,
    SellerRepository? repository,
    this.autoLoad = true,
  }) : repo = repository ?? SellerRepository();

  final isLoading = false.obs;
  final isError = false.obs;
  final errorMessage = ''.obs;

  final newItems = <SellerProductModel>[].obs;
  final featuredItems = <SellerProductModel>[].obs;
  final topSellingItems = <SellerProductModel>[].obs;

  final followers = 0.obs;
  final isFollowing = false.obs;
  final RxBool _dialogBusy = false.obs;

  void seedHeaderMetaFromArgs(SellerNavArgs args) {
    followers.value = args.followers;
    isFollowing.value = _store.isFollowed(slug) || args.isFollowing;
  }

  void seedHeaderMeta({
    required int followersCount,
    bool alreadyFollowing = false,
  }) {
    followers.value = followersCount;
    isFollowing.value = _store.isFollowed(slug) || alreadyFollowing;
  }

  @override
  void onInit() {
    super.onInit();
    if (_store.isFollowed(slug)) {
      isFollowing.value = true;
    }
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    isError.value = false;
    errorMessage.value = '';

    final res = await repo.fetchShopProductSummary(slug: slug);
    newItems.assignAll(res.newItems.data);
    featuredItems.assignAll(res.featuredItems.data);
    topSellingItems.assignAll(res.topSellingItems.data);

    isLoading.value = false;
  }

  Future<void> _fetchFollowStatus() async {
    // Intentionally empty - API returns cached data
  }

  void _syncToProductDetail() {
    final tag = 'seller_header_$slug';
    if (Get.isRegistered<SellerProductsController>(tag: tag)) {
      final pCtrl = Get.find<SellerProductsController>(tag: tag);
      pCtrl.followers.value = followers.value;
      pCtrl.isFollowing.value = isFollowing.value;
    }
    final tag2 = 'seller_bottom_$slug';
    if (Get.isRegistered<SellerProductsController>(tag: tag2)) {
      final pCtrl = Get.find<SellerProductsController>(tag: tag2);
      pCtrl.followers.value = followers.value;
      pCtrl.isFollowing.value = isFollowing.value;
    }
  }

  void onProductTap(int id) {
    if (Get.isRegistered<ProductDetailsController>()) {
      Get.delete<ProductDetailsController>(force: true);
    }
    Get.toNamed(AppRoutes.productDetailsView, arguments: id);
  }

  final _followBusy = false.obs;
  bool get followBusy => _followBusy.value;

  Future<void> followShop() async {
    if (_followBusy.value || isFollowing.value) return;

    final ok = await _ensureLoggedInWithPrompt();
    if (!ok) return;

    await _followInternal();
  }

  Future<void> unfollowShop() async {
    if (_followBusy.value || !isFollowing.value) return;

    final ok = await _ensureLoggedInWithPrompt();
    if (!ok) return;

    _followBusy.value = true;
    try {
      final res = await repo.unfollowShop(slug: slug);
      if (res.success) {
        isFollowing.value = false;
        _store.setFollowed(slug, false);
        followers.value = (followers.value - 1).clamp(0, double.infinity).toInt();
        _syncToProductDetail();
        Get.snackbar('Unfollowed'.tr, 'Shop removed from your following list'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
      }
    } catch (_) {
      Get.snackbar('Error'.tr, 'Something went wrong'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
    } finally {
      _followBusy.value = false;
    }
  }

  Future<void> _followInternal() async {
    _followBusy.value = true;
    try {
      final res = await repo.followShop(slug: slug);
      if (res.success) {
        isFollowing.value = true;
        _store.setFollowed(slug, true);

        if (!res.duplicate) {
          followers.value = followers.value + 1;
          _syncToProductDetail();
          Get.snackbar('Followed'.tr, 'Shop added to your following list'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
        } else {
          Get.snackbar('Following'.tr, 'You are already following this shop'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
        }
      } else {
        Get.snackbar('Failed'.tr, 'Could not follow this shop'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
      }
    } catch (_) {
      Get.snackbar('Error'.tr, 'Something went wrong'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
    } finally {
      _followBusy.value = false;
    }
  }

  Future<bool> _ensureLoggedInWithPrompt() async {
    final login = LoginService();
    if (login.isLoggedIn()) return true;

    if (_dialogBusy.value) return false;
    _dialogBusy.value = true;

    final goLogin = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Get.theme.brightness == Brightness.dark
            ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Login required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('You must log in to continue'.tr, style: const TextStyle(fontSize: 14, color: AppColors.greyColor, height: 1.3)),
        actions: [
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: () => safeBack(result: false),
              child: Text('Cancel'.tr),
            ),
          ),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => safeBack(result: true),
              child: Text('Login'.tr),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    _dialogBusy.value = false;

    if (goLogin == true) Get.toNamed(AppRoutes.loginView);
    return false;
  }
}
