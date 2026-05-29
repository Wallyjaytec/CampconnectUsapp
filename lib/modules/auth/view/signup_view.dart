import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/modules/account/widgets/custom_text_form_field.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../core/routes/app_routes.dart';
import '../controller/auth_controller.dart';

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

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  IsoCode _getSavedIsoCode() {
    final box = GetStorage();
    final code = box.read<String>('selected_country_code') ?? 'NG';
    try {
      return IsoCode.values.firstWhere((e) => e.name == code);
    } catch (_) {
      return IsoCode.NG;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.transparentColor,
          leadingWidth: 44,
          titleSpacing: 0,
          leading: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () {
                controller.clearFieldErrors();
                controller.resetForm();
                Get.back();
              },
              icon: const Icon(
                Iconsax.arrow_left_2_copy,
                size: 20,
                color: AppColors.greyColor,
              ),
              splashRadius: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Registration".tr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Set up your account to continue your shopping experience".tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                CustomTextFormField(
                  controller: controller.nameController,
                  hint: "Full Name".tr,
                  icon: Iconsax.user_copy,
                  onTap: () => controller.nameError.value = '',
                  onChanged: (_) => controller.nameError.value = '',
                ),
                Obx(() => _ErrorLine(text: controller.nameError.value)),
                CustomTextFormField(
                  controller: controller.emailController,
                  hint: "Email".tr,
                  icon: Iconsax.sms_copy,
                  keyboardType: TextInputType.emailAddress,
                  onTap: () => controller.emailError.value = '',
                  onChanged: (_) => controller.emailError.value = '',
                ),
                Obx(() => _ErrorLine(text: controller.emailError.value)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (hasFocus) controller.phoneError.value = '';
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardColor
                              : AppColors.lightCardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: PhoneFormField(
                            initialValue: PhoneNumber(
                              isoCode: _getSavedIsoCode(),
                              nsn: '',
                            ),
                            countrySelectorNavigator:
                                const CountrySelectorNavigator.page(),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkCardColor
                                  : AppColors.lightCardColor,
                              hintText: "Phone number".tr,
                              contentPadding: EdgeInsets.zero,
                              errorStyle: const TextStyle(
                                height: 0,
                                fontSize: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16, height: 1.2),
                            onChanged: (p) {
                              controller.phoneError.value = '';
                              controller.setPhoneFromPicker(
                                code: '+${p.countryCode}',
                                iso: p.isoCode.name,
                                international: p.international,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Obx(() => _ErrorLine(text: controller.phoneError.value)),
                  ],
                ),
                CustomTextFormField(
                  maxLines: 1,
                  controller: controller.passwordController,
                  hint: "Password".tr,
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
                CustomTextFormField(
                  maxLines: 1,
                  controller: controller.confirmPasswordController,
                  hint: "Confirm password".tr,
                  icon: Iconsax.lock_1_copy,
                  suffix: IconButton(
                    onPressed: controller.toggleConfirmPasswordVisibility,
                    icon: Icon(
                      controller.confirmPasswordObscure.value
                          ? controller.eyeClosedIcon
                          : controller.eyeOpenIcon,
                      size: 18,
                    ),
                  ),
                  obscure: controller.confirmPasswordObscure.value,
                  onTap: () => controller.confirmPasswordError.value = '',
                  onChanged: (_) =>
                      controller.confirmPasswordError.value = '',
                ),
                Obx(
                  () => _ErrorLine(text: controller.confirmPasswordError.value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: controller.isRemember.value,
                        onChanged: (v) =>
                            controller.isRemember.value = v ?? false,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "I have read and agree to the terms and conditions".tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          (!controller.isRemember.value ||
                              controller.isLoading.value)
                          ? null
                          : controller.register,
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
                          : Text("Register".tr),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${'Already have an account'.tr}?",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        controller.clearFieldErrors();
                        controller.resetForm();
                        Get.toNamed(AppRoutes.loginView);
                      },
                      child: Text(
                        "Login".tr,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
