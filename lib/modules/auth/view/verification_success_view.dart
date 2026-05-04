import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';

class VerificationSuccessView extends StatelessWidget {
  final String code;
  const VerificationSuccessView({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        Get.offAllNamed(AppRoutes.loginView);
        Get.snackbar(
          'Email Verified',
          'Your email has been verified successfully. You can now login.',
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
        );
      });
    });

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('Email Verified!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10),
            Text('Redirecting to login...', style: TextStyle(fontSize: 16, color: Colors.white70)),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
