import 'dart:convert';

import '../../../core/services/follow_store_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/login_service.dart';
import '../../../core/services/passcode_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../modules/settings/view/passcode_lock_screen.dart';

class AuthController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxString dialCode = ''.obs;
  final RxString isoCode = ''.obs;
  final RxString completePhone = ''.obs;

  final isRemember = false.obs;
  final isLoading = false.obs;

  final nameError = ''.obs;
  final emailError = ''.obs;
  final phoneError = ''.obs;
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;

  final storage = LoginService();
  final _repo = AuthRepository();

  void _showSnackbar(String title, String message) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
            Text(message, style: const TextStyle(color: AppColors.whiteColor)),
          ],
        ),
      ),
    );
  }

  void clearFieldErrors() {
    nameError.value = '';
    emailError.value = '';
    phoneError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
  }

  void _applyFieldErrors(Map<String, dynamic> errors) {
    String firstMsg(dynamic v) => (v is List && v.isNotEmpty) ? v.first.toString() : '';
    nameError.value = firstMsg(errors['name']).tr;
    emailError.value = firstMsg(errors['email']).tr;
    phoneError.value = firstMsg(errors['phone']).tr;
    passwordError.value = firstMsg(errors['password']).tr;
    confirmPasswordError.value = firstMsg(errors['password_confirmation'] ?? errors['confirm_password']).tr;
  }

  String _buildValidationMessage(Map<String, dynamic> errors) {
    const order = ['name', 'email', 'phone', 'password', 'password_confirmation'];
    final lines = <String>[];
    for (final k in order) {
      final v = errors[k];
      if (v is List && v.isNotEmpty) lines.add(v.first.toString().tr);
    }
    errors.forEach((k, v) {
      if (!order.contains(k) && v is List && v.isNotEmpty) {
        lines.add(v.first.toString().tr);
      }
    });
    return lines.isEmpty ? '${'Validation failed'.tr}. ${'Please check your inputs'.tr}.' : lines.join('\n');
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _deriveLocalPhone({required String international, required String code}) {
    var p = international;
    if (code.isNotEmpty && p.startsWith(code)) {
      p = p.substring(code.length);
    }
    return _digitsOnly(p);
  }

  void setPhoneFromPicker({required String code, required String iso, required String international}) {
    Future.microtask(() {
      dialCode.value = code;
      isoCode.value = iso;
      completePhone.value = international.replaceAll(' ', '');
    });
  }

  void _handleApiException(Object e, {String? fallbackMessage}) {
    try {
      if (e is ApiHttpException) {
        final map = json.decode(e.body) as Map<String, dynamic>;
        final errors = map['errors'] is Map<String, dynamic> ? map['errors'] as Map<String, dynamic> : const <String, dynamic>{};
        if (errors.isNotEmpty) {
          _applyFieldErrors(errors);
          _showSnackbar('Validation'.tr, _buildValidationMessage(errors));
        } else {
          _showSnackbar('Failed'.tr, fallbackMessage ?? 'Request failed'.tr);
        }
      } else {
        _showSnackbar('Failed'.tr, 'Something went wrong'.tr);
      }
    } catch (_) {
      _showSnackbar('Failed'.tr, 'Something went wrong'.tr);
    }
  }

  Future<void> register() async {
    if (!isRemember.value) {
      _showSnackbar('Terms'.tr, 'You must accept the terms and conditions'.tr);
      return;
    }
    clearFieldErrors();
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final cpass = confirmPasswordController.text;
    final code = dialCode.value.trim();
    final intl = completePhone.value.trim();
    final phone = _deriveLocalPhone(international: intl, code: code);

    bool hasError = false;
    if (name.isEmpty) { nameError.value = 'Name is required'.tr; hasError = true; }
    if (email.isEmpty) { emailError.value = 'Email is required'.tr; hasError = true; }
    else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) { emailError.value = 'Please enter a valid email'.tr; hasError = true; }
    if (code.isEmpty || phone.isEmpty) { phoneError.value = 'Phone is required'.tr; hasError = true; }
    if (pass.length < 6) { passwordError.value = 'Password is too short'.tr; hasError = true; }
    if (cpass.isEmpty) { confirmPasswordError.value = 'Confirm password is required'.tr; hasError = true; }
    else if (pass != cpass) { confirmPasswordError.value = 'Passwords do not match'.tr; hasError = true; }

    if (hasError) {
      _showSnackbar('Validation'.tr, 'Please correct the highlighted fields'.tr);
      return;
    }

    try {
      isLoading.value = true;
      final res = await _repo.registerCustomer(name: name, email: email, phoneCode: code, phone: phone, phoneWithCode: intl, password: pass, passwordConfirmation: cpass);
      if (Get.context == null) return;
      if (res.success) {
        _showSnackbar('Registration successful'.tr, 'Please check your email to verify your account before logging in'.tr);
        Get.offAllNamed(AppRoutes.loginView);
      } else {
        _showSnackbar('Failed'.tr, 'Registration failed'.tr);
      }
    } catch (e) {
      if (Get.context == null) return;
      _handleApiException(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    clearFieldErrors();
    final email = emailController.text.trim();
    final pass = passwordController.text;

    bool hasError = false;
    if (email.isEmpty) { emailError.value = 'Email is required'.tr; hasError = true; }
    else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) { emailError.value = 'Please enter a valid email'.tr; hasError = true; }
    if (pass.isEmpty) { passwordError.value = 'Password is required'.tr; hasError = true; }

    if (hasError) {
      _showSnackbar('Validation'.tr, 'Please correct the highlighted fields'.tr);
      return;
    }

    try {
      isLoading.value = true;
      final loginRes = await _repo.loginCustomer(email: email, password: pass);
      if (Get.context == null) return;
      if (!loginRes.success) {
        final msg = loginRes.message ?? '';
        if (msg.toLowerCase().contains('suspend') || 
            msg.toLowerCase().contains('deactivate') ||
            msg.toLowerCase().contains('disabled') ||
            msg.toLowerCase().contains('banned') ||
            msg.toLowerCase().contains('deleted') ||
            msg.toLowerCase().contains('not found') ||
            msg.toLowerCase().contains('does not exist') ||
            msg.toLowerCase().contains('no account') ||
            msg.toLowerCase().contains('inactive')) {
          _showSnackbar('Account suspended'.tr, msg.tr);
        } else if (msg.toLowerCase().contains('verify') ||
            msg.toLowerCase().contains('not verified') ||
            msg.toLowerCase().contains('not active')) {
          _showSnackbar('Account not verified'.tr, 'Please check your email to verify your account before logging in'.tr);
        } else {
          _showSnackbar('Failed'.tr, 'Invalid email or password'.tr);
        }
        return;
      }
      storage.saveLogin(true, remember: isRemember.value);
      final followStore = FollowStore();
      followStore.clearAllFollowed();
      final token = loginRes.accessToken ?? '';
      if (token.isNotEmpty) {
        storage.saveToken(token, tokenType: loginRes.tokenType ?? 'bearer');
      }
      storage.saveLoginUser(loginRes.user);
      storage.saveDashboardContent(loginRes.dashboardContent);
      
      await PasscodeService.checkPasscodeOnServer();
      
      _showSnackbar('Success'.tr, 'Login successful'.tr);
      final args = Get.arguments is Map ? Get.arguments as Map : null;
      final redirect = args?['redirect'] as String?;
      
      if (PasscodeService.isPasscodeEnabled()) {
        Get.offAll(() => PasscodeLockScreen(
          onUnlocked: () {
            final box = GetStorage();
            box.write('_last_active_time', DateTime.now().millisecondsSinceEpoch);
            Get.offAllNamed(AppRoutes.bottomNavbarView);
            if (redirect != null && redirect.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (redirect == AppRoutes.myOrderDetailsView) {
                  final orderId = args?['order_id'];
                  Get.toNamed(redirect, arguments: {'order_id': orderId});
                } else if (redirect == AppRoutes.refundRequestDetailsView) {
                  final refundId = args?['refund_id'];
                  Get.toNamed(redirect, arguments: refundId);
                } else {
                  Get.toNamed(redirect);
                }
              });
            }
          },
        ));
        return;
      }
      
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      
      if (redirect != null && redirect.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (redirect == AppRoutes.myOrderDetailsView) {
            final orderId = args?['order_id'];
            Get.toNamed(redirect, arguments: {'order_id': orderId});
          } else if (redirect == AppRoutes.refundRequestDetailsView) {
            final refundId = args?['refund_id'];
            Get.toNamed(redirect, arguments: refundId);
          } else {
            Get.toNamed(redirect);
          }
        });
      }
    } catch (e) {
      if (Get.context == null) return;
      _handleApiException(e, fallbackMessage: 'Login failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      final followStore = FollowStore();
      followStore.clearAllFollowed();
      storage.logout();
      _showSnackbar('Logged out'.tr, 'You have been signed out'.tr);
      Get.offAllNamed(AppRoutes.bottomNavbarView);
    } catch (e) {
      _showSnackbar('Error'.tr, 'Something went wrong'.tr);
    }
  }

  Future<void> sendResetEmail() async {
    try {
      isLoading.value = true;
      final res = await _repo.sendEmailResetLink();
      if (Get.context == null) return;
      if (res.success) {
        _showSnackbar('Success'.tr, res.message ?? 'Reset email has been sent to your email address'.tr);
      } else {
        _showSnackbar('Failed'.tr, 'Could not send reset email'.tr);
      }
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Failed'.tr, 'Something went wrong'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> verifyEmailResetToken(String identifier) async {
    return await _repo.verifyResetToken(identifier);
  }

  Future<void> resetEmail({required String token, required String email}) async {
    if (email.isEmpty) {
      _showSnackbar('Required'.tr, 'Please enter your new email address'.tr);
      return;
    }
    try {
      isLoading.value = true;
      final res = await _repo.resetEmail(token: token, email: email);
      if (Get.context == null) return;
      if (res.success) {
        _showSnackbar('Success'.tr, 'Email updated successfully'.tr);
        Get.offAllNamed(AppRoutes.loginView);
      } else {
        final msg = res.message ?? '';
        if (msg.toLowerCase().contains('expired') || msg.toLowerCase().contains('invalid')) {
          _showSnackbar('Link Expired'.tr, 'This reset link has expired or is invalid. Please request a new one.'.tr);
        } else {
          _showSnackbar('Failed'.tr, msg.isNotEmpty ? msg : 'Could not update email'.tr);
        }
      }
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Failed'.tr, 'Something went wrong'.tr);
      }
    } finally {
      isLoading.value = false;
    }
  }

  final passwordObscure = true.obs;
  final confirmPasswordObscure = true.obs;
  void togglePasswordVisibility() => passwordObscure.toggle();
  void toggleConfirmPasswordVisibility() => confirmPasswordObscure.toggle();
  IconData get eyeClosedIcon => Iconsax.eye_slash_copy;
  IconData get eyeOpenIcon => Iconsax.eye_copy;

  void resetForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    dialCode.value = '';
    isoCode.value = '';
    completePhone.value = '';
    isRemember.value = false;
    clearFieldErrors();
  }
}
