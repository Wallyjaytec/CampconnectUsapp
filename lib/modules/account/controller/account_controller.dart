import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';

import '../../../core/controllers/currency_controller.dart';

class AccountController extends GetxController {
  var username = "John Doe".obs;
  var email = "johndoe@gmail.com".obs;
  var phone = "+880 1234 567890".obs;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: username.value);
    emailController = TextEditingController(text: email.value);
    phoneController = TextEditingController(text: phone.value);
    passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<CurrencyController>()) {
        await Get.find<CurrencyController>().fetchCurrencies(force: true);
      }
    });
  }

  void updateProfile() {
    username.value = nameController.text;
    email.value = emailController.text;
    phone.value = phoneController.text;

    Get.back();
    Get.snackbar(
      "Success".tr,
      "Profile updated successfully".tr,
      backgroundColor: AppColors.primaryColor,
      colorText: AppColors.whiteColor,
    );
  }

  var orderCount = 12.obs;
  var wishlistCount = 5.obs;
  var cartCount = 3.obs;

  void logout() {
    Get.snackbar(
      "Logout".tr,
      "You have been logged out".tr,
      backgroundColor: AppColors.primaryColor,
      snackPosition: SnackPosition.TOP,
      colorText: AppColors.whiteColor,
    );
  }
}
