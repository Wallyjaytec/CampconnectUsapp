import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/visual_search_service.dart';
import '../controller/image_search_history_controller.dart';
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
      Get.to(() => _ImageScanningView(imageFile: File(x.path)));
      await _search(File(x.path));
      Get.off(() => const VisualSearchResultsView());
    }
  }

  Future<void> searchFromGallery() async {
    final allowed = await PermissionService.I.canUseGalleryOrExplain();
    if (!allowed) return;

    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) {
      Get.to(() => _ImageScanningView(imageFile: File(x.path)));
      await _search(File(x.path));
      Get.off(() => const VisualSearchResultsView());
    }
  }

  Future<void> _search(File image) async {
    isLoading.value = true;
    error.value = '';
    results.clear();

    final historyCtrl = Get.isRegistered<ImageSearchHistoryController>()
        ? Get.find<ImageSearchHistoryController>()
        : Get.put(ImageSearchHistoryController());
    historyCtrl.addToHistory(image.path);

    try {
      final searchResults = await _service.searchByImage(image);
      searchResults.sort((a, b) => a.score.compareTo(b.score));
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

class _ImageScanningView extends StatelessWidget {
  final File imageFile;
  const _ImageScanningView({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(imageFile, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  AppColors.primaryColor.withValues(alpha: 0.15),
                  AppColors.primaryColor.withValues(alpha: 0.3),
                  AppColors.primaryColor.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scanning image...'.tr,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Finding similar products'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
