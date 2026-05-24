import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/permission_service.dart';

class ReportSubmitController extends GetxController {
  final RxString? selectedReason = RxString(null);
  final RxString description = ''.obs;
  final RxList<XFile> images = <XFile>[].obs;
  final RxBool submitting = false.obs;
  final ImagePicker _picker = ImagePicker();

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
    submitting.value = true;
    try {
      // TODO: Add backend API call here
      // await _repo.submitReport(sellerId: sellerId, reason: selectedReason.value, description: description.value, images: images);
      await Future.delayed(const Duration(seconds: 1)); // Placeholder
      return true;
    } catch (_) {
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
