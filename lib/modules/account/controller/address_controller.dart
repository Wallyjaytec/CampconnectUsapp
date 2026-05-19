import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/site_settings_properties_repository.dart';
import '../../../shared/utils/dialog_utils.dart';
import '../model/address_field_visibility_model.dart';
import '../model/address_model.dart';

class AddressController extends GetxController {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final countryC = TextEditingController();
  final stateC = TextEditingController();
  final cityC = TextEditingController();
  final postalC = TextEditingController();
  final addressC = TextEditingController();

  String? phoneCode;

  final addresses = <CustomerAddress>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  bool _loadedOnce = false;

  final isFormLoading = true.obs;

  final fieldVisibility = AddressFieldVisibility.defaults().obs;

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

  // Error states for each field
  final nameError = ''.obs;
  final phoneError = ''.obs;
  final countryError = ''.obs;
  final stateError = ''.obs;
  final cityError = ''.obs;
  final postalError = ''.obs;
  final addressError = ''.obs;

  late final AddressRepository _addressRepo;
  late final SiteSettingsPropertiesRepository _settingsRepo;

  @override
  void onInit() {
    super.onInit();
    final api = ApiService();
    _addressRepo = AddressRepository(api);
    _settingsRepo = SiteSettingsPropertiesRepository(api);

    _initForm();
  }

  void _clearErrors() {
    nameError.value = '';
    phoneError.value = '';
    countryError.value = '';
    stateError.value = '';
    cityError.value = '';
    postalError.value = '';
    addressError.value = '';
  }

  Future<void> _initForm() async {
    try {
      await _loadFieldVisibility();
      await ensureCountriesLoaded();
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

      countryC.clear();
      stateC.clear();
      cityC.clear();
      _clearErrors();

      await fetchCountries();
    } finally {
      isFormLoading.value = false;
    }
  }

  Future<void> ensureCountriesLoaded() async {
    if (countries.isNotEmpty) return;
    await fetchCountries();
  }

  Future<void> fetchCountries() async {
    try {
      isCountriesLoading.value = true;
      final list = await _addressRepo.getCountries();
      countries.assignAll(list);
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to load countries'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor);
    } finally {
      isCountriesLoading.value = false;
    }
  }

  Future<void> ensureStatesLoaded() async {
    final co = selectedCountry.value;
    if (co == null) return;
    if (states.isNotEmpty) return;
    await fetchStates(co.id);
  }

  Future<void> fetchStates(int countryId) async {
    try {
      isStatesLoading.value = true;
      final list = await _addressRepo.getStates(countryId: countryId);
      states.assignAll(list);
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to load states'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor);
    } finally {
      isStatesLoading.value = false;
    }
  }

  Future<void> ensureCitiesLoaded() async {
    final st = selectedState.value;
    if (st == null) return;
    if (cities.isNotEmpty) return;
    await fetchCities(st.id);
  }

  Future<void> fetchCities(int stateId) async {
    try {
      isCitiesLoading.value = true;
      final list = await _addressRepo.getCities(stateId: stateId);
      cities.assignAll(list);
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to load cities'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor);
    } finally {
      isCitiesLoading.value = false;
    }
  }

  Future<void> onSelectCountry(CountryModel c) async {
    selectedCountry.value = c;
    countryC.text = c.name;
    countryError.value = '';

    phoneCode = _guessPhoneCode(c.code);

    selectedState.value = null;
    stateC.clear();
    states.clear();

    selectedCity.value = null;
    cityC.clear();
    cities.clear();

    await fetchStates(c.id);
  }

  Future<void> onSelectState(StateModel s) async {
    selectedState.value = s;
    stateC.text = s.name;
    stateError.value = '';

    selectedCity.value = null;
    cityC.clear();
    cities.clear();

    await fetchCities(s.id);
  }

  Future<void> onSelectCity(CityModel c) async {
    selectedCity.value = c;
    cityC.text = c.name;
    cityError.value = '';
  }

  Future<void> submitNewAddress() async {
    _clearErrors();
    final v = fieldVisibility.value;
    bool hasError = false;

    if (v.showName && nameC.text.trim().isEmpty) {
      nameError.value = 'Required'.tr;
      hasError = true;
    }

    if (v.showPhone && phoneC.text.trim().isEmpty) {
      phoneError.value = 'Required'.tr;
      hasError = true;
    }

    if (v.showLocation) {
      if (selectedCountry.value == null) {
        countryError.value = 'Required'.tr;
        hasError = true;
      }
      if (selectedState.value == null) {
        stateError.value = 'Required'.tr;
        hasError = true;
      }
      if (selectedCity.value == null) {
        cityError.value = 'Required'.tr;
        hasError = true;
      }
    }

    if (v.showPostalCode && postalC.text.trim().isEmpty) {
      postalError.value = 'Required'.tr;
      hasError = true;
    }

    if (v.showAddress && addressC.text.trim().isEmpty) {
      addressError.value = 'Required'.tr;
      hasError = true;
    }

    if (hasError) return;

    final co = selectedCountry.value;
    final st = selectedState.value;
    final ci = selectedCity.value;

    int countryId = co?.id ?? 0;
    int stateId = st?.id ?? 0;
    int cityId = ci?.id ?? 0;

    try {
      isSubmitting.value = true;

      final res = await _addressRepo.addCustomerAddress(
        name: nameC.text.trim(),
        phoneCode: phoneCode,
        phone: phoneC.text.trim(),
        postalCode: postalC.text.trim(),
        address: addressC.text.trim(),
        countryId: countryId,
        stateId: stateId,
        cityId: cityId,
      );

      final success = (res['success'] == true) || (res['success']?.toString() == 'true');

      if (success) {
        Get.snackbar('Success'.tr, 'Address saved successfully'.tr, backgroundColor: Colors.green, snackPosition: SnackPosition.TOP, colorText: Colors.white, duration: const Duration(seconds: 2));
        await Future.delayed(const Duration(milliseconds: 500));
        safeBack(result: true);
      } else {
        Get.snackbar('Error'.tr, 'Failed to save address'.tr, backgroundColor: Colors.red, snackPosition: SnackPosition.TOP, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error'.tr, 'Something went wrong'.tr, backgroundColor: Colors.red, snackPosition: SnackPosition.TOP, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  String? _guessPhoneCode(String code) {
    switch (code.toUpperCase()) {
      case 'BD': return '880';
      case 'IN': return '91';
      case 'US': return '1';
      case 'GB': return '44';
      default: return null;
    }
  }

  Future<void> initLoad() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    await fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      final list = await _addressRepo.getAllCustomerAddresses();
      addresses.assignAll(list);
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to load addresses'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAddresses() async {
    try {
      isRefreshing.value = true;
      final list = await _addressRepo.getAllCustomerAddresses();
      addresses.assignAll(list);
    } catch (_) {
      Get.snackbar('Error'.tr, 'Refresh failed'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> deleteAddress(int addressId) async {
    try {
      await _addressRepo.deleteCustomerAddress(addressId);
      addresses.removeWhere((a) => a.id == addressId);
      addresses.refresh();
      Get.snackbar('Deleted'.tr, 'Address deleted successfully'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor, duration: const Duration(seconds: 2));
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to delete address: ${e.toString()}'.tr, backgroundColor: AppColors.redColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor, duration: const Duration(seconds: 3));
    }
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
