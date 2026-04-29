import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/widget/custom_text_field.dart';
import '../controller/address_controller.dart';
import '../model/address_model.dart';

class AddAddressView extends StatelessWidget {
  const AddAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<AddressController>()
        ? Get.find<AddressController>()
        : Get.put(AddressController());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Add Address'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
      ),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: c.refreshFormConfig,
          child: ListView(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (c.isFormLoading.value)
                ..._buildShimmerForm(context)
              else
                ..._buildRealForm(context, c),
            ],
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Obx(() {
          final submitLoading = c.isSubmitting.value;
          final disableBtn = submitLoading || c.isFormLoading.value;
          return SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: disableBtn ? null : c.submitNewAddress,
              child: submitLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Save address'.tr),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildRealForm(BuildContext context, AddressController c) {
    final v = c.fieldVisibility.value;
    final widgets = <Widget>[];

    if (v.showName) {
      widgets.addAll([
        CustomTextField(
          controller: c.nameC,
          hint: 'Name'.tr,
          icon: Iconsax.user_copy,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (v.showPhone) {
      widgets.addAll([
        CustomTextField(
          controller: c.phoneC,
          hint: 'Phone Number'.tr,
          icon: Iconsax.call_copy,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (v.showLocation) {
      widgets.addAll([
        CustomTextField(
          controller: c.countryC,
          hint: 'Country'.tr,
          icon: Iconsax.global_copy,
          readOnly: true,
          onTap: () => _openCountrySheet(context, c),
          suffix: const Icon(Iconsax.arrow_down_1_copy, size: 16),
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: c.stateC,
          hint: 'State'.tr,
          icon: Iconsax.location_copy,
          readOnly: true,
          onTap: () {
            if (c.selectedCountry.value == null) {
              Get.snackbar(
                'Select Country'.tr,
                'Please select country first'.tr,
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.primaryColor,
                colorText: AppColors.whiteColor,
              );
              return;
            }
            _openStateSheet(context, c);
          },
          suffix: const Icon(Iconsax.arrow_down_1_copy, size: 16),
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: c.cityC,
          hint: 'City'.tr,
          icon: Iconsax.route_square_copy,
          readOnly: true,
          onTap: () {
            if (c.selectedState.value == null) {
              Get.snackbar(
                'Select State',
                'Please select state first'.tr,
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.primaryColor,
                colorText: AppColors.whiteColor,
              );
              return;
            }
            _openCitySheet(context, c);
          },
          suffix: const Icon(Iconsax.arrow_down_1_copy, size: 16),
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (v.showPostalCode) {
      widgets.addAll([
        CustomTextField(
          controller: c.postalC,
          hint: 'Postal Code'.tr,
          icon: Iconsax.hashtag_1_copy,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (v.showAddress) {
      widgets.addAll([
        CustomTextField(
          controller: c.addressC,
          hint: 'Address'.tr,
          icon: Iconsax.location_copy,
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (widgets.isEmpty) {
      widgets.add(Text('No address fields enabled from server settings'.tr));
    }

    return widgets;
  }

  List<Widget> _buildShimmerForm(BuildContext context) {
    return [
      _shimmerField(context),
      const SizedBox(height: 10),
      _shimmerField(context),
      const SizedBox(height: 10),
      _shimmerField(context),
      const SizedBox(height: 10),
      _shimmerField(context),
      const SizedBox(height: 10),
      _shimmerField(context),
      const SizedBox(height: 10),
      _shimmerField(context),
    ];
  }

  Widget _shimmerField(BuildContext context) {
    final isDark = Get.theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCardColor : Colors.grey[300]!,
      highlightColor: isDark
          ? Theme.of(context).dividerColor
          : Colors.grey[100]!,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _openCountrySheet(BuildContext context, AddressController c) {
    _openSelectSheet<CountryModel>(
      title: 'Select Country',
      itemsRx: c.countries,
      itemLabel: (x) => x.name,
      onSelected: (x) => c.onSelectCountry(x),
      isLoadingRx: c.isCountriesLoading,
      ensureLoad: () => c.ensureCountriesLoaded(),
      onSearch: (q, list) {
        final ql = q.toLowerCase();
        return list.where((e) => e.name.toLowerCase().contains(ql)).toList();
      },
    );
  }

  void _openStateSheet(BuildContext context, AddressController c) {
    _openSelectSheet<StateModel>(
      title: 'Select State'.tr,
      itemsRx: c.states,
      itemLabel: (x) => x.name,
      onSelected: (x) => c.onSelectState(x),
      isLoadingRx: c.isStatesLoading,
      ensureLoad: () => c.ensureStatesLoaded(),
      onSearch: (q, list) {
        final ql = q.toLowerCase();
        return list.where((e) => e.name.toLowerCase().contains(ql)).toList();
      },
    );
  }

  void _openCitySheet(BuildContext context, AddressController c) {
    _openSelectSheet<CityModel>(
      title: 'Select City'.tr,
      itemsRx: c.cities,
      itemLabel: (x) => x.name,
      onSelected: (x) => c.onSelectCity(x),
      isLoadingRx: c.isCitiesLoading,
      ensureLoad: () => c.ensureCitiesLoaded(),
      onSearch: (q, list) {
        final ql = q.toLowerCase();
        return list.where((e) => e.name.toLowerCase().contains(ql)).toList();
      },
    );
  }

  void _openSelectSheet<T>({
    required String title,
    required RxList<T> itemsRx,
    required String Function(T) itemLabel,
    required Future<void> Function(T) onSelected,
    required RxBool isLoadingRx,
    required Future<void> Function() ensureLoad,
    required List<T> Function(String query, List<T> current) onSearch,
  }) {
    final searchC = TextEditingController();
    final filtered = RxList<T>([]);
    final isDark = Get.theme.brightness == Brightness.dark;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackgroundColor
                : AppColors.lightBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          height: Get.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: const Icon(Iconsax.close_circle_copy, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CustomTextField(
                  controller: searchC,
                  onChanged: (q) {
                    filtered.assignAll(onSearch(q, itemsRx));
                  },
                  hint: 'Search'.tr,
                  icon: Iconsax.search_normal_1_copy,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  if (filtered.isEmpty && searchC.text.isEmpty) {
                    filtered.assignAll(itemsRx);
                  }

                  if (isLoadingRx.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filtered.isEmpty) {
                    return Center(child: Text('No data found'.tr));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text(itemLabel(item)),
                        onTap: () async {
                          await onSelected(item);
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppColors.darkBackgroundColor
          : AppColors.lightBackgroundColor,
    );

    Future.microtask(() async {
      await ensureLoad();
      if (searchC.text.isEmpty) {
        filtered.assignAll(itemsRx);
      } else {
        filtered.assignAll(onSearch(searchC.text, itemsRx));
      }
    });
  }
}
