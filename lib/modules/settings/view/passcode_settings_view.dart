import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/passcode_service.dart';
import 'package:kartly_e_commerce/modules/settings/view/passcode_input_view.dart';
import 'package:kartly_e_commerce/modules/settings/view/security_questions_view.dart';

class PasscodeSettingsView extends StatefulWidget {
  const PasscodeSettingsView({super.key});

  @override
  State<PasscodeSettingsView> createState() => _PasscodeSettingsViewState();
}

class _PasscodeSettingsViewState extends State<PasscodeSettingsView> {
  bool _passcodeEnabled = PasscodeService.isPasscodeEnabled;
  bool _useFingerprint = PasscodeService.useFingerprint;
  int _autoLockMinutes = PasscodeService.autoLockMinutes;

  @override
  void initState() {
    super.initState();
    _passcodeEnabled = PasscodeService.isPasscodeEnabled;
    _useFingerprint = PasscodeService.useFingerprint;
    _autoLockMinutes = PasscodeService.autoLockMinutes;
  }

  Future<void> _handlePasscodeToggle(bool value) async {
    if (value) {
      final passcode = await Get.to(
        () => PasscodeInputView(
          title: 'Create Passcode'.tr,
          onCompleted: (code) => Get.back(result: code),
        ),
      );

      if (passcode == null || passcode.toString().isEmpty) {
        if (mounted) {
          setState(() => _passcodeEnabled = false);
        }
        return;
      }

      final confirmed = await Get.to(
        () => PasscodeInputView(
          title: 'Confirm Passcode'.tr,
          confirmPasscode: passcode.toString(),
          onCompleted: (code) => Get.back(result: code),
        ),
      );

      if (confirmed == null) {
        if (mounted) {
          setState(() => _passcodeEnabled = false);
        }
        return;
      }

      final questionsData = await Get.to(() => const SecurityQuestionsView());

      if (questionsData == null) {
        if (mounted) {
          setState(() => _passcodeEnabled = false);
        }
        return;
      }

      await PasscodeService.setPasscode(passcode.toString());
      await PasscodeService.setSecurityQuestions(
        question1: questionsData['question1'],
        answer1: questionsData['answer1'],
        question2: questionsData['question2'],
        answer2: questionsData['answer2'],
      );

      if (mounted) {
        setState(() {
          _passcodeEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passcode enabled successfully'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      final entered = await Get.to(
        () => PasscodeInputView(
          title: 'Enter Passcode'.tr,
          onCompleted: (code) => Get.back(result: code),
        ),
      );

      if (entered != null && entered.toString() == PasscodeService.passcode) {
        await PasscodeService.disablePasscode();
        if (mounted) {
          setState(() {
            _passcodeEnabled = false;
            _useFingerprint = false;
            _autoLockMinutes = 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Passcode disabled'.tr),
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (entered != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wrong passcode'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _changePasscode() async {
    final current = await Get.to(
      () => PasscodeInputView(
        title: 'Enter Current Passcode'.tr,
        onCompleted: (code) => Get.back(result: code),
      ),
    );

    if (current == null || current.toString() != PasscodeService.passcode) {
      if (current != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wrong passcode'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final newPasscode = await Get.to(
      () => PasscodeInputView(
        title: 'New Passcode'.tr,
        onCompleted: (code) => Get.back(result: code),
      ),
    );

    if (newPasscode == null) return;

    final confirmed = await Get.to(
      () => PasscodeInputView(
        title: 'Confirm New Passcode'.tr,
        confirmPasscode: newPasscode.toString(),
        onCompleted: (code) => Get.back(result: code),
      ),
    );

    if (confirmed != null) {
      await PasscodeService.setPasscode(newPasscode.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passcode changed successfully'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Passcode Lock'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline, color: AppColors.primaryColor),
            title: Text('Passcode Lock'.tr),
            activeColor: AppColors.primaryColor,
            value: _passcodeEnabled,
            onChanged: _handlePasscodeToggle,
          ),
          const Divider(),
          if (_passcodeEnabled) ...[
            ListTile(
              leading: const Icon(Icons.key, color: AppColors.primaryColor),
              title: Text('Change Passcode'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePasscode,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppColors.primaryColor),
              title: Text('Unlock with Fingerprint'.tr),
              activeColor: AppColors.primaryColor,
              value: _useFingerprint,
              onChanged: (value) {
                setState(() => _useFingerprint = value);
                PasscodeService.setUseFingerprint(value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: AppColors.primaryColor),
              title: Text('Auto-lock'.tr),
              subtitle: Text('$_autoLockMinutes min'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.preview, color: AppColors.primaryColor),
              title: Text('App in Task Switcher'.tr),
              subtitle: Text(PasscodeService.taskSwitcherPreview == 'show' ? 'Show'.tr : 'Hide'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}
