import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../data/models/site_settings_properties_model.dart';

class LanguageSelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final RxnString selectedLangCode = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;
  
  late final LanguageController _languageController;

  List<LanguageModel> get languages => _languageController.languages;
  bool get isLoading => _languageController.isLoading.value;

  List<LanguageModel> get filteredLanguages {
    if (searchQuery.value.isEmpty) return languages;
    return languages.where((lang) {
      return lang.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
             lang.code.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _languageController = Get.find<LanguageController>();
  }

  void selectLanguage(String code) {
    selectedLangCode.value = code;
  }

  void saveAndContinue() async {
    if (selectedLangCode.value != null) {
      isSaving.value = true;
      
      // Save to storage immediately
      _box.write('selected_language_code', selectedLangCode.value);
      _box.write('selected_language_api_code', selectedLangCode.value);
      _box.write('language_selected', true);
      
      // Navigate immediately - don't wait for language to load
      Get.offAllNamed('/country_select');
      
      // Do the heavy work after navigation
      await _languageController.setLanguage(selectedLangCode.value!);
      
      isSaving.value = false;
    }
  }

  static bool get isLanguageSelected => GetStorage().read<bool>('language_selected') ?? false;

  String getFlagUrl(String code) {
    return 'https://campconnectus.store/public/web-assets/backend/img/flags/$code.png';
  }
}
