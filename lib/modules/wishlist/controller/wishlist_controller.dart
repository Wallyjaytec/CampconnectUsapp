import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/login_service.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../../shared/utils/dialog_utils.dart';
import '../../product/model/product_model.dart';

class WishlistController extends GetxController {
  WishlistController({WishlistRepository? repo})
    : _repo = repo ?? WishlistRepository(ApiService());

  final WishlistRepository _repo;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;

  final RxList<ProductModel> items = <ProductModel>[].obs;

  final RxSet<int> _ids = <int>{}.obs;

  RxSet<int> get ids => _ids;

  int _page = 1;
  final int _perPage = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  static WishlistController ensure() {
    if (Get.isRegistered<WishlistController>()) {
      return Get.find<WishlistController>();
    }
    return Get.put(WishlistController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    final login = LoginService();
    if (login.isLoggedIn()) {
      refreshFirstPage();
    }
  }

  Future<void> onUserLoggedIn() => refreshFirstPage();

  void onUserLoggedOut() {
    isLoading.value = false;
    isLoadingMore.value = false;
    error.value = '';
    _page = 1;
    _hasMore = true;

    items.clear();
    _ids.clear();
    items.refresh();
    _ids.refresh();
  }

  bool isInWishlist(int? productId) {
    if (productId == null || productId <= 0) return false;
    return _ids.contains(productId);
  }

  void setFromExternalList(Iterable<ProductModel> list) {
    final seen = list.map((e) => e.id).whereType<int>();
    _ids.addAll(seen);
    _ids.refresh();
  }

  Future<void> ensureLoaded() async {
    if (items.isEmpty && !isLoading.value) {
      await refreshFirstPage();
    }
  }

  Future<bool> _ensureLoggedInWithPrompt() async {
    final login = LoginService();
    if (login.isLoggedIn()) return true;

    final goLogin =
        await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Get.theme.brightness == Brightness.dark
                ? AppColors.darkProductCardColor
                : AppColors.lightBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            title: Text(
              'Login required'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: Text(
              'You need to login to use wishlist'.tr,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.greyColor,
                height: 1.3,
              ),
            ),
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
        ) ??
        false;

    if (goLogin) {
      Get.toNamed(AppRoutes.loginView);
    }
    return false;
  }

  Future<void> refreshFirstPage() async {
    try {
      isLoading.value = true;
      error.value = '';

      _page = 1;
      _hasMore = true;
      items.clear();
      _ids.clear();
      _ids.refresh();

      final resp = await _repo.fetchWishlist(page: _page, perPage: _perPage);

      items.assignAll(resp.items);
      _ids.addAll(resp.items.map((e) => e.id).whereType<int>());
      _ids.refresh();

      _hasMore = resp.hasMore;
      if (_hasMore) _page = resp.nextPage;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      items.clear();
      _ids.clear();
      _ids.refresh();
      _hasMore = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;
    try {
      isLoadingMore.value = true;

      final resp = await _repo.fetchWishlist(page: _page, perPage: _perPage);

      final exist = _ids.toSet();
      final inc = resp.items.where((e) => !exist.contains(e.id)).toList();

      if (inc.isNotEmpty) {
        items.addAll(inc);
        _ids.addAll(inc.map((e) => e.id).whereType<int>());
        _ids.refresh();
      }

      _hasMore = resp.hasMore;
      if (_hasMore) _page = resp.nextPage;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      _hasMore = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggle(ProductModel p) async {
    if (!await _ensureLoggedInWithPrompt()) return;

    final id = p.id;
    if (id <= 0) return;

    final already = _ids.contains(id);

    if (already) {
      _ids.remove(id);
      _ids.refresh();
      items.removeWhere((e) => e.id == id);
    } else {
      if (!_ids.contains(id)) {
        _ids.add(id);
        _ids.refresh();
      }
      final existsIdx = items.indexWhere((e) => e.id == id);
      if (existsIdx == -1) items.insert(0, p);
    }

    try {
      if (already) {
        await _repo.removeFromWishlist(productId: id);
      } else {
        await _repo.addToWishlist(productId: id);
      }
    } catch (e) {
      if (already) {
        _ids.add(id);
        _ids.refresh();
        final existsIdx = items.indexWhere((e) => e.id == id);
        if (existsIdx == -1) items.insert(0, p);
      } else {
        _ids.remove(id);
        _ids.refresh();
        items.removeWhere((e) => e.id == id);
      }
      rethrow;
    }
  }

  Future<void> remove(int productId) async {
    if (!await _ensureLoggedInWithPrompt()) return;

    final backup = items.toList();
    final wasInSet = _ids.contains(productId);

    items.removeWhere((e) => e.id == productId);
    _ids.remove(productId);
    _ids.refresh();

    try {
      await _repo.removeFromWishlist(productId: productId);
    } catch (e) {
      items.assignAll(backup);
      if (wasInSet) {
        _ids.add(productId);
        _ids.refresh();
      }
      rethrow;
    }
  }
}
