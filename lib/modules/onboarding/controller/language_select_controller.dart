import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../data/models/site_settings_properties_model.dart';

class LanguageSelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final RxnString selectedLangCode = RxnString();
  
  late final LanguageController _languageController;

  List<LanguageModel> get languages => _languageController.languages;
  bool get isLoading => _languageController.isLoading.value;

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
      // Use your existing LanguageController to set the language
      await _languageController.setLanguage(selectedLangCode.value!);
      
      // Mark onboarding language step as done
      _box.write('language_selected', true);
      
      // Navigate to country select
      Get.offAllNamed('/country_select');
    }
  }

  static bool get isLanguageSelected => GetStorage().read<bool>('language_selected') ?? false;

  String getFlagEmoji(String code) {
    if (code.length != 2) return '';
    final first = code.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = code.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }
}
