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
import 'modules/auth/view/password_reset_view.dart';
import 'modules/auth/view/verification_success_view.dart';

class MyApp extends StatefulWidget {
  final String initialLocaleCode;
  const MyApp({super.key, required this.initialLocaleCode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
  Widget build(BuildContext context) {
    final initialLocale = LocaleMapper.fromApiCode(widget.initialLocaleCode);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      useInheritedMediaQuery: true,
      locale: initialLocale,
      fallbackLocale: const Locale('en'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('bn'), Locale('ar', 'SA')],
      onGenerateTitle: (_) => 'app_title'.tr,
      theme: AppTheme.lightFor(initialLocale),
      darkTheme: AppTheme.darkFor(initialLocale),
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
    );
  }
}
