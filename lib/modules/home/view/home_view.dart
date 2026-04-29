import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/product_repository.dart';
import 'package:kartly_e_commerce/modules/category/view/category_view.dart';
import 'package:kartly_e_commerce/modules/product/controller/new_product_list_controller.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/controllers/currency_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/permission_service.dart';
import '../../account/controller/notifications_controller.dart';
import '../../category/controller/category_controller.dart';
import '../../product/controller/cart_controller.dart';
import '../../product/controller/for_you_controller.dart';
import '../../product/controller/top_sales_controller.dart';
import '../../product/view/flash_deals_section.dart';
import '../../product/view/for_you_section.dart';
import '../../product/view/new_product_list_view.dart';
import '../../product/view/new_product_section.dart';
import '../../product/view/top_sales_section.dart';
import '../controller/banner_controller.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/search_header.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ForYouController _forYouCtl = ForYouController.ensure();

  Future<void> _onRefresh() async {
    final futures = <Future<void>>[];

    if (Get.isRegistered<CurrencyController>()) {
      final curCtl = Get.find<CurrencyController>();
      futures.add(curCtl.fetchCurrencies(force: true));
    }

    if (Get.isRegistered<BannerController>()) {
      final c = Get.find<BannerController>();
      c.banners.clear();
      c.error.value = '';
      c.isLoading.value = true;
      futures.add(c.load());
    }

    if (Get.isRegistered<CategoryController>()) {
      final c = Get.find<CategoryController>();
      c.categories.clear();
      c.error.value = '';
      c.isLoading.value = true;
      futures.add(c.fetchCategories());
    }

    futures.add(FlashDealsSection.refreshSection());

    if (Get.isRegistered<TopSalesController>(tag: 'topSalesSection')) {
      final topSectionCtl = Get.find<TopSalesController>(
        tag: 'topSalesSection',
      );
      futures.add(topSectionCtl.refresh());
    }

    futures.add(NewProductSection.refreshSection());

    futures.add(ForYouSection.refreshSection());

    CartController cartCtl;
    if (Get.isRegistered<CartController>()) {
      cartCtl = Get.find<CartController>();
    } else {
      cartCtl = Get.put(CartController(Get.find()));
    }
    futures.add(cartCtl.loadCart());

    NotificationController notifCtl;
    if (Get.isRegistered<NotificationController>()) {
      notifCtl = Get.find<NotificationController>();
    } else {
      notifCtl = Get.put(NotificationController());
    }
    futures.add(notifCtl.refreshList());

    await Future.wait(futures);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<CurrencyController>()) {
        await Get.find<CurrencyController>().fetchCurrencies(force: true);
      }

      if (!Get.isRegistered<PermissionService>()) {
        await Get.putAsync<PermissionService>(() => PermissionService().init());
      }
      await PermissionService.I.requestOnceOnHome();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleScrollMetrics(ScrollMetrics metrics) {
    if (_forYouCtl.isLoadingMore.value || !_forYouCtl.hasMore.value) return;

    if (metrics.pixels >= metrics.maxScrollExtent - 200) {
      _forYouCtl.loadMoreRandom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                primary: false,
                automaticallyImplyLeading: false,
                leading: null,
                titleSpacing: 10,
                title: Image.asset(
                  AppAssets.appLogo,
                  width: 150,
                  height: 45,
                  fit: BoxFit.contain,
                ),
                actionsPadding: const EdgeInsetsDirectional.only(end: 10),
                actions: const [CartIconWidget(), NotificationIconWidget()],
                floating: true,
                snap: true,
                pinned: false,
                centerTitle: false,
                elevation: 0,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SearchHeader(height: 40, child: _SearchField()),
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is OverscrollNotification) {
                  _handleScrollMetrics(notification.metrics);
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: GetX<BannerController>(
                      init: BannerController(),
                      builder: (bCtrl) {
                        if (bCtrl.isLoading.value) {
                          return const BannerCarousel(
                            items: [
                              _BannerShimmer(),
                              _BannerShimmer(),
                              _BannerShimmer(),
                            ],
                            height: 130,
                            viewportFraction: 0.84,
                            padEnds: true,
                            itemSpacing: 8,
                            padding: EdgeInsets.zero,
                            autoPlay: true,
                          );
                        }

                        if (bCtrl.error.isNotEmpty || bCtrl.banners.isEmpty) {
                          return const BannerCarousel(
                            items: [
                              Icon(Iconsax.gallery_copy, size: 52),
                              Icon(Iconsax.gallery_copy, size: 52),
                              Icon(Iconsax.gallery_copy, size: 52),
                            ],
                            height: 130,
                            viewportFraction: 0.84,
                            padEnds: true,
                            itemSpacing: 8,
                            padding: EdgeInsets.zero,
                            autoPlay: true,
                          );
                        }

                        final items = bCtrl.banners.map((b) {
                          return GestureDetector(
                            onTap: () => bCtrl.onTapBanner(b),
                            child: CachedNetworkImage(
                              imageUrl: b.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 130,
                            ),
                          );
                        }).toList();

                        return BannerCarousel(
                          items: items,
                          height: 130,
                          viewportFraction: 0.84,
                          padEnds: true,
                          itemSpacing: 8,
                          padding: EdgeInsets.zero,
                          autoPlay: true,
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: CategoryView(
                      onViewAll: () => Get.toNamed(AppRoutes.allCategoriesView),
                      onTapCategory: (id) {
                        final c = Get.put(
                          NewProductListController(
                            ProductRepository(ApiService()),
                          ),
                        );

                        String? name;
                        if (Get.isRegistered<CategoryController>()) {
                          final cat = Get.find<CategoryController>();
                          final found = cat.categories.firstWhereOrNull(
                            (e) => e.id == id,
                          );
                          name = found?.name;
                        }
                        c.openForCategory(categoryId: id, categoryName: name);
                        Get.to(
                          () => const NewProductListView(),
                          arguments: {'categoryId': id, 'categoryName': name},
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: FlashDealsSection()),
                  SliverToBoxAdapter(child: TopSalesSection(limit: 4)),
                  const SliverToBoxAdapter(child: NewProductSection(limit: 4)),
                  SliverToBoxAdapter(child: ForYouSection()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Get.toNamed(AppRoutes.searchView);
      },
      child: Container(
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
              child: AbsorbPointer(
                absorbing: true,
                child: TextField(
                  readOnly: true,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    hintText: 'Search Here'.tr,
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
            ),
            const Icon(Iconsax.search_normal_1_copy, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
