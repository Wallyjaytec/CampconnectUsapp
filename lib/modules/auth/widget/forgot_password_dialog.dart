import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../account/widgets/custom_text_form_field.dart';
import '../controller/forgot_password_controller.dart';

class ForgotPasswordDialog extends StatelessWidget {
  const ForgotPasswordDialog({super.key, required this.controller});

  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkProductCardColor
          : AppColors.lightBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      titlePadding: const EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      title: Row(
        children: [
          Text(
            'Forgot Password'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              controller.clear();
              Navigator.of(context).pop();
            },
            icon: const Icon(Iconsax.close_circle_copy, size: 18),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.only(
        top: 0,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we will send you a password reset link'
                  .tr,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.greyColor,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              hint: 'Email'.tr,
              icon: Iconsax.sms_copy,
            ),
            const SizedBox(height: 6),
            Obx(() {
              final err = controller.emailError.value;
              if (err.isEmpty) return const SizedBox.shrink();
              return Text(
                err,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              );
            }),
          ],
        ),
      ),
      actions: [
        Obx(
          () => SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.submit(context),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    )
                  : Text('Send'.tr),
            ),
          ),
        ),
      ],
    );
  }
}
