import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/core/services/login_service.dart';
import 'package:kartly_e_commerce/core/services/passcode_service.dart';
import 'passcode_input_view.dart';

class PasscodeLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PasscodeLockScreen({super.key, required this.onUnlocked});
  @override
  State<PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<PasscodeLockScreen> {
  String _errorMessage = '';
  String _passcode = '';
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  bool _unlocking = false;
  bool _checkingPasscode = false;
  bool _biometricAvailable = false;
  bool _biometricChecked = false;
  bool _biometricTriggered = false;

  bool get isLoggedIn => (LoginService().token ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    if (!PasscodeService.useFingerprint) {
      setState(() => _biometricChecked = true);
      return;
    }
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final availableBiometrics = await localAuth.getAvailableBiometrics();
      if (mounted) {
        final available = canCheck && availableBiometrics.isNotEmpty;
        setState(() {
          _biometricAvailable = available;
          _biometricChecked = true;
        });
        if (available && !_unlocking && !_biometricTriggered) {
          _biometricTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_unlocking) _useBiometric();
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _biometricChecked = true);
    }
  }

  void _doUnlock() {
    if (!mounted || _unlocking) return;
    _unlocking = true;
    _lockoutTimer?.cancel();
    GetStorage().write('_last_active_time', DateTime.now().millisecondsSinceEpoch);
    widget.onUnlocked();
  }

  void _onKeyPressed(String value) {
    if (_isLockedOut || _unlocking || _checkingPasscode) return;
    if (value == 'delete') {
      if (_passcode.isNotEmpty) {
        setState(() {
          _passcode = _passcode.substring(0, _passcode.length - 1);
          _errorMessage = '';
        });
      }
    } else if (value == 'clear') {
      setState(() {
        _passcode = '';
        _errorMessage = '';
      });
    } else {
      if (_passcode.length < 6) {
        setState(() {
          _passcode += value;
          _errorMessage = '';
        });
        if (_passcode.length == 6) {
          _verifyPasscode();
        }
      }
    }
  }

  Future<void> _verifyPasscode() async {
    if (_unlocking || _checkingPasscode) return;
    _checkingPasscode = true;
    final verified = await PasscodeService.verifyPasscodeOnServer(_passcode);
    _checkingPasscode = false;
    if (verified) {
      _doUnlock();
    } else {
      if (isLoggedIn) {
        try {
          final api = ApiService();
          final resp = await api.getJson(AppConfig.customerGetPasscodeStatusUrl());
          if (resp['success'] == true && resp['has_passcode'] != true) {
            _doUnlock();
            return;
          }
        } catch (_) {}
      }
      _failedAttempts++;
      setState(() => _passcode = '');
      if (_failedAttempts >= 5) {
        _startLockout();
      } else {
        setState(() {
          _errorMessage = '${'Wrong passcode'.tr}. ${5 - _failedAttempts} ${'tries remaining'.tr}.';
        });
      }
    }
  }

  void _startLockout() {
    _isLockedOut = true;
    _lockoutSeconds = 60;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _lockoutSeconds--;
        _errorMessage = '${'Too many attempts. Please wait'.tr} ${_formatTime(_lockoutSeconds)}';
      });
      if (_lockoutSeconds <= 0) {
        timer.cancel();
        setState(() { _failedAttempts = 0; _isLockedOut = false; _errorMessage = ''; });
      }
    });
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '0:${seconds.toString().padLeft(2, '0')}';
    final min = seconds ~/ 60; final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  void _forgotPasscode() {
    if (_isLockedOut || _unlocking) return;
    Get.to(() => _ForgotPasscodeScreen(
      onReset: (newPasscode) async {
        final questions = await PasscodeService.fetchSecurityQuestions();
        await PasscodeService.setPasscodeOnServer(
          passcode: newPasscode,
          question1: questions?['question1'] ?? '',
          answer1: questions?['answer1'] ?? '',
          question2: questions?['question2'] ?? '',
          answer2: questions?['answer2'] ?? '',
        );
        _lockoutTimer?.cancel();
        _failedAttempts = 0;
        _unlocking = false;
        _checkingPasscode = false;
        setState(() { _passcode = ''; _errorMessage = ''; _isLockedOut = false; });
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passcode reset successfully. Enter your new passcode.'.tr),
                backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2)),
          );
        }
      },
    ));
  }

  void _useBiometric() async {
    if (_unlocking) return;
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      if (!canCheck) return;
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Unlock CampConnectUs Marketplace'.tr,
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (authenticated && mounted && !_unlocking) {
        _lockoutTimer?.cancel();
        _doUnlock();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(),
          Icon(Icons.lock_outline, size: 60, color: AppColors.primaryColor),
          const SizedBox(height: 20),
          Text('CampConnectUs Marketplace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
          const SizedBox(height: 10),
          Text('Enter Passcode'.tr, style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey)),
          const SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (index) {
            return Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 16, height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey, width: 1.5),
                  color: index < _passcode.length ? AppColors.primaryColor : Colors.transparent));
          })),
          const SizedBox(height: 10),
          if (_errorMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10, left: 20, right: 20), child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          _buildKeypad(),
          const SizedBox(height: 20),
          if (PasscodeService.useFingerprint && _biometricChecked && _biometricAvailable)
            InkWell(onTap: _useBiometric, child: Column(children: [
              Icon(Icons.fingerprint, size: 40, color: AppColors.primaryColor),
              const SizedBox(height: 8),
              Text('Use Biometrics'.tr, style: TextStyle(color: AppColors.primaryColor)),
            ])),
          const SizedBox(height: 20),
          if (!_isLockedOut) TextButton(onPressed: _forgotPasscode, child: Text('Forgot Passcode?'.tr, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey))),
          const Spacer(),
        ]),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('1'), _buildKey('2'), _buildKey('3')]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('7'), _buildKey('8'), _buildKey('9')]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('clear', text: 'Clear'.tr, isAction: true), _buildKey('0'), _buildKey('delete', text: '⌫', isAction: true)]),
    ]);
  }

  Widget _buildKey(String value, {String? text, bool isAction = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.all(8.0), child: InkWell(onTap: () => _onKeyPressed(value), borderRadius: BorderRadius.circular(40), child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1)), child: Center(child: text != null ? Text(text, style: TextStyle(fontSize: isAction ? 16 : 22, color: isAction ? AppColors.primaryColor : (isDark ? Colors.white : Colors.black))) : Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black))))));
  }
}

class _ForgotPasscodeScreen extends StatefulWidget {
  final Function(String) onReset;
  const _ForgotPasscodeScreen({required this.onReset});
  @override
  State<_ForgotPasscodeScreen> createState() => _ForgotPasscodeScreenState();
}

class _ForgotPasscodeScreenState extends State<_ForgotPasscodeScreen> {
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  int _step = 1;
  int _attemptsLeft = 3;
  String? _errorMessage;
  Map<String, dynamic>? _questions;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final q = await PasscodeService.fetchSecurityQuestions();
    if (mounted) setState(() => _questions = q);
  }

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    final answer = _step == 1 ? _answer1Controller.text.trim() : _answer2Controller.text.trim();
    if (answer.isEmpty) { setState(() => _errorMessage = 'Please enter an answer'.tr); return; }
    final storedAnswer = _step == 1 ? (_questions?['answer1'] ?? '') : (_questions?['answer2'] ?? '');
    if (answer.toLowerCase() == storedAnswer.toLowerCase()) {
      if (_step == 1) {
        setState(() { _step = 2; _errorMessage = null; });
        _answer2Controller.clear();
      } else {
        Get.back();
        _showResetPasscode();
      }
    } else {
      _attemptsLeft--;
      if (_attemptsLeft <= 0) {
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Too many failed attempts. Please try again later.'.tr), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 3)));
      } else {
        setState(() { _errorMessage = '${'Wrong answer'.tr}. $_attemptsLeft ${'tries remaining'.tr}.'; });
      }
    }
  }

  void _showResetPasscode() {
    Get.to(() => PasscodeInputView(title: 'Passcode Lock'.tr, hintText: 'Create a new passcode'.tr, onCompleted: (code) { widget.onReset(code); Get.back(); Get.back(); }));
  }

  @override
  Widget build(BuildContext context) {
    final question = _step == 1 ? (_questions?['question1'] ?? '') : (_questions?['question2'] ?? '');
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, automaticallyImplyLeading: false, leadingWidth: 44, leading: Material(color: Colors.transparent, shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: IconButton(onPressed: () { final nav = Navigator.of(context); if (nav.canPop()) { nav.pop(); return; } if (Get.key.currentState?.canPop() ?? false) { Get.back(); return; } Get.offAllNamed(AppRoutes.bottomNavbarView); }, icon: const Icon(Iconsax.arrow_left_2_copy, size: 20), splashRadius: 20)), centerTitle: false, titleSpacing: 0, title: Text('Forgot Passcode'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18))),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${'Step'.tr} $_step ${'of'.tr} 2', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Text('Answer your security question to reset your passcode.'.tr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 30),
        Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(controller: _step == 1 ? _answer1Controller : _answer2Controller, decoration: InputDecoration(hintText: 'Your answer'.tr, border: const OutlineInputBorder()), onSubmitted: (_) => _submitAnswer()),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitAnswer, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('Submit'.tr))),
        if (_errorMessage != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),
      ])),
    );
  }
}
