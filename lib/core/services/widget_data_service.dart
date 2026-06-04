import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetDataService {
  static const _key = 'widget_data';

  static Future<void> updateWidgetData({
    required int cartItems,
    required String cartTotal,
    String? latestOrderId,
    String? latestOrderAmount,
    String? latestOrderStatus,
    String? refundId,
    String? refundAmount,
    String? refundStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'cartItems': cartItems,
      'cartTotal': cartTotal,
      'latestOrderId': latestOrderId ?? '',
      'latestOrderAmount': latestOrderAmount ?? '',
      'latestOrderStatus': latestOrderStatus ?? '0',
      'refundId': refundId ?? '',
      'refundAmount': refundAmount ?? '',
      'refundStatus': refundStatus ?? '0',
    });
    await prefs.setString(_key, data);
  }
}
