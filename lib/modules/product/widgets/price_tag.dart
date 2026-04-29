import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../model/product_model.dart';

class PriceTag extends StatelessWidget {
  final ProductModel p;
  final double? fontSize;
  final TextStyle? style;

  const PriceTag(this.p, {super.key, this.fontSize = 15, this.style});

  bool get _hasDiscount => p.oldPrice != null && p.oldPrice! > p.price;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_hasDiscount) {
      return Text(
        _fmt(p.price, p.currency),
        style:
            style ??
            TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.whiteColor : AppColors.primaryColor,
            ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmt(p.price, p.currency),
          style:
              style ??
              TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.whiteColor : AppColors.primaryColor,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _fmt(p.oldPrice!, p.currency),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF98A2B3),
              decoration: TextDecoration.lineThrough,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(double value, String currency) {
    final sym = (currency.trim().isEmpty) ? r'$' : currency.trim();
    final isInt = value == value.roundToDouble();
    final amount = isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

    if (sym == r'$') return '$sym$amount';
    return '$sym $amount';
  }
}

class PriceRangeTag extends StatelessWidget {
  final ProductModel p;
  final double? fontSize;
  final TextStyle? style;

  const PriceRangeTag(this.p, {super.key, this.fontSize = 15, this.style});

  @override
  Widget build(BuildContext context) {
    return PriceTag(p, fontSize: fontSize, style: style);
  }
}
