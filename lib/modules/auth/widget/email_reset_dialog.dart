import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/email_reset_controller.dart';

class EmailResetDialog extends StatelessWidget {
  const EmailResetDialog({super.key, required this.controller});

  final EmailResetController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset Email'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we will send you an email reset link'
                  .tr,
            ),
            const SizedBox(height: 12),
            Obx(
              () => TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email'.tr,
                  errorText: controller.emailError.value.isEmpty
                      ? null
                      : controller.emailError.value,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.clear();
            Get.back();
          },
          child: Text('Cancel'.tr),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () => controller.submit(),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Send'.tr),
          ),
        ),
      ],
    );
  }
}
