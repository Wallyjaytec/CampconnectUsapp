import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../controller/report_submit_controller.dart';

class ReportSellerDialog extends StatelessWidget {
  const ReportSellerDialog({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLogo,
  });

  final int sellerId;
  final String sellerName;
  final String sellerLogo;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportSubmitController());

    final reasons = [
      'Fake/Counterfeit Products',
      'Scam/Fraud',
      'Poor Quality Products',
      'Misleading Product Description',
      'Non-Delivery of Items',
      'Poor Customer Service',
      'Other',
    ];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Report Seller'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
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
                // Seller info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: sellerLogo,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.store, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sellerName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Reason dropdown
                Row(
                  children: [
                    Text('Reason'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    const Text('*', style: TextStyle(color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 6),
                Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedReason.value,
                      items: reasons
                          .map((r) => DropdownMenuItem<String>(
                                value: r,
                                child: Text(r.tr, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => controller.selectedReason.value = v,
                      isExpanded: true,
                      icon: const Icon(Iconsax.arrow_down_1_copy, size: 18),
                      borderRadius: BorderRadius.circular(8),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkCardColor
                            : AppColors.lightCardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: Text('Select a reason'.tr),
                    )),
                const SizedBox(height: 12),
                // Description
                Text('Description'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 4,
                  onChanged: (v) => controller.description.value = v,
                  decoration: InputDecoration(
                    hintText: 'Write your complaint...'.tr,
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
                // Images
                Obx(() {
                  final files = controller.images;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(files.length, (i) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(files[i].path), width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: GestureDetector(
                                      onTap: () => controller.removeImageAt(i),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: controller.pickFromGallery,
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryColor,
                              child: Icon(Iconsax.gallery_copy, size: 24, color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.pickFromCamera,
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryColor,
                              child: Icon(Iconsax.camera_copy, size: 24, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                // Submit button
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: controller.submitting.value
                            ? null
                            : () async {
                                if (controller.selectedReason.value == null) {
                                  Get.snackbar(
                                    'Required'.tr,
                                    'Please select a reason'.tr,
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: AppColors.primaryColor,
                                    colorText: AppColors.whiteColor,
                                  );
                                  return;
                                }
                                final ok = await controller.submit(sellerId: sellerId);
                                if (ok) {
                                  Navigator.of(context).pop(true);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (Get.context != null) {
                                      ScaffoldMessenger.of(Get.context!).showSnackBar(
                                        SnackBar(
                                          content: Text('Report submitted'.tr),
                                          backgroundColor: AppColors.primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not submit report'.tr),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.submitting.value
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                            : Text('Submit Report'.tr),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
