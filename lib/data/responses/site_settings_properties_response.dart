import '../models/site_settings_properties_model.dart';

class SiteSettingsPropertiesResponse {
  final bool success;
  final List<LanguageModel> languages;
  final List<CurrencyModel> currencies;
  final CurrencyModel? defaultCurrency;
  final SiteProperties siteProperties;
  final Map<String, dynamic> siteSettings;

  const SiteSettingsPropertiesResponse({
    required this.success,
    required this.languages,
    required this.currencies,
    required this.defaultCurrency,
    required this.siteProperties,
    required this.siteSettings,
  });

  factory SiteSettingsPropertiesResponse.fromJson(Map<String, dynamic> json) {
    final langs = (json['languages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LanguageModel.fromJson)
        .toList();

    final currs = (json['currencies'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CurrencyModel.fromJson)
        .toList();

    final defMap = json['default_currency'] as Map<String, dynamic>?;
    final def = defMap != null ? CurrencyModel.fromJson(defMap) : null;

    return SiteSettingsPropertiesResponse(
      success: json['success'] == true,
      languages: langs,
      currencies: currs,
      defaultCurrency: def,
      siteProperties: SiteProperties.fromJson(
        (json['siteProperties'] as Map<String, dynamic>? ?? const {}),
      ),
      siteSettings: Map<String, dynamic>.from(
        (json['site_settings'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'languages': languages.map((e) => e.toJson()).toList(),
    'currencies': currencies.map((e) => e.toJson()).toList(),
    'default_currency': defaultCurrency?.toJson(),
    'siteProperties': siteProperties.toJson(),
    'site_settings': siteSettings,
  };
}
