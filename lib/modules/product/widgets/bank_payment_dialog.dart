import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/permission_service.dart';
import '../../../shared/utils/dialog_utils.dart';
import '../../account/widgets/custom_text_form_field.dart';
import '../controller/checkout_controller.dart';

class BankPaymentDialog extends StatelessWidget {
  const BankPaymentDialog({super.key, required this.controller});
  final CheckoutController controller;

  Future<void> _pick(ImageSource src) async {
    final allowed = await PermissionService.I.canUseMediaOrExplain();
    if (!allowed) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: src, imageQuality: 70);
    if (file != null) {
      controller.bankReceiptImagePath.value = file.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );

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
                Row(
                  children: [
                    Text(
                      'Bank Payment'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => safeBack(),
                      icon: const Icon(Iconsax.close_circle_copy),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: controller.bankAccountNameCtrl,
                  hint: 'Account Name'.tr,
                  icon: Iconsax.personalcard_copy,
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: controller.bankAccountNumberCtrl,
                  hint: 'Account Number'.tr,
                  icon: Iconsax.keyboard_copy,
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: controller.bankNameCtrl,
                  hint: 'Bank Name'.tr,
                  icon: Iconsax.bank_copy,
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: controller.bankBranchCtrl,
                  hint: 'Branch Name'.tr,
                  icon: Iconsax.note_add_copy,
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: controller.bankTransactionIdCtrl,
                  hint: 'Transaction Number'.tr,
                  icon: Iconsax.keyboard_copy,
                ),

                const SizedBox(height: 10),
                label('Attach Receipt'.tr),
                Obx(() {
                  final path = controller.bankReceiptImagePath.value;
                  return Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (path != null && path.isNotEmpty)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: -8,
                              top: -8,
                              child: IconButton(
                                onPressed: () => {
                                  controller.bankReceiptImagePath.value = '',
                                },
                                icon: const Icon(
                                  Iconsax.close_circle_copy,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _pick(ImageSource.camera),
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
                          GestureDetector(
                            onTap: () => _pick(ImageSource.gallery),
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
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      safeBack();
                      Get.snackbar(
                        'Bank Payment'.tr,
                        'Details captured'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppColors.primaryColor,
                        colorText: AppColors.whiteColor,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Submit'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
