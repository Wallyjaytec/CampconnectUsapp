import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/constants/app_assets.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/view/password_reset_view.dart';
import '../../auth/view/verification_success_view.dart';
import '../../../core/services/network_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _slideAnimation = Tween<double>(begin: -300.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    _controller.forward();

    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted || _navigated) return;
    
    final networkService = Get.isRegistered<NetworkService>() 
        ? Get.find<NetworkService>() 
        : await Get.putAsync<NetworkService>(() => NetworkService().init());
    
    if (!networkService.isConnected.value) {
      networkService.showNoInternetDialog();
      // Listen for when internet comes back
      ever(networkService.isConnected, (connected) {
        if (connected == true && mounted && !_navigated) {
          _navigateToNext();
        }
      });
      return;
    }
    
    _navigateToNext();
  }

  void _navigateToNext() {
    if (_navigated) return;
    _navigated = true;
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
