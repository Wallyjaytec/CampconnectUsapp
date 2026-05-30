import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';

class PasscodeSettingsView extends StatefulWidget {
  const PasscodeSettingsView({super.key});

  @override
  State<PasscodeSettingsView> createState() => _PasscodeSettingsViewState();
}

class _PasscodeSettingsViewState extends State<PasscodeSettingsView> {
  bool _passcodeEnabled = false;

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
            onChanged: (value) {
              setState(() {
                _passcodeEnabled = value;
              });
            },
          ),
          const Divider(),
          if (_passcodeEnabled) ...[
            ListTile(
              leading: const Icon(Icons.key, color: AppColors.primaryColor),
              title: Text('Change Passcode'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppColors.primaryColor),
              title: Text('Unlock with Fingerprint'.tr),
              activeColor: AppColors.primaryColor,
              value: false,
              onChanged: (value) {},
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: AppColors.primaryColor),
              title: Text('Auto-lock'.tr),
              subtitle: Text('1 min'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.preview, color: AppColors.primaryColor),
              title: Text('App in Task Switcher'.tr),
              subtitle: Text('Show'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}
