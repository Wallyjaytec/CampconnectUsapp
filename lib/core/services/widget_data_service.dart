import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetDataService {
  static const _key = 'widget_data';

  static Future<void> updateWidgetData({
    int? cartItems,
    String? cartTotal,
    String? cartItemsText,
    String? currencySymbol,
    String? latestOrderId,
    String? latestOrderAmount,
    String? latestOrderStatus,
    String? latestOrderProduct,
    String? latestOrderImage,
    String? refundId,
    String? refundAmount,
    String? refundStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final existing = prefs.getString(_key);
    Map<String, dynamic> data = {};
    if (existing != null) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(existing));
      } catch (_) {}
    }
    
    if (cartItems != null) data['cartItems'] = cartItems;
    if (cartTotal != null) data['cartTotal'] = cartTotal;
    if (cartItemsText != null) data['cartItemsText'] = cartItemsText;
    if (currencySymbol != null) data['currencySymbol'] = currencySymbol;
    if (latestOrderId != null) data['latestOrderId'] = latestOrderId;
    if (latestOrderAmount != null) data['latestOrderAmount'] = latestOrderAmount;
    if (latestOrderStatus != null) data['latestOrderStatus'] = latestOrderStatus;
    if (latestOrderProduct != null) data['latestOrderProduct'] = latestOrderProduct;
    if (latestOrderImage != null) data['latestOrderImage'] = latestOrderImage;
    if (refundId != null) data['refundId'] = refundId;
    if (refundAmount != null) data['refundAmount'] = refundAmount;
    if (refundStatus != null) data['refundStatus'] = refundStatus;

    await prefs.setString(_key, jsonEncode(data));

    try {
      const channel = MethodChannel('com.campconnectus.store/widget_update');
      await channel.invokeMethod('updateWidgets');
    } catch (_) {}
  }
}
