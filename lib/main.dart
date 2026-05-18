import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  
  // Initialize OneSignal
  OneSignal.initialize("d254c403-bcbb-494d-8920-5f49ecf67de7");
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('Notification received in foreground');
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshList();
    }
  });
  
  OneSignal.Notifications.addClickListener((event) {
    print('Notification clicked');
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

  // Get initial deep link
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

  // Run the app first
  runApp(MyApp(initialLocaleCode: savedApiCode));
  
  // Then check internet and show dialog after app is running
  Future.delayed(Duration(seconds: 1), () async {
    final results = await Connectivity().checkConnectivity();
    final hasInternet = results.any((r) => r != ConnectivityResult.none);
    
    if (!hasInternet) {
      Get.dialog(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.red),
                SizedBox(width: 10),
                Text('No Internet Connection'),
              ],
            ),
            content: const Text('Please check your Wi-Fi or mobile data.'),
            actions: [
              TextButton(
                onPressed: () async {
                  final newResults = await Connectivity().checkConnectivity();
                  final newHas = newResults.any((r) => r != ConnectivityResult.none);
                  if (newHas) {
                    if (Get.isDialogOpen == true) Get.back();
                    Get.forceAppUpdate();
                  } else {
                    Get.snackbar('No Internet', 'Still no connection',
                        backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    }
  });
}
