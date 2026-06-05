import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:campconnectus_marketplace/data/models/site_settings_properties_model.dart';
import 'package:campconnectus_marketplace/data/responses/site_settings_properties_response.dart';

class SiteSettingsPropertiesRepository {
  final ApiService _api;
  SiteSettingsPropertiesRepository(this._api);

  Future<SiteSettingsPropertiesResponse> fetchSiteProperties() async {
    final json = await _api.getJson(AppConfig.sitePropertiesUrl());
    return SiteSettingsPropertiesResponse.fromJson(json);
  }

  Future<List<CurrencyModel>> fetchCurrencies() async {
    final res = await fetchSiteProperties();
    return res.currencies;
  }

  Future<CurrencyModel?> fetchDefaultCurrency() async {
    final res = await fetchSiteProperties();
    return res.defaultCurrency;
  }

  Future<List<LanguageModel>> fetchLanguages() async {
    final res = await fetchSiteProperties();
    return res.languages;
  }

  Future<Map<String, dynamic>> fetchSiteSettingsMap() async {
    final res = await fetchSiteProperties();
    return res.siteSettings;
  }

  Future<double?> fetchMinimumRechargeAmount() async {
    final s = await fetchSiteSettingsMap();
    final v = s['minimum_recharge_amount'];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<double?> fetchMaximumRechargeAmount() async {
    final s = await fetchSiteSettingsMap();
    final v = s['maximum_recharge_amount'];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
