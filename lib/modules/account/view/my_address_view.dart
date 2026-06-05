import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';
import 'package:campconnectus_marketplace/shared/widgets/back_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/notification_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/search_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../controller/address_controller.dart';
import '../model/address_model.dart';

class MyAddressView extends StatelessWidget {
  const MyAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<AddressController>()
        ? Get.find<AddressController>()
        : Get.put(AddressController());

    Future.microtask(() => c.initLoad());

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'My Addresses'.tr,
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

        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primaryColor,
          elevation: 10,
          shape: const CircleBorder(),
          mini: true,
          onPressed: () async {
            final changed = await Get.toNamed(AppRoutes.addAddressView);
            if (changed == true) {
              await c.refreshAddresses();
            }
          },
          child: const Icon(Iconsax.add_copy, color: AppColors.whiteColor, size: 18),
        ),

        body: Obx(() {
          if (c.isLoading.value) {
            return _ShimmerList();
          }

          if (c.addresses.isEmpty) {
            return RefreshIndicator(
              onRefresh: c.refreshAddresses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/icons/empty_address.png', width: 120, height: 120),
                          const SizedBox(height: 24),
                          Text('You have no address'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Click the plus sign button at the bottom right corner to add address(es)'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: c.refreshAddresses,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: c.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = c.addresses[i];
                final lineTop = a.name.isNotEmpty ? a.name : 'Unnamed';
                final phone = (a.phoneCode.isNotEmpty ? '+${a.phoneCode} ' : '') + a.phone;
                final locationParts = [
                  if (a.country?.name.isNotEmpty == true) a.country!.name,
                  if (a.state?.name.isNotEmpty == true) a.state!.name,
                  if (a.city?.name.isNotEmpty == true) a.city!.name,
                  if (a.postalCode.isNotEmpty) a.postalCode,
                ].join(', ');

                return Container(
                  decoration: BoxDecoration(
                    color: Get.theme.brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(lineTop, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () async {
                              final changed = await Get.toNamed(AppRoutes.editAddressView, arguments: a);
                              if (changed == true) await c.refreshAddresses();
                            },
                            child: const Icon(Iconsax.edit_copy, size: 16),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _confirmDelete(context, c, a),
                            child: const Icon(Iconsax.trash_copy, size: 16, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (locationParts.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Iconsax.location_copy, size: 14)),
                            const SizedBox(width: 6),
                            Flexible(child: Text('${a.address}, $locationParts', style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      Row(children: [const Icon(Iconsax.call_copy, size: 14), const SizedBox(width: 6), Text(phone, style: const TextStyle(fontSize: 13))]),
                      const SizedBox(height: 4),
                      _statusBlock(a),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AddressController c, CustomerAddress a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Address'.tr),
        content: Text('Are you sure you want to delete this address?'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              c.deleteAddress(a.id);
            },
            child: Text('Delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _statusBlock(CustomerAddress a) {
    final statusActive = _isActive(a.status);
    final shipActive = a.defaultShipping == 1;
    final billActive = a.defaultBilling == 1;
    if (!statusActive) return _pillRow([_pill('Status', false, showActiveWordWhenActive: true)]);
    final items = <_PillItem>[
      _pill('Status'.tr, true, showActiveWordWhenActive: true),
      if (shipActive) _pill('Default Shipping'.tr, true, showActiveWordWhenActive: false),
      if (billActive) _pill('Default Billing'.tr, true, showActiveWordWhenActive: false),
    ];
    return _pillRow(items);
  }

  bool _isActive(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'active' || s == '1') return true;
    if (s == 'inactive' || s == '2') return false;
    return false;
  }

  Widget _pillRow(List<_PillItem> items) => Wrap(runSpacing: 5, spacing: 5, children: [for (var i = 0; i < items.length; i++) ...[_miniPill(items[i])]]);

  Widget _miniPill(_PillItem item) {
    final suppressValue = item.active && !item.showActiveWordWhenActive;
    if (suppressValue) {
      final color = item.active ? AppColors.primaryColor : AppColors.redColor;
      return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)), child: Text(item.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: color)));
    }
    final color = item.active ? Colors.green : AppColors.redColor;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)), child: Text(item.active ? 'Active'.tr : 'Inactive'.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: color))),
    ]);
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26;
    return ListView.builder(physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), itemCount: 6, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: Container(height: 110, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12))))));
  }
}

class _PillItem {
  final String label;
  final bool active;
  final bool showActiveWordWhenActive;
  const _PillItem(this.label, this.active, this.showActiveWordWhenActive);
}

_PillItem _pill(String label, bool active, {required bool showActiveWordWhenActive}) => _PillItem(label, active, showActiveWordWhenActive);
