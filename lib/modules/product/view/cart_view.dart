import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/login_service.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_attachment_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../controller/cart_controller.dart';
import '../model/cart_item_model.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  static final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, leadingWidth: 44, leading: const BackIconWidget(),
          centerTitle: false, titleSpacing: 0, elevation: 0,
          title: Text('My Cart'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
        ),
        body: LoginService().isLoggedIn()
            ? Obx(() {
                if (controller.isLoading.value) {
                  return ListView.builder(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.only(bottom: 10), itemCount: 6, itemBuilder: (_, __) => _orderShimmerCard(context));
                }
                if (controller.error.isNotEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.error.value), const SizedBox(height: 8),
                    ElevatedButton(onPressed: controller.loadCart, child: Text('Retry'.tr)),
                  ]));
                }
                if (controller.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.loadCart,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Image.asset('assets/icons/cart.png', width: 100, height: 100),
                            const SizedBox(height: 24),
                            Text('Your cart is empty'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('Browse products and add them to your cart to get started.'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity, height: 44,
                              child: ElevatedButton(
                                onPressed: () => Get.offAllNamed(AppRoutes.bottomNavbarView),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                child: Text('Continue Shopping'.tr, style: const TextStyle(fontSize: 15)),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadCart,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      return Obx(() {
                        final it = controller.items[index];
                        final unavailable = (it.isAvailable ?? 1) == 2;
                        final selected = controller.isSelectedId(it.id);
                        final showChecked = unavailable ? true : selected;
                        final attachmentLabel = _cartAttachmentLabel(it.attachment);
                        final attachmentPath = _extractAttachmentPath(it.attachment);

                        final card = Container(
                          margin: EdgeInsets.only(bottom: unavailable ? 0 : 10), padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            IgnorePointer(ignoring: unavailable, child: InkWell(onTap: () => controller.toggleItemSelection(it.id), customBorder: const CircleBorder(), child: Padding(padding: const EdgeInsets.only(top: 4, right: 6), child: Icon(showChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank, size: 20, color: unavailable ? (isDark ? Colors.white24 : const Color(0xFFCBD5E1)) : (showChecked ? AppColors.primaryColor : (isDark ? Colors.white54 : const Color(0xFF9CA3AF))))))),
                            GestureDetector(onTap: () => _openDetails(it), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: it.imageUrl, width: 56, height: 68, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: 56, height: 68, alignment: Alignment.center, color: Colors.black12, child: const Icon(Iconsax.gallery_remove_copy, size: 20))))),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Flexible(child: GestureDetector(onTap: () => _openDetails(it), child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))),
                                InkWell(onTap: () => controller.removeAt(index), customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Iconsax.trash_copy, size: 18))),
                              ]),
                              if (controller.variantLine(it).isNotEmpty) Text(controller.variantLine(it), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  FittedBox(fit: BoxFit.scaleDown, child: Row(children: [
                                    Text(controller.money(it.unitPriceNum), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                                    Text('  |  ', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                                    Text(controller.money(it.lineTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryColor)),
                                  ])),
                                  if (attachmentLabel != null) Padding(padding: const EdgeInsets.only(top: 4.0), child: InkWell(onTap: () => _openAttachment(context, attachmentPath), child: Column(children: [Row(children: [
                                    Padding(padding: const EdgeInsets.only(top: 3), child: Icon(Iconsax.document_copy, size: 14, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                                    const SizedBox(width: 4),
                                    Flexible(child: Text(attachmentLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.primaryColor))),
                                    const SizedBox(width: 6),
                                    GestureDetector(onTap: () => _changeCartItemAttachment(context, controller, it), child: Text('Change'.tr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryColor))),
                                  ])])))),
                                ])),
                                const SizedBox(width: 10),
                                IgnorePointer(ignoring: unavailable, child: SizedBox(width: 78, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  _QtyButton(icon: Iconsax.minus_copy, onTap: () => controller.dec(index), disabled: unavailable),
                                  Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: isDark ? const Color(0xFF0B1220) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE5E7EB))), child: Text('${controller.items[index].quantity}', style: const TextStyle(fontSize: 12))),
                                  _QtyButton(icon: Iconsax.add_copy, onTap: () => controller.inc(index), disabled: unavailable),
                                ]))),
                              ]),
                            ])),
                          ]),
                        );

                        return Stack(clipBehavior: Clip.none, children: [
                          card,
                          if (unavailable) Positioned(top: 2, left: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFCDD2))), child: Text('Not available'.tr, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11, fontWeight: FontWeight.w700)))),
                          if (unavailable) Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(12))))),
                        ]);
                      });
                    },
                  ),
                );
              })
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/icons/wishlist_guest.png', width: 120, height: 120),
                    const SizedBox(height: 24),
                    Text('Please sign in to access your cart'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('One step away from managing your cart'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.loginView),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text('Login'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),
        bottomNavigationBar: Obx(() {
          final disabled = controller.selectedCount == 0;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return SafeArea(top: false, child: Container(height: 72, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            InkWell(onTap: () => controller.toggleSelectAll(!controller.allSelected), borderRadius: BorderRadius.circular(8), child: Row(children: [
              Icon(controller.allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank, size: 22, color: controller.allSelected ? AppColors.primaryColor : (isDark ? Colors.white70 : const Color(0xFF6B7280))),
              const SizedBox(width: 6), Text('All'.tr),
            ])),
            const SizedBox(width: 12),
            Row(children: [
              Obx(() {
                final open = controller.isSummaryOpen.value;
                return IconButton(padding: EdgeInsets.zero, onPressed: () async {
                  if (open) { controller.bottomSheetController?.close(); controller.bottomSheetController = null; controller.closeSummary(); }
                  else { controller.openSummary(); controller.bottomSheetController = _scaffoldKey.currentState!.showBottomSheet((ctx) => _BottomSummarySheet(isDark: isDark), backgroundColor: isDark ? AppColors.darkCardColor : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16)))); controller.bottomSheetController!.closed.whenComplete(() { controller.bottomSheetController = null; controller.closeSummary(); }); }
                }, icon: Icon(controller.isSummaryOpen.value ? Iconsax.arrow_down_1_copy : Iconsax.arrow_up_2_copy, size: 18, color: open ? AppColors.primaryColor : (isDark ? Colors.white70 : const Color(0xFF6B7280))), tooltip: open ? 'Hide summary' : 'Show summary');
              }),
              Text(controller.money(controller.grandTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              SizedBox(height: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: disabled ? Colors.grey : AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 18)),
                onPressed: disabled ? null : () {
                  final loginService = LoginService();
                  final selected = controller.selectedCartItems;
                  if (selected.isEmpty) { Get.snackbar('Checkout'.tr, 'Please select at least one item'.tr, snackPosition: SnackPosition.TOP, backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor); return; }
                  if (loginService.isLoggedIn()) { Get.toNamed(AppRoutes.checkoutView, arguments: {'items': selected}); }
                  else { Get.toNamed(AppRoutes.guestCheckoutView, arguments: {'items': selected}); }
                },
                child: Text('Check Out'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ])));
        }),
      ),
    );
  }

  void _openAttachment(BuildContext context, String? path) {
    if (path == null || path.isEmpty) return;
    Get.toNamed(AppRoutes.fullScreenImageView, arguments: {'images': [path], 'index': 0, 'id': null, 'heroPrefix': 'attachment'});
  }

  Future<void> _changeCartItemAttachment(BuildContext context, CartController controller, CartListItem it) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false, withData: false);
      if (result == null || result.files.isEmpty) return;
      final fileInfo = result.files.single;
      final path = fileInfo.path;
      if (path == null || path.isEmpty) { Get.snackbar('Attachment'.tr, 'Selected file has no path'.tr, snackPosition: SnackPosition.TOP, backgroundColor: AppColors.redColor, colorText: AppColors.whiteColor); return; }
      final file = File(path);
      final oldId = _extractAttachmentFileId(it.attachment);
      final repo = OrderAttachmentRepository(ApiService());
      final resp = await repo.uploadOrderAttachment(file, oldFileId: oldId);
      if (!resp.success || resp.fileId == null) { Get.snackbar('Attachment'.tr, 'Failed to upload file'.tr, snackPosition: SnackPosition.TOP, backgroundColor: AppColors.redColor, colorText: AppColors.whiteColor); return; }
      final newAttachment = <String, dynamic>{'file_name': resp.fileName ?? (fileInfo.name.isNotEmpty ? fileInfo.name : 'file_${resp.fileId}'), 'file_id': resp.fileId, 'path': resp.path ?? ''};
      try { final cartRepo = Get.find<CartRepository>(); final apiModel = it.toApiModel(); final updatedApiItem = CartApiItem(uid: apiModel.uid, id: apiModel.id, name: apiModel.name, permalink: apiModel.permalink, image: apiModel.image, variant: apiModel.variant, variantCode: apiModel.variantCode, quantity: apiModel.quantity, unitPrice: apiModel.unitPrice, oldPrice: apiModel.oldPrice, minItem: apiModel.minItem, maxItem: apiModel.maxItem, attachment: newAttachment, seller: apiModel.seller, shopName: apiModel.shopName, shopSlug: apiModel.shopSlug, isAvailable: apiModel.isAvailable, isSelected: apiModel.isSelected); await cartRepo.updateCartItem(updatedApiItem); } catch (_) {}
      final idx = controller.items.indexWhere((e) => e.uid == it.uid);
      if (idx >= 0) { final updatedItem = CartListItem(uid: it.uid, id: it.id, name: it.name, permalink: it.permalink, image: it.image, variant: it.variant, variantCode: it.variantCode, quantity: it.quantity, unitPrice: it.unitPrice, oldPrice: it.oldPrice, minItem: it.minItem, maxItem: it.maxItem, attachment: newAttachment, seller: it.seller, shopName: it.shopName, shopSlug: it.shopSlug, isAvailable: it.isAvailable, isSelected: it.isSelected); controller.items[idx] = updatedItem; controller.items.refresh(); }
      Get.snackbar('Attachment'.tr, 'File updated successfully'.tr, snackPosition: SnackPosition.TOP, backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
    } catch (e) { Get.snackbar('Attachment'.tr, 'Failed to upload file'.tr, snackPosition: SnackPosition.TOP, backgroundColor: AppColors.redColor, colorText: AppColors.whiteColor); }
  }

  Widget _orderShimmerCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    return Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), margin: const EdgeInsets.only(top: 10, left: 12, right: 12), child: Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Container(height: 16, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)))), const SizedBox(width: 8), Container(width: 24, height: 24, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)))]),
      const SizedBox(height: 8), Container(width: 160, height: 14, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
      const SizedBox(height: 6), Container(width: 140, height: 14, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
      const SizedBox(height: 6), Container(width: 180, height: 14, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
    ])));
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap; final bool disabled;
  const _QtyButton({required this.icon, required this.onTap, this.disabled = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = disabled ? (isDark ? Colors.white24 : const Color(0xFFE5E7EB)) : AppColors.primaryColor;
    final iconColor = disabled ? (isDark ? Colors.white24 : const Color(0xFFB8C1CC)) : null;
    return SizedBox(width: 24, height: 24, child: Material(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: border)), child: InkWell(borderRadius: BorderRadius.circular(8), onTap: disabled ? null : onTap, child: Icon(icon, size: 14, color: iconColor))));
  }
}

class _BottomSummarySheet extends GetView<CartController> {
  const _BottomSummarySheet({required this.isDark}); final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Obx(() => SafeArea(top: false, child: Container(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [Text('Summary'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const Spacer(), IconButton(onPressed: () { controller.bottomSheetController?.close(); controller.bottomSheetController = null; controller.closeSummary(); }, icon: Icon(Iconsax.close_circle_copy, size: 18, color: isDark ? Colors.white70 : const Color(0xFF6B7280)))]),
      const SizedBox(height: 8), Row(children: [Expanded(child: _CouponField()), const SizedBox(width: 8), const _ApplyButton()]),
      Align(alignment: Alignment.centerLeft, child: Obx(() { final txt = controller.couponPillText.value; if (txt.isEmpty) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 8), child: _AppliedPill(label: txt, kind: controller.couponPillKind.value)); })),
      const SizedBox(height: 12), _SummaryRow(label: '${'Subtotal'.tr} (${'items'.tr} ${controller.selectedQtyTotal})', value: controller.money(controller.selectedSubTotal)),
      const Divider(height: 2, thickness: 1), _SummaryRow(label: 'Total'.tr, value: controller.money(controller.grandTotal), bold: true),
    ]))));
  }
}

class _CouponField extends GetView<CartController> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(controller: controller.couponCtrl, decoration: InputDecoration(hintText: 'WELCOME500', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), filled: true, fillColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F4F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE5E7EB)))), onSubmitted: (_) => controller.applyCoupon());
  }
}

class _ApplyButton extends GetView<CartController> {
  const _ApplyButton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 44, child: Obx(() { final disabled = controller.isApplyingCoupon.value; return ElevatedButton(onPressed: disabled ? null : controller.applyCoupon, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text('Apply'.tr)); }));
  }
}

class _AppliedPill extends StatelessWidget {
  const _AppliedPill({required this.label, required this.kind}); final String label; final CouponPillKind kind;
  @override
  Widget build(BuildContext context) {
    Color fg; switch (kind) { case CouponPillKind.success: fg = AppColors.primaryColor; break; case CouponPillKind.error: fg = AppColors.redColor; break; case CouponPillKind.info: default: fg = AppColors.primaryColor; break; }
    return Text(label, style: TextStyle(fontWeight: FontWeight.normal, color: fg));
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false}); final String label; final String value; final bool bold;
  @override
  Widget build(BuildContext context) { final ts = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600); return Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Row(children: [Text(label, style: ts), const Spacer(), Text(value, style: ts)])); }
}

String? _cartAttachmentLabel(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map) { final name = raw['file_name']?.toString(); final id = raw['file_id']?.toString(); if (name != null && name.isNotEmpty) return name; if (id != null && id.isNotEmpty) return 'Attachment #$id'; return 'Attachment'; }
  if (raw is String) { final s = raw.trim(); if (s.isEmpty || s == 'null') return null; try { final decoded = jsonDecode(s); return _cartAttachmentLabel(decoded); } catch (_) { return s; } }
  if (raw is int) return 'Attachment #$raw';
  return raw.toString();
}

String? _extractAttachmentPath(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map) { final p = raw['path']?.toString(); if (p != null && p.isNotEmpty) return p; final name = raw['file_name']?.toString(); if (name != null && (name.startsWith('http://') || name.startsWith('https://'))) return name; return null; }
  if (raw is String) { final s = raw.trim(); if (s.isEmpty || s == 'null') return null; try { final decoded = jsonDecode(s); return _extractAttachmentPath(decoded); } catch (_) { if (s.startsWith('http://') || s.startsWith('https://')) return s; return null; } }
  return null;
}

int? _extractAttachmentFileId(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map) { final v = raw['file_id']; if (v is int) return v; if (v is String) return int.tryParse(v); return null; }
  if (raw is String) { final s = raw.trim(); if (s.isEmpty || s == 'null') return null; try { final decoded = jsonDecode(s); return _extractAttachmentFileId(decoded); } catch (_) { return int.tryParse(s); } }
  if (raw is int) return raw;
  return null;
}

void _openDetails(CartListItem item) {
  final slug = item.permalink;
  if (slug.isNotEmpty) { Get.toNamed(AppRoutes.productDetailsView, arguments: {'permalink': slug}); }
  else { Get.toNamed(AppRoutes.productDetailsView, arguments: {'id': item.id}); }
}
