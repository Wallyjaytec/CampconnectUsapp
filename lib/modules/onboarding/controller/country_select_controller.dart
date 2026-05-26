import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';

class CountrySelectController extends GetxController {
  final ApiService _api = ApiService();
  final GetStorage _box = GetStorage();
  
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> countries = <Map<String, dynamic>>[].obs;
  final RxnInt selectedCountryId = RxnInt();
  final RxString selectedCountryName = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;

  static const String _countryKey = 'selected_country';
  static const String _cachedCountriesKey = 'cached_countries';

  // Default fallback countries for first-time offline
  final List<Map<String, dynamic>> defaultCountries = [
    {'id': 1, 'name': 'United States', 'code': 'US'},
    {'id': 2, 'name': 'Nigeria', 'code': 'NG'},
    {'id': 3, 'name': 'United Kingdom', 'code': 'GB'},
    {'id': 4, 'name': 'Canada', 'code': 'CA'},
    {'id': 5, 'name': 'Germany', 'code': 'DE'},
    {'id': 6, 'name': 'France', 'code': 'FR'},
    {'id': 7, 'name': 'Japan', 'code': 'JP'},
    {'id': 8, 'name': 'China', 'code': 'CN'},
    {'id': 9, 'name': 'India', 'code': 'IN'},
    {'id': 10, 'name': 'Australia', 'code': 'AU'},
  ];

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
    isLoading.value = true;
    error.value = '';
    
    // Try to load from cache first (offline support)
    final cachedCountries = _box.read(_cachedCountriesKey);
    if (cachedCountries != null && cachedCountries.isNotEmpty) {
      countries.assignAll(List<Map<String, dynamic>>.from(cachedCountries));
      isLoading.value = false;
    } else {
      // No cache - show default countries
      countries.assignAll(defaultCountries);
      isLoading.value = false;
    }
    
    // Then try to fetch from API (if online)
    try {
      final url = AppConfig.getCountriesUrl();
      final resp = await _api.getJson(url);
      final data = resp['data'];
      if (data != null && data['countries'] != null) {
        final list = List<Map<String, dynamic>>.from(data['countries']);
        list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        countries.assignAll(list);
        // Save to cache for offline use
        _box.write(_cachedCountriesKey, list);
      }
    } catch (e) {
      // Silently fail - default or cached data will be used
      if (countries.isEmpty) {
        error.value = 'Failed to load countries. Please check your internet connection.'.tr;
      }
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
      
      // Save to local storage immediately
      _box.write(_countryKey, country['id']);
      _box.write('selected_country_code', country['code']);
      _box.write('selected_country_name', country['name']);
      _box.write('country_selected', true);
      _box.write('onboarding_complete', true);
      
      // Navigate immediately - no waiting
      Get.offAllNamed('/bottom_navbar_view');
      
      // Sync with server in background (if needed)
      try {
        // Add any API call to save country to server here if needed
      } catch (e) {
        print('Background country sync failed: $e');
      }
      
      isSaving.value = false;
    }
  }

  static bool get isOnboardingDone => GetStorage().read<bool>('onboarding_complete') ?? false;
  static bool get isCountrySelected => GetStorage().read<bool>('country_selected') ?? false;
  static String? get savedCountryCode => GetStorage().read<String>('selected_country_code');
  static int? get savedCountryId => GetStorage().read<int>('selected_country');
}
