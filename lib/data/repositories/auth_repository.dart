import 'package:get_storage/get_storage.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../modules/auth/model/forgot_password_model.dart';
import '../responses/customer_login_response.dart';
import '../responses/registration_response.dart';

class AuthRepository {
  AuthRepository({ApiService? api, GetStorage? storage})
    : _api = api ?? ApiService(storage: storage);

  final ApiService _api;

  Future<RegistrationResponse> registerCustomer({
    required String name,
    required String email,
    required String phoneCode,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? phoneWithCode,
  }) async {
    final url = AppConfig.customerRegistrationUrl();

    final fields = <String, String>{
      'name': name,
      'email': email,
      'phone_code': phoneCode,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'from': 'app',
    };

    if ((phoneWithCode ?? '').isNotEmpty) {
      fields['phone_with_code'] = phoneWithCode!;
    }

    final json = await _api.postMultipart(url, fields: fields);
    return RegistrationResponse.fromJson(json);
  }

  Future<CustomerLoginResponse> loginCustomer({
    required String email,
    required String password,
  }) async {
    final url = AppConfig.customerLoginUrl();
    final fields = <String, String>{'email': email, 'password': password};
    final json = await _api.postMultipart(url, fields: fields);
    return CustomerLoginResponse.fromJson(json);
  }

  Future<ForgotPasswordResponse> forgotPassword({required String email}) async {
    final url = AppConfig.customerForgotPasswordUrl();
    final fields = <String, String>{'email': email, 'from': 'app'};

    final json = await _api.postMultipart(url, fields: fields);
    return ForgotPasswordResponse.fromJson(json);
  }

  Future<ForgotPasswordResponse> sendEmailResetLink() async {
    final url = AppConfig.customerEmailResetLinkUrl();
    final fields = <String, String>{};
    final json = await _api.postMultipart(url, fields: fields);
    return ForgotPasswordResponse.fromJson(json);
  }

  Future<ForgotPasswordResponse> resetEmail({
    required String token,
    required String email,
  }) async {
    final url = AppConfig.customerResetEmailUrl();
    final fields = <String, String>{
      'identifier': token,
      'email': email,
    };
    final json = await _api.postMultipart(url, fields: fields);
    return ForgotPasswordResponse.fromJson(json);
  }

  Future<Map<String, dynamic>?> verifyResetToken(String identifier) async {
    final url = AppConfig.verifyResetTokenUrl();
    final fields = <String, String>{'identifier': identifier};
    final json = await _api.postMultipart(url, fields: fields);
    if (json['success'] == true) {
      return {'success': true, 'email': json['email'] ?? ''};
    }
    return null;
  }

  Future<dynamic> resetPassword({
    required String identifier,
    required String password,
  }) async {
    final url = AppConfig.resetPasswordUrl();
    final fields = <String, String>{
      'identifier': identifier,
      'password': password,
      'password_confirmation': password,
    };
    final json = await _api.postMultipart(url, fields: fields);
    if (json['success'] == true) return true;
    if (json['message'] != null) return 'old_password';
    return false;
  }

  Future<Map<String, dynamic>> sendEmailVerificationCode(String email) async {
    final url = '/api/v1/ecommerce-core/customer/send-email-code';
    final json = await _api.postJson(url, body: {'email': email});
    return json;
  }

  Future<Map<String, dynamic>> verifyEmailCode(String email, String code) async {
    final url = '/api/v1/ecommerce-core/customer/verify-email-code';
    final json = await _api.postJson(url, body: {'email': email, 'code': code});
    return json;
  }
}
