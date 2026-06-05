import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:http/http.dart' as http;

class CheckoutRepository {
  CheckoutRepository(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> fetchShippingOptions({
    required int location,
    String? postCode,
    required String shippingType,
    required String productsJsonString,
  }) {
    final body = <String, dynamic>{
      'location': location,
      if (postCode != null && postCode.trim().isNotEmpty) 'post_code': postCode,
      'shipping_type': shippingType,
      'products': productsJsonString,
    };

    return _api.postJson(AppConfig.getShippingOptionsUrl(), body: body);
  }

  Future<Map<String, dynamic>> fetchActivePickupPoints() async {
    return await _api.postJson(AppConfig.activePickupPointsUrl());
  }

  Future<Map<String, dynamic>> fetchActivePaymentMethods({
    required String city,
    required String pickupPoint,
    required String productsJsonString,
  }) {
    final body = <String, dynamic>{
      'city': city,
      'pickup_point': pickupPoint,
      'products': productsJsonString,
    };
    return _api.postJson(AppConfig.activePaymentMethodsUrl(), body: body);
  }

  Future<Map<String, dynamic>> customerCheckoutOrderCreate({
    required Map<String, dynamic> body,
  }) async {
    final url = AppConfig.customerCheckoutOrderUrl();

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
}
