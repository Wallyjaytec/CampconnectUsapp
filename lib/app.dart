import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/initial_bindings.dart';
import 'core/config/app_scroll_behavior.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/locale_mapper.dart';
import 'modules/auth/view/password_reset_view.dart';
import 'modules/auth/view/verification_success_view.dart';

class MyApp extends StatelessWidget {
  final String initialLocaleCode;
  const MyApp({super.key, required this.initialLocaleCode});

  @override
  Widget build(BuildContext context) {
    final initialLocale = LocaleMapper.fromApiCode(initialLocaleCode);

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
      initialBinding: InitialBindings(),
      initialRoute: AppRoutes.splashView,
      getPages: AppPages.pages,
      onGenerateRoute: (settings) {
        final rawPath = settings.name ?? '';
        final uri = Uri.tryParse(rawPath);
        
        if (uri != null) {
          if (rawPath.contains('/password/reset')) {
            final token = uri.queryParameters['u'] ?? '';
            final isEmail = rawPath.contains('type=email') || 
                           (uri.queryParameters['type'] ?? '') == 'email';
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
