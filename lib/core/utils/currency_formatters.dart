import 'package:get/get.dart';

import '../services/currency_service.dart';

String _formatShortForm(num v) {
  final d = v.toDouble();
  if (d >= 1000000000) return '${_trimZero(d / 1000000000)}B';
  if (d >= 1000000) return '${_trimZero(d / 1000000)}M';
  if (d >= 1000) return '${_trimZero(d / 1000)}K';
  return _trimZero(d);
}

String _trimZero(num v) {
  String s = v.toStringAsFixed(1);
  if (s.endsWith('.0')) return s.substring(0, s.length - 2);
  return s;
}

String formatCurrency(num? amount, {bool applyConversion = true}) {
  final a = (amount ?? 0).toDouble();

  if (Get.isRegistered<CurrencyService>()) {
    return Get.find<CurrencyService>().format(
      a,
      applyConversion: applyConversion,
    );
  }

  return '\$${a.toStringAsFixed(2)}';
}

String formatCurrencyCompact(num amount, {bool applyConversion = true}) {
  if (!Get.isRegistered<CurrencyService>()) {
    return '\$${_formatShortForm(amount)}';
  }

  final svc = Get.find<CurrencyService>();
  final selected = svc.current;
  final def = svc.systemDefault;

  double finalAmount = amount.toDouble();

  if (applyConversion && selected != null && def != null) {
    final double baseRate = def.conversionRate == 0 ? 1.0 : def.conversionRate;
    final double selectedRate = selected.conversionRate == 0
        ? 1.0
        : selected.conversionRate;
    finalAmount = (finalAmount * selectedRate) / baseRate;
  }

  final String shortValue = _formatShortForm(finalAmount);

  if (selected == null) return shortValue;

  return selected.position == '1'
      ? '${selected.symbol}$shortValue'
      : '$shortValue${selected.symbol}';
}
