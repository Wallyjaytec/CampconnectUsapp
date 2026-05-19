import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../controller/my_order_controller.dart';
import '../model/my_order_model.dart';

class MyOrderListView extends StatefulWidget {
  const MyOrderListView({super.key});

  @override
  State<MyOrderListView> createState() => _MyOrderListViewState();
}

class _MyOrderListViewState extends State<MyOrderListView> {
  late final OrderController controller;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(OrderController(), permanent: false);

    _scroll.addListener(() {
      const threshold = 200.0;
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - threshold) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID copied'.tr),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _searchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final query = controller.searchKey.value;

      if (_searchCtrl.text != query) {
        _searchCtrl.text = query;
        _searchCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchCtrl.text.length),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
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
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  controller.searchOrders(value.trim());
                },
                onSubmitted: (value) {
                  controller.searchOrders(value.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search by Order ID'.tr,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (query.isNotEmpty)
                  InkWell(
                    radius: 10,
                    onTap: () {
                      _searchCtrl.clear();
                      controller.searchOrders('');
                    },
                    child: const Icon(Iconsax.close_circle_copy, size: 18),
                  ),
                const SizedBox(width: 10),
                InkWell(
                  radius: 10,
                  onTap: () {
                    final q = controller.searchKey.value.trim();
                    controller.searchOrders(q);
                  },
                  child: const Icon(Iconsax.search_normal_1_copy, size: 18),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _orderShimmerCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 140,
              height: 14,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(OrderItem o) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.myOrderDetailsView, arguments: o);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCardColor
              : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.orderCode.isEmpty
                        ? '${'Order ID'.tr}: ${o.id}'
                        : '${'Order ID'.tr}: ${o.orderCode}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy Order ID'.tr,
                  icon: const Icon(Iconsax.copy_copy, size: 18),
                  onPressed: () => _copy(o.orderCode.toString()),
                ),
              ],
            ),
            Text(
              '${'Order Date'.tr}: ${o.orderDate}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${'Num of Products'.tr}: ${o.totalProducts}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${'Amount'.tr}: ${formatCurrency(o.totalPayableAmount, applyConversion: true)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyOrdersView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/empty_orders.png', width: 120, height: 120),
            const SizedBox(height: 24),
            Text(
              'You have no orders yet!'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Why not place your first order now?".tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.bottomNavbarView),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Continue Shopping'.tr, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySearchView(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/empty_orders.png', width: 120, height: 120),
            const SizedBox(height: 24),
            Text(
              'No order ID found'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'No order ID found for "$query"'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.bottomNavbarView),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Continue Shopping'.tr, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: controller.initLoad,
              child: Text('Retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  int get _initialShimmerCount => 6;
  int get _loadMoreShimmerCount => 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'My Orders'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
        actionsPadding: const EdgeInsetsDirectional.only(end: 10),
        actions: const [
          SearchIconWidget(),
          CartIconWidget(),
          NotificationIconWidget(),
        ],
        elevation: 0,
      ),
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final isLoadingMore = controller.isLoadingMore.value;
        final items = controller.orders;
        final err = controller.error.value;
        final query = controller.searchKey.value.trim();

        return RefreshIndicator(
          onRefresh: controller.refreshList,
          child: Builder(
            builder: (_) {
              // Loading shimmer
              if (isLoading && items.isEmpty) {
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _initialShimmerCount + 1,
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return _searchField();
                    }
                    return _orderShimmerCard(context);
                  },
                );
              }

              // Error state
              if (err != null && items.isEmpty && query.isEmpty) {
                return _errorView(err);
              }

              // Empty state - no orders at all
              if (!isLoading && items.isEmpty && query.isEmpty) {
                return Column(
                  children: [
                    _searchField(),
                    Expanded(child: _emptyOrdersView()),
                  ],
                );
              }

              // Search results empty
              if (!isLoading && items.isEmpty && query.isNotEmpty) {
                return Column(
                  children: [
                    _searchField(),
                    Expanded(child: _emptySearchView(query)),
                  ],
                );
              }

              // Has orders - show list
              if (items.isNotEmpty) {
                return ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      items.length +
                      1 +
                      (isLoadingMore ? _loadMoreShimmerCount : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _searchField();
                    }

                    final listIndex = index - 1;

                    if (listIndex >= items.length) {
                      return _orderShimmerCard(context);
                    }

                    final o = items[listIndex];
                    return _orderTile(o);
                  },
                );
              }

              // Fallback
              return ListView(
                padding: EdgeInsets.zero,
                children: [_searchField()],
              );
            },
          ),
        );
      }),
    );
  }
}
