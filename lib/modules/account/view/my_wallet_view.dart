import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_transaction_model.dart';

class MyWalletView extends StatelessWidget {
  MyWalletView({super.key});

  final WalletController c = Get.put(
    WalletController(repo: WalletRepository(api: ApiService())),
  );

  final ScrollController _scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        c.loadMore();
      }
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'My Wallet'.tr,
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
        if (c.error.isNotEmpty && c.items.isEmpty) {
          return _ErrorView(error: c.error.value, onRetry: c.fetchInitial);
        }

        if (c.isLoading.value && c.items.isEmpty) {
          return const _ShimmerWithSummary();
        }

        return RefreshIndicator(
          onRefresh: c.refreshList,
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                if (c.isSummaryLoading.value && c.summary.value == null) {
                  return const _SummaryShimmer();
                }
                return _SummaryCard(summary: c.summary.value);
              }

              final listIndex = index - 1;

              if (listIndex == c.items.length) {
                if (c.hasMore) {
                  return const _BottomShimmerLoader();
                }
                return const SizedBox(height: 0);
              }

              final tx = c.items[listIndex];
              return _TransactionCard(tx: tx);
            },
            separatorBuilder: (_, __) => const SizedBox(),
            itemCount: c.items.length + 2,
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        elevation: 10,
        shape: const CircleBorder(),
        mini: true,
        onPressed: () {
          Get.toNamed(AppRoutes.rechargeWalletView);
        },
        child: const Icon(
          Iconsax.add_copy,
          color: AppColors.whiteColor,
          size: 18,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final WalletSummary? summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardColor : AppColors.lightCardColor;

    final available = summary?.totalAvailable ?? 0;
    final pending = summary?.totalPending ?? 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 98,
            padding: const EdgeInsets.only(left: 10, right: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _SummaryCell(
              title: 'Available Balance'.tr,
              value: formatCurrency(available, applyConversion: true),
              icon: Iconsax.wallet_3_copy,
              iconColor: AppColors.greenColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 98,
            padding: const EdgeInsets.only(left: 10, right: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _SummaryCell(
              title: 'Pending Balance'.tr,
              value: formatCurrency(pending, applyConversion: true),
              icon: Iconsax.clock_copy,
              iconColor: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black26;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          height: 98,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String capFirst(String s) =>
        s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        height: 98,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: _StatusChip(status: tx.status),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: _Line(label: 'Date'.tr, value: tx.date),
            ),
            Positioned(
              left: 10,
              top: 30,
              child: _Line(
                label: 'Amount'.tr,
                value: formatCurrency(tx.rechargeAmount, applyConversion: true),
              ),
            ),
            Positioned(left: 10, top: 50, child: _TypeLine(type: tx.type)),
            Positioned(
              left: 10,
              top: 70,
              child: _Line(
                label: 'Payment Option'.tr,
                value: capFirst(tx.paymentMethod),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontWeight: FontWeight.normal, fontSize: 14);
    const valueStyle = TextStyle(fontWeight: FontWeight.normal, fontSize: 14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: labelStyle),
        Text(
          value,
          style: valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TypeLine extends StatelessWidget {
  const _TypeLine({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    final isCredited = t == 'credited';
    final icon = isCredited ? Iconsax.arrow_up_3_copy : Iconsax.arrow_down_copy;
    const labelStyle = TextStyle(fontWeight: FontWeight.normal, fontSize: 14);
    const valueStyle = TextStyle(fontWeight: FontWeight.normal, fontSize: 14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${'Type'.tr}: ', style: labelStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_cap(type), style: valueStyle),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 16,
              color: isCredited ? AppColors.greenColor : AppColors.redColor,
            ),
          ],
        ),
      ],
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    late final Color color;
    if (s == 'accepted' || s.contains('accept')) {
      color = Colors.green;
    } else if (s == 'pending' || s.contains('pend')) {
      color = AppColors.primaryColor;
    } else if (s == 'declined' || s.contains('declin')) {
      color = AppColors.redColor;
    } else {
      color = const Color(0xFF5E35B1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _cap(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1);
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.info_circle, size: 38),
            const SizedBox(height: 10),
            Text(
              'Failed to load transactions'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: Text('Retry'.tr)),
          ],
        ),
      ),
    );
  }
}

class _ShimmerWithSummary extends StatelessWidget {
  const _ShimmerWithSummary();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: const [_SummaryShimmer(), SizedBox(height: 8), _ShimmerList()],
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black26;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomShimmerLoader extends StatelessWidget {
  const _BottomShimmerLoader();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black26;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
