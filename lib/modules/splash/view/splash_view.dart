import 'dart:async';

import 'package:kartly_e_commerce/core/constants/app_assets.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/view/password_reset_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _slideAnimation = Tween<double>(begin: -300.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      final token = Get.parameters['u'] ?? '';
      if (token.isNotEmpty) {
        Get.offAll(() => PasswordResetView(token: token));
        return;
      }
      
      Get.offAllNamed(AppRoutes.bottomNavbarView);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_slideAnimation.value, 0),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 160,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
