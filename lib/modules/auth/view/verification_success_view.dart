import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';

class VerificationSuccessView extends StatefulWidget {
  final String code;
  const VerificationSuccessView({super.key, required this.code});

  @override
  State<VerificationSuccessView> createState() => _VerificationSuccessViewState();
}

class _VerificationSuccessViewState extends State<VerificationSuccessView> {
  bool _loading = true;
  bool _success = false;
  String _message = 'Verifying your email...';

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      final api = ApiService();
      final url = '${AppConfig.baseUrl}/api/v1/ecommerce-core/auth/verify-customer-email';
      final fields = <String, String>{'identifier': widget.code};
      final json = await api.postMultipart(url, fields: fields);
      
      if (json['success'] == true) {
        setState(() {
          _success = true;
          _message = 'Email Verified!'.tr;
          _loading = false;
        });
      } else {
        setState(() {
          _success = false;
          _message = 'Email already verified or link expired.'.tr;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Something went wrong. Please try again.'.tr;
        _loading = false;
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final message = _success 
          ? 'Your email has been verified. You can now login.'.tr
          : 'Email already verified or link expired.'.tr;
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.toNamed(AppRoutes.loginView, arguments: message);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) ...[
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text('Verifying...'.tr, style: const TextStyle(fontSize: 18, color: Colors.white70)),
            ] else ...[
              Icon(
                _success ? Icons.check_circle : Icons.info_outline,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(_message, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text('Redirecting to login...'.tr, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}
