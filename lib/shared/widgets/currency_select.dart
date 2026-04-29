import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/controllers/currency_controller.dart';

class CurrencySelect extends StatelessWidget {
  CurrencySelect({super.key});

  final controller = Get.find<CurrencyController>();

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
      child: Obx(() {
        final sel = controller.selected;
        final title = sel == null ? '—' : '${sel.name} (${sel.code})';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openBottomSheet(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  const Icon(Iconsax.arrow_down_1_copy, size: 18),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _openBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final RxString temp = (controller.selected?.code ?? '').obs;

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
              final list = controller.currencies;

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
                    groupValue: temp.value,
                    onChanged: (v) {
                      if (v != null) temp.value = v;
                    },
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
                            child: Text(
                              'Select Currency'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final c = list[index];
                            return RadioListTile<String>(
                              key: ValueKey(c.code),
                              value: c.code,
                              title: Text(
                                c.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                c.code,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }, childCount: list.length),
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
                          onPressed: () {
                            final picked = controller.currencies
                                .firstWhereOrNull((e) => e.code == temp.value);
                            if (picked != null) {
                              controller.select(picked);
                            }
                            Navigator.of(ctx).pop();
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
