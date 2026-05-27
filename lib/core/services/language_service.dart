import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/locale_mapper.dart';

class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static final _box = GetStorage();

  static final Map<String, Map<String, String>> _memCache = {};
  static final Map<String, DateTime> _memCacheTime = {};
  static final Set<String> _inflight = <String>{};

  static const Duration _ttl = Duration(seconds: 1);

  static String _cacheKey(String apiCode) => 'i18n_$apiCode';
  static String _tsKey(String apiCode) => 'i18n_${apiCode}_ts';
  static String _etagKey(String apiCode) => 'i18n_${apiCode}_etag';

  static Future<void> load(String apiCode, {bool force = false}) async {
    final code = (apiCode).trim();

    if (!force && _memCache.containsKey(code)) {
      final memTime = _memCacheTime[code];
      if (memTime != null && DateTime.now().difference(memTime) < _ttl) {
        _applyToGetX(code, _memCache[code]!);
        return;
      }
    }

    if (!force) {
      final cachedStr = _box.read<String>(_cacheKey(code));
      final tsStr = _box.read<String>(_tsKey(code));
      DateTime? ts = tsStr != null ? DateTime.tryParse(tsStr) : null;

      if (cachedStr != null &&
          ts != null &&
          DateTime.now().difference(ts) < _ttl) {
        try {
          final cachedMap = Map<String, String>.from(json.decode(cachedStr));
          _memCache[code] = cachedMap;
          _memCacheTime[code] = ts;
          _applyToGetX(code, cachedMap);
          return;
        } catch (_) {}
      }
    }

    _inflight.add(code);
    try {
      final url = AppConfig.localeUrl(apiCode);
      final headers = <String, String>{'Accept': 'application/json'};

      final etag = _box.read<String>(_etagKey(code));
      if (!force && etag != null && etag.isNotEmpty) {
        headers['If-None-Match'] = etag;
      }

      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = json.decode(res.body);

        Map<String, dynamic> raw;
        if (decoded is Map<String, dynamic>) {
          raw = (decoded['data'] is Map<String, dynamic>)
              ? Map<String, dynamic>.from(decoded['data'])
              : decoded;
        } else {
          raw = const {};
        }

        final casted = <String, String>{};
        raw.forEach((k, v) {
          final key = k.toString();
          final s = (v is String) ? v : v?.toString();
          if (s == null ||
              s.trim().isEmpty ||
              s.trim().toLowerCase() == 'null') {
            casted[key] = key;
          } else {
            casted[key] = s;
          }
        });

        _memCache[code] = casted;
        _memCacheTime[code] = DateTime.now();

        _box.write(_cacheKey(code), json.encode(casted));
        _box.write(_tsKey(code), _memCacheTime[code]!.toIso8601String());

        final newEtag = res.headers['etag'];
        if (newEtag != null && newEtag.isNotEmpty) {
          _box.write(_etagKey(code), newEtag);
        }

        _applyToGetX(code, casted);
      } else {
        final cachedStr = _box.read<String>(_cacheKey(code));
        if (cachedStr != null) {
          try {
            final cachedMap = Map<String, String>.from(json.decode(cachedStr));
            _memCache[code] = cachedMap;
            _memCacheTime[code] = DateTime.now();
            _applyToGetX(code, cachedMap);
          } catch (_) {}
        }
      }
    } catch (_) {
      // FALLBACK: Load cached translations when offline
      final cachedStr = _box.read<String>(_cacheKey(code));
      if (cachedStr != null) {
        try {
          final cachedMap = Map<String, String>.from(json.decode(cachedStr));
          _memCache[code] = cachedMap;
          _memCacheTime[code] = DateTime.now();
          _applyToGetX(code, cachedMap);
        } catch (_) {}
      }
    } finally {
      _inflight.remove(code);
    }
  }

  static bool isCached(String apiCode) {
    if (_memCache.containsKey(apiCode)) return true;
    final cachedStr = _box.read<String>(_cacheKey(apiCode));
    return cachedStr != null;
  }

  static Future<void> warmup(
    List<String> apiCodes, {
    bool force = false,
  }) async {
    for (final code in apiCodes) {
      await load(code, force: force);
    }
  }

  static void _applyToGetX(String apiCode, Map<String, String> map) {
    final locale = LocaleMapper.fromApiCode(apiCode);
    final getxKey = LocaleMapper.localeKey(locale);

    final existing = Get.translations[getxKey] ?? const <String, String>{};
    final merged = <String, String>{...existing, ...map};
    Get.addTranslations({getxKey: merged});
  }
}
