import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../data/models/site_settings_properties_model.dart';
import '../../data/repositories/site_settings_properties_repository.dart';
import '../../modules/category/controller/category_controller.dart';
import '../../modules/compare/controller/compare_controller.dart';
import '../config/app_config.dart';
import '../services/language_service.dart';
import '../services/login_service.dart';
import '../utils/locale_mapper.dart';

class LanguageController extends GetxController {
  final SiteSettingsPropertiesRepository repo;
  LanguageController(this.repo);

  final box = GetStorage();

  final languages = <LanguageModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final selectedApiCode = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadPersistedLang();
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    isLoading.value = true;
    error.value = null;
    try {
      final res = await repo.fetchSiteProperties();
      languages.assignAll(res.languages);

      if ((selectedApiCode.value ?? '').isEmpty) {
        final fallback = res.languages.firstWhere(
          (l) => l.code == 'en',
          orElse: () => res.languages.first,
        );
        setLanguage(fallback.code, persist: false);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setLanguage(String apiCode, {bool persist = true}) async {
    selectedApiCode.value = apiCode;

    await LanguageService.load(apiCode, force: true);

    final locale = LocaleMapper.fromApiCode(apiCode);
    Get.updateLocale(locale);

    if (persist) {
      box.write(AppConfig.kLangCode, apiCode);
      box.write('selected_language_api_code', apiCode);
      _syncLanguageToServer(apiCode);
    }

    if (Get.isRegistered<CompareController>()) {
      await Get.find<CompareController>().refreshAll();
    }

    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().fetchCategories();
    }
  }

  Future<void> _syncLanguageToServer(String apiCode) async {
    try {
      final login = LoginService();
      final token = login.token;
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/ecommerce-core/customer/update-language');
      await http.post(
        uri,
        headers: {
          'Authorization': '${login.tokenType} $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'language': apiCode}),
      );
    } catch (_) {}
  }

  void _loadPersistedLang() {
    final saved = box.read<String>('selected_language_api_code') ?? box.read<String>(AppConfig.kLangCode);
    if (saved != null && saved.isNotEmpty) {
      selectedApiCode.value = saved;
      LanguageService.load(saved);
    }
  }
}
