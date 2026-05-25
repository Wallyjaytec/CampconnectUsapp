import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/repositories/seller_repository.dart';
import '../controller/report_submit_controller.dart';

class ReportSubmitController extends GetxController {
  final RxnString selectedReason = RxnString();
  final RxString description = ''.obs;
  final RxList<XFile> images = <XFile>[].obs;
  final RxBool submitting = false.obs;
  final RxBool isLoadingReasons = false.obs;
  final RxList<String> reasons = <String>[].obs;
  final ImagePicker _picker = ImagePicker();
  final SellerRepository _repo = SellerRepository();

  @override
  void onInit() {
    super.onInit();
    loadReasons();
  }

  Future<void> loadReasons() async {
    isLoadingReasons.value = true;
    try {
      final data = await _repo.fetchReportReasons();
      reasons.assignAll(data.map((e) => e['name']?.toString() ?? '').toList());
    } catch (_) {
      reasons.assignAll([
        'Fake/Counterfeit Products',
        'Scam/Fraud',
        'Poor Quality Products',
        'Misleading Product Description',
        'Non-Delivery of Items',
        'Poor Customer Service',
        'Other',
      ]);
    } finally {
      isLoadingReasons.value = false;
    }
  }

  void clearAll() {
    selectedReason.value = null;
    description.value = '';
    images.clear();
  }

  Future<void> pickFromCamera() async {
    final allowed = await PermissionService.I.canUseMediaOrExplain();
    if (!allowed) return;
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) images.add(x);
  }

  Future<void> pickFromGallery() async {
    final allowed = await PermissionService.I.canUseMediaOrExplain();
    if (!allowed) return;
    final xs = await _picker.pickMultiImage(imageQuality: 85);
    if (xs.isNotEmpty) images.addAll(xs);
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
    }
  }

  Future<bool> submit({required int sellerId}) async {
    if (submitting.value) return false;
    if (selectedReason.value == null) return false;
    
    submitting.value = true;
    try {
      List<File>? imageFiles;
      if (images.isNotEmpty) {
        imageFiles = images.map((x) => File(x.path)).toList();
      }

      final ok = await _repo.submitSellerReport(
        sellerId: sellerId,
        reason: selectedReason.value!,
        description: description.value,
        images: imageFiles,
      );
      if (ok) {
        clearAll();
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
