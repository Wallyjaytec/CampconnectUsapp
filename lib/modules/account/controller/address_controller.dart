import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/site_settings_properties_repository.dart';
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
      Get.snackbar(
        'Error'.tr,
        'Failed to load countries'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
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
      Get.snackbar(
        'Error'.tr,
        'Failed to load states'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
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
      Get.snackbar(
        'Error'.tr,
        'Failed to load cities'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      isCitiesLoading.value = false;
    }
  }

  Future<void> onSelectCountry(CountryModel c) async {
    selectedCountry.value = c;
    countryC.text = c.name;

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

    selectedCity.value = null;
    cityC.clear();
    cities.clear();

    await fetchCities(s.id);
  }

  Future<void> onSelectCity(CityModel c) async {
    selectedCity.value = c;
    cityC.text = c.name;
  }

  Future<void> submitNewAddress() async {
    final v = fieldVisibility.value;

    final co = selectedCountry.value;
    final st = selectedState.value;
    final ci = selectedCity.value;

    int countryId = 0;
    int stateId = 0;
    int cityId = 0;

    if (v.showLocation) {
      if (co == null || st == null || ci == null) {
        Get.snackbar(
          'Missing info'.tr,
          '${'Country'.tr}, ${'State'.tr}, ${'City'.tr} ${'required'.tr}',
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
        return;
      }
      countryId = co.id;
      stateId = st.id;
      cityId = ci.id;
    } else {
      countryId = 0;
      stateId = 0;
      cityId = 0;
    }

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

      final success =
          (res['success'] == true) || (res['success']?.toString() == 'true');

      if (success) {
        Get.back(result: true);
      } else {
        Get.snackbar(
          'Address not added'.tr,
          'Check required fields'.tr,
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

  String? _guessPhoneCode(String code) {
    switch (code.toUpperCase()) {
      case 'BD':
        return '880';
      case 'IN':
        return '91';
      case 'US':
        return '1';
      case 'GB':
        return '44';
      default:
        return null;
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
      Get.snackbar(
        'Error'.tr,
        'Failed to load addresses'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
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
      Get.snackbar(
        'Error'.tr,
        'Refresh failed'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      isRefreshing.value = false;
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
