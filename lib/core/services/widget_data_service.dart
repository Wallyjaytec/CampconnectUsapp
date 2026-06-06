import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetDataService {
  static const _key = 'widget_data';

  static Future<void> updateWidgetData({
    required int cartItems,
    required String cartTotal,
    required String currencySymbol,
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
    final data = jsonEncode({
      'cartItems': cartItems,
      'cartTotal': cartTotal,
      'currencySymbol': currencySymbol,
      'latestOrderId': latestOrderId ?? '',
      'latestOrderAmount': latestOrderAmount ?? '',
      'latestOrderStatus': latestOrderStatus ?? '0',
      'latestOrderProduct': latestOrderProduct ?? '',
      'latestOrderImage': latestOrderImage ?? '',
      'refundId': refundId ?? '',
      'refundAmount': refundAmount ?? '',
      'refundStatus': refundStatus ?? '0',
    });
    await prefs.setString(_key, data);

    try {
      const channel = MethodChannel('com.campconnectus.store/widget_update');
      await channel.invokeMethod('updateWidgets');
    } catch (_) {}
  }
}
