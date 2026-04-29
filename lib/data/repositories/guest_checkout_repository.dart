import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:http/http.dart' as http;

import '../../core/services/api_service.dart';
import '../../modules/account/model/my_order_details_model.dart';

class GuestCheckoutRepository {
  GuestCheckoutRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<Map<String, dynamic>> guestCheckout({
    required Map<String, dynamic> body,
  }) async {
    final url = AppConfig.guestCheckoutUrl();

    if (body.containsKey('receipt') &&
        body['receipt'] != null &&
        body['receipt'].toString().isNotEmpty) {
      final String imagePath = body['receipt'].toString();

      final Map<String, String> fields = {};
      body.forEach((key, value) {
        if (key != 'receipt') {
          fields[key] = value.toString();
        }
      });

      try {
        final multipartFile = await http.MultipartFile.fromPath(
          'receipt',
          imagePath,
        );

        return _api.postMultipart(url, fields: fields, files: [multipartFile]);
      } catch (e) {
        return Future.error("Image file not found or invalid");
      }
    } else {
      return _api.postJson(url, body: body);
    }
  }

  Future<OrderDetailsData> getGuestOrderDetails({
    required String orderCode,
  }) async {
    final url = AppConfig.guestOrderDetailsUrl();
    final resp = await _api.postMultipart(
      url,
      fields: {'order_code': orderCode},
    );

    if (resp['success'] == true && resp['data'] is Map<String, dynamic>) {
      final dataJson = resp['data'] as Map<String, dynamic>;
      return OrderDetailsData.fromMap(dataJson);
    }

    throw Exception(
      resp['message']?.toString() ?? 'Failed to load guest order',
    );
  }
}
