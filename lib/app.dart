import 'core/routes/app_routes.dart';
import 'package:flutter/material.dart';
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

bool isLockScreenShowing = false;
bool isAppFullyInitialized = false;

class MyApp extends StatefulWidget {
  final String initialLocaleCode;
  const MyApp({super.key, required this.initialLocaleCode});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Brightness? _lastBrightness;
  late Rx<Locale> _locale;
  int _lastActiveTime = 0;
  bool _showingLockScreen = false;
  bool _skipNextResume = false;
  bool _taskSwitcherHidden = false;
  bool _appWasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final box = GetStorage();
    _lastActiveTime = box.read<int>('_last_active_time') ?? DateTime.now().millisecondsSinceEpoch;
    final savedLangCode = box.read<String>('selected_language_api_code');
    final localeCode = savedLangCode ?? widget.initialLocaleCode;
    _locale = LocaleMapper.fromApiCode(localeCode).obs;
    WidgetsBinding.instance.addPostFrameCallback((_) => LanguageService.load(localeCode));
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  @override
  void didChangePlatformBrightness() {
    final newBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_lastBrightness != newBrightness && Get.isRegistered<ThemeController>()) {
      _lastBrightness = newBrightness;
      Get.find<ThemeController>().setMode(ThemeMode.system);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appWasActive = true;
      _taskSwitcherHidden = false;
      
      if (!isAppFullyInitialized) {
        setState(() {});
        return;
      }
      
      if (_skipNextResume) {
        _skipNextResume = false;
        setState(() {});
        return;
      }

      final box = GetStorage();
      final savedLang = box.read<String>('selected_language_api_code') ?? 'en';
      LanguageService.load(savedLang);
      final locale = LocaleMapper.fromApiCode(savedLang);
      if (Get.locale?.languageCode != locale.languageCode) Get.updateLocale(locale);

      if (_showingLockScreen || isLockScreenShowing) {
        setState(() {});
        return;
      }

      if (PasscodeService.isPasscodeEnabled()) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSeconds = (now - _lastActiveTime) ~/ 1000;
        final autoLockSeconds = PasscodeService.autoLockMinutes * 60;
        
        if (autoLockSeconds == 0 || elapsedSeconds >= autoLockSeconds) {
          _showingLockScreen = true;
          isLockScreenShowing = true;
          
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
          
          Get.to(() => PasscodeLockScreen(
            onUnlocked: () {
              _lastActiveTime = DateTime.now().millisecondsSinceEpoch;
              GetStorage().write('_last_active_time', _lastActiveTime);
              _skipNextResume = true;
              Get.back();
              
              Future.delayed(const Duration(milliseconds: 300), () {
                _showingLockScreen = false;
                isLockScreenShowing = false;
              });
              
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
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Get.to(() => NotificationDetailView(item: item));
                  }
                });
              }
            },
          ));
        }
      } else {
        if (pendingNotificationData != null) {
          final data = Map<String, dynamic>.from(pendingNotificationData!);
          pendingNotificationData = null;
          final item = NotificationItem(
            id: data['notification_id']!,
            message: data['notif_message'] ?? '',
            link: '',
            time: 'Just now',
            title: (data['notif_title'] != null && data['notif_title']!.isNotEmpty) ? data['notif_title'] : null,
            image: (data['notif_image'] != null && data['notif_image']!.isNotEmpty) ? data['notif_image'] : null,
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Get.to(() => NotificationDetailView(item: item));
            }
          });
        }
        if (PushNotificationData.notificationId != null && PushNotificationData.notificationId!.isNotEmpty) {
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
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Get.to(() => NotificationDetailView(item: item));
            }
          });
        }
      }
      setState(() {});
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _skipNextResume = false;
      _lastActiveTime = DateTime.now().millisecondsSinceEpoch;
      GetStorage().write('_last_active_time', _lastActiveTime);
      
      if (_appWasActive && PasscodeService.isPasscodeEnabled() && PasscodeService.taskSwitcherPreview == 'hide' && !_showingLockScreen && !isLockScreenShowing) {
        _taskSwitcherHidden = true;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false, scrollBehavior: AppScrollBehavior(), useInheritedMediaQuery: true,
      locale: _locale.value, fallbackLocale: const Locale('en'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('de'), Locale('zh'), Locale('es'), Locale('ar'), Locale('fr'), Locale('ru'), Locale('ja'), Locale('ko'), Locale('pt'), Locale('it'), Locale('hi')],
      onGenerateTitle: (_) => 'app_title'.tr,
      theme: AppTheme.lightFor(_locale.value), darkTheme: AppTheme.darkFor(_locale.value), themeMode: ThemeMode.system,
      builder: (context, child) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
              body: child!
            ),
            if (_taskSwitcherHidden)
              Container(
                color: AppColors.primaryColor,
                child: const Center(
                  child: Icon(Icons.lock_outline, size: 60, color: Colors.white),
                ),
              ),
          ],
        );
      },
      initialBinding: InitialBindings(), initialRoute: AppRoutes.splashView, getPages: AppPages.pages,
      onGenerateRoute: (settings) {
        final rawPath = settings.name ?? ''; final uri = Uri.tryParse(rawPath);
        if (uri != null) {
          if (rawPath.contains('/password/reset')) {
            var token = uri.queryParameters['u'] ?? ''; var isEmail = false;
            if (token.contains('type=email')) { isEmail = true; token = token.replaceAll('&type=email', '').replaceAll('%26type%3Demail', ''); }
            if ((uri.queryParameters['type'] ?? '') == 'email') isEmail = true;
            return GetPageRoute(page: () => PasswordResetView(token: token, isEmailReset: isEmail), routeName: '/password-reset');
          }
          if (uri.path.contains('email-verification')) {
            return GetPageRoute(page: () => VerificationSuccessView(code: uri.queryParameters['u'] ?? ''), routeName: '/verify-email');
          }
        }
        return null;
      },
    ));
  }
}
