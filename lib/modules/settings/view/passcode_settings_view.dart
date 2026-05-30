import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
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
  bool _taskSwitcherShow = PasscodeService.taskSwitcherPreview == 'show';
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _passcodeEnabled = PasscodeService.isPasscodeEnabled;
    _useFingerprint = PasscodeService.useFingerprint;
    _autoLockMinutes = PasscodeService.autoLockMinutes;
    _taskSwitcherShow = PasscodeService.taskSwitcherPreview == 'show';
  }

  Future<void> _handleFingerprintToggle(bool value) async {
    if (value) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        if (!canCheck) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No biometrics available on this device'.tr),
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
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable fingerprint unlock'.tr,
        );
        if (authenticated) {
          setState(() => _useFingerprint = true);
          PasscodeService.setUseFingerprint(true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication failed. Try again.'.tr),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric error: ${e.toString()}'.tr),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      setState(() => _useFingerprint = false);
      PasscodeService.setUseFingerprint(false);
    }
  }

  Future<void> _showAutoLockPicker() async {
    final options = [
      {'label': 'Immediately'.tr, 'value': 0},
      {'label': '1 min'.tr, 'value': 1},
      {'label': '5 min'.tr, 'value': 5},
      {'label': '15 min'.tr, 'value': 15},
      {'label': '30 min'.tr, 'value': 30},
      {'label': '1 hour'.tr, 'value': 60},
    ];

    final result = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Auto-lock'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ...options.map((opt) => ListTile(
                title: Text(opt['label'] as String),
                trailing: _autoLockMinutes == opt['value'] ? const Icon(Icons.check, color: AppColors.primaryColor) : null,
                onTap: () => Navigator.pop(ctx, opt['value'] as int),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() => _autoLockMinutes = result);
      PasscodeService.setAutoLockMinutes(result);
    }
  }

  Future<void> _handlePasscodeToggle(bool value) async {
    if (value) {
      final passcode = await Get.to(
        () => PasscodeInputView(
          title: 'Passcode Lock'.tr,
          onCompleted: (code) => Get.back(result: code),
        ),
      );

      if (passcode == null || passcode.toString().isEmpty) {
        if (mounted) setState(() => _passcodeEnabled = false);
        return;
      }

      final confirmed = await Get.to(
        () => PasscodeInputView(
          title: 'Passcode Lock'.tr,
          confirmPasscode: passcode.toString(),
          onCompleted: (code) => Get.back(result: code),
        ),
      );

      if (confirmed == null) {
        if (mounted) setState(() => _passcodeEnabled = false);
        return;
      }

      final questionsData = await Get.to(() => const SecurityQuestionsView());

      if (questionsData == null) {
        if (mounted) setState(() => _passcodeEnabled = false);
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
        setState(() => _passcodeEnabled = true);
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
          title: 'Passcode Lock'.tr,
          hintText: 'Enter your passcode to disable'.tr,
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
            _taskSwitcherShow = true;
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
        title: 'Passcode Lock'.tr,
        hintText: 'Enter your current passcode'.tr,
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
        title: 'Passcode Lock'.tr,
        onCompleted: (code) => Get.back(result: code),
      ),
    );

    if (newPasscode == null) return;

    final confirmed = await Get.to(
      () => PasscodeInputView(
        title: 'Passcode Lock'.tr,
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
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            onPressed: () {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
                return;
              }
              if (Get.key.currentState?.canPop() ?? false) {
                Get.back();
                return;
              }
              Get.offAllNamed(AppRoutes.bottomNavbarView);
            },
            icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
            splashRadius: 20,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text('Passcode Lock'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          SwitchListTile(
            secondary: const Icon(Iconsax.lock, color: AppColors.primaryColor, size: 20),
            title: Text('Passcode Lock'.tr),
            activeColor: AppColors.primaryColor,
            value: _passcodeEnabled,
            onChanged: _handlePasscodeToggle,
          ),
          const Divider(),
          if (_passcodeEnabled) ...[
            ListTile(
              leading: const Icon(Iconsax.key, color: AppColors.primaryColor, size: 20),
              title: Text('Change Passcode'.tr),
              trailing: const Icon(Iconsax.arrow_right_3_copy, size: 18),
              onTap: _changePasscode,
            ),
            SwitchListTile(
              secondary: const Icon(Iconsax.finger_scan, color: AppColors.primaryColor, size: 20),
              title: Text('Unlock with Fingerprint'.tr),
              activeColor: AppColors.primaryColor,
              value: _useFingerprint,
              onChanged: _handleFingerprintToggle,
            ),
            ListTile(
              leading: const Icon(Iconsax.timer_1, color: AppColors.primaryColor, size: 20),
              title: Text('Auto-lock'.tr),
              subtitle: Text(_autoLockMinutes == 0 ? 'Immediately'.tr : '$_autoLockMinutes min'),
              trailing: const Icon(Iconsax.arrow_right_3_copy, size: 18),
              onTap: _showAutoLockPicker,
            ),
            SwitchListTile(
              secondary: const Icon(Iconsax.eye, color: AppColors.primaryColor, size: 20),
              title: Text('App in Task Switcher'.tr),
              subtitle: Text(_taskSwitcherShow ? 'Show'.tr : 'Hide'.tr),
              activeColor: AppColors.primaryColor,
              value: _taskSwitcherShow,
              onChanged: (val) {
                setState(() => _taskSwitcherShow = val);
                PasscodeService.setTaskSwitcherPreview(val ? 'show' : 'hide');
              },
            ),
          ],
        ],
      ),
    );
  }
}
