import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/product_repository.dart';
import 'package:kartly_e_commerce/modules/brand/controller/brand_controller.dart';
import 'package:kartly_e_commerce/modules/brand/view/all_brands_view.dart';
import 'package:kartly_e_commerce/modules/brand/view/brand_view.dart';
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

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final ForYouController _forYouCtl = ForYouController.ensure();
  final ScrollController _scrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;

  Future<void> _onRefresh() async {
    final List<Future<void>> futures = [];
    if (Get.isRegistered<CurrencyController>()) {
      futures.add(Get.find<CurrencyController>().fetchCurrencies(force: true));
    }
    if (Get.isRegistered<BannerController>()) {
      final c = Get.find<BannerController>();
      c.banners.clear(); c.error.value = ''; c.isLoading.value = true;
      futures.add(c.load());
    }
    if (Get.isRegistered<CategoryController>()) {
      final c = Get.find<CategoryController>();
      c.categories.clear(); c.error.value = ''; c.isLoading.value = true;
      futures.add(c.fetchCategories());
    }
    if (Get.isRegistered<BrandController>()) {
      final b = Get.find<BrandController>();
      b.brands.clear(); b.error.value = ''; b.isLoading.value = true;
      futures.add(b.fetchBrands());
    }
    futures.add(FlashDealsSection.refreshSection());
    if (Get.isRegistered<TopSalesController>(tag: 'topSalesSection')) {
      futures.add(Get.find<TopSalesController>(tag: 'topSalesSection').refresh());
    }
    futures.add(NewProductSection.refreshSection());
    futures.add(ForYouSection.refreshSection());
    final cartCtl = Get.isRegistered<CartController>() ? Get.find<CartController>() : Get.put(CartController(Get.find()));
    futures.add(cartCtl.loadCart());
    final notifCtl = Get.isRegistered<NotificationController>() ? Get.find<NotificationController>() : Get.put(NotificationController());
    futures.add(notifCtl.refreshList());
    await Future.wait(futures);
  }

  void _scrollToTop() {
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _onScrollDetected() {
    if (!_scrollCtrl.hasClients) return;
    if (!_showBackToTop) {
      setState(() => _showBackToTop = true);
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showBackToTop) setState(() => _showBackToTop = false);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScrollDetected);
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
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _scrollCtrl.removeListener(_onScrollDetected);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Get.offAllNamed(AppRoutes.splashView);
    }
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
        top: true, bottom: false,
        child: Stack(
          children: [
            NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    primary: false, automaticallyImplyLeading: false, leading: null,
                    titleSpacing: 10,
                    title: Image.asset(AppAssets.appLogo, width: 150, height: 45, fit: BoxFit.contain),
                    actionsPadding: const EdgeInsetsDirectional.only(end: 10),
                    actions: const [CartIconWidget(), NotificationIconWidget()],
                    floating: true, snap: true, pinned: false, centerTitle: false, elevation: 0,
                  ),
                  SliverPersistentHeader(pinned: true, delegate: SearchHeader(height: 40, child: _SearchField())),
                ];
              },
              body: RefreshIndicator(
                onRefresh: _onRefresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
                      _handleScrollMetrics(notification.metrics);
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    slivers: [
                      SliverToBoxAdapter(
                        child: GetX<BannerController>(
                          init: BannerController(),
                          builder: (bCtrl) {
                            if (bCtrl.isLoading.value) {
                              return const BannerCarousel(
                                items: [_BannerShimmer(), _BannerShimmer(), _BannerShimmer()],
                                height: 130, viewportFraction: 0.84, padEnds: true, itemSpacing: 8, padding: EdgeInsets.zero, autoPlay: true,
                              );
                            }
                            if (bCtrl.error.isNotEmpty || bCtrl.banners.isEmpty) {
                              return const BannerCarousel(
                                items: [Icon(Iconsax.gallery_copy, size: 52), Icon(Iconsax.gallery_copy, size: 52), Icon(Iconsax.gallery_copy, size: 52)],
                                height: 130, viewportFraction: 0.84, padEnds: true, itemSpacing: 8, padding: EdgeInsets.zero, autoPlay: true,
                              );
                            }
                            final items = bCtrl.banners.map((b) => GestureDetector(
                              onTap: () => bCtrl.onTapBanner(b),
                              child: CachedNetworkImage(imageUrl: b.image, fit: BoxFit.cover, width: double.infinity, height: 130),
                            )).toList();
                            return BannerCarousel(items: items, height: 130, viewportFraction: 0.84, padEnds: true, itemSpacing: 8, padding: EdgeInsets.zero, autoPlay: true);
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: CategoryView(
                          onViewAll: () => Get.toNamed(AppRoutes.allCategoriesView),
                          onTapCategory: (id) {
                            final c = Get.put(NewProductListController(ProductRepository(ApiService())));
                            String? name;
                            if (Get.isRegistered<CategoryController>()) {
                              name = Get.find<CategoryController>().categories.firstWhereOrNull((e) => e.id == id)?.name;
                            }
                            c.openForCategory(categoryId: id, categoryName: name);
                            Get.to(() => const NewProductListView(), arguments: {'categoryId': id, 'categoryName': name});
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: BrandView(
                          onViewAll: () => Get.to(() => AllBrandsView(onTapBrand: (brand) {
                            Get.back();
                            final c = Get.put(NewProductListController(ProductRepository(ApiService())));
                            c.openForBrand(brandId: brand.id, brandName: brand.name);
                            Get.to(() => const NewProductListView(), arguments: {'brandId': brand.id, 'brandName': brand.name});
                          })),
                          onTapBrand: (brand) {
                            final c = Get.put(NewProductListController(ProductRepository(ApiService())));
                            c.openForBrand(brandId: brand.id, brandName: brand.name);
                            Get.to(() => const NewProductListView(), arguments: {'brandId': brand.id, 'brandName': brand.name});
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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showBackToTop ? 20 : -60,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showBackToTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.primaryColor,
                  onPressed: _scrollToTop,
                  child: const Icon(Iconsax.arrow_up_2_copy, color: Colors.white),
                ),
              ),
            ),
          ],
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
      onTap: () { FocusScope.of(context).unfocus(); Get.toNamed(AppRoutes.searchView); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Expanded(child: AbsorbPointer(absorbing: true,
              child: TextField(readOnly: true, showCursor: false, enableInteractiveSelection: false,
                decoration: InputDecoration(hintText: 'Search Here'.tr, hintStyle: const TextStyle(color: AppColors.greyColor, fontWeight: FontWeight.normal, fontSize: 14), border: InputBorder.none, isDense: true),
              ),
            )),
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
    return Container(width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)));
  }
}
