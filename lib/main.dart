import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:campconnectus_marketplace/core/controllers/currency_controller.dart';
import 'package:campconnectus_marketplace/core/controllers/language_controller.dart';
import 'package:campconnectus_marketplace/core/controllers/theme_controller.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/core/services/currency_service.dart';
import 'package:campconnectus_marketplace/core/services/connectivity_service.dart';
import 'package:campconnectus_marketplace/core/services/login_service.dart';
import 'package:campconnectus_marketplace/core/services/passcode_service.dart';
import 'package:campconnectus_marketplace/data/repositories/site_settings_properties_repository.dart';
import 'package:campconnectus_marketplace/modules/auth/controller/auth_controller.dart';
import 'package:campconnectus_marketplace/modules/settings/view/passcode_lock_screen.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';
import 'core/services/language_service.dart';
import 'core/services/network_service.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/product_repository.dart';
import 'modules/account/controller/notifications_controller.dart';
import 'modules/bottom_navbar/controller/bottom_navbar_controller.dart';
import 'modules/category/controller/category_controller.dart';
import 'modules/product/controller/cart_controller.dart';
import 'modules/product/controller/new_product_list_controller.dart';

final _appLinks = AppLinks();

Map<String, dynamic>? pendingNotificationData;

class PushNotificationData {
  static String? notificationId;
  static String? message;
  static String? title;
  static String? image;
}

String debugOneSignal = '';

String? _lastMethodChannelLink;

bool isLockScreenShowing = false;

Future<void> updateOneSignalIdOnServer(String playerId) async {
  try {
    final login = LoginService();
    final token = login.token;
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse(
        '${AppConfig.baseUrl}/api/v1/ecommerce-core/customer/update-onesignal-id');
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
  box.write('debug_last_link', uri.toString());
  box.write('debug_last_link_time', DateTime.now().toString());

  if (uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == 'shortcut' &&
      uri.pathSegments.length > 1) {
    final dest = uri.pathSegments[1];
    _navigateOrStore(dest, box);
  } else if (uri.host == 'search') {
    _navigateOrStore('search', box);
  } else if (uri.host == 'orders') {
    _navigateOrStore('orders', box);
  } else if (uri.host == 'cart') {
    _navigateOrStore('cart', box);
  } else if (uri.host == 'wallet') {
    _navigateOrStore('wallet', box);
  } else if (uri.host == 'refunds') {
    _navigateOrStore('refunds', box);
  } else if (uri.host == 'order' && uri.pathSegments.isNotEmpty) {
    final orderId = int.tryParse(uri.pathSegments.first) ?? 0;
    if (orderId > 0) box.write('deep_link_order_id', orderId);
  } else if (uri.host == 'refund' && uri.pathSegments.isNotEmpty) {
    final refundId = int.tryParse(uri.pathSegments.first) ?? 0;
    if (refundId > 0) box.write('deep_link_refund_id', refundId);
  } else {
    final token = uri.queryParameters['u'] ?? '';
    if (token.isNotEmpty) {
      box.write('deep_link_token', token);
      final type = uri.path.contains('email-verification')
          ? 'email_verify'
          : 'password_reset';
      box.write('deep_link_type', type);
    }
  }
}

void _navigateOrStore(String dest, GetStorage box) {
  final context = Get.context;
  if (context != null && ModalRoute.of(context) != null) {
    // FIX: App is already running — check passcode before navigating directly.
    // Without this, widgets/shortcuts bypass the lock screen entirely.
    if (PasscodeService.isPasscodeEnabled() && !isLockScreenShowing) {
      box.write('shortcut_destination', dest);
      isLockScreenShowing = true;
      Get.to(() => PasscodeLockScreen(
            onUnlocked: () {
              isLockScreenShowing = false;
              box.write('_last_active_time',
                  DateTime.now().millisecondsSinceEpoch);
              final pending =
                  box.read<String>('shortcut_destination') ?? '';
              if (pending.isNotEmpty) {
                box.remove('shortcut_destination');
                _doNavigate(pending);
              }
            },
          ));
    } else {
      // No passcode or lock already showing — navigate directly
      _doNavigate(dest);
    }
  } else {
    // App is cold starting — store for splash to pick up
    box.write('shortcut_destination', dest);
  }
}

void _doNavigate(String dest) {
  switch (dest) {
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
    case 'refunds':
      Get.toNamed(AppRoutes.refundRequestListView);
      break;
    case 'account':
      if (Get.isRegistered<BottomNavbarController>()) {
        Get.find<BottomNavbarController>().currentIndex.value = 4;
      } else {
        Get.toNamed(AppRoutes.bottomNavbarView);
      }
      break;
    case 'notifications':
      Get.toNamed(AppRoutes.notificationsView);
      break;
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
    const channel =
        MethodChannel('com.campconnectus.store/onesignal');
    final result =
        await channel.invokeMethod('getColdStartNotification');
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
  } catch (_) {}

  OneSignal.Notifications.addClickListener((event) {
    final additionalData = event.notification.additionalData;
    if (additionalData != null) {
      final notificationId =
          additionalData['notification_id']?.toString();
      final orderId = additionalData['order_id']?.toString();
      final refundId = additionalData['refund_id']?.toString();
      final type = additionalData['type']?.toString();

      if (isLockScreenShowing) return;

      if (notificationId != null && notificationId.isNotEmpty) {
        pendingNotificationData = {
          'notification_id': notificationId,
          'notif_message':
              additionalData['notif_message']?.toString() ?? '',
          'notif_title':
              additionalData['notif_title']?.toString() ?? '',
          'notif_image':
              additionalData['notif_image']?.toString() ?? '',
        };

        PushNotificationData.notificationId = notificationId;
        PushNotificationData.message =
            additionalData['notif_message']?.toString() ?? '';
        PushNotificationData.title =
            additionalData['notif_title']?.toString() ?? '';
        PushNotificationData.image =
            additionalData['notif_image']?.toString() ?? '';

        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().refreshList();
        }
      } else if (orderId != null && orderId.isNotEmpty) {
        final id = int.tryParse(orderId) ?? 0;
        if (id > 0) {
          GetStorage().write('deep_link_order_id', id);
          Get.toNamed(AppRoutes.myOrderDetailsView,
              arguments: {'order_id': id});
        }
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().refreshList();
        }
      } else if (refundId != null && refundId.isNotEmpty) {
        final id = int.tryParse(refundId) ?? 0;
        if (id > 0) {
          GetStorage().write('deep_link_refund_id', id);
          Get.toNamed(AppRoutes.refundRequestDetailsView,
              arguments: id);
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

  const deepLinkChannel =
      MethodChannel('com.campconnectus.store/deeplink');
  deepLinkChannel.setMethodCallHandler((call) async {
    if (call.method == 'onDeepLink') {
      final url = call.arguments?.toString() ?? '';
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          _lastMethodChannelLink = url;
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

  await Get.putAsync<ConnectivityService>(
      () => ConnectivityService().init());

  final savedLanguage =
      box.read<String>('selected_language_api_code');
  if (savedLanguage != null && savedLanguage.isNotEmpty) {
    try {
      await LanguageService.load(savedLanguage);
    } catch (_) {}
  }

  try {
    Get.put(
        LanguageController(
            SiteSettingsPropertiesRepository(ApiService())),
        permanent: true);
  } catch (_) {}

  try {
    final siteRepo = SiteSettingsPropertiesRepository(ApiService());
    final currencyService = CurrencyService(siteRepo);
    Get.put<CurrencyService>(currencyService, permanent: true);
    Get.put<CurrencyController>(
        CurrencyController(siteRepo, currencyService),
        permanent: true);
  } catch (_) {}

  Get.put<NotificationController>(NotificationController(),
      permanent: true);
  Get.put(CategoryController(CategoryRepository(ApiService())));
  Get.put<NewProductListController>(
      NewProductListController(ProductRepository(ApiService())),
      permanent: true);
  Get.put(CartRepository(ApiService()), permanent: true);
  Get.put<CartController>(
      CartController(CartRepository(ApiService())),
      permanent: true);
  Get.put(AuthController(), permanent: true);

  final savedApiCode =
      box.read<String>(AppConfig.kLangCode) ?? 'en';

  try {
    await LanguageService.load(savedApiCode);
  } catch (_) {}

  try {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      final uriStr = uri.toString();
      if (uriStr != _lastMethodChannelLink) {
        _handleDeepLink(uri, box);
      }
    }
  } catch (_) {}

  _appLinks.uriLinkStream.listen((uri) {
    final uriStr = uri.toString();
    if (uriStr == _lastMethodChannelLink) {
      _lastMethodChannelLink = null;
      return;
    }
    _handleDeepLink(uri, box);
  });

  final elapsed = DateTime.now().difference(startTime);
  if (elapsed < const Duration(seconds: 2)) {
    await Future.delayed(const Duration(seconds: 2) - elapsed);
  }

  if (Get.isRegistered<NetworkService>()) {
    Get.find<NetworkService>().isConnected.refresh();
  }

  // Check passcode lock on cold start
  if (PasscodeService.isPasscodeEnabled() && !isLockScreenShowing) {
    isLockScreenShowing = true;
    runApp(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: PasscodeLockScreen(
        onUnlocked: () {
          isLockScreenShowing = false;
          box.write('_last_active_time', DateTime.now().millisecondsSinceEpoch);
          // Handle any pending deep links
          final pending = box.read<String>('shortcut_destination') ?? '';
          if (pending.isNotEmpty) {
            box.remove('shortcut_destination');
            _doNavigate(pending);
          }
        },
      ),
    ));
  } else {
    runApp(MyApp(initialLocaleCode: savedApiCode));
  }
}
