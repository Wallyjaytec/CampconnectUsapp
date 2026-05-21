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

class RefundRequestListView extends StatelessWidget {
  const RefundRequestListView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<RefundRequestController>(
      init: RefundRequestController(),
      builder: (c) {
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
            child: c.isLoading.value && c.items.isEmpty
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: 6,
                    itemBuilder: (ctx, i) => _orderShimmerCard(ctx),
                  )
                : c.items.isEmpty
                ? Center(
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
                  )
                : c.error.isNotEmpty && c.items.isEmpty
                ? _ErrorView(error: c.error.value, onRetry: c.fetchFirstPage)
                : NotificationListener<ScrollNotification>(
                    onNotification: (sn) {
                      if (sn.metrics.pixels >=
                          sn.metrics.maxScrollExtent - 80) {
                        c.loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: c.items.length + (c.canLoadMore ? 1 : 0),
                      itemBuilder: (ctx, index) {
                        if (index >= c.items.length) {
                          return _orderShimmerCard(ctx);
                        }
                        final item = c.items[index];
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
                  ),
          ),
        );
      },
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
