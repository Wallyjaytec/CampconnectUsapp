import 'package:get/get.dart';
import '../../../data/repositories/seller_repository.dart';
import '../model/report_seller_model.dart';

class ReportSellerStatusController extends GetxController {
  ReportSellerStatusController({SellerRepository? repository})
      : _repo = repository ?? SellerRepository();

  final SellerRepository _repo;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<ReportSellerModel> reports = <ReportSellerModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    isLoading.value = true;
    error.value = '';

    try {
      final data = await _repo.fetchMyReports();
      reports.assignAll(
        data.map((e) => ReportSellerModel.fromJson(e)),
      );
    } catch (e) {
      error.value = 'Failed to load reports'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
