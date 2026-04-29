class SiteSettingsPropertiesModel {
  final bool success;
  final List<LanguageModel> languages;
  final List<CurrencyModel> currencies;
  final CurrencyModel? defaultCurrency;
  final SiteProperties siteProperties;

  final Map<String, dynamic> siteSettings;

  const SiteSettingsPropertiesModel({
    required this.success,
    required this.languages,
    required this.currencies,
    required this.defaultCurrency,
    required this.siteProperties,
    required this.siteSettings,
  });

  factory SiteSettingsPropertiesModel.fromJson(Map<String, dynamic> json) {
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

    return SiteSettingsPropertiesModel(
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

class LanguageModel {
  final int id;
  final String title;
  final String code;

  const LanguageModel({
    required this.id,
    required this.title,
    required this.code,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> j) {
    return LanguageModel(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      title: j['title']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'code': code};
}

class CurrencyModel {
  final int id;
  final String name;
  final String code;
  final String symbol;
  final double conversionRate;

  final String position;
  final String thousandSeparator;
  final String decimalSeparator;
  final int numberOfDecimal;

  const CurrencyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.symbol,
    required this.conversionRate,
    required this.position,
    required this.thousandSeparator,
    required this.decimalSeparator,
    required this.numberOfDecimal,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> j) {
    final String decSep = (j['decimal_separator'] as String?) ?? '.';
    final String decimalsRaw = j['number_of_decimal']?.toString() ?? '2';
    final String convRaw = j['conversion_rate']?.toString() ?? '1';

    return CurrencyModel(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      symbol: j['symbol']?.toString() ?? '',
      conversionRate: double.tryParse(convRaw) ?? 1.0,
      position: j['position']?.toString() ?? '1',
      thousandSeparator: j['thousand_separator']?.toString() ?? ',',
      decimalSeparator: decSep,
      numberOfDecimal: int.tryParse(decimalsRaw) ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'symbol': symbol,
    'conversion_rate': conversionRate.toString(),
    'position': position,
    'thousand_separator': thousandSeparator,
    'decimal_separator': decimalSeparator,
    'number_of_decimal': numberOfDecimal.toString(),
  };

  bool get isPrefix => position == '1';

  String formatSimple(num amount) {
    final double n = amount.toDouble();
    final fixed = n.toStringAsFixed(numberOfDecimal);

    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    final withThousands = _withThousands(intPart, thousandSeparator);
    final numberStr = decPart.isEmpty
        ? withThousands
        : '$withThousands$decimalSeparator$decPart';

    return isPrefix ? '$symbol$numberStr' : '$numberStr$symbol';
  }

  static String _withThousands(String digits, String sep) {
    final buf = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buf.write(digits[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(sep);
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }
}

class SiteProperties {
  final String logo;
  final String logoDark;
  final String mobileLogo;
  final String mobileDarkLogo;
  final String siteTitle;
  final String siteName;
  final String siteMotto;
  final String favicon;
  final String stickyBlackLogo;
  final String stickyLogo;
  final String stickyBlackMobileLogo;
  final String stickyMobileLogo;
  final String copyright;
  final int appDemo;

  const SiteProperties({
    required this.logo,
    required this.logoDark,
    required this.mobileLogo,
    required this.mobileDarkLogo,
    required this.siteTitle,
    required this.siteName,
    required this.siteMotto,
    required this.favicon,
    required this.stickyBlackLogo,
    required this.stickyLogo,
    required this.stickyBlackMobileLogo,
    required this.stickyMobileLogo,
    required this.copyright,
    required this.appDemo,
  });

  factory SiteProperties.fromJson(Map<String, dynamic> j) {
    return SiteProperties(
      logo: j['logo']?.toString() ?? '',
      logoDark: j['logo_dark']?.toString() ?? '',
      mobileLogo: j['mobile_logo']?.toString() ?? '',
      mobileDarkLogo: j['mobile_dark_logo']?.toString() ?? '',
      siteTitle: j['site_title']?.toString() ?? '',
      siteName: j['site_name']?.toString() ?? '',
      siteMotto: j['site_motto']?.toString() ?? '',
      favicon: j['favicon']?.toString() ?? '',
      stickyBlackLogo: j['sticky_black_logo']?.toString() ?? '',
      stickyLogo: j['sticky_logo']?.toString() ?? '',
      stickyBlackMobileLogo: j['sticky_black_mobile_logo']?.toString() ?? '',
      stickyMobileLogo: j['sticky_mobile_logo']?.toString() ?? '',
      copyright: j['copyright']?.toString() ?? '',
      appDemo: j['app_demo'] is int
          ? j['app_demo'] as int
          : int.tryParse('${j['app_demo']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'logo': logo,
    'logo_dark': logoDark,
    'mobile_logo': mobileLogo,
    'mobile_dark_logo': mobileDarkLogo,
    'site_title': siteTitle,
    'site_name': siteName,
    'site_motto': siteMotto,
    'favicon': favicon,
    'sticky_black_logo': stickyBlackLogo,
    'sticky_logo': stickyLogo,
    'sticky_black_mobile_logo': stickyBlackMobileLogo,
    'sticky_mobile_logo': stickyMobileLogo,
    'copyright': copyright,
    'app_demo': appDemo,
  };
}
