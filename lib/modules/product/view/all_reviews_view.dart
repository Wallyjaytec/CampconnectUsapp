import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../product/widgets/star_row.dart';
import '../controller/product_details_controller.dart';
import '../model/review_model.dart';

class AllReviewsView extends StatefulWidget {
  const AllReviewsView({super.key});

  @override
  State<AllReviewsView> createState() => _AllReviewsViewState();
}

class _AllReviewsViewState extends State<AllReviewsView> {
  late final ProductDetailsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProductDetailsController>();
    if (controller.allReviews.isEmpty) {
      controller.loadAllReviews(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'All Reviews'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Obx(() {
                  final totalText = controller.totalReviewsText;
                  final sort = controller.reviewSort.value;

                  String label(ReviewSort s) {
                    switch (s) {
                      case ReviewSort.recent:
                        return 'Recent'.tr;
                      case ReviewSort.ratingHigh:
                        return 'Rating: High to Low'.tr;
                      case ReviewSort.ratingLow:
                        return 'Rating: Low to High'.tr;
                    }
                  }

                  return Row(
                    children: [
                      Text(
                        '${'Reviews'.tr}: $totalText',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ReviewSort>(
                          alignment: AlignmentDirectional.centerEnd,
                          icon: const SizedBox.shrink(),
                          isDense: true,
                          isExpanded: false,
                          borderRadius: BorderRadius.circular(10),
                          dropdownColor: isDark
                              ? AppColors.darkCardColor
                              : AppColors.lightCardColor,
                          value: sort,
                          selectedItemBuilder: (context) {
                            return ReviewSort.values.map((v) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label(v),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Iconsax.arrow_down_1_copy,
                                    size: 14,
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          items: [
                            DropdownMenuItem(
                              value: ReviewSort.recent,
                              child: Text(
                                'Recent'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ReviewSort.ratingHigh,
                              child: Text(
                                'Rating: High to Low'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ReviewSort.ratingLow,
                              child: Text(
                                'Rating: Low to High'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) controller.setReviewSort(v);
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Obx(() {
                  final list = controller.reviewsByCurrentSort;
                  if (controller.isLoadingAll.value && list.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.isEmpty) {
                    return Center(child: Text('No reviews yet'.tr));
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      if (i == list.length) {
                        if (controller.canLoadMoreAll) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () =>
                                    controller.loadAllReviews(reset: false),
                                child: Text('Load more'.tr),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(height: 12);
                        }
                      }
                      final item = list[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        child: _ReviewTileAll(item: item),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTileAll extends StatelessWidget {
  const _ReviewTileAll({required this.item});
  final ProductReview item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d MMM yyyy hh:mm:ss a');
    final timeText = item.time != null ? df.format(item.time!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (item.customer.avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(item.customer.avatarUrl)
                  : null,
              child: item.customer.avatarUrl.isEmpty
                  ? const Icon(Iconsax.user_copy, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.customer.verified == 1 ||
                          item.customer.verified == 2)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StarRow(rating: item.rating),
                  if (timeText != null) ...[
                    const SizedBox(height: 6),
                    Text(timeText, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (item.review.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(item.review),
        ],
        if (item.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ReviewImagesStrip(images: item.images),
        ],
      ],
    );
  }
}

class _ReviewImagesStrip extends StatelessWidget {
  const _ReviewImagesStrip({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    const double h = 76;
    const double w = 76;

    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: images.length,
        itemBuilder: (_, i) {
          final src = images[i];
          return GestureDetector(
            onTap: () {
              Get.toNamed(
                AppRoutes.fullScreenImageView,
                arguments: {
                  'images': images,
                  'index': i,
                  'title':
                      (Get.find<ProductDetailsController>()
                          .product
                          .value
                          ?.name) ??
                      'Gallery',
                },
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: src,
                width: w,
                height: h,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: w,
                  height: h,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
                  child: const Icon(Iconsax.gallery_remove_copy, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
