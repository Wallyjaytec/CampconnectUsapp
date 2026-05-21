import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../modules/account/controller/notifications_controller.dart';
import '../../modules/auth/model/customer_login_model.dart';
import '../../modules/product/controller/cart_controller.dart';
import '../../modules/wishlist/controller/wishlist_controller.dart';
import 'guest_cart_service.dart';

class LoginService {
  static const _kIsLoggedIn = 'isLoggedIn';
  static const _kRememberMe = 'rememberMe';
  static const _kAccessToken = 'access_token';
  static const _kTokenType = 'token_type';

  static const _kLoginUser = 'login_user';
  static const _kDashboardContent = 'dashboard_content';

  static const _keySellerApplied = 'seller_applied';
  static const _keySellerApproved = 'seller_approved';

  final _storage = GetStorage();

  void saveLogin(bool status, {bool remember = false}) {
    _storage.write(_kIsLoggedIn, status);
    _storage.write(_kRememberMe, remember);
  }

  bool isLoggedIn() => _storage.read(_kIsLoggedIn) ?? false;
  bool isRemembered() => _storage.read(_kRememberMe) ?? false;

  void saveToken(String token, {String tokenType = 'bearer'}) {
    _storage.write(_kAccessToken, token);
    _storage.write(_kTokenType, tokenType);

    GuestCartService().clear();

    _notifyLoggedInControllersSafely();
  }

  void _notifyLoggedInControllersSafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<WishlistController>()) {
        Get.find<WishlistController>().onUserLoggedIn();
      } else {
        WishlistController.ensure().onUserLoggedIn();
      }

      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().loadCart();
      }
    });

    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().load();
    } else {
      Get.put(NotificationController());
    }
  }

  String? get token => _storage.read(_kAccessToken);
  String get tokenType => _storage.read(_kTokenType) ?? 'bearer';

  void saveLoginUser(CustomerLoginUser? user) {
    if (user == null) {
      _storage.remove(_kLoginUser);
    } else {
      _storage.write(_kLoginUser, jsonEncode(user.toJson()));
    }
  }

  CustomerLoginUser? getLoginUser() {
    final raw = _storage.read(_kLoginUser);
    if (raw is String && raw.isNotEmpty) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CustomerLoginUser.fromJson(map);
    }
    return null;
  }

  void saveDashboardContent(CustomerDashboardContent? dash) {
    if (dash == null) {
      _storage.remove(_kDashboardContent);
    } else {
      _storage.write(_kDashboardContent, jsonEncode(dash.toJson()));
    }
  }

  CustomerDashboardContent? getDashboardContent() {
    final raw = _storage.read(_kDashboardContent);
    if (raw is String && raw.isNotEmpty) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CustomerDashboardContent.fromJson(map);
    }
    return null;
  }

  Future<CustomerDashboardContent?> fetchDashboardFromApi() async {
    try {
      final t = token;
      if (t == null) return null;

      final uri = Uri.parse('${AppConfig.baseUrl}/api/customer-dashboard');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': '$tokenType $t',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final dashData = body['dashboard_content'] ?? body;
        final dash = CustomerDashboardContent.fromJson(dashData);
        saveDashboardContent(dash);
        return dash;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void saveSellerApplied(bool v) => _storage.write(_keySellerApplied, v);
  bool isSellerApplied() => _storage.read(_keySellerApplied) ?? false;

  void saveSellerApproved(bool v) => _storage.write(_keySellerApproved, v);
  bool isSellerApproved() => _storage.read(_keySellerApproved) ?? false;

  void logout() {
    _storage.remove(_kIsLoggedIn);
    _storage.remove(_kRememberMe);
    _storage.remove(_kAccessToken);
    _storage.remove(_kTokenType);
    _storage.remove(_kLoginUser);
    _storage.remove(_kDashboardContent);
    if (Get.isRegistered<WishlistController>()) {
      Get.find<WishlistController>().onUserLoggedOut();
    }
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().loadCart();
    }
    if (Get.isRegistered<NotificationController>()) {
      final n = Get.find<NotificationController>();
      n.items.clear();
      n.notificationCount.value = 0;
      n.errorText.value = null;
    }
  }
}
