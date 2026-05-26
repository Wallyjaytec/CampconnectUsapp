import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';

class CountrySelectController extends GetxController {
  final ApiService _api = ApiService();
  final GetStorage _box = GetStorage();
  
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> countries = <Map<String, dynamic>>[].obs;
  final RxnInt selectedCountryId = RxnInt();
  final RxString selectedCountryName = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;

  static const String _countryKey = 'selected_country';
  static const String _cachedCountriesKey = 'cached_countries';

  List<Map<String, dynamic>> get filteredCountries {
    if (searchQuery.value.isEmpty) return countries;
    return countries.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadCountries();
  }

  Future<void> loadCountries() async {
    // Load from local JSON file (offline first - works immediately)
    try {
      final jsonString = await rootBundle.loadString('assets/countries.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> jsonList = jsonData['data']['countries'];
      final list = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      countries.assignAll(list);
      
      // Save to cache for faster loading next time
      _box.write(_cachedCountriesKey, list);
    } catch (e) {
      print('Error loading local countries: $e');
      // Fallback to cache or API
      final cachedCountries = _box.read(_cachedCountriesKey);
      if (cachedCountries != null && cachedCountries.isNotEmpty) {
        countries.assignAll(List<Map<String, dynamic>>.from(cachedCountries));
      } else {
        isLoading.value = true;
        await _fetchFromApi();
      }
    }
  }
  
  Future<void> _fetchFromApi() async {
    try {
      final url = AppConfig.getCountriesUrl();
      final resp = await _api.getJson(url);
      final data = resp['data'];
      if (data != null && data['countries'] != null) {
        final list = List<Map<String, dynamic>>.from(data['countries']);
        list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        countries.assignAll(list);
        _box.write(_cachedCountriesKey, list);
      } else {
        error.value = 'Failed to load countries'.tr;
      }
    } catch (e) {
      error.value = 'Failed to load countries'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  void selectCountry(int id) {
    selectedCountryId.value = id;
    final country = countries.firstWhere((c) => c['id'] == id);
    selectedCountryName.value = country['name'] ?? '';
  }

  void saveAndContinue() {
    if (selectedCountryId.value != null) {
      isSaving.value = true;
      
      final country = countries.firstWhere((c) => c['id'] == selectedCountryId.value);
      
      _box.write(_countryKey, country['id']);
      _box.write('selected_country_code', country['code']);
      _box.write('selected_country_name', country['name']);
      _box.write('country_selected', true);
      _box.write('onboarding_complete', true);
      
      Get.offAllNamed('/bottom_navbar_view');
      
      isSaving.value = false;
    }
  }

  String getCountryFlagEmoji(String countryCode) {
    if (countryCode.isEmpty || countryCode.length != 2) return '🏳️';
    final first = countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  static bool get isOnboardingDone => GetStorage().read<bool>('onboarding_complete') ?? false;
  static bool get isCountrySelected => GetStorage().read<bool>('country_selected') ?? false;
  static String? get savedCountryCode => GetStorage().read<String>('selected_country_code');
  static int? get savedCountryId => GetStorage().read<int>('selected_country');
}
