import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:campconnectus_marketplace/core/config/app_config.dart';

import '../model/search_model.dart';

class SearchProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  const SearchProductTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: AppConfig.assetUrl(product.thumbnailImage),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const SizedBox(
            width: 56,
            height: 56,
            child: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
      title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '৳${product.price} • ⭐ ${product.avgRating} (${product.totalReviews})',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
