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

  static const String _countryKey = 'selected_country';

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
    try {
      final url = AppConfig.getCountriesUrl();
      final resp = await _api.getJson(url);
      final data = resp['data'];
      if (data != null && data['countries'] != null) {
        final list = List<Map<String, dynamic>>.from(data['countries']);
        list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        countries.assignAll(list);
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
      final country = countries.firstWhere((c) => c['id'] == selectedCountryId.value);
      _box.write(_countryKey, country['id']);
      _box.write('selected_country_code', country['code']);
      _box.write('selected_country_name', country['name']);
      _box.write('onboarding_done', true);
      Get.offAllNamed('/bottom_navbar_view');
    }
  }

  static bool get isOnboardingDone => GetStorage().read<bool>('onboarding_done') ?? false;
  static String? get savedCountryCode => GetStorage().read<String>('selected_country_code');
  static int? get savedCountryId => GetStorage().read<int>('selected_country');
}
