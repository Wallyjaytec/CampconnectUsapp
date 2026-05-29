import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/modules/account/widgets/custom_text_form_field.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../controller/auth_controller.dart';
import '../controller/forgot_password_controller.dart';
import '../widget/forgot_password_dialog.dart';

class _ErrorLine extends StatelessWidget {
  final String text;
  const _ErrorLine({required this.text});
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        maxLines: null,
        overflow: TextOverflow.visible,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    final arguments = Get.arguments;
    if (arguments is String && arguments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Success',
          arguments,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is Map && args['show_forgot'] == true) {
        final forgotCtrl = Get.put(
          ForgotPasswordController(),
          permanent: false,
        );
        Get.dialog(
          ForgotPasswordDialog(controller: forgotCtrl),
          barrierDismissible: false,
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    AppAssets.appLogo,
                    color: AppColors.primaryColor,
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Login'.tr,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Log in to continue your shopping experience".tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextFormField(
                  controller: controller.emailController,
                  hint: 'Email'.tr,
                  icon: Iconsax.sms_copy,
                  keyboardType: TextInputType.emailAddress,
                  onTap: () => controller.emailError.value = '',
                  onChanged: (_) => controller.emailError.value = '',
                ),
                Obx(() => _ErrorLine(text: controller.emailError.value)),
                CustomTextFormField(
                  maxLines: 1,
                  minLines: 1,
                  controller: controller.passwordController,
                  hint: 'Password'.tr,
                  icon: Iconsax.lock_1_copy,
                  suffix: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.passwordObscure.value
                          ? controller.eyeClosedIcon
                          : controller.eyeOpenIcon,
                      size: 18,
                    ),
                  ),
                  obscure: controller.passwordObscure.value,
                  onTap: () => controller.passwordError.value = '',
                  onChanged: (_) => controller.passwordError.value = '',
                ),
                Obx(() => _ErrorLine(text: controller.passwordError.value)),
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: controller.isRemember.value,
                        onChanged: (val) =>
                            controller.isRemember.value = val ?? false,
                      ),
                    ),
                    Text(
                      "Remember me".tr,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final forgotCtrl = Get.put(
                          ForgotPasswordController(),
                          permanent: false,
                        );

                        final loginEmail = controller.emailController.text
                            .trim();
                        if (loginEmail.isNotEmpty &&
                            forgotCtrl.emailController.text.isEmpty) {
                          forgotCtrl.emailController.text = loginEmail;
                        }

                        Get.dialog(
                          ForgotPasswordDialog(controller: forgotCtrl),
                          barrierDismissible: false,
                        );
                      },
                      child: Text(
                        '${'Forgot Password'.tr} ?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Login'.tr),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                   '${'Don\'t have a CampconnectUs account yet'.tr}?',
                    style: const TextStyle(fontSize: 14),
                    ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          if (Get.isRegistered<AuthController>()) {
                            Get.delete<AuthController>();
                          }
                          Get.toNamed(AppRoutes.signupView);
                          controller.clearFieldErrors();
                          controller.resetForm();
                        },
                        child: Text(
                          'Register Here'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
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
