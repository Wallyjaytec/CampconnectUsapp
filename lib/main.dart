import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:kartly_e_commerce/core/controllers/currency_controller.dart';
import 'package:kartly_e_commerce/core/controllers/language_controller.dart';
import 'package:kartly_e_commerce/core/controllers/theme_controller.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/currency_service.dart';
import 'package:kartly_e_commerce/core/services/connectivity_service.dart';
import 'package:kartly_e_commerce/core/services/login_service.dart';
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
import 'modules/bottom_navbar/controller/bottom_navbar_controller.dart';

final _appLinks = AppLinks();

Map<String, dynamic>? pendingNotificationData;

class PushNotificationData {
  static String? notificationId;
  static String? message;
  static String? title;
  static String? image;
}

String debugOneSignal = '';

Future<void> updateOneSignalIdOnServer(String playerId) async {
  try {
    final login = LoginService();
    final token = login.token;
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/ecommerce-core/customer/update-onesignal-id');
    await http.post(
      uri,
      headers: {
        'Authorization': '${login.tokenType} $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'onesignal_id': playerId}),
    );
  } catch (_) {}
}

Future<void> initServices() async {
  await Get.putAsync<NetworkService>(() async => NetworkService().init());
}

void _handleDeepLink(Uri uri, GetStorage box) {
  if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shortcut' && uri.pathSegments.length > 1) {
    final dest = uri.pathSegments[1];
    switch (dest) {
      case 'search': Get.toNamed(AppRoutes.searchView); break;
      case 'orders': Get.toNamed(AppRoutes.myOrderListView); break;
      case 'cart': Get.toNamed(AppRoutes.cartView); break;
      case 'wallet': Get.toNamed(AppRoutes.myWalletView); break;
      case 'account':
        if (Get.isRegistered<BottomNavbarController>()) {
          Get.find<BottomNavbarController>().currentIndex.value = 4;
        } else {
          Get.toNamed(AppRoutes.bottomNavbarView);
        }
        break;
      case 'notifications': Get.toNamed(AppRoutes.notificationsView); break;
    }
  } else if (uri.host == 'search') {
    Get.toNamed(AppRoutes.searchView);
  } else if (uri.host == 'orders') {
    Get.toNamed(AppRoutes.myOrderListView);
  } else if (uri.host == 'cart') {
    Get.toNamed(AppRoutes.cartView);
  } else if (uri.host == 'wallet') {
    Get.toNamed(AppRoutes.myWalletView);
  } else if (uri.host == 'order' && uri.pathSegments.isNotEmpty) {
    final orderId = int.tryParse(uri.pathSegments.first) ?? 0;
    if (orderId > 0) {
      box.write('deep_link_order_id', orderId);
    }
  } else if (uri.host == 'refund' && uri.pathSegments.isNotEmpty) {
    final refundId = int.tryParse(uri.pathSegments.first) ?? 0;
    if (refundId > 0) {
      box.write('deep_link_refund_id', refundId);
    }
  } else {
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.initialize("d254c403-bcbb-494d-8920-5f49ecf67de7");

  OneSignal.User.pushSubscription.addObserver((state) {
    final playerId = state.current.id;
    if (playerId != null && playerId.isNotEmpty) {
      updateOneSignalIdOnServer(playerId);
    }
  });

  try {
    const channel = MethodChannel('com.example.kartly_e_commerce/onesignal');
    final result = await channel.invokeMethod('getColdStartNotification');
    if (result != null && result is Map) {
      final notificationId = result['notification_id']?.toString();
      if (notificationId != null && notificationId.isNotEmpty) {
        pendingNotificationData = {
          'notification_id': notificationId,
          'notif_message': result['notif_message']?.toString() ?? '',
          'notif_title': result['notif_title']?.toString() ?? '',
          'notif_image': result['notif_image']?.toString() ?? '',
        };
      }
    }
  } catch (e) {}

  OneSignal.Notifications.addClickListener((event) {
    final additionalData = event.notification.additionalData;
    if (additionalData != null) {
      final notificationId = additionalData['notification_id']?.toString();
      final orderId = additionalData['order_id']?.toString();
      final refundId = additionalData['refund_id']?.toString();
      final type = additionalData['type']?.toString();

      if (isLockScreenShowing) return;

      if (notificationId != null && notificationId.isNotEmpty) {
        pendingNotificationData = {
          'notification_id': notificationId,
          'notif_message': additionalData['notif_message']?.toString() ?? '',
          'notif_title': additionalData['notif_title']?.toString() ?? '',
          'notif_image': additionalData['notif_image']?.toString() ?? '',
        };

        PushNotificationData.notificationId = notificationId;
        PushNotificationData.message = additionalData['notif_message']?.toString() ?? '';
        PushNotificationData.title = additionalData['notif_title']?.toString() ?? '';
        PushNotificationData.image = additionalData['notif_image']?.toString() ?? '';

        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().refreshList();
        }
      } else if (orderId != null && orderId.isNotEmpty) {
        final id = int.tryParse(orderId) ?? 0;
        if (id > 0) {
          GetStorage().write('deep_link_order_id', id);
          Get.toNamed(AppRoutes.myOrderDetailsView, arguments: {'order_id': id});
        }
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().refreshList();
        }
      } else if (refundId != null && refundId.isNotEmpty) {
        final id = int.tryParse(refundId) ?? 0;
        if (id > 0) {
          GetStorage().write('deep_link_refund_id', id);
          Get.toNamed(AppRoutes.refundRequestDetailsView, arguments: id);
        }
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().refreshList();
        }
      } else if (type == 'wallet') {
        GetStorage().write('deep_link_wallet', true);
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().refreshList();
        }
        Get.toNamed(AppRoutes.myWalletView);
      }
    }
  });

  await GetStorage.init();

  final box = GetStorage();

  // Listen for widget deep links from Android
  const deepLinkChannel = MethodChannel('com.example.kartly_e_commerce/deeplink');
  deepLinkChannel.setMethodCallHandler((call) async {
    if (call.method == 'onDeepLink') {
      final url = call.arguments?.toString() ?? '';
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          _handleDeepLink(uri, box);
        }
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
      _handleDeepLink(uri, box);
    }
  } catch (_) {}

  _appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri, box);
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
