import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        title: const Text('Passcode Lock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // Passcode Lock Toggle
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Passcode Lock'),
            value: _passcodeEnabled,
            onChanged: (value) {
              setState(() {
                _passcodeEnabled = value;
              });
            },
          ),
          const Divider(),
          // Other options (only visible when passcode is ON)
          if (_passcodeEnabled) ...[
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Change Passcode'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to change passcode screen
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Unlock with Fingerprint'),
              value: false,
              onChanged: (value) {
                // TODO: Enable fingerprint
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Auto-lock'),
              subtitle: const Text('1 min'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show auto-lock options
              },
            ),
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('App in Task Switcher'),
              subtitle: const Text('Show'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show task switcher options
              },
            ),
          ],
        ],
      ),
    );
  }
}
