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

class _ImageScanningView extends StatefulWidget {
  final File imageFile;
  const _ImageScanningView({required this.imageFile});

  @override
  State<_ImageScanningView> createState() => _ImageScanningViewState();
}

class _ImageScanningViewState extends State<_ImageScanningView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.file(widget.imageFile, fit: BoxFit.cover),

          // Dark overlay for readability
          Container(color: Colors.black.withValues(alpha: 0.55)),

          // Scanning line animation
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, _) {
              return Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height * _scanAnimation.value,
                child: Column(
                  children: [
                    Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xCCFF8C00),
                            Color(0xFFFF8C00),
                            Color(0xCCFF8C00),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryColor.withValues(alpha: 0.2),
                            Colors.transparent,
                            AppColors.primaryColor.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xCCFF8C00),
                            Color(0xFFFF8C00),
                            Color(0xCCFF8C00),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withValues(
                          alpha: 0.15 * _pulseAnimation.value,
                        ),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(
                            alpha: 0.4 * _pulseAnimation.value,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 35,
                              height: 35,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Text with frosted glass effect
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Scanning image...'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Finding similar products'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
