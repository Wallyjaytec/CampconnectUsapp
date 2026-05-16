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
  final phoneCode = '+234'.obs;

  final isLoading = false.obs;
  final isSendingResetLink = false.obs;

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
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Profile picture removed'), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Could not remove profile picture'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Something went wrong'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      isLoading.value = false;
    }
  }

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
    phoneCode.value = '+234';

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

    phoneCode.value = info.phoneCode ?? '+234';
    final phoneOnly = info.phone ?? '';
    phone.value = '${phoneCode.value}$phoneOnly';

    nameController.text = info.name;
    phoneController.text = phoneOnly;

    _originalName = info.name;
    _originalPhoneDisplay = phone.value;
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
    if (!LoginService().isLoggedIn()) return;

    final newName = nameController.text.trim();
    final phoneRaw = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (newName.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Name is required'), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating),
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
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Update failed'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendForgotPasswordLink() async {
    final currentEmail = email.value.trim();
    if (currentEmail.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('No email found'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    try {
      final res = await _authRepo.forgotPassword(email: currentEmail);
      if (res.success) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Password reset link sent'), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text('Could not send password reset link'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Request failed'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> sendResetEmailLink() async {
    try {
      isSendingResetLink.value = true;
      print('Sending reset email link to: ${email.value}');
      final res = await _authRepo.sendEmailResetLink();
      print('Response success: ${res.success}, message: ${res.message}');
      if (res.success) {
        Get.snackbar('Success', 'Reset email link sent to ${email.value}',
          backgroundColor: AppColors.primaryColor, colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      } else {
        Get.snackbar('Failed', res.message ?? 'Could not send reset email',
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      print('Error: $e');
      Get.snackbar('Failed', 'Request failed',
        backgroundColor: Colors.red, colorText: Colors.white,
        snackPosition: SnackPosition.TOP);
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
