import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/account/model/my_order_details_model.dart';
import '../../modules/account/model/my_order_model.dart';
import '../../modules/account/model/refund_reason_model.dart';

class OrderRepository {
  OrderRepository({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<OrderListResponse> fetchOrders({
    required int page,
    required int perPage,
    String? searchKey,
    String? dateFrom,
    String? dateTo,
  }) async {
    final cb = DateTime.now().millisecondsSinceEpoch;
    final base = AppConfig.customerOrdersUrl();
    final url = '$base?_cb=$cb';

    final body = <String, dynamic>{'page': page, 'perPage': perPage};
    if (searchKey != null && searchKey.isNotEmpty) {
      body['search_key'] = searchKey;
    }
    if (dateFrom != null && dateFrom.isNotEmpty && dateTo != null && dateTo.isNotEmpty) {
      body['date_from'] = '$dateFrom 00:00:00';
      body['date_to'] = '$dateTo 23:59:59';
    }

    final resp = await _api.postJson(url, body: body);

    return OrderListResponse.fromMap(resp);
  }

  Future<OrderDetailsResponse> fetchOrderDetails({required int orderId}) async {
    final cb = DateTime.now().millisecondsSinceEpoch;
    final base = AppConfig.customerOrderDetailsUrl();
    final url = '$base?_cb=$cb';

    final resp = await _api.postJson(url, body: {'order_id': orderId});

    return OrderDetailsResponse.fromMap(resp);
  }

  Future<bool> cancelOrder({required int orderId, int? itemId}) async {
    final url = AppConfig.cancelOrderUrl();

    final fields = <String, String>{'order_id': orderId.toString()};
    if (itemId != null) {
      fields['item_id'] = itemId.toString();
    }

    final resp = await _api.postMultipart(url, fields: fields);

    final ok =
        (resp['success'] == true) ||
        (resp['success']?.toString().toLowerCase() == 'true');

    return ok;
  }

  Future<bool> submitReview({
    required int orderId,
    required int productId,
    required int rating,
    required String review,
    List<http.MultipartFile>? images,
  }) async {
    final url = AppConfig.reviewProductUrl();

    final fields = <String, String>{
      'order_id': orderId.toString(),
      'product_id': productId.toString(),
      'rating': rating.toString(),
      'review': review,
    };

    final resp = await _api.postMultipart(url, fields: fields, files: images);

    final ok =
        (resp['success'] == true) ||
        (resp['success']?.toString().toLowerCase() == 'true');

    return ok;
  }

  Future<List<RefundReason>> fetchRefundReasons() async {
    final url = AppConfig.refundReasonsUrl();
    final resp = await _api.getJson(url);
    final parsed = RefundReasonsResponse.fromMap(resp);

    return parsed.data;
  }

  Future<bool> submitReturnRequest({
    required int packageId,
    required int refundReasonId,
    String? refundComment,
    List<http.MultipartFile>? images,
  }) async {
    final url = AppConfig.submitReturnUrl();
    final fields = <String, String>{
      'package_id': packageId.toString(),
      'refund_reason': refundReasonId.toString(),
      'refund_comment': refundComment ?? '',
    };

    final resp = await _api.postMultipart(url, fields: fields, files: images);

    final ok =
        (resp['success'] == true) ||
        (resp['success']?.toString().toLowerCase() == 'true');

    return ok;
  }

  Future<String?> generateOrderPaymentLink({required int orderId}) async {
    final fields = <String, String>{
      'origin': 'app',
      'order_id': orderId.toString(),
    };

    try {
      final res = await _api.postMultipart(
        AppConfig.generateOrderPaymentUrl(),
        fields: fields,
        files: const [],
      );

      final ok =
          res['success'] == true ||
          (res['success']?.toString().toLowerCase() == 'true');

      final url = res['link']?.toString();

      if (!ok || url == null || url.isEmpty) {
        return null;
      }
      return url;
    } on ApiHttpException catch (e) {
      try {
        final decoded = json.decode(e.body);
        if (decoded is Map<String, dynamic> &&
            (decoded.containsKey('errors') ||
                decoded.containsKey('message'))) {}
      } catch (_) {}
      rethrow;
    }
  }
}
