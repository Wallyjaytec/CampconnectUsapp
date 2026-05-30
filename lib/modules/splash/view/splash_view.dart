import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/constants/app_assets.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/login_service.dart';
import 'package:kartly_e_commerce/main.dart';
import 'package:kartly_e_commerce/modules/account/model/notification_model.dart';
import 'package:kartly_e_commerce/modules/account/view/notification_detail_view.dart';
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
  bool _navigated = false;

  bool get isLoggedIn => (LoginService().token ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _slideAnimation = Tween<double>(begin: -300.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();

      Timer(const Duration(seconds: 3), () {
        if (!mounted || _navigated) return;
        _checkPushAndNavigate(attempts: 0);
      });
    });
  }

  void _checkPushAndNavigate({int attempts = 0}) {
    if (!mounted || _navigated) return;

    // Check global cache from cold start first
    if (pendingNotificationData != null) {
      final data = pendingNotificationData!;
      pendingNotificationData = null;
      
      _navigated = true;
      final item = NotificationItem(
        id: data['notification_id']!,
        message: data['notif_message'] ?? '',
        link: '',
        time: 'Just now',
        title: (data['notif_title'] != null && data['notif_title']!.isNotEmpty) ? data['notif_title'] : null,
        image: (data['notif_image'] != null && data['notif_image']!.isNotEmpty) ? data['notif_image'] : null,
      );
      
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Get.to(() => NotificationDetailView(item: item));
      return;
    }
    
    if (PushNotificationData.notificationId != null && PushNotificationData.notificationId!.isNotEmpty) {
      _navigated = true;
      final item = NotificationItem(
        id: PushNotificationData.notificationId!,
        message: PushNotificationData.message ?? '',
        link: '',
        time: 'Just now',
        title: (PushNotificationData.title != null && PushNotificationData.title!.isNotEmpty) ? PushNotificationData.title : null,
        image: (PushNotificationData.image != null && PushNotificationData.image!.isNotEmpty) ? PushNotificationData.image : null,
      );
      
      PushNotificationData.notificationId = null;
      PushNotificationData.message = null;
      PushNotificationData.title = null;
      PushNotificationData.image = null;
      
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Get.to(() => NotificationDetailView(item: item));
      return;
    }
    
    if (attempts > 10) {
      _navigated = true;
      _navigateNormally();
      return;
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkPushAndNavigate(attempts: attempts + 1);
    });
  }

  void _navigateNormally() {
    final box = GetStorage();
    
    final refundId = box.read<int>('deep_link_refund_id') ?? 0;
    if (refundId > 0) {
      box.remove('deep_link_refund_id');
      if (!isLoggedIn) {
        Get.offAllNamed(AppRoutes.bottomNavbarView);
        Future.delayed(const Duration(milliseconds: 200), () {
          Get.toNamed(AppRoutes.loginView, arguments: {'redirect': AppRoutes.refundRequestDetailsView, 'refund_id': refundId});
        });
        return;
      }
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Get.toNamed(AppRoutes.refundRequestDetailsView, arguments: refundId);
      return;
    }
    
    final orderId = box.read<int>('deep_link_order_id') ?? 0;
    if (orderId > 0) {
      box.remove('deep_link_order_id');
      if (!isLoggedIn) {
        Get.offAllNamed(AppRoutes.bottomNavbarView);
        Future.delayed(const Duration(milliseconds: 200), () {
          Get.toNamed(AppRoutes.loginView, arguments: {'redirect': AppRoutes.myOrderDetailsView, 'order_id': orderId});
        });
        return;
      }
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Get.toNamed(AppRoutes.myOrderDetailsView, arguments: {'order_id': orderId});
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
    
    final onboardingComplete = box.read<bool>('onboarding_done') ?? false;
    final languageSelected = box.read<bool>('language_selected') ?? false;
    final countrySelected = box.read<bool>('country_selected') ?? false;
    final currencySelected = box.read<bool>('currency_selected') ?? false;
    
    if (!onboardingComplete || !languageSelected || !countrySelected || !currencySelected) {
      Get.offAllNamed(AppRoutes.languageSelect);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(offset: Offset(_slideAnimation.value, 0), child: Opacity(opacity: _fadeAnimation.value, child: child)),
              child: SizedBox(width: 160, height: 160, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain))),
            ),
            const SizedBox(height: 20),
            Text(
              'Push: ${pendingNotificationData?['notification_id'] ?? PushNotificationData.notificationId ?? "null"}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
