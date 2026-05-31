import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/passcode_repository.dart';

class PasscodeService {
  static const String _boxName = 'passcode_data';
  static const String _passcodeKey = 'passcode';
  static const String _fingerprintKey = 'use_fingerprint';
  static const String _autoLockKey = 'auto_lock_minutes';
  static const String _taskSwitcherKey = 'task_switcher_preview';
  static const String _question1Key = 'security_question_1';
  static const String _answer1Key = 'security_answer_1';
  static const String _question2Key = 'security_question_2';
  static const String _answer2Key = 'security_answer_2';

  static GetStorage? _box;

  static GetStorage get box {
    _box ??= GetStorage(_boxName);
    return _box!;
  }

  static final PasscodeRepository _repo = PasscodeRepository(ApiService());

  // Passcode
  static bool get isPasscodeEnabled => box.read(_passcodeKey) != null;
  static String? get passcode => box.read(_passcodeKey);

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
        await box.write(_passcodeKey, passcode);
        await box.write(_question1Key, question1);
        await box.write(_answer1Key, answer1.toLowerCase().trim());
        await box.write(_question2Key, question2);
        await box.write(_answer2Key, answer2.toLowerCase().trim());
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
      return code == passcode;
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
        await box.write(_passcodeKey, newPasscode);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setPasscode(String code) async {
    await box.write(_passcodeKey, code);
  }

  static Future<void> removePasscode() async {
    await box.remove(_passcodeKey);
    await box.remove(_question1Key);
    await box.remove(_answer1Key);
    await box.remove(_question2Key);
    await box.remove(_answer2Key);
  }

  // Fingerprint
  static bool get useFingerprint => box.read(_fingerprintKey) ?? false;
  static Future<void> setUseFingerprint(bool value) => box.write(_fingerprintKey, value);

  // Auto-lock (default Immediately = 0)
  static int get autoLockMinutes => box.read(_autoLockKey) ?? 0;
  static Future<void> setAutoLockMinutes(int minutes) => box.write(_autoLockKey, minutes);

  // Task switcher
  static String get taskSwitcherPreview => box.read(_taskSwitcherKey) ?? 'show';
  static Future<void> setTaskSwitcherPreview(String value) => box.write(_taskSwitcherKey, value);

  // Security questions
  static String? get securityQuestion1 => box.read(_question1Key);
  static String? get securityAnswer1 => box.read(_answer1Key);
  static String? get securityQuestion2 => box.read(_question2Key);
  static String? get securityAnswer2 => box.read(_answer2Key);

  static Future<void> setSecurityQuestions({
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
  }) async {
    await box.write(_question1Key, question1);
    await box.write(_answer1Key, answer1.toLowerCase().trim());
    await box.write(_question2Key, question2);
    await box.write(_answer2Key, answer2.toLowerCase().trim());
  }

  static Future<void> disablePasscode() async {
    await removePasscode();
    await box.remove(_fingerprintKey);
    await box.remove(_autoLockKey);
    await box.remove(_taskSwitcherKey);
  }

  static bool verifySecurityAnswers(String answer1, String answer2) {
    final storedAnswer1 = box.read(_answer1Key)?.toString().toLowerCase().trim();
    final storedAnswer2 = box.read(_answer2Key)?.toString().toLowerCase().trim();
    return answer1.toLowerCase().trim() == storedAnswer1 &&
           answer2.toLowerCase().trim() == storedAnswer2;
  }
}
