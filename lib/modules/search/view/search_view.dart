import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/modules/home/widgets/search_header.dart';
import 'package:kartly_e_commerce/modules/search/controller/search_view_controller.dart';
import 'package:kartly_e_commerce/modules/search/controller/visual_search_controller.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/search_nav_helper.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../controller/search_input_controller.dart';
import '../controller/search_results_controller.dart';
import '../model/search_model.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchViewController());
    Get.put(SearchResultsController(), permanent: false);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leadingWidth: 44,
          elevation: 0,
          leading: const BackIconWidget(),
          centerTitle: false,
          title: Text(
            '${'Products'.tr} ${'Search'.tr}',
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: SearchHeader(
                height: 40,
                child: _SearchField(
                  key: ValueKey('sf_${controller.tick.value}'),
                ),
              ),
            ),
            const _SuggestionsSection(),
            const _RecentSearchesSection(),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<SearchInputController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.textController,
              autofocus: true,
              onChanged: controller.onSearchChanged,
              onSubmitted: controller.submitSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search for products here'.tr,
                hintStyle: const TextStyle(
                  color: AppColors.greyColor,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Obx(
            () => Row(
              spacing: 6,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.query.value.isNotEmpty)
                  InkWell(
                    radius: 10,
                    onTap: () {
                      controller.textController.clear();
                      controller.onSearchChanged('');
                    },
                    child: const Icon(Iconsax.close_circle_copy, size: 18),
                  ),
                InkWell(
                  radius: 10,
                  onTap: () {
                    Get.put(VisualSearchController()).searchFromGallery();
                  },
                  child: const Icon(Iconsax.camera_copy, size: 18, color: AppColors.primaryColor),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final q = controller.query.value.trim();
                      if (q.isEmpty) return;
                      SearchNavHelper.goToSearchResults(query: q);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Icon(Iconsax.search_normal_1_copy, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark
        ? Colors.white.withValues(alpha: .08)
        : Colors.black.withValues(alpha: .06);

    final res = Get.find<SearchResultsController>();
    final input = Get.find<SearchInputController>();

    return Obx(() {
      final s = res.suggestions.value;
      final q = input.query.value.trim();

      if (q.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      if (s == null || (s.categories.isEmpty && s.tags.isEmpty && s.products.isEmpty)) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.search_normal_1_copy,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '${'No product found for'.tr} "$q"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final catList = s.categories.take(8).toList();
      final tagList = s.tags.take(10).toList();
      final prodList = s.products.take(6).toList();

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tagList.isNotEmpty) ...[
                Text('Tags'.tr, style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagList.map((t) {
                    return InputChip(
                      label: Text(t.name),
                      backgroundColor: chipBg,
                      onPressed: () {
                        input.submitSearch(t.name);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (catList.isNotEmpty) ...[
                Text(
                  'Category'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Column(
                  children: catList.map((c) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 0,
                        end: 4,
                      ),
                      leading: const Icon(Iconsax.folder_2_copy, size: 18),
                      title: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Iconsax.arrow_right_3_copy,
                        size: 18,
                      ),
                      onTap: () {
                        SearchNavHelper.goToCategory(
                          id: c.id,
                          name: c.name,
                          slug: c.slug,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
              if (prodList.isNotEmpty) ...[
                Text(
                  'Products'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Column(
                  children: prodList.map((p) {
                    return SuggestionProductRow(
                      product: p,
                      onTap: () {
                        SearchNavHelper.goToProductDetails(
                          slug: p.slug,
                          id: p.id,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class SuggestionProductRow extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  const SuggestionProductRow({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: AppConfig.assetUrl(product.thumbnailImage),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const SizedBox(
            width: 40,
            height: 40,
            child: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatCurrency(product.price, applyConversion: true)} • ⭐ ${product.avgRating}',
      ),
      trailing: const Icon(Iconsax.arrow_right_3_copy, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsetsDirectional.only(start: 0, end: 4),
    );
  }
}

class _RecentSearchesSection extends StatelessWidget {
  const _RecentSearchesSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark
        ? Colors.white.withValues(alpha: .08)
        : Colors.black.withValues(alpha: .06);
    final controller = Get.find<SearchInputController>();
    final input = Get.find<SearchInputController>();

    return Obx(() {
      final query = input.query.value.trim();

      if (controller.history.isEmpty && query.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.search_normal_1_copy,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Search product across all categories'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find your favorite products by searching above'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.history.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Recent'.tr,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.whiteColor
                          : AppColors.blackColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearHistory,
                    child: Text('CLEAR ALL'.tr),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.history.map((term) {
                  return InputChip(
                    label: Text(term),
                    backgroundColor: chipBg,
                    onPressed: () => controller.selectFromHistory(term),
                    onDeleted: () => controller.removeFromHistory(term),
                    deleteIcon: const Icon(Iconsax.close_circle_copy, size: 16),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }
}
