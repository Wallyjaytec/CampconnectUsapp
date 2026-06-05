import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';

class PasscodeRepository {
  final ApiService _api;

  PasscodeRepository(this._api);

  Future<Map<String, dynamic>> setPasscode({
    required String passcode,
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
  }) {
    return _api.postJson(
      AppConfig.customerSetPasscodeUrl(),
      body: {
        'passcode': passcode,
        'security_question_1': question1,
        'security_answer_1': answer1,
        'security_question_2': question2,
        'security_answer_2': answer2,
      },
    );
  }

  Future<Map<String, dynamic>> verifyPasscode(String passcode) {
    return _api.postJson(
      AppConfig.customerVerifyPasscodeUrl(),
      body: {'passcode': passcode},
    );
  }

  Future<Map<String, dynamic>> resetPasscode({
    required String answer1,
    required String answer2,
    required String newPasscode,
  }) {
    return _api.postJson(
      AppConfig.customerResetPasscodeUrl(),
      body: {
        'security_answer_1': answer1,
        'security_answer_2': answer2,
        'new_passcode': newPasscode,
      },
    );
  }

  Future<Map<String, dynamic>> getPasscodeStatus() {
    return _api.getJson(AppConfig.customerGetPasscodeStatusUrl());
  }

  Future<Map<String, dynamic>> disablePasscode() {
    return _api.postJson(
      AppConfig.customerSetPasscodeUrl(),
      body: {'disable': true},
    );
  }
}
