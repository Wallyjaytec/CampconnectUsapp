import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
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

  void _onKeyPressed(String value) {
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

  void _verifyPasscode() {
    if (_passcode == PasscodeService.passcode) {
      widget.onUnlocked();
    } else {
      _failedAttempts++;
      setState(() {
        _errorMessage = 'Wrong passcode. Try again.'.tr;
        _passcode = '';
      });

      if (_failedAttempts >= 5) {
        setState(() {
          _errorMessage = 'Too many attempts. Please wait 1 minute.'.tr;
        });
        Future.delayed(const Duration(minutes: 1), () {
          if (mounted) {
            setState(() {
              _failedAttempts = 0;
              _errorMessage = '';
            });
          }
        });
      }
    }
  }

  void _forgotPasscode() {
    Get.to(() => _ForgotPasscodeScreen(
      onReset: (newPasscode) {
        Get.back();
        PasscodeService.setPasscode(newPasscode);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Passcode reset successfully'.tr),
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo
            Icon(Icons.lock_outline, size: 60, color: AppColors.primaryColor),
            const SizedBox(height: 20),
            Text(
              'CampConnectUs Marketplace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Enter Passcode'.tr,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Passcode dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 1.5),
                    color: index < _passcode.length ? AppColors.primaryColor : Colors.transparent,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),

            // Keypad
            _buildKeypad(),
            const SizedBox(height: 20),

            // Fingerprint
            if (PasscodeService.useFingerprint)
              InkWell(
                onTap: () {
                  // TODO: Implement fingerprint
                },
                child: Column(
                  children: [
                    Icon(Icons.fingerprint, size: 40, color: AppColors.primaryColor),
                    const SizedBox(height: 8),
                    Text('Use Fingerprint'.tr, style: TextStyle(color: AppColors.primaryColor)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Forgot passcode
            TextButton(
              onPressed: _forgotPasscode,
              child: Text('Forgot Passcode?'.tr, style: const TextStyle(color: Colors.grey)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('clear', text: 'Clear'.tr, isAction: true),
            _buildKey('0'),
            _buildKey('delete', text: '⌫', isAction: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value, {String? text, bool isAction = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onKeyPressed(value),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Center(
            child: text != null
                ? Text(text, style: TextStyle(fontSize: isAction ? 16 : 22, color: isAction ? AppColors.primaryColor : Colors.black))
                : Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}

// Forgot passcode recovery screen
class _ForgotPasscodeScreen extends StatefulWidget {
  final Function(String) onReset;

  const _ForgotPasscodeScreen({required this.onReset});

  @override
  State<_ForgotPasscodeScreen> createState() => _ForgotPasscodeScreenState();
}

class _ForgotPasscodeScreenState extends State<_ForgotPasscodeScreen> {
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  int _attemptsLeft = 3;
  String? _errorMessage;
  bool _showQuestion2 = false;
  bool _firstAnswerCorrect = false;

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  void _submitAnswer1() {
    final answer = _answer1Controller.text.trim();
    final stored = PasscodeService.securityAnswer1 ?? '';
    if (answer.toLowerCase() == stored.toLowerCase()) {
      setState(() {
        _firstAnswerCorrect = true;
        _showQuestion2 = true;
        _errorMessage = null;
      });
    } else {
      _attemptsLeft--;
      if (_attemptsLeft <= 0) {
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Too many failed attempts. Please try again later.'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _errorMessage = '${'Wrong answer'.tr}. $_attemptsLeft ${'tries remaining'.tr}.';
        });
      }
    }
  }

  void _submitAnswer2() {
    final answer = _answer2Controller.text.trim();
    final stored = PasscodeService.securityAnswer2 ?? '';
    if (answer.toLowerCase() == stored.toLowerCase()) {
      // Both answers correct - show reset passcode
      Get.back();
      _showResetPasscode();
    } else {
      _attemptsLeft--;
      if (_attemptsLeft <= 0) {
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Too many failed attempts. Please try again later.'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _errorMessage = '${'Wrong answer'.tr}. $_attemptsLeft ${'tries remaining'.tr}.';
        });
      }
    }
  }

  void _showResetPasscode() {
    Get.to(
      () => PasscodeInputView(
        title: 'New Passcode'.tr,
        onCompleted: (code) {
          widget.onReset(code);
          Get.back();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Forgot Passcode'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answer your security questions to reset your passcode.'.tr,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Question 1
            Text(
              PasscodeService.securityQuestion1 ?? 'Question 1'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answer1Controller,
              enabled: !_firstAnswerCorrect,
              decoration: InputDecoration(
                hintText: 'Your answer'.tr,
                border: const OutlineInputBorder(),
                suffixIcon: _firstAnswerCorrect
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
            if (!_firstAnswerCorrect) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAnswer1,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Submit'.tr),
                ),
              ),
            ],
            const SizedBox(height: 25),

            // Question 2
            if (_showQuestion2) ...[
              Text(
                PasscodeService.securityQuestion2 ?? 'Question 2'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _answer2Controller,
                decoration: InputDecoration(
                  hintText: 'Your answer'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAnswer2,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Submit'.tr),
                ),
              ),
            ],

            // Error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
