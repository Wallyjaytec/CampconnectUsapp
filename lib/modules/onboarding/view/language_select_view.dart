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
    final searchCtrl = TextEditingController();

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
              const SizedBox(height: 20),
              // Search Box
              TextField(
                controller: searchCtrl,
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search language...'.tr,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            searchCtrl.clear();
                            controller.searchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink()),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.filteredLanguages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: AppColors.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'No language found'.tr,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  final _ = controller.selectedLangCode.value;
                  return ListView.separated(
                    itemCount: controller.filteredLanguages.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                    itemBuilder: (_, i) {
                      final lang = controller.filteredLanguages[i];
                      final isSelected = controller.selectedLangCode.value == lang.code;

                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primaryColor : Colors.grey,
                          size: 22,
                        ),
                        title: Text(
                          lang.title,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? AppColors.primaryColor : null,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          lang.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected 
                                ? AppColors.primaryColor.withValues(alpha: 0.7) 
                                : Colors.grey,
                          ),
                        ),
                        trailing: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              controller.getFlagEmoji(lang.code),
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        onTap: () => controller.selectLanguage(lang.code),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.selectedLangCode.value != null && !controller.isSaving.value
                      ? () => controller.saveAndContinue()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Continue'.tr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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
