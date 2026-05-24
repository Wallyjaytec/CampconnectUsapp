import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../model/coupon_model.dart';

class CouponController extends GetxController {
  CouponController({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<CouponModel> activeCoupons = <CouponModel>[].obs;
  final RxList<CouponModel> inactiveCoupons = <CouponModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    isLoading.value = true;
    error.value = '';

    try {
      final url = '${AppConfig.baseUrl}/api/v1/ecommerce-core/coupons';
      final response = await _api.getJson(url);

      final List<dynamic> data = response['data'] ?? response['coupons'] ?? [];
      final allCoupons = data.map((e) => CouponModel.fromJson(e)).toList();

      activeCoupons.assignAll(allCoupons.where((c) => c.isActive && !c.isExpired));
      inactiveCoupons.assignAll(allCoupons.where((c) => !c.isActive || c.isExpired));
    } catch (e) {
      error.value = 'Failed to load coupons'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
