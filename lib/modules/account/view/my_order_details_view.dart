import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/utils/currency_formatters.dart';
import 'package:campconnectus_marketplace/shared/widgets/cart_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/notification_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/search_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../controller/my_order_details_controller.dart';
import '../model/my_order_details_model.dart';
import '../widgets/return_dialog.dart';
import '../widgets/review_dialog.dart';

class MyOrderDetailsView extends StatelessWidget {
  const MyOrderDetailsView({super.key, required this.orderId, this.fromSummary = false, this.fromNotification = false});
  final int orderId;
  final bool fromSummary;
  final bool fromNotification;

  String _translateTrackingMessage(String msg) {
    final contactRegExp = RegExp(r'^(.*Contact:)\s*(\+?[\d\s]+)$');
    final match = contactRegExp.firstMatch(msg);
    if (match != null) { final prefix = match.group(1)!; final number = match.group(2)!; return '${prefix.tr} $number'; }
    return msg.tr;
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text('Order ID copied'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2)));
  }

  int _stepFromDeliveryCode(String code) { switch (code) { case '1': return 3; case '3': return 2; case '2': default: return 1; } }

  bool _shouldShowUnpaidBanner(OrderDetailsData d) {
    final method = (d.paymentMethod).toLowerCase().trim(); final label = (d.paymentStatusLabel).toLowerCase().trim(); final rawStatus = (d.paymentStatus).toString().trim().toLowerCase(); final statusInt = int.tryParse(rawStatus);
    final isCOD = method == 'cod' || method == 'cash on delivery' || method.contains('cash on delivery');
    bool textSaysPaid(String s) => const {'paid','success','succeeded','completed','complete','captured','settled'}.contains(s);
    bool textSaysUnpaid(String s) => const {'unpaid','pending','awaiting payment','due','failed','declined','cancelled','canceled'}.contains(s);
    final paidByCode = statusInt == 1; final unpaidByCode = statusInt == 0;
    final paidByText = textSaysPaid(rawStatus) || textSaysPaid(label); final unpaidByText = textSaysUnpaid(rawStatus) || textSaysUnpaid(label);
    final notRequired = (d.paymentRequired == 2);
    if (isCOD || (paidByCode || paidByText || notRequired) && !(unpaidByCode || unpaidByText)) return false;
    return true;
  }

  Widget _paymentBanner(BuildContext context, OrderDetailsData d) {
    if (!_shouldShowUnpaidBanner(d)) return const SizedBox.shrink();
    final c = Get.find<OrderDetailsController>();
    return Container(decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 10, left: 12, right: 12), child: Column(children: [Text('Payment is incomplete'.tr), const SizedBox(height: 10), SizedBox(height: 38, child: ElevatedButton(onPressed: () => c.showPayOptions(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: Obx(() { final paying = c.paying.value; return paying ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Pay Now'.tr); })))]));
  }

  Widget _header(BuildContext context, OrderDetailsData d, OrderDetailsController c) {
    return Container(decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 10, left: 12, right: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Row(children: [Flexible(child: Text('${'Order ID'.tr} : ${d.orderCode.isNotEmpty ? d.orderCode : d.id}', overflow: TextOverflow.ellipsis)), IconButton(visualDensity: VisualDensity.compact, tooltip: 'Copy Order ID'.tr, icon: const Icon(Iconsax.copy_copy, size: 18), onPressed: () => _copy(d.orderCode.toString()))])), if (d.canCancel == 1) OutlinedButton(onPressed: () => c.cancelWholeOrder(), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)), child: Text('Cancel Order'.tr))]), Text('${'Total Price'.tr} : ${formatCurrency(d.totalPayableAmount, applyConversion: true)}', maxLines: 1, overflow: TextOverflow.ellipsis), Text('${'Order Placed on'.tr} ${d.orderDate}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))]));
  }

  Widget _returnStatusChip(BuildContext context, OrderProductItem p) {
    final statusRaw = p.returnStatus.status.trim();
    if (statusRaw == '4' || statusRaw == '3') return OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppColors.redColor, side: const BorderSide(color: AppColors.redColor), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)), child: Text(p.returnStatus.label.tr));
    if (p.canReturn == 1) return OutlinedButton(onPressed: () async { final oid = Get.find<OrderDetailsController>().order.value?.id; if (oid == null || oid == 0) { Get.snackbar('Error'.tr, 'Order not found'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor); return; } await showDialog<bool>(context: context, barrierDismissible: false, builder: (ctx) => ReturnDialog(orderId: oid, packageId: p.id, productName: p.name, productImage: (p.image.startsWith('http') ? p.image : (p.image.startsWith('/') ? '${AppConfig.baseUrl}${p.image}' : '${AppConfig.baseUrl}/${p.image}')), unitPrice: p.unitPrice, quantity: p.quantity)); try { Get.find<OrderDetailsController>().refreshNow(orderId); } catch (_) {} }, style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryColor, side: const BorderSide(color: AppColors.primaryColor), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)), child: Text('${'Return'.tr}/${'Refund'.tr}'));
    return const SizedBox.shrink();
  }

  Widget _productActions(BuildContext context, OrderProductItem p, bool delivered) {
    return Row(spacing: 8, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_returnStatusChip(context, p), if (delivered) OutlinedButton(onPressed: () { final oid = Get.find<OrderDetailsController>().order.value?.id; if (oid == null || oid == 0) { Get.snackbar('Error'.tr, 'Order not found'.tr, backgroundColor: AppColors.primaryColor, snackPosition: SnackPosition.TOP, colorText: AppColors.whiteColor); return; } showDialog(context: context, barrierDismissible: false, builder: (ctx) => ReviewDialog(orderId: oid, productId: p.productId, productName: '', productImage: '')); }, style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryColor, side: const BorderSide(color: AppColors.primaryColor), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)), child: Text('Write a review'.tr))]);
  }

  Widget _stepperWithShimmer(BuildContext context, int currentStep, String firstLabel) {
    Widget dot(bool active, String label) => Column(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: active ? AppColors.primaryColor : Colors.transparent, border: Border.all(color: active ? AppColors.primaryColor : Colors.grey), shape: BoxShape.circle), alignment: Alignment.center, child: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.grey.shade700))), const SizedBox(height: 6)]);
    Widget shimmerLine() => Shimmer.fromColors(baseColor: AppColors.primaryColor.withValues(alpha: 0.45), highlightColor: AppColors.primaryColor.withValues(alpha: 0.95), period: const Duration(milliseconds: 1200), child: Container(height: 2, color: AppColors.primaryColor));
    Widget solidLine(Color color) => Container(height: 2, color: color);
    Widget leftLine() => (currentStep == 1) ? shimmerLine() : (currentStep >= 2) ? solidLine(AppColors.primaryColor) : solidLine(Colors.grey.shade400);
    Widget rightLine() => (currentStep == 2) ? shimmerLine() : (currentStep >= 3) ? solidLine(AppColors.primaryColor) : solidLine(Colors.grey.shade400);
    Widget line(Widget child) => Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 3), child: SizedBox(height: 2, child: child)));
    return Column(children: [Row(children: [dot(currentStep >= 1, '1'), line(leftLine()), dot(currentStep >= 2, '2'), line(rightLine()), dot(currentStep >= 3, '3')]), const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(firstLabel.tr, style: TextStyle(fontSize: 12, color: currentStep == 1 ? AppColors.primaryColor : Colors.grey, fontWeight: currentStep == 1 ? FontWeight.w600 : FontWeight.normal)), Text('Shipped'.tr, style: TextStyle(fontSize: 12, color: currentStep == 2 ? AppColors.primaryColor : Colors.grey, fontWeight: currentStep == 2 ? FontWeight.w600 : FontWeight.normal)), Text('Delivered'.tr, style: TextStyle(fontSize: 12, color: currentStep == 3 ? AppColors.primaryColor : Colors.grey, fontWeight: currentStep == 3 ? FontWeight.w600 : FontWeight.normal))])]);
  }

  Widget _packageCard({required BuildContext context, required int index, required OrderDetailsData d, required OrderProductItem p, required OrderDetailsController c}) {
    final cancelled = c.isItemCancelledEffective(p);
    final attachmentLabel = _attachmentLabelFromRaw(p.attachment);
    final attachmentPath = _attachmentPathFromRaw(p.attachment);
    final hasAttachmentText = attachmentLabel != null && attachmentLabel.trim().isNotEmpty;
    final canOpenAttachment = attachmentPath != null && attachmentPath.trim().isNotEmpty;
    final isPickup = (p.deliveryMode == 'pickup');

    if (cancelled) {
      return Container(margin: const EdgeInsets.fromLTRB(12, 8, 12, 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('${'Package'.tr} ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)))]),
        const SizedBox(height: 10), Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.25))), child: Text('This item has been cancelled'.tr, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red))),
        const SizedBox(height: 12), _productRow(context, p, hasAttachmentText, canOpenAttachment, attachmentPath),
      ]));
    }

    final step = _stepFromDeliveryCode(p.deliveryStatus);
    final delivered = step >= 3;
    String firstLabelFromCode(String code) => (code == '1' || code == '3') ? 'Processing' : 'Pending';

    return Container(margin: const EdgeInsets.fromLTRB(12, 8, 12, 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('${'Package'.tr} ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600))), if (p.shippingType == 'logistics' && p.trackingId != null && p.trackingId!.isNotEmpty) Text('${'Tracking ID'.tr}: ${p.trackingId}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), if (p.shippingType == 'driver' && p.shippingContact != null && p.shippingContact!.isNotEmpty) Text('${'Driver Phone'.tr}: ${p.shippingContact}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))]),
      const SizedBox(height: 10),
      _stepperWithShimmer(context, step.clamp(1, 3), firstLabelFromCode(p.deliveryStatus)),
      const SizedBox(height: 6),
      _trackingPanel(context: context, pkgIndex: index, tracking: p.trackingList, c: c, isFinalStatus: delivered || cancelled),
      const SizedBox(height: 12),
      _productRow(context, p, hasAttachmentText, canOpenAttachment, attachmentPath),
      const SizedBox(height: 8),
      _productActions(context, p, delivered),
      const SizedBox(height: 10),
      // Per-package address
      if (isPickup && p.pickupPoint != null)
        _PackageAddress(icon: Iconsax.location, title: 'Pickup Point'.tr, lines: [p.pickupPoint!.name, p.pickupPoint!.phone, p.pickupPoint!.location, p.pickupPoint!.zoneName])
      else
        _PackageAddress(icon: Iconsax.truck_fast, title: 'Home Delivery'.tr, lines: [d.shippingDetails.name, d.shippingDetails.phone, d.shippingDetails.address, '${d.shippingDetails.city}, ${d.shippingDetails.state}, ${d.shippingDetails.country}']),
      if (p.canCancel == 1 && !delivered) Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: () => c.cancelItem(p.id), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)), child: Text('Cancel Order'.tr))),
    ]));
  }

  Widget _productRow(BuildContext context, OrderProductItem p, bool hasAttachmentText, bool canOpenAttachment, String? attachmentPath) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: AppConfig.assetUrl(p.image), width: 56, height: 56, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey.shade300, alignment: Alignment.center, child: const Icon(Iconsax.gallery_remove_copy)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        if ((p.variant ?? '').isNotEmpty) Text(p.variant!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text('${formatCurrency(p.unitPrice, applyConversion: true)} x${p.quantity}', style: const TextStyle(fontSize: 12)),
        Text(formatCurrency(p.lineTotal, applyConversion: true), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Row(children: [Text('${'Sold by'.tr} : ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)), Flexible(child: Text(p.shop.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.primaryColor)))]),
        if (hasAttachmentText) InkWell(onTap: canOpenAttachment ? () => _openAttachment(context, attachmentPath) : null, child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Iconsax.document_copy, size: 14, color: AppColors.greyColor), const SizedBox(width: 4), Flexible(child: Text('View attachment'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.primaryColor, fontSize: 13)))]))),
      ])),
    ]);
  }

  Widget _trackingPanel({required BuildContext context, required int pkgIndex, required List<TrackingItem> tracking, required OrderDetailsController c, bool isFinalStatus = false}) {
    if (tracking.isEmpty) return const SizedBox.shrink();
    final sortedDesc = List<TrackingItem>.from(tracking)..sort((a, b) { final da = DateTime.tryParse(a.date); final db = DateTime.tryParse(b.date); if (da == null || db == null) return b.date.compareTo(a.date); return db.compareTo(da); });
    return Obx(() {
      final expanded = c.isExpanded(pkgIndex);
      final itemsToShow = expanded ? sortedDesc : [sortedDesc.first];
      return Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Iconsax.truck_fast_copy, size: 14, color: AppColors.primaryColor), const SizedBox(width: 6), Text('Tracking History'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), const Spacer(), if (sortedDesc.length > 1) GestureDetector(onTap: () => c.toggleExpanded(pkgIndex), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(expanded ? 'Show less'.tr : 'Show all'.tr, style: const TextStyle(fontSize: 12, color: AppColors.primaryColor)), const SizedBox(width: 4), Icon(expanded ? Iconsax.arrow_up_2_copy : Iconsax.arrow_down_2_copy, size: 14, color: AppColors.primaryColor)]))]),
        const SizedBox(height: 10),
        ...List.generate(itemsToShow.length, (i) { final t = itemsToShow[i]; return _TimelineItem(date: t.date, message: t.message, isFirst: i == 0, isLast: i == itemsToShow.length - 1, isFinalStatus: isFinalStatus, view: this); }),
      ]));
    });
  }

  String _assetOrAbsolute(String path) { if (path.startsWith('http')) return path; if (path.startsWith('/')) return '${AppConfig.baseUrl}$path'; return '${AppConfig.baseUrl}/$path'; }

  Widget _addressCard(BuildContext context, String title, OrderAddress a) => Container(decoration: BoxDecoration(color: Get.theme.brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 10, left: 12, right: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 2), _kv('Name'.tr, a.name), _kv('Phone'.tr, a.phone), _kv('Address'.tr, a.address), _kv('City'.tr, a.city), _kv('State'.tr, a.state), _kv('Postal Code'.tr, a.postalCode), _kv('Country'.tr, a.country)]));
  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 110, child: Text(k, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))), const SizedBox(width: 6), Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(fontSize: 13)))]));

  Widget _summaryCard(BuildContext context, OrderDetailsData d) => Container(decoration: BoxDecoration(color: Get.theme.brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 10, left: 12, right: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total Summary'.tr, style: const TextStyle(fontWeight: FontWeight.w700)), _sumRow('Subtotal'.tr, formatCurrency(d.subTotal, applyConversion: true)), _sumRow('Shipping Cost'.tr, formatCurrency(d.totalDeliveryCost, applyConversion: true)), _sumRow('Tax'.tr, formatCurrency(d.totalTax, applyConversion: true)), _sumRow('Discount'.tr, '- ${formatCurrency(d.totalDiscount, applyConversion: true)}'), const Divider(), _sumRow('Total'.tr, formatCurrency(d.totalPayableAmount, applyConversion: true), bold: true), const SizedBox(height: 8), if (d.paymentMethod.isNotEmpty) Row(children: [Text('${'Payment method'.tr}: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)), Text(d.paymentMethod, style: const TextStyle(fontSize: 12, color: AppColors.primaryColor))])]));
  Widget _sumRow(String k, String v, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 0), child: Row(children: [Expanded(child: Text(k, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))), Text(v, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500))]));
  Widget _fullScreenShimmer(BuildContext context) { final isDark = Theme.of(context).brightness == Brightness.dark; final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300; final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100; return Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: SingleChildScrollView(padding: EdgeInsets.zero, child: Column(children: List.generate(6, (i) => Container(margin: const EdgeInsets.fromLTRB(12, 8, 12, 8), height: [90, 190, 190, 140, 140, 160][i], decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12))))))); }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrderDetailsController());
    if (c.order.value == null && !c.isLoading.value) c.load(orderId);
    void navigateBackToNotifications() { if (Get.previousRoute == AppRoutes.notificationsView) { Get.back(); return; } Get.offNamedUntil(AppRoutes.notificationsView, (route) => route.settings.name == AppRoutes.notificationsView); }
    void handleBack() { if (fromNotification) { navigateBackToNotifications(); return; } if (fromSummary) { Get.offAllNamed(AppRoutes.bottomNavbarView); } else { Get.back(); } }
    return PopScope(canPop: !(fromSummary || fromNotification), onPopInvokedWithResult: (didPop, result) { if (didPop) return; handleBack(); }, child: Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, leadingWidth: 44, centerTitle: false, titleSpacing: 0, leading: Material(color: Colors.transparent, shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: IconButton(onPressed: handleBack, icon: const Icon(Iconsax.arrow_left_2_copy, size: 20), splashRadius: 20)), title: Text('Order Details'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)), actionsPadding: const EdgeInsetsDirectional.only(end: 10), actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()], elevation: 0),
      body: Obx(() { final isLoading = c.isLoading.value; final err = c.error.value; final d = c.order.value; if (isLoading && d == null) return _fullScreenShimmer(context); if (err != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 12), Text('Something went wrong'.tr, textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: () => c.load(orderId), child: Text('Retry'.tr))]))); if (d == null) return const SizedBox.shrink(); return RefreshIndicator(onRefresh: () => c.refreshNow(orderId), child: ListView(padding: EdgeInsets.zero, children: [_paymentBanner(context, d), _header(context, d, c), ...List.generate(d.products.length, (i) => _packageCard(context: context, index: i, d: d, p: d.products[i], c: c)), _addressCard(context, 'Billing Address'.tr, d.billingDetails), _summaryCard(context, d), const SizedBox(height: 16)])); }),
    ));
  }

  void _openAttachment(BuildContext context, String path) { if (path.isEmpty) return; Get.toNamed(AppRoutes.fullScreenImageView, arguments: {'images': [path], 'index': 0, 'id': null, 'heroPrefix': 'orderAttachment'}); }
  String? _attachmentPathFromRaw(dynamic raw) { if (raw == null) return null; if (raw is Map) { String? p = raw['path']?.toString() ?? raw['file_path']?.toString() ?? raw['url']?.toString(); if (p == null || p.isEmpty) return null; final s = p.trim(); return (s.startsWith('http')) ? s : AppConfig.assetUrl(s); } if (raw is String) { final s = raw.trim(); if (s.isEmpty || s == 'null') return null; try { final fromJson = _attachmentPathFromRaw(jsonDecode(s)); if (fromJson != null && fromJson.isNotEmpty) return fromJson; } catch (_) {} return (s.startsWith('http')) ? s : AppConfig.assetUrl(s); } return null; }
  String? _attachmentLabelFromRaw(dynamic raw) { if (raw == null) return null; if (raw is Map) { String? label = raw['label']?.toString() ?? raw['file_name']?.toString() ?? raw['name']?.toString(); if (label != null && label.isNotEmpty) return label; } if (raw is String) { final s = raw.trim(); if (s.isEmpty || s == 'null') return null; try { final fromJson = _attachmentLabelFromRaw(jsonDecode(s)); if (fromJson != null && fromJson.isNotEmpty) return fromJson; } catch (_) {} return s.split('/').last; } return null; }
}

class _PackageAddress extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  const _PackageAddress({required this.icon, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.primaryColor), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          ...lines.where((l) => l.trim().isNotEmpty).map((l) => Text(l, style: const TextStyle(fontSize: 12, color: AppColors.greyColor))),
        ])),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String date; final String message; final bool isFirst; final bool isLast; final bool isFinalStatus; final MyOrderDetailsView view;
  const _TimelineItem({required this.date, required this.message, required this.isFirst, required this.isLast, this.isFinalStatus = false, required this.view});
  Color get _dotColor => isFirst ? AppColors.primaryColor : AppColors.primaryColor.withValues(alpha: 0.5);
  Color get _lineColor => isFinalStatus ? AppColors.primaryColor : AppColors.primaryColor.withValues(alpha: 0.5);
  @override
  Widget build(BuildContext context) {
    final displayMessage = view._translateTrackingMessage(message);
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 24, child: Column(children: [const SizedBox(height: 2), _AnimatedDot(isActive: isFirst, dotColor: _dotColor), if (!isLast) Expanded(child: Container(width: 2, color: _lineColor))])),
      const SizedBox(width: 10),
      Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dotColor)), const SizedBox(height: 4), HtmlWidget(displayMessage, textStyle: const TextStyle(fontSize: 13))]))),
    ]));
  }
}

class _AnimatedDot extends StatefulWidget {
  final bool isActive; final Color dotColor;
  const _AnimatedDot({required this.isActive, required this.dotColor});
  @override State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _animation;
  @override void initState() { super.initState(); if (widget.isActive) { _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true); _animation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); } }
  @override void dispose() { if (widget.isActive) _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { if (!widget.isActive) return Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.dotColor, shape: BoxShape.circle)); return AnimatedBuilder(animation: _animation, builder: (context, child) => Transform.scale(scale: _animation.value, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.dotColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.dotColor.withValues(alpha: 0.6), blurRadius: 8 * _animation.value, spreadRadius: 2 * _animation.value)])))); }
}
