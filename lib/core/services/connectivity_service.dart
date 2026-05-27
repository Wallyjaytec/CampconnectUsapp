import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/utils/locale_mapper.dart';
import 'package:kartly_e_commerce/core/services/language_service.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final GetStorage _box = GetStorage();

  Future<ConnectivityService> init() async {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncLanguageWhenOnline();
      }
    });
    return this;
  }

  void _syncLanguageWhenOnline() async {
    final savedLang = _box.read<String>('selected_language_api_code');
    if (savedLang != null && savedLang.isNotEmpty) {
      // Re-fetch translations from API now that we're back online
      try {
        await LanguageService.load(savedLang, force: true);
      } catch (_) {}

      // Then update the locale
      final expectedLocale = LocaleMapper.fromApiCode(savedLang);
      final currentLocale = Get.locale;

      if (currentLocale?.languageCode != expectedLocale.languageCode) {
        Get.updateLocale(expectedLocale);
      }
    }
  }
}
