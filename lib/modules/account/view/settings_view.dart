import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/shared/widgets/currency_select.dart';
import 'package:kartly_e_commerce/shared/widgets/language_select.dart';

import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/theme_switch.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('locale=${Get.locale}, tr(Registration)=${'Registration'.tr}');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Settings'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 12,
            right: 12,
            bottom: 10,
          ),
          child: Column(
            children: [
              const ThemeSwitch(),
              const SizedBox(height: 8),
              LanguageSelect(),
              const SizedBox(height: 8),
              CurrencySelect(),
            ],
          ),
        ),
      ),
    );
  }
}
