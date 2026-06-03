import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/visual_search_service.dart';
import '../view/visual_search_results_view.dart';

class VisualSearchController extends GetxController {
  final VisualSearchService _service = VisualSearchService();
  final ImagePicker _picker = ImagePicker();

  final RxList<VisualSearchResult> results = <VisualSearchResult>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Future<void> searchFromCamera() async {
    final allowed = await PermissionService.I.canUseCameraOrExplain();
    if (!allowed) return;

    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) {
      Get.to(() => const VisualSearchResultsView());
      await _search(File(x.path));
    }
  }

  Future<void> searchFromGallery() async {
    final allowed = await PermissionService.I.canUseGalleryOrExplain();
    if (!allowed) return;

    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) {
      Get.to(() => const VisualSearchResultsView());
      await _search(File(x.path));
    }
  }

  Future<void> _search(File image) async {
    isLoading.value = true;
    error.value = '';
    results.clear();

    try {
      final searchResults = await _service.searchByImage(image);
      results.assignAll(searchResults);
      if (results.isEmpty) {
        error.value = 'No similar products found'.tr;
      }
    } catch (e) {
      error.value = 'Search failed. Please try again.'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  void clearResults() {
    results.clear();
    error.value = '';
  }
}
