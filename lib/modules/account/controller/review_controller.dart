import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/services/permission_service.dart';
import '../../../data/repositories/my_order_repository.dart';

class ReviewController extends GetxController {
  ReviewController({OrderRepository? repository})
    : _repo = repository ?? OrderRepository();

  final OrderRepository _repo;

  final RxInt rating = 5.obs;
  final RxString reviewText = ''.obs;
  final RxList<XFile> images = <XFile>[].obs;
  final RxBool submitting = false.obs;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromCamera() async {
    final allowed = await PermissionService.I.canUseCameraOrExplain();
    if (!allowed) return;

    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x != null) images.add(x);
  }

  Future<void> pickFromGallery() async {
    final allowed = await PermissionService.I.canUseGalleryOrExplain();
    if (!allowed) return;

    final xs = await _picker.pickMultiImage(imageQuality: 85);
    if (xs.isNotEmpty) images.addAll(xs);
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
    }
  }

  Future<bool> submit({required int orderId, required int productId}) async {
    if (submitting.value) return false;
    submitting.value = true;

    try {
      final List<http.MultipartFile> files = [];
      for (final x in images) {
        final file = File(x.path);
        final filename = file.path.split('/').last;
        files.add(
          await http.MultipartFile.fromPath(
            'review_images[]',
            file.path,
            filename: filename,
          ),
        );
      }

      final ok = await _repo.submitReview(
        orderId: orderId,
        productId: productId,
        rating: rating.value,
        review: reviewText.value.trim(),
        images: files.isEmpty ? null : files,
      );

      return ok;
    } catch (_) {
      return false;
    } finally {
      submitting.value = false;
    }
  }

  void clearAll() {
    rating.value = 5;
    reviewText.value = '';
    images.clear();
  }
}
