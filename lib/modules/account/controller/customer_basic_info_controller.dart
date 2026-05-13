import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/login_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../model/customer_basic_info.dart';

class CustomerBasicInfoController extends GetxController {
  final _repo = CustomerRepository();
  final _picker = ImagePicker();

  final _authRepo = AuthRepository();

  final avatarUrl = ''.obs;
  final name = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;

  final isLoading = false.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  String _originalName = '';
  String _originalPhoneDisplay = '';

  final pickedImagePath = ''.obs;

  final nameError = ''.obs;
  final phoneError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBasicInfo();
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> pickFromGallery() async {
    final ok = await PermissionService.I.canUseMediaOrExplain();
    if (!ok) return;
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) pickedImagePath.value = x.path;
  }

  Future<void> pickFromCamera() async {
    final ok = await PermissionService.I.canUseMediaOrExplain();
    if (!ok) return;
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x != null) pickedImagePath.value = x.path;
  }

  void clearPickedImage() => pickedImagePath.value = '';

  Future<void> fetchBasicInfo() async {
    if (!LoginService().isLoggedIn()) {
      _bindGuest();
      return;
    }

    try {
      isLoading.value = true;
      final res = await _repo.fetchBasicInfo();

      if (res.info != null) {
        _bindInfo(res.info!);
      } else if (!res.success) {
        _bindGuest();
      }
    } catch (e) {
      if (e is ApiHttpException && e.statusCode == 401) {
        _bindGuest();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _bindGuest() {
    avatarUrl.value = '';
    name.value = '';
    email.value = '';
    phone.value = '';

    nameController.text = '';
    phoneController.text = '';

    _originalName = '';
    _originalPhoneDisplay = '';
  }

  void _bindInfo(CustomerBasicInfo info) {
    avatarUrl.value = AppConfig.assetUrl(info.image);
    name.value = info.name;
    email.value = info.email;

    final displayPhone = (info.phoneWithCode?.trim().isNotEmpty ?? false)
        ? info.phoneWithCode!.trim()
        : ((info.phone?.trim().isNotEmpty ?? false) ? info.phone!.trim() : '');

    phone.value = displayPhone;

    nameController.text = info.name;
    phoneController.text = displayPhone;

    _originalName = info.name;
    _originalPhoneDisplay = displayPhone;
  }

  void _clearFieldErrors() {
    nameError.value = '';
    phoneError.value = '';
  }

  void _applyFieldErrors(Map<String, dynamic> errors) {
    String firstMsg(dynamic v) =>
        (v is List && v.isNotEmpty) ? v.first.toString() : '';
    nameError.value = firstMsg(errors['name']);
    phoneError.value = firstMsg(errors['phone']);
  }

  Future<void> saveBasicInfo() async {
    Get.snackbar('TEST', 'Button works');
  }

  void _handleException(Object e, {required String fallback}) {
    try {
      if (e is ApiHttpException) {
        final map = json.decode(e.body) as Map<String, dynamic>;
        if (map['errors'] is Map<String, dynamic>) {
          final errors = map['errors'] as Map<String, dynamic>;
          _applyFieldErrors(errors);
        } else {
          if (e.statusCode != 401) {
            Get.snackbar(
              'Failed'.tr,
              'Something went wrong'.tr,
              backgroundColor: AppColors.primaryColor,
              snackPosition: SnackPosition.TOP,
              colorText: AppColors.whiteColor,
            );
          }
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
        fallback,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
  }

  Future<void> sendForgotPasswordLink() async {
    final currentEmail = email.value.trim();

    if (currentEmail.isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'No email found for this account'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    try {
      final res = await _authRepo.forgotPassword(email: currentEmail);

      if (res.success) {
        Get.snackbar(
          'Success'.tr,
          res.message ??
              '${'Password reset link has been sent to your email'.tr} ($currentEmail)',
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      } else {
        Get.snackbar(
          'Failed'.tr,
          'Could not send password reset link'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      try {
        if (e is ApiHttpException) {
          Get.snackbar(
            'Failed'.tr,
            'Request failed'.tr,
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
      } catch (_) {
        Get.snackbar(
          'Failed'.tr,
          'Request failed'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    }
  }

  Future<void> sendResetEmailLink() async {
    final currentEmail = email.value.trim();

    if (currentEmail.isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'No email found for this account'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    try {
      final res = await _authRepo.sendEmailResetLink();

      if (res.success) {
        Get.snackbar(
          'Success'.tr,
          res.message ??
              '${'Reset email has been sent to your email'.tr} ($currentEmail)',
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      } else {
        Get.snackbar(
          'Failed'.tr,
          'Could not send reset email'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      try {
        if (e is ApiHttpException) {
          Get.snackbar(
            'Failed'.tr,
            'Request failed'.tr,
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
      } catch (_) {
        Get.snackbar(
          'Failed'.tr,
          'Request failed'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
