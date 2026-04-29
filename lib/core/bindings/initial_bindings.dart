import 'package:get/get.dart';

import '../../data/repositories/site_settings_properties_repository.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LanguageService>()) {
      Get.put<LanguageService>(LanguageService.instance, permanent: true);
    }

    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiService(), permanent: true);
    }

    if (!Get.isRegistered<SiteSettingsPropertiesRepository>()) {
      Get.put<SiteSettingsPropertiesRepository>(
        SiteSettingsPropertiesRepository(Get.find<ApiService>()),
        permanent: true,
      );
    }
  }
}
