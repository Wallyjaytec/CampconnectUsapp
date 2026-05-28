import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/auth_repository.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({AuthRepository? repo})
    : _repo = repo ?? AuthRepository();

  final AuthRepository _repo;

  final emailController = TextEditingController();
  final emailError = ''.obs;
  final isLoading = false.obs;

  void clear() {
    emailController.clear();
    emailError.value = '';
  }

  void _showSnackbar(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
              ),
            ),
            Text(message, style: const TextStyle(color: AppColors.whiteColor)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyFieldErrors(Map<String, dynamic> errors) {
    final emailErrors = errors['email'];
    if (emailErrors is List && emailErrors.isNotEmpty) {
      emailError.value = emailErrors.first.toString().tr;
    }
  }

  String _buildValidationMessage(Map<String, dynamic> errors) {
    final lines = <String>[];
    final emailErrors = errors['email'];
    if (emailErrors is List && emailErrors.isNotEmpty) {
      lines.add(emailErrors.first.toString().tr);
    }
    errors.forEach((k, v) {
      if (k != 'email' && v is List && v.isNotEmpty) {
        lines.add(v.first.toString().tr);
      }
    });
    return lines.isEmpty
        ? '${'Validation failed'.tr}. ${'Please check your inputs'.tr}.'
        : lines.join('\n');
  }

  Future<void> submit(BuildContext context) async {
    emailError.value = '';

    final email = emailController.text.trim();

    if (email.isEmpty) {
      emailError.value = 'Email is required'.tr;
      _showSnackbar(context, 'Validation'.tr, 'Email is required'.tr);
      return;
    }

    try {
      isLoading.value = true;

      final res = await _repo.forgotPassword(email: email);

      if (!context.mounted) return;

      if (res.success) {
        Navigator.of(context).pop();
        _showSnackbar(
          context,
          'Success'.tr,
          res.message ??
              '${'Password reset link has been sent to your email address'.tr} ($email)',
        );
        clear();
      } else {
        if (res.firstEmailError != null) {
          emailError.value = res.firstEmailError!.tr;
          _showSnackbar(context, 'Failed'.tr, res.firstEmailError!.tr);
        } else {
          _showSnackbar(
            context,
            'Failed'.tr,
            'Password reset request failed'.tr,
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      try {
        if (e is ApiHttpException) {
          final map = json.decode(e.body) as Map<String, dynamic>;
          final errors = map['errors'] is Map<String, dynamic>
              ? map['errors'] as Map<String, dynamic>
              : const <String, dynamic>{};

          if (errors.isNotEmpty) {
            _applyFieldErrors(errors);
            _showSnackbar(
              context,
              'Validation'.tr,
              _buildValidationMessage(errors),
            );
          } else {
            _showSnackbar(context, 'Failed'.tr, 'Request failed'.tr);
          }
        } else {
          _showSnackbar(context, 'Failed'.tr, 'Something went wrong'.tr);
        }
      } catch (_) {
        if (context.mounted) {
          _showSnackbar(context, 'Failed'.tr, 'Something went wrong'.tr);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
