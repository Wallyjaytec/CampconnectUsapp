import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import '../../product/widgets/star_row.dart';
import 'dart:convert';

class ReviewDetailDialog extends StatelessWidget {
  const ReviewDetailDialog({
    super.key,
    required this.review,
  });

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rating = (review['rating'] is num)
        ? (review['rating'] as num).toDouble()
        : double.tryParse(review['rating']?.toString() ?? '0') ?? 0.0;
    final productName = review['product_name']?.toString() ?? '';
    final productImage = review['product_image']?.toString() ?? '';
    final reviewText = review['review']?.toString() ?? '';
    final orderCode = review['order_code']?.toString() ?? '';
    final createdAt = review['created_at']?.toString() ?? '';
    
    // Parse images from JSON string
    List<String> images = [];
    final rawImages = review['images'];
    if (rawImages is String && rawImages.isNotEmpty && rawImages != 'null') {
      try {
        final decoded = jsonDecode(rawImages);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    } else if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }

    String formattedDate = '';
    try {
      final dt = DateTime.parse(createdAt);
      formattedDate = DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      formattedDate = createdAt;
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Review'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Iconsax.close_circle_copy),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: CachedNetworkImage(
                          imageUrl: AppConfig.assetUrl(productImage),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Iconsax.gallery_remove_copy),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          StarRow(rating: rating),
                          const SizedBox(height: 4),
                          Text(
                            '${'Order'.tr}: $orderCode',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            '${'Reviewed on'.tr}: $formattedDate',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (reviewText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reviewText,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Attachments'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: images.map((img) {
                      return GestureDetector(
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.fullScreenImageView,
                            arguments: {
                              'images': images,
                              'index': images.indexOf(img),
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: AppConfig.assetUrl(img),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Iconsax.gallery_remove_copy, size: 24),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
