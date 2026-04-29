import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/contact_repository.dart';
import '../model/contact_message_model.dart';

class ContactController extends GetxController {
  final ContactRepository _repository;

  ContactController({required ContactRepository repository})
    : _repository = repository;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  Future<void> submitContactForm() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        'Name Required'.tr,
        'Please enter your name'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (email.isEmpty) {
      Get.snackbar(
        'Email Required'.tr,
        'Please enter your email'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailReg.hasMatch(email)) {
      Get.snackbar(
        'Invalid Email'.tr,
        'Please enter a valid email'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (subject.isEmpty) {
      Get.snackbar(
        'Subject Required'.tr,
        'Please enter a subject'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (message.isEmpty) {
      Get.snackbar(
        'Message Required'.tr,
        'Please enter your message'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (message.length < 10) {
      Get.snackbar(
        'Message Too Short'.tr,
        'Message should be at least 10 characters'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    isLoading.value = true;

    try {
      final ContactMessageResponse response = await _repository
          .sendContactMessage(
            name: name,
            email: email,
            subject: subject,
            message: message,
          );

      if (response.success) {
        Get.snackbar(
          'Success'.tr,
          response.message ?? 'Your message has been sent successfully'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );

        nameController.clear();
        emailController.clear();
        subjectController.clear();
        messageController.clear();
      } else {
        Get.snackbar(
          'Failed'.tr,
          '${'Failed to send your message'.tr}. ${'Please try again'.tr}.',
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
