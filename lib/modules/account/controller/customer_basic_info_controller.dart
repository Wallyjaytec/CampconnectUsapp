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
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('Profile picture removed'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('Could not remove profile picture'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Something went wrong'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
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

  Future<void> saveBasicInfo() async {
    if (!LoginService().isLoggedIn()) return;

    final newName = nameController.text.trim();
    final phoneRaw = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (newName.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Name is required'.tr),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
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
          SnackBar(
            content: Text('Profile updated successfully'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('Update failed'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      String msg = 'Update failed'.tr;
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
        SnackBar(
          content: Text(msg.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendForgotPasswordLink() async {
    final currentEmail = email.value.trim();
    if (currentEmail.isEmpty) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('No email found'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    try {
      isSendingForgotLink.value = true;
      final res = await _authRepo.forgotPassword(email: currentEmail);
      if (res.success) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('${'Password reset link sent to'.tr} $currentEmail'),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('Could not send password reset link'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Request failed'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
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
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('${'Reset email link sent to'.tr} ${email.value}'),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Could not send reset email'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Request failed'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
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
