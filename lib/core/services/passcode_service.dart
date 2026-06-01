import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/passcode_repository.dart';

class PasscodeService {
  static const String _boxName = 'passcode_settings';
  static const String _fingerprintKey = 'use_fingerprint';
  static const String _autoLockKey = 'auto_lock_minutes';
  static const String _taskSwitcherKey = 'task_switcher_preview';

  static GetStorage? _box;

  static GetStorage get box {
    _box ??= GetStorage(_boxName);
    return _box!;
  }

  static final PasscodeRepository _repo = PasscodeRepository(ApiService());
  static final ApiService _api = ApiService();

  static bool? _cachedPasscodeEnabled;
  static DateTime? _cacheTime;

  static Future<bool> checkPasscodeEnabled() async {
    if (_cachedPasscodeEnabled != null && _cacheTime != null) {
      final diff = DateTime.now().difference(_cacheTime!);
      if (diff.inSeconds < 30) return _cachedPasscodeEnabled!;
    }
    try {
      final resp = await _api.getJson(AppConfig.customerGetPasscodeStatusUrl());
      final hasPasscode = resp['has_passcode'];
      if (resp['success'] == true && (hasPasscode == true || hasPasscode == '1' || hasPasscode == 1)) {
        _cachedPasscodeEnabled = true;
      } else {
        _cachedPasscodeEnabled = false;
      }
      _cacheTime = DateTime.now();
      return _cachedPasscodeEnabled!;
    } catch (_) {
      return _cachedPasscodeEnabled ?? false;
    }
  }

  static void clearCache() {
    _cachedPasscodeEnabled = null;
    _cacheTime = null;
  }

  static Future<bool> setPasscodeOnServer({
    required String passcode,
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
  }) async {
    try {
      final resp = await _repo.setPasscode(
        passcode: passcode,
        question1: question1,
        answer1: answer1,
        question2: question2,
        answer2: answer2,
      );
      if (resp['success'] == true) {
        _cachedPasscodeEnabled = true;
        _cacheTime = DateTime.now();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyPasscodeOnServer(String code) async {
    try {
      final resp = await _repo.verifyPasscode(code);
      return resp['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> resetPasscodeOnServer({
    required String answer1,
    required String answer2,
    required String newPasscode,
  }) async {
    try {
      final resp = await _repo.resetPasscode(
        answer1: answer1,
        answer2: answer2,
        newPasscode: newPasscode,
      );
      if (resp['success'] == true) {
        _cachedPasscodeEnabled = true;
        _cacheTime = DateTime.now();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> disablePasscodeOnServer() async {
    try {
      final resp = await _repo.disablePasscode();
      if (resp['success'] == true) {
        _cachedPasscodeEnabled = false;
        _cacheTime = DateTime.now();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchSecurityQuestions() async {
    try {
      final resp = await _api.getJson(AppConfig.customerGetPasscodeStatusUrl());
      if (resp['success'] == true) {
        return {
          'question1': resp['security_question_1']?.toString(),
          'answer1': resp['security_answer_1']?.toString(),
          'question2': resp['security_question_2']?.toString(),
          'answer2': resp['security_answer_2']?.toString(),
        };
      }
    } catch (_) {}
    return null;
  }

  static bool get useFingerprint => box.read(_fingerprintKey) ?? false;
  static Future<void> setUseFingerprint(bool value) => box.write(_fingerprintKey, value);

  static int get autoLockMinutes => box.read(_autoLockKey) ?? 0;
  static Future<void> setAutoLockMinutes(int minutes) => box.write(_autoLockKey, minutes);

  static String get taskSwitcherPreview => box.read(_taskSwitcherKey) ?? 'show';
  static Future<void> setTaskSwitcherPreview(String value) => box.write(_taskSwitcherKey, value);
}
