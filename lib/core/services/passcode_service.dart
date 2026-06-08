import 'package:get_storage/get_storage.dart';
import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:campconnectus_marketplace/data/repositories/passcode_repository.dart';

class PasscodeService {
  static const String _boxName = 'passcode_settings';
  static const String _fingerprintKey = 'use_fingerprint';
  static const String _autoLockKey = 'auto_lock_minutes';
  static const String _taskSwitcherKey = 'task_switcher_preview';
  static const String _passcodeEnabledKey = 'passcode_enabled';

  static GetStorage? _box;
  static GetStorage get box { 
    _box ??= GetStorage(_boxName);
    return _box!;
  }
  static final PasscodeRepository _repo = PasscodeRepository(ApiService());
  static final ApiService _api = ApiService();

  static bool isPasscodeEnabled() {
    return box.read(_passcodeEnabledKey) ?? false;
  }
  
  static Future<void> setPasscodeEnabled(bool value) async {
    await box.write(_passcodeEnabledKey, value);
  }

  static Future<bool> checkPasscodeOnServer() async {
    try {
      final resp = await _api.getJson(AppConfig.customerGetPasscodeStatusUrl());
      final has = resp['has_passcode'];
      if (resp['success'] == true && (has == true || has == '1' || has == 1)) {
        await setPasscodeEnabled(true);
        return true;
      }
      await setPasscodeEnabled(false);
      return false;
    } catch (_) { return isPasscodeEnabled(); }
  }

  static Future<bool> setPasscodeOnServer({required String passcode, required String question1, required String answer1, required String question2, required String answer2}) async {
    try {
      final resp = await _repo.setPasscode(passcode: passcode, question1: question1, answer1: answer1, question2: question2, answer2: answer2);
      if (resp['success'] == true) { await setPasscodeEnabled(true); return true; }
      return false;
    } catch (_) { return false; }
  }

  static Future<bool> verifyPasscodeOnServer(String code) async {
    try { 
      final resp = await _repo.verifyPasscode(code);
      return resp['success'] == true; 
    } catch (_) { return false; }
  }

  static Future<bool> resetPasscodeOnServer({required String answer1, required String answer2, required String newPasscode}) async {
    try {
      final resp = await _repo.resetPasscode(answer1: answer1, answer2: answer2, newPasscode: newPasscode);
      if (resp['success'] == true) { await setPasscodeEnabled(true); return true; }
      return false;
    } catch (_) { return false; }
  }

  static Future<bool> disablePasscodeOnServer() async {
    try { final resp = await _repo.disablePasscode(); if (resp['success'] == true) { await setPasscodeEnabled(false); return true; } return false; } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>?> fetchSecurityQuestions() async {
    try {
      final resp = await _api.getJson(AppConfig.customerGetPasscodeStatusUrl());
      if (resp['success'] == true) return {'question1': resp['security_question_1']?.toString(), 'answer1': resp['security_answer_1']?.toString(), 'question2': resp['security_question_2']?.toString(), 'answer2': resp['security_answer_2']?.toString()};
    } catch (_) {}
    return null;
  }

  static bool get useFingerprint {
    return box.read(_fingerprintKey) ?? false;
  }
  
  static Future<void> setUseFingerprint(bool v) async {
    await box.write(_fingerprintKey, v);
  }
  
  static int get autoLockMinutes {
    return box.read(_autoLockKey) ?? 0;
  }
  
  static Future<void> setAutoLockMinutes(int v) async {
    await box.write(_autoLockKey, v);
  }
  
  static String get taskSwitcherPreview {
    return box.read(_taskSwitcherKey) ?? 'show';
  }
  
  static Future<void> setTaskSwitcherPreview(String v) async {
    await box.write(_taskSwitcherKey, v);
  }
}
