import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/site_settings_properties_model.dart';
import '../../data/repositories/site_settings_properties_repository.dart';
import '../config/app_config.dart';

class CurrencyService extends GetxService {
  CurrencyService(this._repo);

  final SiteSettingsPropertiesRepository _repo;
  final _box = GetStorage();

  CurrencyModel? systemDefault;

  final Rx<CurrencyModel?> _current = Rx<CurrencyModel?>(null);
  CurrencyModel? get current => _current.value;

  final RxList<CurrencyModel> currencies = <CurrencyModel>[].obs;

  bool inflight = false;

  Future<void> load({bool force = false}) async {
    if (inflight) return;

    inflight = true;
    try {
      final res = await _repo.fetchSiteProperties();

      systemDefault = res.defaultCurrency;

      final list = List<CurrencyModel>.from(res.currencies);

      final def = systemDefault;
      if (def != null) {
        final exists = list.any(
          (e) => e.code.toUpperCase() == def.code.toUpperCase(),
        );
        if (!exists) {
          list.insert(0, def);
        }
      }

      currencies.assignAll(list);

      _syncCurrentFromStorageOrDefault();
    } finally {
      inflight = false;
    }
  }

  void setCurrency(CurrencyModel c, {bool persist = true}) {
    _current.value = c;
    if (persist) {
      _box.write(AppConfig.kCurrencyCode, c.code);
    }
  }

  void _syncCurrentFromStorageOrDefault() {
    final savedCode = _box.read<String>(AppConfig.kCurrencyCode);
    CurrencyModel? picked;

    if (savedCode != null && savedCode.isNotEmpty) {
      picked = currencies.firstWhereOrNull(
        (e) => e.code.toUpperCase() == savedCode.toUpperCase(),
      );
    }

    if (picked == null && systemDefault != null) {
      picked = currencies.firstWhereOrNull(
        (e) => e.code.toUpperCase() == systemDefault!.code.toUpperCase(),
      );
      picked ??= systemDefault;
    }

    picked ??= currencies.firstWhereOrNull(
      (e) => e.code.toUpperCase() == 'USD',
    );

    picked ??= currencies.isNotEmpty ? currencies.first : null;

    _current.value = picked;
  }

  String format(num amount, {bool applyConversion = true}) {
    final selected = current;
    if (selected == null) return amount.toStringAsFixed(2);

    final double input = amount.toDouble();
    double out = input;

    final def = systemDefault;

    if (applyConversion && def != null) {
      final double baseRate = def.conversionRate == 0
          ? 1.0
          : def.conversionRate;
      final double selectedRate = selected.conversionRate == 0
          ? 1.0
          : selected.conversionRate;

      out = (input * selectedRate) / baseRate;
    }

    final fixed = out.toStringAsFixed(selected.numberOfDecimal);

    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    final withThousands = _withThousands(intPart, selected.thousandSeparator);
    final numberStr = decPart.isEmpty
        ? withThousands
        : '$withThousands${selected.decimalSeparator}$decPart';

    return selected.position == '1'
        ? '${selected.symbol}$numberStr'
        : '$numberStr${selected.symbol}';
  }

  String _withThousands(String digits, String sep) {
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

  void clearSelectedCurrency() {
    _box.remove(AppConfig.kCurrencyCode);
    _current.value = null;
  }

  Rx<CurrencyModel?> get currentRx => _current;
}
