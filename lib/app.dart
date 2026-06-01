import 'core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/initial_bindings.dart';
import 'core/config/app_scroll_behavior.dart';
import 'core/constants/app_colors.dart';
import 'core/controllers/theme_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/locale_mapper.dart';
import 'core/services/language_service.dart';
import 'core/services/passcode_service.dart';
import 'main.dart';
import 'modules/account/model/notification_model.dart';
import 'modules/account/view/notification_detail_view.dart';
import 'modules/auth/view/password_reset_view.dart';
import 'modules/auth/view/verification_success_view.dart';
import 'modules/settings/view/passcode_lock_screen.dart';

class MyApp extends StatefulWidget {
  final String initialLocaleCode;
  const MyApp({super.key, required this.initialLocaleCode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Brightness? _lastBrightness;
  late Rx<Locale> _locale;
  bool _showingLockScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final savedLangCode = GetStorage().read<String>('selected_language_api_code');
    final localeCode = savedLangCode ?? widget.initialLocaleCode;
    _locale = LocaleMapper.fromApiCode(localeCode).obs;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LanguageService.load(localeCode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final newBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_lastBrightness != newBrightness) {
      _lastBrightness = newBrightness;
      if (Get.isRegistered<ThemeController>()) {
        Get.find<ThemeController>().setMode(ThemeMode.system);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final box = GetStorage();
      final savedLang = box.read<String>('selected_language_api_code') ?? 'en';
      LanguageService.load(savedLang);
      final locale = LocaleMapper.fromApiCode(savedLang);
      if (Get.locale?.languageCode != locale.languageCode) {
        Get.updateLocale(locale);
      }

      if (_showingLockScreen) {
        return;
      }

      if (PasscodeService.isPasscodeEnabled) {
        final storedTime = box.read<int>('_last_active_time');
        final now = DateTime.now().millisecondsSinceEpoch;
        
        bool shouldLock = false;
        
        if (storedTime == null) {
          shouldLock = (PasscodeService.autoLockMinutes == 0);
        } else {
          final elapsedSeconds = (now - storedTime) ~/ 1000;
          final autoLockSeconds = PasscodeService.autoLockMinutes * 60;
          shouldLock = (autoLockSeconds == 0 || elapsedSeconds >= autoLockSeconds);
        }

        if (shouldLock) {
          _showingLockScreen = true;
          
          Map<String, dynamic>? savedNotification;
          if (pendingNotificationData != null) {
            savedNotification = Map<String, dynamic>.from(pendingNotificationData!);
            pendingNotificationData = null;
          }
          if (PushNotificationData.notificationId != null && PushNotificationData.notificationId!.isNotEmpty) {
            savedNotification = {
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
          
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_showingLockScreen) {
              Get.offAll(() => PasscodeLockScreen(
                onUnlocked: () {
                  _showingLockScreen = false;
                  
                  if (savedNotification != null) {
                    final data = savedNotification;
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
                    Get.offAllNamed(AppRoutes.bottomNavbarView);
                  }
                },
              ));
            }
          });
          return;
        }
      }
      
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (!_showingLockScreen) {
        GetStorage().write('_last_active_time', DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      useInheritedMediaQuery: true,
      locale: _locale.value,
      fallbackLocale: const Locale('en'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en'), Locale('de'), Locale('zh'), Locale('es'),
        Locale('ar'), Locale('fr'), Locale('ru'), Locale('ja'),
        Locale('ko'), Locale('pt'), Locale('it'), Locale('hi'),
      ],
      onGenerateTitle: (_) => 'app_title'.tr,
      theme: AppTheme.lightFor(_locale.value),
      darkTheme: AppTheme.darkFor(_locale.value),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: child!,
        );
      },
      initialBinding: InitialBindings(),
      initialRoute: AppRoutes.splashView,
      getPages: AppPages.pages,
      onGenerateRoute: (settings) {
        final rawPath = settings.name ?? '';
        final uri = Uri.tryParse(rawPath);

        if (uri != null) {
          if (rawPath.contains('/password/reset')) {
            var token = uri.queryParameters['u'] ?? '';
            var isEmail = false;

            if (token.contains('type=email')) {
              isEmail = true;
              token = token.replaceAll('&type=email', '').replaceAll('%26type%3Demail', '');
            }
            if ((uri.queryParameters['type'] ?? '') == 'email') {
              isEmail = true;
            }

            return GetPageRoute(
              page: () => PasswordResetView(token: token, isEmailReset: isEmail),
              routeName: '/password-reset',
            );
          }
          if (uri.path.contains('email-verification')) {
            final code = uri.queryParameters['u'] ?? '';
            return GetPageRoute(
              page: () => VerificationSuccessView(code: code),
              routeName: '/verify-email',
            );
          }
        }
        return null;
      },
    ));
  }
}
