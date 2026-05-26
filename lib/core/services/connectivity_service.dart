import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kartly_e_commerce/core/utils/locale_mapper.dart';

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

  void _syncLanguageWhenOnline() {
    final savedLang = _box.read<String>('selected_language_api_code');
    if (savedLang != null && savedLang.isNotEmpty) {
      final currentLocale = Get.locale;
      final expectedLocale = LocaleMapper.fromApiCode(savedLang);
      
      if (currentLocale?.languageCode != expectedLocale.languageCode) {
        Get.updateLocale(expectedLocale);
      }
    }
  }
}
