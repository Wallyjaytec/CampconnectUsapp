import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/seller_repository.dart';
import '../model/follow_seller_model.dart';

class ReportSellerController extends GetxController {
  ReportSellerController({SellerRepository? repository})
      : _repo = repository ?? SellerRepository();

  final SellerRepository _repo;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<FollowSellerModel> allSellers = <FollowSellerModel>[].obs;

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
}
