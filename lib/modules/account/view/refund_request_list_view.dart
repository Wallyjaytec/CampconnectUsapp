import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../controller/refund_request_controller.dart';
import '../widgets/status_badge.dart';

class RefundRequestListView extends StatefulWidget {
  const RefundRequestListView({super.key});

  @override
  State<RefundRequestListView> createState() => _RefundRequestListViewState();
}

class _RefundRequestListViewState extends State<RefundRequestListView> {
  late final RefundRequestController c;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    c = Get.put(RefundRequestController(), permanent: false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    if (c.dateFrom.value.isNotEmpty) {
      c.setDateRange('', '');
      return;
    }
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: c.dateFrom.value.isNotEmpty
          ? DateTimeRange(
              start: DateTime.parse(c.dateFrom.value),
              end: DateTime.parse(c.dateTo.value),
            )
          : initial,
    );
    if (picked != null) {
      c.setDateRange(
        picked.start.toIso8601String().split('T')[0],
        picked.end.toIso8601String().split('T')[0],
      );
    }
  }

  Widget _searchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              onSubmitted: (value) {
                c.setSearchKey(value.trim());
              },
              onChanged: (value) {
                if (value.isEmpty) {
                  c.setSearchKey('');
                }
              },
              decoration: InputDecoration(
                hintText: 'Search by Refund ID'.tr,
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
              if (_searchCtrl.text.isNotEmpty)
                InkWell(
                  radius: 10,
                  onTap: () {
                    _searchCtrl.clear();
                    c.setSearchKey('');
                  },
                  child: const Icon(Iconsax.close_circle_copy, size: 18),
                ),
              const SizedBox(width: 10),
              InkWell(
                radius: 10,
                onTap: () {
                  final q = _searchCtrl.text.trim();
                  FocusScope.of(context).unfocus();
                  c.setSearchKey(q);
                },
                child: const Icon(Iconsax.search_normal_1_copy, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 4),
      child: Row(
        children: [
          const Icon(Iconsax.receipt_2_1_copy, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Text(
            'Refund/Return History'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final filters = [
      {'label': 'All'.tr, 'value': 'all'},
      {'label': 'Pending Return'.tr, 'value': 'pending'},
      {'label': 'Processing'.tr, 'value': 'processing'},
      {'label': 'Product Received'.tr, 'value': 'product_received'},
      {'label': 'Approved Return'.tr, 'value': 'approved'},
      {'label': 'Cancelled'.tr, 'value': 'cancelled'},
      {'label': 'Pending Payment'.tr, 'value': 'payment_pending'},
      {'label': 'Refunded'.tr, 'value': 'refunded'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Obx(() {
        final selected = c.statusFilter.value;
        return Row(
          children: [
            ...filters.map((f) {
              final isSelected = f['value'] == 'all' 
                  ? (selected == 'all' && c.dateFrom.value.isEmpty) 
                  : selected == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => c.setStatusFilter(f['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkCardColor
                              : AppColors.lightCardColor),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      f['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.dateFrom.value.isNotEmpty
                        ? AppColors.primaryColor
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkCardColor
                            : AppColors.lightCardColor),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.dateFrom.value.isNotEmpty
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.calendar_1_copy,
                        size: 14,
                        color: c.dateFrom.value.isNotEmpty ? Colors.white : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.dateFrom.value.isEmpty
                            ? 'Date'.tr
                            : '${c.dateFrom.value} - ${c.dateTo.value}',
                        style: TextStyle(
                          color: c.dateFrom.value.isNotEmpty ? Colors.white : null,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _emptySearchView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/empty_orders.png', width: 120, height: 120),
            const SizedBox(height: 24),
            Text('No refund ID found'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('No refund ID found for "${c.searchKey.value}"'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Refund Requests'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 18,
          ),
        ),
        actionsPadding: const EdgeInsetsDirectional.only(end: 10),
        actions: const [
          SearchIconWidget(),
          CartIconWidget(),
          NotificationIconWidget(),
        ],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: c.refreshList,
        child: Obx(() {
          final items = c.filteredItems;

          if (c.isLoading.value && items.isEmpty) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: 9,
              itemBuilder: (ctx, i) {
                if (i == 0) return _searchField();
                if (i == 1) return _sectionHeader();
                if (i == 2) return _filterChips();
                return _orderShimmerCard(ctx);
              },
            );
          }

          if (c.error.isNotEmpty && items.isEmpty) {
            return _ErrorView(error: c.error.value, onRetry: c.fetchFirstPage);
          }

          if (items.isEmpty) {
            if (c.searchKey.value.isNotEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _searchField(),
                  _sectionHeader(),
                  _filterChips(),
                  _emptySearchView(),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _searchField(),
                _sectionHeader(),
                _filterChips(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/empty_refund.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have no refund/return request'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (sn) {
              if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 80) {
                c.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + 3 + (c.canLoadMore ? 1 : 0),
              itemBuilder: (ctx, index) {
                if (index == 0) return _searchField();
                if (index == 1) return _sectionHeader();
                if (index == 2) return _filterChips();
                final listIndex = index - 3;
                if (listIndex >= items.length) return _orderShimmerCard(ctx);
                final item = items[listIndex];
                return _RefundRow(
                  refundCode: item.refundCode,
                  returnDate: item.returnDate,
                  refundedAmount: item.totalRefundAmount,
                  paymentStatus: item.paymentStatusLabel,
                  returnStatus: item.returnStatusLabel,
                  onCopy: () => c.copyRefundCode(item.refundCode),
                  onTap: () => c.onTapItem(item),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _RefundRow extends StatelessWidget {
  final String refundCode;
  final String returnDate;
  final String refundedAmount;
  final String paymentStatus;
  final String returnStatus;
  final VoidCallback onCopy;
  final VoidCallback onTap;

  const _RefundRow({
    required this.refundCode,
    required this.returnDate,
    required this.refundedAmount,
    required this.paymentStatus,
    required this.returnStatus,
    required this.onCopy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCardColor
              : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${'ID'.tr}: $refundCode',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy'.tr,
                  onPressed: onCopy,
                  icon: const Icon(Iconsax.copy_copy, size: 18),
                ),
              ],
            ),
            Text(
              '${'Return Date'.tr}: $returnDate',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '${'Refund'.tr} ${'Amount'.tr}: ${formatCurrency(double.tryParse(refundedAmount) ?? 0, applyConversion: true)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            _kvWidget(
              '${'Payment Status'.tr}: ',
              StatusBadge(
                text: _titleCase(paymentStatus),
                type: paymentType(paymentStatus),
              ),
            ),
            const SizedBox(height: 8),
            _kvWidget(
              '${'Return Status'.tr}: ',
              StatusBadge(
                text: _titleCase(returnStatus),
                type: returnType(returnStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _titleCase(String s) {
    final v = s.trim();
    if (v.isEmpty) return v;
    return v
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something went wrong'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Widget _kvWidget(String k, Widget child) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text(
        k,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      child,
    ],
  );
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
