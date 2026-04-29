import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../core/utils/banner_nav.dart';
import '../../../data/repositories/banner_repository.dart';
import '../model/app_banner_model.dart';

class BannerController extends GetxController {
  BannerController({BannerRepository? repository})
    : repo = repository ?? BannerRepository(ApiService());

  final BannerRepository repo;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<AppBanner> banners = <AppBanner>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      final list = await repo.fetchActiveBanners();
      banners.assignAll(list);
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      banners.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void onTapBanner(AppBanner b) {
    BannerNav.open(b);
  }
}
