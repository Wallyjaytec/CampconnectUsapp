import 'package:flutter/material.dart';

class LocaleMapper {
  static const Map<String, Locale> _aliases = {
    'bd': Locale('bn'),
    'sa': Locale('ar', 'SA'),
  };

  static Locale fromApiCode(String? code) {
    final normalized = (code ?? '').trim();
    if (normalized.isEmpty) return const Locale('en');

    final alias = _aliases[normalized.toLowerCase()];
    if (alias != null) return alias;

    final hasDash = normalized.contains('-');
    final hasUnderscore = normalized.contains('_');
    if (hasDash || hasUnderscore) {
      final parts = normalized.split(hasDash ? '-' : '_');
      final lang = parts[0].toLowerCase();
      final country = parts.length > 1 ? parts[1].toUpperCase() : null;
      if (country != null && country.isNotEmpty) {
        return Locale(lang, country);
      }
      return Locale(lang);
    }

    if (normalized.length == 2) {
      return Locale(normalized.toLowerCase());
    }

    return const Locale('en');
  }

  static String toApiCode(Locale locale) {
    for (final entry in _aliases.entries) {
      if (entry.value.languageCode == locale.languageCode &&
          (entry.value.countryCode ?? '') == (locale.countryCode ?? '')) {
        return entry.key;
      }
    }
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}-${locale.countryCode}';
    }
    return locale.languageCode;
  }

  static String localeKey(Locale locale) {
    final lang = locale.languageCode;
    final country = locale.countryCode;
    return (country != null && country.isNotEmpty) ? '${lang}_$country' : lang;
  }

  static bool isRtl(Locale locale) {
    const rtlLangs = {'ar', 'fa', 'he', 'ur'};
    return rtlLangs.contains(locale.languageCode.toLowerCase());
  }
}
