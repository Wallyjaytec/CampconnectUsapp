import 'package:get/get.dart';

import '../../data/repositories/site_settings_properties_repository.dart';
import '../controllers/language_controller.dart';
import '../services/api_service.dart';

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiService());
    Get.lazyPut(() => SiteSettingsPropertiesRepository(Get.find<ApiService>()));
    Get.put(LanguageController(Get.find<SiteSettingsPropertiesRepository>()));
  }
}
