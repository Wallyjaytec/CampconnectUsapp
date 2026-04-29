import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/site_settings_properties_repository.dart';
import '../model/address_field_visibility_model.dart';
import '../model/address_model.dart';

class EditAddressController extends GetxController {
  final CustomerAddress initial;

  EditAddressController(this.initial);

  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final countryC = TextEditingController();
  final stateC = TextEditingController();
  final cityC = TextEditingController();
  final postalC = TextEditingController();
  final addressC = TextEditingController();

  final defaultShipping = 2.obs;
  final defaultBilling = 2.obs;
  final status = 1.obs;
  String? phoneCode;

  final selectedCountry = Rx<CountryModel?>(null);
  final selectedState = Rx<StateModel?>(null);
  final selectedCity = Rx<CityModel?>(null);

  final countries = <CountryModel>[].obs;
  final states = <StateModel>[].obs;
  final cities = <CityModel>[].obs;
  final isCountriesLoading = false.obs;
  final isStatesLoading = false.obs;
  final isCitiesLoading = false.obs;

  final isSubmitting = false.obs;

  final isFormLoading = true.obs;

  final fieldVisibility = AddressFieldVisibility.defaults().obs;

  late final AddressRepository addressRepo;
  late final SiteSettingsPropertiesRepository _settingsRepo;

  @override
  void onInit() {
    super.onInit();
    final api = ApiService();
    addressRepo = AddressRepository(api);
    _settingsRepo = SiteSettingsPropertiesRepository(api);

    nameC.text = initial.name;
    phoneC.text = initial.phone;
    postalC.text = initial.postalCode;
    addressC.text = initial.address;
    defaultShipping.value = initial.defaultShipping == 1 ? 1 : 2;
    defaultBilling.value = initial.defaultBilling == 1 ? 1 : 2;
    status.value = _statusFromApi(initial.status);

    phoneCode = initial.phoneCode.isNotEmpty ? initial.phoneCode : null;
    countryC.text = initial.country?.name ?? '';
    stateC.text = initial.state?.name ?? '';
    cityC.text = initial.city?.name ?? '';

    _initForm();
  }

  Future<void> _initForm() async {
    try {
      await _loadFieldVisibility();
      await _bootstrapSelections();
    } finally {
      isFormLoading.value = false;
    }
  }

  Future<void> _loadFieldVisibility() async {
    try {
      final map = await _settingsRepo.fetchSiteSettingsMap();
      fieldVisibility.value = AddressFieldVisibility.fromSiteSettings(map);
    } catch (_) {
      fieldVisibility.value = AddressFieldVisibility.defaults();
    }
  }

  Future<void> refreshFormConfig() async {
    isFormLoading.value = true;
    try {
      await _loadFieldVisibility();

      countries.clear();
      states.clear();
      cities.clear();
      selectedCountry.value = null;
      selectedState.value = null;
      selectedCity.value = null;

      await _bootstrapSelections();
    } finally {
      isFormLoading.value = false;
    }
  }

  Future<void> _bootstrapSelections() async {
    try {
      isCountriesLoading.value = true;
      final clist = await addressRepo.getCountries();
      countries.assignAll(clist);
      isCountriesLoading.value = false;

      if (initial.country != null) {
        final match = countries.firstWhereOrNull(
          (e) => e.id == initial.country!.id,
        );
        if (match != null) {
          selectedCountry.value = match;
        }
      }

      if (selectedCountry.value != null) {
        isStatesLoading.value = true;
        final slist = await addressRepo.getStates(
          countryId: selectedCountry.value!.id,
        );
        states.assignAll(slist);
        isStatesLoading.value = false;

        if (initial.state != null) {
          final sm = states.firstWhereOrNull((e) => e.id == initial.state!.id);
          if (sm != null) selectedState.value = sm;
        }
      }

      if (selectedState.value != null) {
        isCitiesLoading.value = true;
        final ctlist = await addressRepo.getCities(
          stateId: selectedState.value!.id,
        );
        cities.assignAll(ctlist);
        isCitiesLoading.value = false;

        if (initial.city != null) {
          final cm = cities.firstWhereOrNull((e) => e.id == initial.city!.id);
          if (cm != null) selectedCity.value = cm;
        }
      }
    } catch (_) {}
  }

  Future<void> onSelectCountry(CountryModel c) async {
    selectedCountry.value = c;
    countryC.text = c.name;

    selectedState.value = null;
    stateC.clear();
    states.clear();

    selectedCity.value = null;
    cityC.clear();
    cities.clear();

    isStatesLoading.value = true;
    final list = await addressRepo.getStates(countryId: c.id);
    states.assignAll(list);
    isStatesLoading.value = false;
  }

  Future<void> onSelectState(StateModel s) async {
    selectedState.value = s;
    stateC.text = s.name;

    selectedCity.value = null;
    cityC.clear();
    cities.clear();

    isCitiesLoading.value = true;
    final list = await addressRepo.getCities(stateId: s.id);
    cities.assignAll(list);
    isCitiesLoading.value = false;
  }

  void onSelectCity(CityModel c) {
    selectedCity.value = c;
    cityC.text = c.name;
  }

  Future<void> submitUpdate() async {
    final v = fieldVisibility.value;

    final misses = <String>[];

    if (nameC.text.trim().isEmpty) misses.add('Name');
    if (phoneC.text.trim().isEmpty) misses.add('Phone');
    if (postalC.text.trim().isEmpty) misses.add('Postal Code');
    if (addressC.text.trim().isEmpty) misses.add('Address');

    if (v.showLocation) {
      if (selectedCountry.value == null) misses.add('Country');
      if (selectedState.value == null) misses.add('State');
      if (selectedCity.value == null) misses.add('City');
    }

    if (misses.isNotEmpty) {
      Get.snackbar(
        'Missing info'.tr,
        (misses.length == 1)
            ? '${misses.first} ${'is required'.tr}'
            : '${misses.join(', ')} ${'is required'.tr}',
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    int countryId;
    int stateId;
    int cityId;

    if (v.showLocation) {
      countryId = selectedCountry.value!.id;
      stateId = selectedState.value!.id;
      cityId = selectedCity.value!.id;
    } else {
      countryId = initial.country?.id ?? 0;
      stateId = initial.state?.id ?? 0;
      cityId = initial.city?.id ?? 0;
    }

    try {
      isSubmitting.value = true;

      final res = await addressRepo.updateCustomerAddress(
        id: initial.id,
        name: nameC.text.trim(),
        phoneCode: phoneCode,
        phone: phoneC.text.trim(),
        postalCode: postalC.text.trim(),
        address: addressC.text.trim(),
        status: status.value,
        defaultShipping: defaultShipping.value,
        defaultBilling: defaultBilling.value,
        countryId: countryId,
        stateId: stateId,
        cityId: cityId,
      );

      final ok =
          (res['success'] == true) || (res['success']?.toString() == 'true');

      if (ok) {
        Get.snackbar(
          'Updated'.tr,
          'Address updated successfully'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
        await Future.delayed(const Duration(seconds: 2));
        Get.back(result: true);
      } else {
        Get.snackbar(
          'Failed'.tr,
          'Could not update address'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  int _statusFromApi(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s == 'active' || s == '1') return 1;
    if (s == 'inactive' || s == '2') return 2;
    return 1;
  }

  @override
  void onClose() {
    nameC.dispose();
    phoneC.dispose();
    countryC.dispose();
    stateC.dispose();
    cityC.dispose();
    postalC.dispose();
    addressC.dispose();
    super.onClose();
  }
}
