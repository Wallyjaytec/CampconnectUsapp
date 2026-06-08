import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/account/model/contact_message_model.dart';

class ContactRepository {
  final ApiService _apiService;

  ContactRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<ContactMessageResponse> sendContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
    List<PlatformFile>? files,
  }) async {
    final fields = <String, String>{
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
    };

    List<http.MultipartFile>? multipartFiles;
    if (files != null && files.isNotEmpty) {
      multipartFiles = [];
      for (final file in files) {
        if (file.path != null) {
          multipartFiles.add(
            await http.MultipartFile.fromPath('attachments[]', file.path!),
          );
        }
      }
    }

    final json = await _apiService.postMultipart(
      AppConfig.storeContactMessageUrl(),
      fields: fields,
      files: multipartFiles,
    );

    return ContactMessageResponse.fromJson(json);
  }

  Future<ContactMessageResponse> sendFeatureRequest({
    required String name,
    required String email,
    required String subject,
    required String message,
    List<PlatformFile>? files,
  }) async {
    final fields = <String, String>{
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'type': 'feature_request',
    };

    List<http.MultipartFile>? multipartFiles;
    if (files != null && files.isNotEmpty) {
      multipartFiles = [];
      for (final file in files) {
        if (file.path != null) {
          multipartFiles.add(
            await http.MultipartFile.fromPath('attachments[]', file.path!),
          );
        }
      }
    }

    final json = await _apiService.postMultipart(
      AppConfig.storeContactMessageUrl(),
      fields: fields,
      files: multipartFiles,
    );

    return ContactMessageResponse.fromJson(json);
  }
}
