import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../product/model/product_model.dart';
import '../../product/model/related_product_model.dart';

class SinglePriceTag extends StatelessWidget {
  final double price;
  final double? oldPrice;

  const SinglePriceTag._({super.key, required this.price, this.oldPrice});

  factory SinglePriceTag(ProductModel p, {Key? key}) =>
      SinglePriceTag._(key: key, price: p.price, oldPrice: p.oldPrice);

  factory SinglePriceTag.forRelated(RelatedProduct r, {Key? key}) {
    final double price = r.price;
    final double? base = r.basePrice;
    final double? old = (base != null && base > price) ? base : null;
    return SinglePriceTag._(key: key, price: price, oldPrice: old);
  }

  @override
  Widget build(BuildContext context) {
    final priceText = formatCurrency(price, applyConversion: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          priceText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        if (oldPrice != null)
          Text(
            formatCurrency(oldPrice!, applyConversion: true),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.greyColor,
              decoration: TextDecoration.lineThrough,
              decorationThickness: 1.4,
              decorationStyle: TextDecorationStyle.solid,
            ),
          ),
      ],
    );
  }
}
