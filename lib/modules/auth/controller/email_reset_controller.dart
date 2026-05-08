import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/utils/dialog_utils.dart';

class EmailResetController extends GetxController {
  EmailResetController({AuthRepository? repo})
    : _repo = repo ?? AuthRepository();

  final AuthRepository _repo;

  final emailController = TextEditingController();
  final emailError = ''.obs;
  final isLoading = false.obs;

  void clear() {
    emailController.clear();
    emailError.value = '';
  }

  void _applyFieldErrors(Map<String, dynamic> errors) {
    final emailErrors = errors['email'];
    if (emailErrors is List && emailErrors.isNotEmpty) {
      emailError.value = emailErrors.first.toString();
    }
  }

  String _buildValidationMessage(Map<String, dynamic> errors) {
    final lines = <String>[];
    final emailErrors = errors['email'];
    if (emailErrors is List && emailErrors.isNotEmpty) {
      lines.add(emailErrors.first.toString());
    }
    errors.forEach((k, v) {
      if (k != 'email' && v is List && v.isNotEmpty) {
        lines.add(v.first.toString());
      }
    });
    return lines.isEmpty
        ? '${'Validation failed'.tr}. ${'Please check your inputs'.tr}.'
        : lines.join('\n');
  }

  Future<void> submit() async {
    emailError.value = '';

    final email = emailController.text.trim();

    if (email.isEmpty) {
      emailError.value = 'Email is required'.tr;
      Get.snackbar(
        'Validation'.tr,
        'Email is required'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    try {
      isLoading.value = true;

      final res = await _repo.sendEmailResetLink();

      if (res.success) {
        safeBack();
        clear();
        Get.snackbar(
          'Success'.tr,
          res.message ??
              'Email reset link has been sent to your email address'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      } else {
        final firstEmailError = res.firstEmailError;
        if (firstEmailError != null) {
          emailError.value = firstEmailError;
          Get.snackbar(
            'Failed'.tr,
            firstEmailError,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        } else {
          Get.snackbar(
            'Failed'.tr,
            'Email reset request failed'.tr,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        }
      }
    } catch (e) {
      try {
        if (e is ApiHttpException) {
          final map = json.decode(e.body) as Map<String, dynamic>;
          final errors = map['errors'] is Map<String, dynamic>
              ? map['errors'] as Map<String, dynamic>
              : const <String, dynamic>{};

          if (errors.isNotEmpty) {
            _applyFieldErrors(errors);
            Get.snackbar(
              'Validation'.tr,
              _buildValidationMessage(errors),
              backgroundColor: AppColors.primaryColor,
              snackPosition: SnackPosition.TOP,
              colorText: AppColors.whiteColor,
            );
          } else {
            Get.snackbar(
              'Failed'.tr,
              'Request failed'.tr,
              backgroundColor: AppColors.primaryColor,
              snackPosition: SnackPosition.TOP,
              colorText: AppColors.whiteColor,
            );
          }
        } else {
          Get.snackbar(
            'Failed'.tr,
            'Something went wrong'.tr,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        }
      } catch (_) {
        Get.snackbar(
          'Failed'.tr,
          'Something went wrong'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
