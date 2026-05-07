import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/follow_store_service.dart';
import '../../../core/services/login_service.dart';
import '../../../data/repositories/seller_repository.dart';
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
    _fetchFollowStatus();
    if (autoLoad) load();
  }

  Future<void> _fetchFollowStatus() async {
    try {
      final login = LoginService();
      if (!login.isLoggedIn()) return;
      final res = await repo.fetchShopDetails(slug: slug);
      if (res['success'] == true && res['details'] != null) {
        if (res['details']['is_following'] == true) {
          isFollowing.value = true;
          _store.setFollowed(slug, true);
        }
        final apiFollowers = res['details']['total_followers'];
        if (apiFollowers != null) {
          followers.value = apiFollowers is int ? apiFollowers : int.tryParse(apiFollowers.toString()) ?? 0;
        }
      }
    } catch (_) {}
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      isError.value = false;
      errorMessage.value = '';

      final res = await repo.fetchShopProductSummary(slug: slug);
      newItems.assignAll(res.newItems.data);
      featuredItems.assignAll(res.featuredItems.data);
      topSellingItems.assignAll(res.topSellingItems.data);

      // Always try to update shop details
      try {
        final detailsRes = await repo.fetchShopDetails(slug: slug);
        print('SHOP DETAILS: $detailsRes');
        if (detailsRes['details'] != null) {
          final d = detailsRes['details'];
          
          final apiFollowers = d['total_followers'];
          print('FOLLOWERS: $apiFollowers');
          if (apiFollowers != null) {
            followers.value = apiFollowers is int 
                ? apiFollowers 
                : int.tryParse(apiFollowers.toString()) ?? followers.value;
          }
          
          if (d['is_following'] == true) {
            isFollowing.value = true;
            _store.setFollowed(slug, true);
          }
        }
      } catch (e) {
        print('DETAILS ERROR: $e');
      }
    } catch (e) {
      isError.value = true;
      errorMessage.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
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

    final goLogin = await Get.dialog<bool>(AlertDialog(
      backgroundColor: Get.theme.brightness == Brightness.dark
          ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Login required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text('You must log in to unfollow'.tr, style: const TextStyle(fontSize: 14, color: AppColors.greyColor, height: 1.3)),
      actions: [
        SizedBox(height: 44, child: TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel'.tr))),
        SizedBox(height: 44, child: ElevatedButton(onPressed: () => Get.back(result: true), child: Text('Login'.tr))),
      ],
    )) ?? false;

    if (goLogin) Get.toNamed(AppRoutes.loginView);
    return false;
  }
}
