import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:campconnectus_marketplace/core/constants/app_assets.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/core/services/login_service.dart';
import 'package:campconnectus_marketplace/core/services/passcode_service.dart';
import 'package:campconnectus_marketplace/main.dart';
import 'package:campconnectus_marketplace/modules/account/model/notification_model.dart';
import 'package:campconnectus_marketplace/modules/account/view/notification_detail_view.dart';
import 'package:campconnectus_marketplace/modules/bottom_navbar/controller/bottom_navbar_controller.dart';
import 'package:campconnectus_marketplace/modules/settings/view/passcode_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:campconnectus_marketplace/app.dart';
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
  Map<String, dynamic>? _pendingNotificationData;

  bool get isLoggedIn => (LoginService().token ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _slideAnimation = Tween<double>(begin: -300.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      try {
        const skipChannel = MethodChannel('com.campconnectus.store/skip_splash');
        final dest = await skipChannel.invokeMethod<String>('shouldSkip');
        if (dest != null && dest.isNotEmpty) {
          final box = GetStorage();

          final onboardingDone = box.read<bool>('onboarding_done') ?? false;
          final languageSelected = box.read<bool>('language_selected') ?? false;
          final countrySelected = box.read<bool>('country_selected') ?? false;
          final currencySelected = box.read<bool>('currency_selected') ?? false;

          if (!onboardingDone || !languageSelected || !countrySelected || !currencySelected) {
            _controller.forward();
            _checkLockAndNavigate();
            return;
          }

          box.write('shortcut_destination', dest);
          _controller.value = 1.0;
          _navigated = true;
          _navigateNormally();
          return;
        }
      } catch (_) {}

      _controller.forward();
      _checkLockAndNavigate();
    });
  }

  void _checkLockAndNavigate() async {
    if (_navigated) return;

    bool hasPasscode = false;
    if (isLoggedIn) {
      hasPasscode = await PasscodeService.checkPasscodeOnServer();
    }

    if (hasPasscode) {
      _navigated = true;
      isLockScreenShowing = true;

      if (pendingNotificationData != null) {
        _pendingNotificationData = Map<String, dynamic>.from(pendingNotificationData!);
        pendingNotificationData = null;
      }
      if (PushNotificationData.notificationId != null && PushNotificationData.notificationId!.isNotEmpty) {
        _pendingNotificationData = {
          'notification_id': PushNotificationData.notificationId,
          'notif_message': PushNotificationData.message ?? '',
          'notif_title': PushNotificationData.title ?? '',
          'notif_image': PushNotificationData.image ?? '',
        };
        PushNotificationData.notificationId = null;
        PushNotificationData.message = null;
        PushNotificationData.title = null;
        PushNotificationData.image = null;
      }

      Get.offAll(() => PasscodeLockScreen(
        onUnlocked: () {
          isLockScreenShowing = false;
          final box = GetStorage();
          box.write('_last_active_time', DateTime.now().millisecondsSinceEpoch);

          if (_pendingNotificationData != null) {
            final data = _pendingNotificationData!;
            _pendingNotificationData = null;
            final item = NotificationItem(
              id: data['notification_id']!,
              message: data['notif_message'] ?? '',
              link: '',
              time: 'Just now',
              title: (data['notif_title'] != null && data['notif_title']!.isNotEmpty) ? data['notif_title'] : null,
              image: (data['notif_image'] != null && data['notif_image']!.isNotEmpty) ? data['notif_image'] : null,
            );
            Get.offAllNamed(AppRoutes.bottomNavbarView);
            Future.delayed(const Duration(milliseconds: 300), () {
              Get.to(() => NotificationDetailView(item: item));
            });
          } else {
            _navigateNormally();
          }
        },
      ));
      return;
    }

    Timer(const Duration(seconds: 3), () {
      if (!mounted || _navigated) return;
      _checkPushAndNavigate(attempts: 0);
    });
  }

  void _checkPushAndNavigate({int attempts = 0}) {
    if (!mounted || _navigated) return;

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

    if (attempts > 3) {
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

    final onboardingComplete = box.read<bool>('onboarding_done') ?? false;
    final languageSelected = box.read<bool>('language_selected') ?? false;
    final countrySelected = box.read<bool>('country_selected') ?? false;
    final currencySelected = box.read<bool>('currency_selected') ?? false;

    if (!onboardingComplete || !languageSelected || !countrySelected || !currencySelected) {
      Get.offAllNamed(AppRoutes.languageSelect);
      return;
    }

    final shortcutDest = box.read<String>('shortcut_destination') ?? '';
    if (shortcutDest.isNotEmpty) {
      box.remove('shortcut_destination');
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Future.delayed(const Duration(milliseconds: 300), () {
        switch (shortcutDest) {
          case 'search':
            Get.toNamed(AppRoutes.searchView);
            break;
          case 'orders':
            Get.toNamed(AppRoutes.myOrderListView);
            break;
          case 'cart':
            Get.toNamed(AppRoutes.cartView);
            break;
          case 'wallet':
            Get.toNamed(AppRoutes.myWalletView);
            break;
          case 'account':
            if (Get.isRegistered<BottomNavbarController>()) {
              Get.find<BottomNavbarController>().currentIndex.value = 4;
            }
            break;
          case 'notifications':
            Get.toNamed(AppRoutes.notificationsView);
            break;
          case 'refunds':
            Get.toNamed(AppRoutes.refundRequestListView);
            break;
        }
      });
      return;
    }

    if (!isLoggedIn) {
      final onboardingComplete = box.read<bool>('onboarding_done') ?? false;
      if (!onboardingComplete) {
        Get.offAllNamed(AppRoutes.languageSelect);
      } else {
        Get.offAllNamed(AppRoutes.bottomNavbarView);
      }
      return;
    }

    final walletLink = box.read<bool>('deep_link_wallet') ?? false;
    if (walletLink) {
      box.remove('deep_link_wallet');
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.toNamed(AppRoutes.myWalletView);
      });
      return;
    }

    final refundId = box.read<int>('deep_link_refund_id') ?? 0;
    if (refundId > 0) {
      box.remove('deep_link_refund_id');
      Get.offAllNamed(AppRoutes.bottomNavbarView);
      Get.toNamed(AppRoutes.refundRequestDetailsView, arguments: refundId);
      return;
    }

    final orderId = box.read<int>('deep_link_order_id') ?? 0;
    if (orderId > 0) {
      box.remove('deep_link_order_id');
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

    if (!onboardingComplete || !languageSelected || !countrySelected || !currencySelected) {
      Get.offAllNamed(AppRoutes.languageSelect);
      return;
    }

    Get.offAllNamed(AppRoutes.bottomNavbarView);
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
          builder: (context, child) => Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: Opacity(opacity: _fadeAnimation.value, child: child)),
          child: SizedBox(
            width: 160,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain))),
        ),
      ),
    );
  }
}
