import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/cart_item_model.dart';

class CartRepository {
  CartRepository(this._api);
  final ApiService _api;

  Future<CartListResponse> fetchCartItems() async {
    final map = await _api.getJson(AppConfig.cartItemsUrl());
    return CartListResponse.fromJson(map);
  }

  Future<void> storeCartItem(CartApiItem item) async {
    final resp = await _api.postMultipart(
      AppConfig.cartStoreItemUrl(),
      fields: {'item': item.toFormFieldString()},
    );

    final ok =
        (resp['success'] == true) ||
        (resp['status']?.toString() == '200' &&
            resp['success']?.toString() == 'true');
    if (!ok) {
      throw Exception('Cart store failed (success=false).');
    }
  }

  Future<void> updateCartItem(CartApiItem item) async {
    final resp = await _api.postMultipart(
      AppConfig.cartUpdateItemUrl(),
      fields: {'item': item.toFormFieldString()},
    );

    final ok =
        (resp['success'] == true) ||
        (resp['status']?.toString() == '200' &&
            resp['success']?.toString() == 'true');
    if (!ok) {
      throw Exception('Cart update failed (success=false).');
    }
  }

  Future<void> removeCartItem(String uid) async {
    final map = await _api.postJson(
      AppConfig.cartRemoveItemUrl(),
      body: {'uid': uid},
    );
    final ok =
        (map['success'] == true) ||
        (map['status']?.toString() == '200' &&
            map['success']?.toString() == 'true');
    if (!ok) throw Exception('Remove failed.');
  }

  Future<Map<String, dynamic>> validateCartItems(
    List<CartApiItem> items,
  ) async {
    final itemsJson = jsonEncode(items.map((e) => e.toJson()).toList());
    final body = {'items': itemsJson};

    final resp = await _api.postJson(
      AppConfig.cartValidateItemsUrl(),
      body: body,
    );

    return resp;
  }

  Future<ApplyCouponResponse> applyCoupon({
    required String couponCode,
    required int customerId,
    required List<CartApiItem> products,
  }) async {
    final body = {
      'coupon_code': couponCode,
      'customer_id': customerId,
      'products': jsonEncode(products.map((e) => e.toJson()).toList()),
    };

    final resp = await _api.postJson(
      AppConfig.cartApplyCouponUrl(),
      body: body,
    );

    return ApplyCouponResponse.fromJson(resp);
  }
}
