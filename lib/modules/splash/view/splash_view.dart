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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _slideAnimation = Tween<double>(begin: -300.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();

      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        final box = GetStorage();
        
        // Handle order deep link first
        final orderId = box.read<int>('deep_link_order_id') ?? 0;
        if (orderId > 0) {
          box.remove('deep_link_order_id');
          Get.offAllNamed(AppRoutes.myOrderDetailsView, arguments: {'order_id': orderId});
          return;
        }
        
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
        
        // Check if onboarding is complete
        final onboardingComplete = box.read<bool>('onboarding_done') ?? false;
        
        // Check individual steps
        final languageSelected = box.read<bool>('language_selected') ?? false;
        final countrySelected = box.read<bool>('country_selected') ?? false;
        final currencySelected = box.read<bool>('currency_selected') ?? false;
        
        // If onboarding not complete OR missing any step, show language selection
        if (!onboardingComplete || !languageSelected || !countrySelected || !currencySelected) {
          Get.offAllNamed(AppRoutes.languageSelect);
          return;
        }
        
        // All onboarding done, go to homepage
        Get.offAllNamed(AppRoutes.bottomNavbarView);
      });
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(offset: Offset(_slideAnimation.value, 0), child: Opacity(opacity: _fadeAnimation.value, child: child)),
          child: SizedBox(width: 160, height: 160, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain))),
        ),
      ),
    );
  }
}
