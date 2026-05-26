import 'package:flutter/material.dart';
import 'package:flutter_country_selector/flutter_country_selector.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../controller/country_select_controller.dart';

class CountrySelectView extends StatelessWidget {
  const CountrySelectView({super.key});

  String getFlagEmoji(String code) {
    try {
      final country = Country.parse(code);
      return country.flagEmoji;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CountrySelectController());
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
                  'Choose Your Country'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: searchCtrl,
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search countries...'.tr,
                  prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18),
                  suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle_copy, size: 18),
                          onPressed: () {
                            searchCtrl.clear();
                            controller.searchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink()),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error.isNotEmpty) {
                    return Center(child: Text(controller.error.value));
                  }
                  final list = controller.filteredCountries;
                  if (list.isEmpty) {
                    return Center(child: Text('No countries found'.tr));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                    itemBuilder: (_, i) {
                      final country = list[i];
                      final code = country['code']?.toString() ?? '';
                      final isSelected = controller.selectedCountryId.value == country['id'];
                      
                      return Obx(() => ListTile(
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primaryColor : Colors.grey,
                        ),
                        title: Text(country['name'] ?? ''),
                        trailing: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            getFlagEmoji(code),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        onTap: () => controller.selectCountry(country['id']),
                      ));
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.selectedCountryId.value != null
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
            ],
          ),
        ),
      ),
    );
  }
}
