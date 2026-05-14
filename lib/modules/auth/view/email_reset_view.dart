import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/modules/account/widgets/custom_text_form_field.dart';
import 'package:kartly_e_commerce/modules/auth/controller/auth_controller.dart';

class EmailResetView extends StatelessWidget {
  final String token;
  const EmailResetView({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final emailCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('Reset Email'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text('Enter your new email address'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            CustomTextFormField(
              controller: emailCtrl,
              hint: 'New Email'.tr,
              icon: Iconsax.sms_copy,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: () => controller.resetEmail(token: token, email: emailCtrl.text.trim()),
                child: Text('Update Email'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
