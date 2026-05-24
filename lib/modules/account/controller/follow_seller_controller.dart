import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/follow_store_service.dart';
import '../../../data/repositories/seller_repository.dart';
import '../model/follow_seller_model.dart';

class FollowSellerController extends GetxController {
  FollowSellerController({SellerRepository? repository})
      : _repo = repository ?? SellerRepository();

  final SellerRepository _repo;
  final FollowStore _followStore = FollowStore();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<FollowSellerModel> allSellers = <FollowSellerModel>[].obs;

  List<FollowSellerModel> get followList =>
      allSellers.where((s) => !s.isFollowing).toList();

  List<FollowSellerModel> get followingList =>
      allSellers.where((s) => s.isFollowing).toList();

  @override
  void onInit() {
    super.onInit();
    loadSellers();
  }

  Future<void> loadSellers() async {
    isLoading.value = true;
    error.value = '';

    try {
      final data = await _repo.fetchActiveShopList();
      allSellers.assignAll(
        data.map((e) => FollowSellerModel.fromJson(e)),
      );
    } catch (e) {
      error.value = 'Failed to load sellers'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> followShop(FollowSellerModel seller) async {
    try {
      final res = await _repo.followShop(slug: seller.slug);
      if (res.success) {
        _followStore.setFollowed(seller.slug, true);
        final index = allSellers.indexWhere((s) => s.id == seller.id);
        if (index != -1) {
          final updated = FollowSellerModel(
            id: seller.id,
            name: seller.name,
            slug: seller.slug,
            logo: seller.logo,
            shopBanner: seller.shopBanner,
            totalFollowers: res.duplicate
                ? seller.totalFollowers
                : seller.totalFollowers + 1,
            positiveRating: seller.positiveRating,
            isVerified: seller.isVerified,
            isFollowing: true,
          );
          allSellers[index] = updated;
          allSellers.refresh();
        }
      }
    } catch (_) {}
  }

  Future<void> unfollowShop(FollowSellerModel seller) async {
    try {
      final res = await _repo.unfollowShop(slug: seller.slug);
      if (res.success) {
        _followStore.setFollowed(seller.slug, false);
        final index = allSellers.indexWhere((s) => s.id == seller.id);
        if (index != -1) {
          final updated = FollowSellerModel(
            id: seller.id,
            name: seller.name,
            slug: seller.slug,
            logo: seller.logo,
            shopBanner: seller.shopBanner,
            totalFollowers: (seller.totalFollowers - 1).clamp(0, 999999),
            positiveRating: seller.positiveRating,
            isVerified: seller.isVerified,
            isFollowing: false,
          );
          allSellers[index] = updated;
          allSellers.refresh();
        }
      }
    } catch (_) {}
  }
}
