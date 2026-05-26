import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../data/models/site_settings_properties_model.dart';

class LanguageSelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final RxnString selectedLangCode = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;
  final RxList<LanguageModel> cachedLanguages = <LanguageModel>[].obs;
  
  late final LanguageController _languageController;

  List<LanguageModel> get languages {
    // Return cached languages if available, otherwise from controller
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
    final cached = _box.read<List<dynamic>>('cached_languages');
    if (cached != null) {
      cachedLanguages.assignAll(cached.map((e) => LanguageModel.fromJson(e)).toList());
    }
    
    // Listen for when languages load from API and cache them
    ever(_languageController.languages, (List<LanguageModel> langs) {
      if (langs.isNotEmpty) {
        cachedLanguages.assignAll(langs);
        // Save to cache
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
      
      // Navigate immediately - no waiting
      Get.offAllNamed('/country_select');
      
      // Sync with server in background (don't wait for result)
      try {
        await _languageController.setLanguage(selectedLangCode.value!);
      } catch (e) {
        // Silently fail - will retry when app restarts or online
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
