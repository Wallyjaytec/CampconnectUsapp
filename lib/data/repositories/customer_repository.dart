import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/modules/account/model/customer_basic_info.dart';
import 'package:mime/mime.dart';

class CustomerRepository {
  CustomerRepository({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<CustomerBasicInfoResponse> fetchBasicInfo() async {
    final url = AppConfig.customerBasicInfoUrl();
    final json = await _api.getJson(url);
    return CustomerBasicInfoResponse.fromJson(json);
  }

  Future<CustomerBasicInfoResponse> updateBasicInfo({
    required String name,
    required String phone,
    String? phoneCode,
    File? imageFile,
  }) async {
    final url = AppConfig.updateCustomerBasicInfoUrl();

    final fields = <String, String>{'name': name, 'phone': phone};
    if (phoneCode != null) {
      fields['phone_code'] = phoneCode;
    }

    final files = <http.MultipartFile>[];
    if (imageFile != null) {
      final mime = lookupMimeType(imageFile.path) ?? 'image/*';
      final part = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mime),
      );
      files.add(part);
    }

    final json = await _api.postMultipart(
      url,
      fields: fields,
      files: files.isEmpty ? null : files,
    );

    return CustomerBasicInfoResponse.fromJson(json);
  }

  Future<CustomerBasicInfoResponse> removeProfilePicture() async {
    final url = AppConfig.updateCustomerBasicInfoUrl();
    final fields = <String, String>{'remove_image': '1'};
    final json = await _api.postMultipart(url, fields: fields);
    return CustomerBasicInfoResponse.fromJson(json);
  }
}
