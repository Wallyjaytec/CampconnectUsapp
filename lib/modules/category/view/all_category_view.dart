import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/view/new_product_list_view.dart';
import '../controller/category_controller.dart';

class AllCategoriesView extends StatelessWidget {
  final bool showBackButton;
  const AllCategoriesView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leftPaneWidth = MediaQuery.of(context).size.width >= 600
        ? 140.0
        : 100.0;

    final controller = Get.find<CategoryController>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          titleSpacing: showBackButton ? 0 : 10,
          leading: showBackButton
              ? Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
                    splashRadius: 20,
                  ),
                )
              : null,
          centerTitle: false,
          title: Text(
            'All Categories'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return _ShimmerBody(leftPaneWidth: leftPaneWidth, isDark: isDark);
          }
          if (controller.error.isNotEmpty) {
            return Center(
              child: Text(controller.error.value, textAlign: TextAlign.center),
            );
          }
          final cats = controller.categories;
          if (cats.isEmpty) return Center(child: Text('No categories'.tr));

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leftPaneWidth,
                height: double.infinity,
                child: Obx(() {
                  final sel = controller.selectedIndex.value;
                  return ListView.separated(
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (context, index) {
                      final cat = cats[index];
                      final selected = index == sel;

                      return InkWell(
                        onTap: () {
                          controller.selectCategory(index);
                          if (cat.subcategories.isEmpty) {
                            Get.to(
                              () => const NewProductListView(),
                              arguments: {
                                'categoryId': cat.id,
                                'categoryName': cat.name,
                              },
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          color: selected
                              ? (isDark
                                    ? AppColors.darkCardColor
                                    : AppColors.lightCardColor)
                              : AppColors.transparentColor,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 42,
                                width: 42,
                                child: cat.imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.image_not_supported_outlined,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: cat.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            const ShimmerCircle(diameter: 42),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.0,
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              Expanded(
                child: Container(
                  color: isDark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  child: Obx(() {
                    final selected = controller.selectedIndex.value;
                    final cat = controller.categories[selected];
                    final subs = cat.subcategories;

                    if (subs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No subcategories'.tr),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Get.to(
                                  () => const NewProductListView(),
                                  arguments: {
                                    'categoryId': cat.id,
                                    'categoryName': cat.name,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('View Products'.tr),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0),
                      ),
                      itemBuilder: (context, i) {
                        final item = subs[i];
                        if (item.isAll) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 10),
                            title: Text(
                              'All Products'.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                            dense: true,
                            onTap: () {
                              final cat = controller
                                  .categories[controller.selectedIndex.value];
                              Get.to(
                                () => const NewProductListView(),
                                arguments: {
                                  'categoryId': cat.id,
                                  'categoryName': cat.name,
                                  'subcategoryId': null,
                                  'subcategoryName': null,
                                  'leafId': null,
                                  'leafTag': null,
                                },
                              );
                            },
                          );
                        }
                        if (item.hasDropdown) {
                          return Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              key: PageStorageKey('sub_${item.id}'),
                              trailing: const Icon(
                                Iconsax.arrow_down_1_copy,
                                size: 14,
                              ),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              childrenPadding: const EdgeInsets.only(
                                left: 0,
                                right: 10,
                                bottom: 0,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontSize: 15),
                              ),
                              children: item.children.map((leaf) {
                                return ListTile(
                                  title: Text(leaf.name),
                                  dense: true,
                                  onTap: () {
                                    final cat =
                                        controller.categories[controller
                                            .selectedIndex
                                            .value];
                                    Get.to(
                                      () => const NewProductListView(),
                                      arguments: {
                                        'categoryId': cat.id,
                                        'categoryName': cat.name,
                                        'subcategoryId': item.id,
                                        'subcategoryName': item.name,
                                        'leafId': leaf.id,
                                        'leafTag': leaf.name,
                                      },
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        }
                        return ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          dense: true,
                          onTap: () {
                            final cat = controller
                                .categories[controller.selectedIndex.value];
                            Get.to(
                              () => const NewProductListView(),
                              arguments: {
                                'categoryId': cat.id,
                                'categoryName': cat.name,
                                'subcategoryId': item.id,
                                'subcategoryName': item.name,
                                'leafId': null,
                                'leafTag': null,
                              },
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody({required this.leftPaneWidth, required this.isDark});
  final double leftPaneWidth;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: leftPaneWidth,
          child: ListView.separated(
            itemCount: 8,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                children: [
                  ShimmerCircle(diameter: 42),
                  SizedBox(height: 8),
                  ShimmerBox(width: 60, height: 10, borderRadius: 6),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: 10,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, __) =>
                  const ShimmerBox(height: 16, borderRadius: 6),
            ),
          ),
        ),
      ],
    );
  }
}
