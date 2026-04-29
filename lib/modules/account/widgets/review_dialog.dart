import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../controller/review_controller.dart';

class ReviewDialog extends StatelessWidget {
  const ReviewDialog({
    super.key,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
  });

  final int orderId;
  final int productId;
  final String productName;
  final String productImage;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ReviewController());

    Widget stars() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Obx(() {
            final v = c.rating.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (i) {
                final on = i < v;
                return GestureDetector(
                  onTap: () => c.rating.value = i + 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      on ? Icons.star_rounded : Icons.star_border_rounded,
                      color: on ? const Color(0xFFFFC107) : AppColors.greyColor,
                      size: 38,
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      );
    }

    Widget imagePicker() {
      return Obx(() {
        final files = c.images;
        return Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(files.length, (i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(files[i].path),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: IconButton(
                          onPressed: () => c.removeImageAt(i),
                          icon: const Icon(Iconsax.close_circle_copy, size: 18),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: c.pickFromGallery,
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryColor,
                    child: Icon(
                      Iconsax.gallery_copy,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: c.pickFromCamera,
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryColor,
                    child: Icon(
                      Iconsax.camera_copy,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      });
    }

    final reviewTextController = TextEditingController();
    reviewTextController.addListener(() {
      Get.find<ReviewController>().reviewText.value = reviewTextController.text;
    });

    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkProductCardColor
          : AppColors.lightBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Review product'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Iconsax.close_circle_copy),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                stars(),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewTextController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write a review'.tr,
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCardColor
                        : AppColors.lightCardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                imagePicker(),
                const SizedBox(height: 16),
                Obx(() {
                  final busy = c.submitting.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: busy
                          ? null
                          : () async {
                              final ok = await c.submit(
                                orderId: orderId,
                                productId: productId,
                              );
                              if (ok) {
                                Get.back();
                                Get.snackbar(
                                  'Success'.tr,
                                  'Review submitted'.tr,
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: AppColors.primaryColor,
                                  colorText: AppColors.whiteColor,
                                );
                                c.clearAll();
                              } else {
                                Get.snackbar(
                                  'Failed'.tr,
                                  'Could not submit review'.tr,
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: AppColors.primaryColor,
                                  colorText: AppColors.whiteColor,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(),
                            )
                          : Text('Submit'.tr),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
