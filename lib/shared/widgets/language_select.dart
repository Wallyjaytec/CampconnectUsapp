import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../../shared/utils/dialog_utils.dart';

import '../../core/controllers/language_controller.dart';

class LanguageSelect extends StatelessWidget {
  LanguageSelect({super.key});

  final controller = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final selectedCode = controller.selectedApiCode.value ?? 'en';
            final selectedTitle =
                controller.languages
                    .firstWhereOrNull((e) => e.code == selectedCode)
                    ?.title ??
                selectedCode.toUpperCase();
            return GestureDetector(
              onTap: () => _openLanguageBottomSheet(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Icon(Iconsax.arrow_down_1_copy, size: 18),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openLanguageBottomSheet(BuildContext context) {
    final RxString tempSelected =
        (controller.selectedApiCode.value ?? 'en').obs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppColors.darkCardColor
          : AppColors.lightCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.66,
          maxChildSize: 0.66,
          minChildSize: 0.40,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final langs = controller.languages;
              final selected = tempSelected.value;

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) tempSelected.value = v;
                    },
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
                            child: Text(
                              'Select Language'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final lang = langs[index];
                            final code = lang.code.toString();

                            return RadioListTile<String>(
                              key: ValueKey(code),
                              value: code,
                              title: Text(
                                lang.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                code.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            );
                          }, childCount: langs.length),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      ],
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardColor
                            : AppColors.lightCardColor,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await controller.setLanguage(selected);
                            safeBack();
                          },
                          child: Text('Select'.tr),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }
}
