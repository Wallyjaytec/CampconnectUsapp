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
  }) async {
    final fields = <String, String>{
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
    };

    final json = await _apiService.postMultipart(
      AppConfig.storeContactMessageUrl(),
      fields: fields,
    );

    return ContactMessageResponse.fromJson(json);
  }
}
