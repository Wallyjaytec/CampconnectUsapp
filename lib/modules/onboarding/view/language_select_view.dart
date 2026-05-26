import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../controller/language_select_controller.dart';

class LanguageSelectView extends StatelessWidget {
  const LanguageSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageSelectController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Choose Your Language'.tr,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.languages.isEmpty) {
                    return Center(child: Text('No languages available'.tr));
                  }
                  final _ = controller.selectedLangCode.value;
                  return ListView.separated(
                    itemCount: controller.languages.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final lang = controller.languages[i];
                      final isSelected = controller.selectedLangCode.value == lang.code;
                      final flagCode = lang.code.length >= 2 ? lang.code.substring(0, 2) : '';

                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primaryColor : Colors.grey,
                          size: 22,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.title,  // Changed from 'name' to 'title'
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                color: isSelected ? AppColors.primaryColor : null,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang.code.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.7) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Center(
                            child: Text(
                              controller.getFlagEmoji(flagCode),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        onTap: () => controller.selectLanguage(lang.code),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              Obx(() => SizedBox(
                width: double.infinity, 
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.selectedLangCode.value != null
                      ? () => controller.saveAndContinue()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Continue'.tr),
                ),
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
