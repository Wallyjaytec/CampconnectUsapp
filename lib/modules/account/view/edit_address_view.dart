import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../auth/widget/custom_text_field.dart';
import '../controller/edit_address_controller.dart';
import '../model/address_model.dart';

class EditAddressView extends StatelessWidget {
  const EditAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    final initial = Get.arguments as CustomerAddress;
    Get.delete<EditAddressController>(force: true);
    final c = Get.put(EditAddressController(initial));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Edit Address'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: c.refreshFormConfig,
        child: Obx(() {
          return ListView(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (c.isFormLoading.value)
                ..._buildShimmerForm(context)
              else
                ..._buildRealForm(context, c),
            ],
          );
        }),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Obx(() {
          final submitLoading = c.isSubmitting.value;
          final disableBtn = submitLoading || c.isFormLoading.value;
          return SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: disableBtn ? null : c.submitUpdate,
              child: submitLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Update Address'.tr),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildRealForm(BuildContext context, EditAddressController c) {
    final v = c.fieldVisibility.value;
    final widgets = <Widget>[];

    if (v.showName) {
      widgets.addAll([
        CustomTextField(controller: c.nameC, hint: 'Name'.tr, icon: Iconsax.user_copy),
        const SizedBox(height: 10),
      ]);
    }

    if (v.showPhone) {
      widgets.addAll([
        CustomTextField(controller: c.phoneC, hint: 'Phone Number'.tr, icon: Iconsax.call_copy, keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
      ]);
    }

    if (v.showLocation) {
      widgets.addAll([
        CustomTextField(controller: c.countryC, hint: 'Country'.tr, icon: Iconsax.global_copy, readOnly: true, onTap: () => _openCountrySheet(context, c), suffix: const Icon(Iconsax.arrow_down_1_copy, size: 16)),
        const SizedBox(height: 10),
        CustomTextField(
          controller: c.stateC, hint: 'State'.tr, icon: Iconsax.location_copy, readOnly: true,
          onTap: () {
            if (c.selectedCountry.value == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select country first'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2)),
              );
              return;
            }
            _openStateSheet(context, c);
          },
          suffix: const Icon(Iconsax.arrow_down_1_copy, size: 16),
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: c.cityC, hint: 'City'.tr, icon: Iconsax.route_square_copy, readOnly: true,
          onTap: () {
            if (c.selectedState.value == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select state first'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2)),
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
      widgets.addAll([CustomTextField(controller: c.postalC, hint: 'Postal Code'.tr, icon: Iconsax.hashtag_1_copy, keyboardType: TextInputType.number), const SizedBox(height: 10)]);
    }

    if (v.showAddress) {
      widgets.addAll([CustomTextField(controller: c.addressC, hint: 'Address'.tr, icon: Iconsax.location_copy), const SizedBox(height: 10)]);
    }

    widgets.addAll([
      Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionHeader('Status'.tr), RadioGroup<int>(groupValue: c.status.value, onChanged: (v) { if (v == null) return; c.status.value = v; }, child: _radioPair())])),
      const SizedBox(height: 8),
      Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionHeader('Default Shipping Address'.tr), RadioGroup<int>(groupValue: c.defaultShipping.value, onChanged: (v) { if (v == null) return; c.defaultShipping.value = v; }, child: _radioPair())])),
      const SizedBox(height: 8),
      Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionHeader('Default Billing Address'.tr), RadioGroup<int>(groupValue: c.defaultBilling.value, onChanged: (v) { if (v == null) return; c.defaultBilling.value = v; }, child: _radioPair())])),
      const SizedBox(height: 10),
    ]);

    if (widgets.isEmpty) widgets.add(Text('No address fields enabled from server settings'.tr));
    return widgets;
  }

  List<Widget> _buildShimmerForm(BuildContext context) => [_shimmerField(context), const SizedBox(height: 10), _shimmerField(context), const SizedBox(height: 10), _shimmerField(context), const SizedBox(height: 10), _shimmerField(context), const SizedBox(height: 10), _shimmerField(context), const SizedBox(height: 10), _shimmerField(context), const SizedBox(height: 16), _shimmerRadioRow(context), const SizedBox(height: 8), _shimmerRadioRow(context), const SizedBox(height: 8), _shimmerRadioRow(context)];

  Widget _shimmerField(BuildContext context) {
    final isDark = Get.theme.brightness == Brightness.dark;
    return Shimmer.fromColors(baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!, highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!, child: Container(height: 52, decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12))));
  }

  Widget _shimmerRadioRow(BuildContext context) {
    final isDark = Get.theme.brightness == Brightness.dark;
    return Shimmer.fromColors(baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!, highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!, child: Row(children: [Expanded(child: Container(height: 32, decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(8)))), const SizedBox(width: 8), Expanded(child: Container(height: 32, decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(8))))]));
  }

  Widget _sectionHeader(String title) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)))]);

  Widget _radioPair() => Row(children: [SizedBox(width: 100, child: _radioTile(label: 'Active'.tr, value: 1)), SizedBox(width: 200, child: _radioTile(label: 'Inactive'.tr, value: 2))]);

  Widget _radioTile({required String label, required int value}) => RadioListTile<int>(value: value, title: Text(label), dense: true, radioScaleFactor: 0.8, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, visualDensity: const VisualDensity(horizontal: -4, vertical: -4));

  void _openCountrySheet(BuildContext context, EditAddressController c) {
    _openSelectSheet<CountryModel>(title: 'Select Country'.tr, itemsRx: c.countries, itemLabel: (x) => x.name, onSelected: (x) => c.onSelectCountry(x), isLoadingRx: c.isCountriesLoading, ensureLoad: () async { if (c.countries.isNotEmpty) return; c.isCountriesLoading.value = true; final list = await c.addressRepo.getCountries(); c.countries.assignAll(list); c.isCountriesLoading.value = false; }, onSearch: (q, list) { final ql = q.toLowerCase(); return list.where((e) => e.name.toLowerCase().contains(ql)).toList(); });
  }

  void _openStateSheet(BuildContext context, EditAddressController c) {
    _openSelectSheet<StateModel>(title: 'Select State'.tr, itemsRx: c.states, itemLabel: (x) => x.name, onSelected: (x) => c.onSelectState(x), isLoadingRx: c.isStatesLoading, ensureLoad: () async { if (c.selectedCountry.value == null) return; if (c.states.isNotEmpty) return; c.isStatesLoading.value = true; final list = await c.addressRepo.getStates(countryId: c.selectedCountry.value!.id); c.states.assignAll(list); c.isStatesLoading.value = false; }, onSearch: (q, list) { final ql = q.toLowerCase(); return list.where((e) => e.name.toLowerCase().contains(ql)).toList(); });
  }

  void _openCitySheet(BuildContext context, EditAddressController c) {
    _openSelectSheet<CityModel>(title: 'Select City'.tr, itemsRx: c.cities, itemLabel: (x) => x.name, onSelected: (x) => c.onSelectCity(x), isLoadingRx: c.isCitiesLoading, ensureLoad: () async { if (c.selectedState.value == null) return; if (c.cities.isNotEmpty) return; c.isCitiesLoading.value = true; final list = await c.addressRepo.getCities(stateId: c.selectedState.value!.id); c.cities.assignAll(list); c.isCitiesLoading.value = false; }, onSearch: (q, list) { final ql = q.toLowerCase(); return list.where((e) => e.name.toLowerCase().contains(ql)).toList(); });
  }

  void _openSelectSheet<T>({
    required String title,
    required RxList<T> itemsRx,
    required String Function(T) itemLabel,
    required void Function(T) onSelected,
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
          decoration: BoxDecoration(color: isDark ? AppColors.darkBackgroundColor : AppColors.lightBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          height: Get.height * 0.7,
          child: Column(
            children: [
              Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))), GestureDetector(onTap: () => Get.back(), child: const Icon(Iconsax.close_circle_copy, size: 18))]),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3))]), child: CustomTextField(controller: searchC, onChanged: (q) => filtered.assignAll(onSearch(q, itemsRx)), hint: 'Search'.tr, icon: Iconsax.search_normal_1_copy)),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  if (filtered.isEmpty && searchC.text.isEmpty) filtered.assignAll(itemsRx);
                  if (isLoadingRx.value) return const Center(child: CircularProgressIndicator());
                  if (filtered.isEmpty) return Center(child: Text('No data found'.tr));
                  return ListView.separated(itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) { final item = filtered[i]; return ListTile(dense: true, title: Text(itemLabel(item)), onTap: () { onSelected(item); Get.back(); }); });
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBackgroundColor : AppColors.lightBackgroundColor,
    );

    Future.microtask(() async {
      await ensureLoad();
      if (searchC.text.isEmpty) filtered.assignAll(itemsRx);
      else filtered.assignAll(onSearch(searchC.text, itemsRx));
    });
  }
}
