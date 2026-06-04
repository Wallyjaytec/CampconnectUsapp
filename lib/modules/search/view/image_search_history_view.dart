import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import '../controller/image_search_history_controller.dart';
import '../controller/visual_search_controller.dart';

class ImageSearchHistoryView extends StatefulWidget {
  const ImageSearchHistoryView({super.key});

  @override
  State<ImageSearchHistoryView> createState() => _ImageSearchHistoryViewState();
}

class _ImageSearchHistoryViewState extends State<ImageSearchHistoryView> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  ImageSearchHistoryController get _controller =>
      Get.find<ImageSearchHistoryController>();

  @override
  void initState() {
    super.initState();
    Get.put(ImageSearchHistoryController());
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIndices.length == _controller.history.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(_controller.history.length, (i) => i));
      }
    });
  }

  void _deleteSelected() {
    _controller.deleteSelected(_selectedIndices);
    setState(() {
      _selectedIndices.clear();
      _isSelectionMode = false;
    });
  }

  void _openCamera() {
    final controller = Get.put(VisualSearchController());
    controller.searchFromCamera();
  }

  void _openGallery() {
    final controller = Get.put(VisualSearchController());
    controller.searchFromGallery();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        title: Text('Search history'.tr),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIndices.clear();
              }),
            )
          else if (_controller.history.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash_copy, size: 20),
              onPressed: () => setState(() => _isSelectionMode = true),
            ),
        ],
      ),
      body: Obx(() {
        if (_controller.history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.gallery_copy, size: 80, color: AppColors.primaryColor),
                  const SizedBox(height: 16),
                  Text('It is empty'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('You can take a photo or upload an image to find similar items.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openCamera,
                        icon: const Icon(Iconsax.camera_copy, size: 18),
                        label: Text('Take photo'.tr),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _openGallery,
                        icon: const Icon(Iconsax.gallery_copy, size: 18),
                        label: Text('Select from album'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Showing your image search history from the last 30 days.'.tr,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _controller.history.length,
                itemBuilder: (context, index) {
                  final item = _controller.history[index];
                  final isSelected = _selectedIndices.contains(index);
                  final imageFile = File(item.imagePath);

                  return GestureDetector(
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(index);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageFile.existsSync()
                              ? Image.file(imageFile, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 30, color: Colors.grey)),
                        ),
                        if (_isSelectionMode && isSelected)
                          Positioned(
                            top: 4, left: 4,
                            child: Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor, shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                          ),
                        if (_isSelectionMode && !isSelected)
                          Positioned(
                            top: 4, left: 4,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardColor : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      child: Text(
                        _selectedIndices.length == _controller.history.length ? 'Deselect all'.tr : 'Select all'.tr,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _selectedIndices.isEmpty ? null : _deleteSelected,
                      icon: const Icon(Iconsax.trash_copy, size: 18),
                      label: Text('Delete'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}
