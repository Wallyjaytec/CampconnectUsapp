import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../product/widgets/star_row.dart';
import '../controller/seller_ratings_controller.dart';
import '../model/seller_shop_model.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  late final SellerRatingsController controller;
  late final SellerNavArgs navArgs;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args is SellerNavArgs) {
      navArgs = args;
    } else if (args is Map) {
      navArgs = SellerNavArgs(
        title: (args['title'] ?? '').toString(),
        logo: (args['logo'] ?? '').toString(),
        slug: (args['slug'] ?? '').toString(),
        ratingPercent: int.tryParse('${args['ratingPercent'] ?? 0}') ?? 0,
        followers: int.tryParse('${args['followers'] ?? 0}') ?? 0,
      );
    } else {
      navArgs = const SellerNavArgs(title: 'Seller', logo: '', slug: '');
    }

    if (Get.isRegistered<SellerRatingsController>()) {
      Get.delete<SellerRatingsController>(force: true);
    }

    controller = Get.put(
      SellerRatingsController(slug: navArgs.slug, shopTitle: navArgs.title),
      permanent: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 10,
          leadingWidth: 0,
          elevation: 0,
          //leading: const BackIconWidget(),
          centerTitle: false,
          title: Text(
            '${navArgs.title} — ${'Reviews'.tr}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        body: Obx(() {
          final err = controller.loadError.value;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: SellerRatingsCard(),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
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

                if (err.isNotEmpty && controller.rawReviews.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(err, textAlign: TextAlign.center),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Obx(() {
                    if (controller.isSorting.value) {
                      return const _ShimmerReviewList();
                    }

                    final list = controller.reviewsForView;
                    if (controller.isLoading.value && list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No reviews yet'.tr)),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: list.length + 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        if (i == list.length) {
                          if (controller.hasMore.value) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: controller.loadMore,
                                  child: Text('Load more'.tr),
                                ),
                              ),
                            );
                          }
                          return const SizedBox(height: 8);
                        }
                        final item = list[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: _ReviewTile(item: item),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.item});
  final ReviewVM item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d MMM yyyy hh:mm:ss a');
    final timeText = df.format(item.dateTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (item.avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(item.avatarUrl)
                  : null,
              child: item.avatarUrl.isEmpty
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
                          item.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.verified == 1 || item.verified == 2)
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
                  const SizedBox(height: 6),
                  Text(timeText, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
        if (item.comment.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(item.comment),
        ],
        if (item.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ReviewImagesStrip(images: item.images, galleryTitle: item.userName),
        ],
      ],
    );
  }
}

class _ReviewImagesStrip extends StatelessWidget {
  const _ReviewImagesStrip({required this.images, required this.galleryTitle});

  final List<String> images;
  final String galleryTitle;

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
                  'title': galleryTitle,
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

class SellerRatingsCard extends GetView<SellerRatingsController> {
  const SellerRatingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final avg = controller.average;

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Ratings'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  avg.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/5',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _Stars(value: avg),
            const SizedBox(height: 16),

            for (int s = 5; s >= 1; s--) ...[
              _BreakdownRow(
                stars: s,
                percent: controller.percentFor(s),
                count: controller.counts[s] ?? 0,
              ),
              const SizedBox(height: 8),
            ],

            if (controller.total == 0)
              Text(
                'No ratings yet'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
    });
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final filled = value.floor();
    final hasHalf = (value - filled) >= 0.5;

    return Row(
      children: List.generate(5, (i) {
        IconData icon;
        if (i < filled) {
          icon = Icons.star_rounded;
        } else if (i == filled && hasHalf) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: 24, color: Colors.amber[700]);
      }),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.stars,
    required this.percent,
    required this.count,
  });

  final int stars;
  final double percent;
  final int count;

  @override
  Widget build(BuildContext context) {
    final trackColor = Theme.of(context).dividerColor.withValues(alpha: 0.35);
    const valueColor = AppColors.primaryColor;

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16,
                color: Colors.amber[700],
              ),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: percent.clamp(0, 1),
              backgroundColor: trackColor,
              valueColor: const AlwaysStoppedAnimation<Color>(valueColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ShimmerReviewList extends StatelessWidget {
  const _ShimmerReviewList();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.08);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Shimmer.fromColors(
            baseColor: isDark
                ? AppColors.lightCardColor
                : AppColors.darkCardColor,
            highlightColor: AppColors.greyColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 120, color: base),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 80, color: base),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: double.infinity,
                        color: base,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(height: 76, width: 76, color: base),
                          const SizedBox(width: 8),
                          Container(height: 76, width: 76, color: base),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
