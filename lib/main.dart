import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:kartly_e_commerce/core/controllers/currency_controller.dart';
import 'package:kartly_e_commerce/core/controllers/language_controller.dart';
import 'package:kartly_e_commerce/core/controllers/theme_controller.dart';
import 'package:kartly_e_commerce/core/services/currency_service.dart';
import 'package:kartly_e_commerce/core/services/connectivity_service.dart';
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
  
  await GetStorage.init();
  final box = GetStorage();
  
  OneSignal.initialize("d254c403-bcbb-494d-8920-5f49ecf67de7");
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshList();
    }
  });
  
  OneSignal.Notifications.addClickListener((event) {
    final additionalData = event.notification.additionalData;
    if (additionalData != null) {
      final notificationId = additionalData['notification_id']?.toString();
      if (notificationId != null && notificationId.isNotEmpty) {
        box.write('push_notification_id', notificationId);
        box.write('push_notif_message', additionalData['notif_message']?.toString() ?? '');
        box.write('push_notif_title', additionalData['notif_title']?.toString() ?? '');
        box.write('push_notif_image', additionalData['notif_image']?.toString() ?? '');
        
        Get.toNamed('/notifications_view');
        final controller = Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());
        controller.refreshList().then((_) {
          controller.checkPushNotification();
        });
      }
    }
  });
  
  final startTime = DateTime.now();
  
  try {
    await initServices().timeout(const Duration(seconds: 5));
  } catch (_) {}
  
  Get.put(ThemeController(), permanent: true);
  
  await Get.putAsync<ConnectivityService>(() => ConnectivityService().init());
  
  final savedLanguage = box.read<String>('selected_language_api_code');
  if (savedLanguage != null && savedLanguage.isNotEmpty) {
    try {
      await LanguageService.load(savedLanguage);
    } catch (_) {}
  }
  
  try {
    Get.put(LanguageController(SiteSettingsPropertiesRepository(ApiService())), permanent: true);
  } catch (_) {}
  
  try {
    final siteRepo = SiteSettingsPropertiesRepository(ApiService());
    final currencyService = CurrencyService(siteRepo);
    Get.put<CurrencyService>(currencyService, permanent: true);
    Get.put<CurrencyController>(CurrencyController(siteRepo, currencyService), permanent: true);
  } catch (_) {}
  
  Get.put<NotificationController>(NotificationController(), permanent: true);
  Get.put(CategoryController(CategoryRepository(ApiService())));
  Get.put<NewProductListController>(NewProductListController(ProductRepository(ApiService())), permanent: true);
  Get.put(CartRepository(ApiService()), permanent: true);
  Get.put<CartController>(CartController(CartRepository(ApiService())), permanent: true);
  Get.put(AuthController(), permanent: true);

  final savedApiCode = box.read<String>(AppConfig.kLangCode) ?? 'en';
  
  try {
    await LanguageService.load(savedApiCode);
  } catch (_) {}

  try {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      if (uri.host == 'order' && uri.pathSegments.isNotEmpty) {
        final orderId = int.tryParse(uri.pathSegments.first) ?? 0;
        if (orderId > 0) {
          box.write('deep_link_order_id', orderId);
        }
      }
      else if (uri.host == 'refund' && uri.pathSegments.isNotEmpty) {
        final refundId = int.tryParse(uri.pathSegments.first) ?? 0;
        if (refundId > 0) {
          box.write('deep_link_refund_id', refundId);
        }
      }
      else {
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
    }
  } catch (_) {}

  _appLinks.uriLinkStream.listen((uri) {
    if (uri.host == 'order' && uri.pathSegments.isNotEmpty) {
      final orderId = int.tryParse(uri.pathSegments.first) ?? 0;
      if (orderId > 0) {
        box.write('deep_link_order_id', orderId);
      }
    }
    else if (uri.host == 'refund' && uri.pathSegments.isNotEmpty) {
      final refundId = int.tryParse(uri.pathSegments.first) ?? 0;
      if (refundId > 0) {
        box.write('deep_link_refund_id', refundId);
      }
    }
    else {
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
  });

  final elapsed = DateTime.now().difference(startTime);
  if (elapsed < const Duration(seconds: 2)) {
    await Future.delayed(const Duration(seconds: 2) - elapsed);
  }

  if (Get.isRegistered<NetworkService>()) {
    Get.find<NetworkService>().isConnected.refresh();
  }

  runApp(MyApp(initialLocaleCode: savedApiCode));
}
