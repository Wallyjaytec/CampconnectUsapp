import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/site_settings_properties_model.dart';

class LanguageSelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final ApiService _api = ApiService();
  final RxnString selectedLangCode = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;
  final RxList<LanguageModel> cachedLanguages = <LanguageModel>[].obs;
  
  late final LanguageController _languageController;

  List<LanguageModel> get languages {
    if (cachedLanguages.isNotEmpty) {
      return cachedLanguages;
    }
    return _languageController.languages;
  }
  
  bool get isLoading {
    return _languageController.isLoading.value && cachedLanguages.isEmpty;
  }

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
    
    // Load cached languages first (offline support)
    final cached = _box.read<List>('cached_languages');
    if (cached != null && cached.isNotEmpty) {
      final langs = cached.map((e) => LanguageModel.fromJson(e as Map<String, dynamic>)).toList();
      cachedLanguages.assignAll(langs);
    }
    
    // Default fallback languages for first-time offline
    if (cachedLanguages.isEmpty && _languageController.languages.isEmpty) {
      cachedLanguages.assignAll([
        LanguageModel(id: 1, title: 'English', code: 'en'),
        LanguageModel(id: 22, title: 'Deutsch', code: 'de'),
        LanguageModel(id: 23, title: '中文', code: 'zh'),
        LanguageModel(id: 24, title: 'Español', code: 'es'),
        LanguageModel(id: 25, title: 'العربية', code: 'ar'),
        LanguageModel(id: 26, title: 'Français', code: 'fr'),
        LanguageModel(id: 27, title: 'Русский', code: 'ru'),
        LanguageModel(id: 28, title: '日本語', code: 'ja'),
        LanguageModel(id: 29, title: '한국어', code: 'ko'),
        LanguageModel(id: 30, title: 'Português', code: 'pt'),
        LanguageModel(id: 31, title: 'Italiano', code: 'it'),
        LanguageModel(id: 32, title: 'हिन्दी', code: 'hi'),
      ]);
    }
    
    // Also check if languages already loaded in controller
    if (_languageController.languages.isNotEmpty) {
      cachedLanguages.assignAll(_languageController.languages);
      final jsonList = _languageController.languages.map((e) => e.toJson()).toList();
      _box.write('cached_languages', jsonList);
    }
    
    // Listen for when languages load from API
    ever(_languageController.languages, (List<LanguageModel> langs) {
      if (langs.isNotEmpty) {
        cachedLanguages.assignAll(langs);
        final jsonList = langs.map((e) => e.toJson()).toList();
        _box.write('cached_languages', jsonList);
      }
    });
  }

  void selectLanguage(String code) {
    selectedLangCode.value = code;
  }

  void saveAndContinue() async {
    if (selectedLangCode.value != null) {
      isSaving.value = true;
      
      // Save to local storage immediately
      _box.write('selected_language_code', selectedLangCode.value);
      _box.write('selected_language_api_code', selectedLangCode.value);
      _box.write('language_selected', true);
      // DO NOT write onboarding_done here - only in country screen
      
      // Preload countries in background
      try {
        final url = AppConfig.getCountriesUrl();
        await _api.getJson(url);
      } catch (e) {}
      
      // Navigate immediately - no waiting
      Get.offAllNamed('/country_select');
      
      // Sync with server in background
      try {
        await _languageController.setLanguage(selectedLangCode.value!);
      } catch (e) {
        print('Background language sync failed: $e');
      }
      
      isSaving.value = false;
    }
  }

  static bool get isLanguageSelected => GetStorage().read<bool>('language_selected') ?? false;

  String getFlagEmoji(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en': return '🇺🇸';
      case 'de': return '🇩🇪';
      case 'zh': return '🇨🇳';
      case 'es': return '🇪🇸';
      case 'ar': return '🇸🇦';
      case 'fr': return '🇫🇷';
      case 'ru': return '🇷🇺';
      case 'ja': return '🇯🇵';
      case 'ko': return '🇰🇷';
      case 'pt': return '🇵🇹';
      case 'it': return '🇮🇹';
      case 'hi': return '🇮🇳';
      default: return '🏳️';
    }
  }
}
