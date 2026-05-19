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
  final phoneCode = ''.obs;

  final isLoading = false.obs;
  final isSendingResetLink = false.obs;
  final isSendingForgotLink = false.obs;

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

  String getPhoneNumberWithoutCode() {
    if (phone.value.isEmpty) return '';
    if (phoneCode.value.isNotEmpty && phone.value.startsWith(phoneCode.value)) {
      return phone.value.substring(phoneCode.value.length);
    }
    return phone.value;
  }

  Future<void> pickFromGallery() async {
    final ok = await PermissionService.I.canUseMediaOrExplain();
    if (!ok) return;
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) pickedImagePath.value = x.path;
  }

  Future<void> pickFromCamera() async {
    final ok = await PermissionService.I.canUseMediaOrExplain();
    if (!ok) return;
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) pickedImagePath.value = x.path;
  }

  void clearPickedImage() => pickedImagePath.value = '';

  Future<void> removeProfilePicture() async {
    if (!LoginService().isLoggedIn()) return;

    try {
      isLoading.value = true;
      String phoneToSend = _digitsOnly(phoneController.text);
      if (phoneToSend.isEmpty) phoneToSend = _digitsOnly(phone.value);
      if (phoneToSend.startsWith('234') && phoneToSend.length > 10) {
        phoneToSend = phoneToSend.substring(3);
      }

      final res = await _repo.removeProfilePicture(
        name: nameController.text.isEmpty ? name.value : nameController.text,
        phone: phoneToSend,
      );

      if (res.success) {
        pickedImagePath.value = '';
        await fetchBasicInfo();
        Get.snackbar(
          'Success',
          'Profile picture removed',
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not remove profile picture',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBasicInfo({int retryCount = 0}) async {
    if (!LoginService().isLoggedIn()) {
      _bindGuest();
      return;
    }

    try {
      isLoading.value = true;
      final res = await _repo.fetchBasicInfo();

      if (res.info != null) {
        _bindInfo(res.info!);
      } else if (!res.success && retryCount < 3) {
        await Future.delayed(Duration(milliseconds: 500));
        await fetchBasicInfo(retryCount: retryCount + 1);
        return;
      } else if (!res.success) {
        _bindGuest();
      }
    } catch (e) {
      if (e is ApiHttpException && e.statusCode == 401 && retryCount < 3) {
        await Future.delayed(Duration(milliseconds: 500));
        await fetchBasicInfo(retryCount: retryCount + 1);
        return;
      } else if (e is ApiHttpException && e.statusCode == 401) {
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
    phoneCode.value = '';
    nameController.text = '';
    phoneController.text = '';
    _originalName = '';
    _originalPhoneDisplay = '';
  }

  void _bindInfo(CustomerBasicInfo info) {
    final rawImage = info.image ?? '';
    avatarUrl.value = (rawImage.isEmpty || rawImage == '/') ? '' : AppConfig.assetUrl(rawImage);
    name.value = info.name;
    email.value = info.email;

    final fullPhone = info.phone ?? '';
    
    if (fullPhone.isNotEmpty) {
      final match = RegExp(r'^\+(\d+)').firstMatch(fullPhone);
      if (match != null) {
        phoneCode.value = '+' + match.group(1)!;
        phone.value = fullPhone;
      } else {
        phoneCode.value = info.phoneCode ?? '';
        if (phoneCode.value.isNotEmpty) {
          phone.value = '$phoneCode$fullPhone';
        } else {
          phone.value = fullPhone;
        }
      }
    } else {
      phone.value = '';
      phoneCode.value = '';
    }

    nameController.text = info.name;
    _originalName = info.name;
    _originalPhoneDisplay = phone.value;
  }

  void _clearFieldErrors() {
    nameError.value = '';
    phoneError.value = '';
  }

  void _applyFieldErrors(Map<String, dynamic> errors) {
    String firstMsg(dynamic v) => (v is List && v.isNotEmpty) ? v.first.toString() : '';
    nameError.value = firstMsg(errors['name']);
    phoneError.value = firstMsg(errors['phone']);
  }

  Future<void> saveBasicInfo() async {
    if (!LoginService().isLoggedIn()) return;

    final newName = nameController.text.trim();
    final phoneRaw = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (newName.isEmpty) {
      Get.snackbar(
        'Error',
        'Name is required',
        backgroundColor: AppColors.primaryColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      isLoading.value = true;
      final res = await _repo.updateBasicInfo(
        name: newName,
        phone: phoneRaw,
        phoneCode: phoneCode.value,
        imageFile: pickedImagePath.value.isNotEmpty ? File(pickedImagePath.value) : null,
      );

      if (res.success) {
        await fetchBasicInfo();
        pickedImagePath.value = '';
        _originalName = nameController.text.trim();
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Update failed',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      String msg = 'Update failed';
      if (e is ApiHttpException) {
        try {
          final body = json.decode(e.body);
          if (body['errors'] != null) {
            final errors = body['errors'] as Map<String, dynamic>;
            msg = errors.values.expand((v) => v is List ? v.map((x) => x.toString()) : [v.toString()]).join('\n');
          } else if (body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}
      }
      Get.snackbar(
        'Error',
        msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendForgotPasswordLink() async {
    final currentEmail = email.value.trim();
    if (currentEmail.isEmpty) {
      Get.snackbar(
        'Error',
        'No email found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    try {
      isSendingForgotLink.value = true;
      final res = await _authRepo.forgotPassword(email: currentEmail);
      if (res.success) {
        Get.snackbar(
          'Success',
          'Password reset link sent to $currentEmail',
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not send password reset link',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Request failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSendingForgotLink.value = false;
    }
  }

  Future<void> sendResetEmailLink() async {
    try {
      isSendingResetLink.value = true;
      final res = await _authRepo.sendEmailResetLink();
      if (res.success) {
        Get.snackbar(
          'Success',
          'Reset email link sent to ${email.value}',
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          res.message ?? 'Could not send reset email',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Request failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSendingResetLink.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
