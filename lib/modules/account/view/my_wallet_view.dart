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

class MyWalletView extends StatefulWidget {
  MyWalletView({super.key});

  @override
  State<MyWalletView> createState() => _MyWalletViewState();
}

class _MyWalletViewState extends State<MyWalletView> {
  final WalletController c = Get.put(
    WalletController(repo: WalletRepository(api: ApiService())),
  );

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, leadingWidth: 44, leading: const BackIconWidget(),
        centerTitle: false, titleSpacing: 0,
        title: Text('My Wallet'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
        actionsPadding: const EdgeInsetsDirectional.only(end: 10),
        actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
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
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            children: [
              if (c.isSummaryLoading.value && c.summary.value == null)
                const _SummaryShimmer()
              else
                _SummaryCard(summary: c.summary.value),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Iconsax.receipt_2_1_copy, size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text('Transaction History'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
              const SizedBox(height: 10),
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(children: [
    _FilterChip(label: 'All'.tr, selected: c.filterType.value == 'all' && c.filterMethod.value == 'all' && c.filterStatus.value == 'all' && c.dateFrom.value.isEmpty, onTap: c.clearFilters),
    const SizedBox(width: 8),
    _FilterChip(label: 'Credit'.tr, selected: c.filterType.value == 'credit', onTap: () => c.setFilterType('credit')),
    const SizedBox(width: 8),
    _FilterChip(label: 'Debit'.tr, selected: c.filterType.value == 'debit', onTap: () => c.setFilterType('debit')),
    const SizedBox(width: 8),
    _FilterChip(label: 'Online'.tr, selected: c.filterMethod.value == 'online', onTap: () => c.setFilterMethod('online')),
    const SizedBox(width: 8),
    _FilterChip(label: 'Offline'.tr, selected: c.filterMethod.value == 'offline', onTap: () => c.setFilterMethod('offline')),
    const SizedBox(width: 8),
    _FilterChip(label: 'Pending'.tr, selected: c.filterStatus.value == 'pending', onTap: () => c.setFilterStatus('pending')),
    const SizedBox(width: 8),
    _FilterChip(label: 'Declined'.tr, selected: c.filterStatus.value == 'declined', onTap: () => c.setFilterStatus('declined')),
    const SizedBox(width: 8),
    _FilterChip(
      label: c.dateFrom.value.isEmpty ? 'Date'.tr : '${c.dateFrom.value} - ${c.dateTo.value}',
      selected: c.dateFrom.value.isNotEmpty,
      onTap: _pickDateRange,
      icon: Iconsax.calendar_1_copy,
    ),
  ]),
),
              const SizedBox(height: 12),
              if (c.items.isEmpty && !c.isLoading.value)
                _EmptyTransactionsView()
              else
                ...c.items.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TransactionCard(tx: tx),
                )),
              if (c.hasMore && c.items.isNotEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor, elevation: 10, shape: const CircleBorder(), mini: true,
        onPressed: () => Get.toNamed(AppRoutes.rechargeWalletView),
        child: const Icon(Iconsax.add_copy, color: AppColors.whiteColor, size: 18),
      ),
    );
  }
}

class _EmptyTransactionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Image.asset('assets/icons/empty_transactions.png', width: 120, height: 120),
    const SizedBox(height: 24),
    Text('No recent transactions'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text('Make your first deposit now by clicking the plus icon at the bottom right corner'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
  ])));
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap; final IconData? icon;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? AppColors.primaryColor : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: selected ? AppColors.primaryColor : Colors.grey.shade300),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 14, color: selected ? Colors.white : null), const SizedBox(width: 4)],
      Text(label, style: TextStyle(color: selected ? Colors.white : null, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  ));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary}); final WalletSummary? summary;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardColor : AppColors.lightCardColor;
    final available = summary?.totalAvailable ?? 0; final pending = summary?.totalPending ?? 0;
    return Row(children: [
      Expanded(child: Container(height: 98, padding: const EdgeInsets.only(left: 10, right: 10), margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: _SummaryCell(title: 'Available Balance'.tr, value: formatCurrency(available, applyConversion: true), icon: Iconsax.wallet_3_copy, iconColor: AppColors.greenColor))),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 98, padding: const EdgeInsets.only(left: 10, right: 10), margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: _SummaryCell(title: 'Pending Balance'.tr, value: formatCurrency(pending, applyConversion: true), icon: Iconsax.clock_copy, iconColor: AppColors.primaryColor))),
    ]);
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.title, required this.value, required this.icon, required this.iconColor});
  final String title; final String value; final IconData icon; final Color iconColor;
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
    Container(width: 28, height: 28, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)),
    const SizedBox(height: 2), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx}); final WalletTransaction tx;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String capFirst(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    return Container(height: 115, decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), child: Stack(children: [
      Positioned(top: 10, right: 10, child: _StatusChip(status: tx.status)),
      Positioned(left: 10, top: 10, child: _Line(label: 'Date'.tr, value: tx.date)),
      Positioned(left: 10, top: 28, child: _Line(label: 'Time'.tr, value: tx.time)),
      Positioned(left: 10, top: 46, child: _Line(label: 'Amount'.tr, value: formatCurrency(tx.rechargeAmount, applyConversion: true))),
      Positioned(left: 10, top: 64, child: _TypeLine(type: tx.type)),
      Positioned(left: 10, top: 82, child: _Line(label: 'Payment Option'.tr, value: capFirst(tx.paymentMethod))),
    ]));
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value}); final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$label: ', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14)), Text(value, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)]);
}

class _TypeLine extends StatelessWidget {
  const _TypeLine({required this.type}); final String type;
  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase(); final isCredited = t == 'credited'; final icon = isCredited ? Iconsax.arrow_up_3_copy : Iconsax.arrow_down_copy;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${'Type'.tr}: ', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14)), Row(mainAxisSize: MainAxisSize.min, children: [Text(_cap(type), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14)), const SizedBox(width: 6), Icon(icon, size: 16, color: isCredited ? AppColors.greenColor : AppColors.redColor)])]);
  }
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status}); final String status;
  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim(); late final Color color;
    if (s == 'accepted' || s.contains('accept')) { color = Colors.green; } else if (s == 'pending' || s.contains('pend')) { color = AppColors.primaryColor; } else if (s == 'declined' || s.contains('declin')) { color = AppColors.redColor; } else { color = const Color(0xFF5E35B1); }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)), child: Text(_cap(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)));
  }
  String _cap(String s) => s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1);
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry}); final String error; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Iconsax.info_circle, size: 38), const SizedBox(height: 10), Text('Failed to load transactions'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(error, textAlign: TextAlign.center), const SizedBox(height: 14), ElevatedButton(onPressed: onRetry, child: Text('Retry'.tr))])));
}

class _ShimmerWithSummary extends StatelessWidget {
  const _ShimmerWithSummary();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), children: const [_SummaryShimmer(), SizedBox(height: 8), _ShimmerList()]);
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26;
    return ListView.builder(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, itemCount: 6, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: Container(height: 115, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12))))));
  }
}

class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: Container(height: 98, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12)))));
  }
}
