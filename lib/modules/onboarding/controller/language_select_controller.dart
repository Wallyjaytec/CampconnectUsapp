import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageSelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final RxnString selectedLangCode = RxnString();

  final List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'EN', 'flag': 'GB'},
    {'name': 'German (Deutsch)', 'code': 'DE', 'flag': 'DE'},
    {'name': 'Chinese (中文)', 'code': 'ZH', 'flag': 'CN'},
    {'name': 'Spanish (Español)', 'code': 'ES', 'flag': 'ES'},
    {'name': 'Arabic (العربية)', 'code': 'AR', 'flag': 'SA'},
    {'name': 'French (Français)', 'code': 'FR', 'flag': 'FR'},
    {'name': 'Russian (Русский)', 'code': 'RU', 'flag': 'RU'},
    {'name': 'Japanese (日本語)', 'code': 'JA', 'flag': 'JP'},
    {'name': 'Korean (한국어)', 'code': 'KO', 'flag': 'KR'},
    {'name': 'Portuguese (Português)', 'code': 'PT', 'flag': 'PT'},
    {'name': 'Italian (Italiano)', 'code': 'IT', 'flag': 'IT'},
    {'name': 'Hindi (हिन्दी)', 'code': 'HI', 'flag': 'IN'},
  ];

  void selectLanguage(String code) {
    selectedLangCode.value = code;
  }

  void saveAndContinue() {
    if (selectedLangCode.value != null) {
      final lang = languages.firstWhere((l) => l['code'] == selectedLangCode.value);
      _box.write('selected_language_code', lang['code']);
      _box.write('selected_language_api_code', lang['code']?.toLowerCase());
      _box.write('language_selected', true);
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
