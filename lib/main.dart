import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:kartly_e_commerce/core/controllers/currency_controller.dart';
import 'package:kartly_e_commerce/core/controllers/language_controller.dart';
import 'package:kartly_e_commerce/core/controllers/theme_controller.dart';
import 'package:kartly_e_commerce/core/services/currency_service.dart';
import 'package:kartly_e_commerce/data/repositories/site_settings_properties_repository.dart';
import 'package:kartly_e_commerce/modules/auth/controller/auth_controller.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';
import 'core/services/language_service.dart';
import 'core/services/network_service.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/product_repository.dart';
import 'modules/account/controller/notifications_controller.dart';
import 'modules/category/controller/category_controller.dart';
import 'modules/product/controller/cart_controller.dart';
import 'modules/product/controller/new_product_list_controller.dart';

final _appLinks = AppLinks();

Future<void> initServices() async {
  await Get.putAsync<NetworkService>(() async => NetworkService().init());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FIX: Show app immediately so splash screen doesn't get stuck when no internet
  runApp(MyApp(initialLocaleCode: 'en'));
  
  OneSignal.initialize("d254c403-bcbb-494d-8920-5f49ecf67de7");
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshList();
    }
  });
  
  OneSignal.Notifications.addClickListener((event) {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshList();
    }
  });
  
  await initServices();
  await GetStorage.init();
  Get.put(ThemeController(), permanent: true);
  Get.put(LanguageController(SiteSettingsPropertiesRepository(ApiService())), permanent: true);
  final siteRepo = SiteSettingsPropertiesRepository(ApiService());
  final currencyService = CurrencyService(siteRepo);
  Get.put<CurrencyService>(currencyService, permanent: true);
  Get.put<CurrencyController>(CurrencyController(siteRepo, currencyService), permanent: true);
  Get.put<NotificationController>(NotificationController(), permanent: true);
  Get.put(CategoryController(CategoryRepository(ApiService())));
  Get.put<NewProductListController>(NewProductListController(ProductRepository(ApiService())), permanent: true);
  Get.put(CartRepository(ApiService()), permanent: true);
  Get.put<CartController>(CartController(CartRepository(ApiService())), permanent: true);
  Get.put(AuthController(), permanent: true);

  final box = GetStorage();
  final savedApiCode = box.read<String>(AppConfig.kLangCode) ?? 'en';
  await LanguageService.load(savedApiCode);

  try {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      final token = uri.queryParameters['u'] ?? '';
      if (token.isNotEmpty) {
        box.write('deep_link_token', token);
        String type = 'password_reset';
        if (uri.path.contains('email-verification')) {
          type = 'email_verify';
        }
        box.write('deep_link_type', type);
      }
    }
  } catch (_) {}

  _appLinks.uriLinkStream.listen((uri) {
    final token = uri.queryParameters['u'] ?? '';
    if (token.isNotEmpty) {
      box.write('deep_link_token', token);
      String type = 'password_reset';
      if (uri.path.contains('email-verification')) {
        type = 'email_verify';
      }
      box.write('deep_link_type', type);
    }
  });

  // FIX: runApp removed from here - already called at the top
}
