import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/constants/app_assets.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/view/password_reset_view.dart';
import '../../auth/view/verification_success_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final box = GetStorage();
      final token = box.read<String>('deep_link_token') ?? '';
      final type = box.read<String>('deep_link_type') ?? '';
      if (token.isNotEmpty) {
        box.remove('deep_link_token');
        box.remove('deep_link_type');
        if (type == 'email_verify') {
          Get.offAll(() => VerificationSuccessView(code: token));
        } else {
          Get.offAll(() => PasswordResetView(token: token));
        }
        return;
      }
      Get.offAllNamed(AppRoutes.bottomNavbarView);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Image.asset(AppAssets.appLogo, width: 160, height: 160),
      ),
    );
  }
}
