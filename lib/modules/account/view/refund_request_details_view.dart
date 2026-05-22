import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/search_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../controller/refund_request_details_controller.dart';
import '../model/refund_request_details_model.dart';

class RefundRequestDetailsView extends StatelessWidget {
  const RefundRequestDetailsView({super.key, required this.refundId});
  final int refundId;

  String _assetOrAbsolute(String path) => AppConfig.assetUrl(path);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RefundRequestDetailsController());

    if (c.details.value == null && !c.isLoading.value) {
      c.load(refundId);
    }

    Future<void> copyRefundId(String code) async {
      await Clipboard.setData(ClipboardData(text: code));
      Get.snackbar(
        'Copied'.tr,
        'Refund ID copied'.tr,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        titleSpacing: 0,
        leading: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
            splashRadius: 20,
          ),
        ),
        centerTitle: false,
        title: Text('Refund Details'.tr, style: const TextStyle(fontSize: 18)),
        actionsPadding: const EdgeInsetsDirectional.only(end: 10),
        actions: const [
          SearchIconWidget(),
          NotificationIconWidget(),
          CartIconWidget(),
        ],
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.details.value == null) {
          return _fullScreenShimmer(context);
        }

        final err = c.error.value;
        if (err != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(err, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => c.load(refundId),
                    child: Text('Retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final d = c.details.value;
        if (d == null) return const SizedBox.shrink();

        final cancelled = d.returnStatus.toLowerCase() == 'cancelled' ||
                          d.returnStatus.toLowerCase() == 'canceled';

        final step = c.currentStepByLabel(d.returnStatus, d.paymentStatus);
        final isFinalStatus = d.returnStatus.toLowerCase() == 'refunded' ||
                              d.returnStatus.toLowerCase() == 'approved';

        return RefreshIndicator(
          onRefresh: () => c.refreshNow(refundId),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Get.theme.brightness == Brightness.dark
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
                            '${'Refund ID'.tr} : ${d.refundCode}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy Refund ID'.tr,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Iconsax.copy_copy, size: 18),
                          onPressed: () => copyRefundId(d.refundCode),
                        ),
                      ],
                    ),
                    Text(
                      '${'Total'.tr} : ${formatCurrency(double.tryParse(d.totalAmount) ?? 0, applyConversion: true)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${'Returned on'.tr} ${d.refundDate}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Get.theme.brightness == Brightness.dark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cancelled) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'This refund request has been cancelled'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _kvSmall('Return'.tr, _titleCase(d.returnStatus)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _kvSmall(
                                'Payment'.tr,
                                _titleCase(d.paymentStatus),
                                color: _statusColor(d.paymentStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _stepperWithShimmer(context, step),
                      const SizedBox(height: 10),
                      _trackingPanel(
                        context: context,
                        tracking: d.tracking,
                        c: c,
                        isFinalStatus: isFinalStatus,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _assetOrAbsolute(d.product.image),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade300,
                              alignment: Alignment.center,
                              child: const Icon(Iconsax.gallery_remove_copy),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${'Qty'.tr}: ${d.product.quantity}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '${'Price'.tr}: ${formatCurrency(double.tryParse(d.product.price) ?? 0, applyConversion: true)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Get.theme.brightness == Brightness.dark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                margin: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refund Request Information'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _kvRow('Reason'.tr, d.refundReason),
                    _kvRow('Note'.tr, d.note.isEmpty ? '-' : d.note),
                    const SizedBox(height: 6),
                    Text('Attachments'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (d.attachments.isEmpty)
                      Text('-', style: TextStyle(color: Colors.grey.shade700))
                    else
                      _attachmentsGrid(context, d.attachments.map(_assetOrAbsolute).toList()),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _fullScreenShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    Widget block({double h = 120, EdgeInsets? m}) => Container(
      margin: m ?? const EdgeInsets.fromLTRB(12, 8, 12, 8), height: h,
      decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)),
    );
    return Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: SingleChildScrollView(child: Column(children: [block(h: 80, m: const EdgeInsets.fromLTRB(12, 12, 12, 8)), block(h: 220), block(h: 200)])));
  }

  Widget _kvSmall(String k, String v, {Color? color}) => Row(mainAxisSize: MainAxisSize.min, children: [Text('$k: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)), Flexible(child: Text(_titleCase(v), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: color ?? (Get.theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87))))]);
  Color _statusColor(String p) { final v = p.toLowerCase(); if (v == 'refunded' || v == 'paid' || v == 'success') return Colors.green; if (v == 'pending' || v == 'processing') return Colors.blue; return Colors.grey; }

  String _titleCase(String s) { final v = s.trim(); if (v.isEmpty) return v; return v.split(' ').map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1))).join(' '); }

  Widget _stepperWithShimmer(BuildContext context, int currentStep) {
    Widget dot(bool active, String label) => Column(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: active ? AppColors.primaryColor : Colors.transparent, border: Border.all(color: active ? AppColors.primaryColor : Colors.grey), shape: BoxShape.circle), alignment: Alignment.center, child: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.grey.shade700))), const SizedBox(height: 6)]);
    Widget shimmerLine() => Shimmer.fromColors(baseColor: AppColors.primaryColor.withValues(alpha: 0.45), highlightColor: AppColors.primaryColor.withValues(alpha: 0.95), period: const Duration(milliseconds: 1200), child: Container(height: 2, color: AppColors.primaryColor));
    Widget solidLine(Color c) => Container(height: 2, color: c);
    Widget line(Widget child) => Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 3), child: SizedBox(height: 2, child: child)));
    Widget line12() { if (currentStep == 1) return shimmerLine(); if (currentStep > 1) return solidLine(AppColors.primaryColor); return solidLine(Colors.grey.shade400); }
    Widget line23() { if (currentStep == 2) return shimmerLine(); if (currentStep > 2) return solidLine(AppColors.primaryColor); return solidLine(Colors.grey.shade400); }
    Widget line34() { if (currentStep == 3) return shimmerLine(); if (currentStep > 3) return solidLine(AppColors.primaryColor); return solidLine(Colors.grey.shade400); }
    Color labelColor(int stepNo) => currentStep == stepNo ? AppColors.primaryColor : Colors.grey;
    FontWeight labelWeight(int stepNo) => currentStep == stepNo ? FontWeight.w600 : FontWeight.normal;
    return Column(children: [
      Row(children: [dot(currentStep >= 1, '1'), line(line12()), dot(currentStep >= 2, '2'), line(line23()), dot(currentStep >= 3, '3'), line(line34()), dot(currentStep >= 4, '4')]),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, child: Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pending'.tr, style: TextStyle(fontSize: 12, color: labelColor(1), fontWeight: labelWeight(1))), Text('Product Received'.tr, style: TextStyle(fontSize: 12, color: labelColor(2), fontWeight: labelWeight(2))), Text('Return Approved'.tr, style: TextStyle(fontSize: 12, color: labelColor(3), fontWeight: labelWeight(3))), Text('Refunded'.tr, style: TextStyle(fontSize: 12, color: labelColor(4), fontWeight: labelWeight(4)))])),
    ]);
  }

  Widget _trackingPanel({required BuildContext context, required List<RefundTrackingItem> tracking, required RefundRequestDetailsController c, bool isFinalStatus = false}) {
    if (tracking.isEmpty) return const SizedBox.shrink();
    final sortedDesc = List<RefundTrackingItem>.from(tracking)..sort((a, b) { final da = DateTime.tryParse(a.date); final db = DateTime.tryParse(b.date); if (da == null || db == null) return b.date.compareTo(a.date); return db.compareTo(da); });
    return Obx(() {
      final expanded = c.trackingExpanded.value; final itemsToShow = expanded ? sortedDesc : [sortedDesc.first]; final canToggle = sortedDesc.length > 1;
      return Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Iconsax.empty_wallet_change, size: 14, color: AppColors.primaryColor), const SizedBox(width: 6), Text('Refund History'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), const Spacer(), if (canToggle) GestureDetector(onTap: () => c.toggleTracking(), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(expanded ? 'Show less'.tr : 'Show all'.tr, style: const TextStyle(fontSize: 12, color: AppColors.primaryColor)), const SizedBox(width: 4), Icon(expanded ? Iconsax.arrow_up_2_copy : Iconsax.arrow_down_2_copy, size: 14, color: AppColors.primaryColor)]))]),
        const SizedBox(height: 10),
        ...List.generate(itemsToShow.length, (i) { final t = itemsToShow[i]; final isLast = i == itemsToShow.length - 1; final isFirst = i == 0; return _RefundTimelineItem(date: t.date, message: t.message, isFirst: isFirst, isLast: isLast, isFinalStatus: isFinalStatus); }),
      ]));
    });
  }

  Widget _kvRow(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(k, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))), const SizedBox(width: 6), Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(fontSize: 13)))]));

  Widget _attachmentsGrid(BuildContext context, List<String> urls) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: urls.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 60, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1), itemBuilder: (_, i) { final u = urls[i]; return InkWell(onTap: () { Get.toNamed(AppRoutes.fullScreenImageView, arguments: {'images': urls, 'index': i, 'id': null, 'heroPrefix': 'refund-attachment'}); }, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: u, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300, alignment: Alignment.center, child: const Icon(Iconsax.gallery_remove_copy))))); });
}

class _RefundTimelineItem extends StatelessWidget {
  final String date; final String message; final bool isFirst; final bool isLast; final bool isFinalStatus;
  const _RefundTimelineItem({required this.date, required this.message, required this.isFirst, required this.isLast, this.isFinalStatus = false});

  Color get _dotColor { if (isFinalStatus) return AppColors.primaryColor; if (isFirst) return AppColors.primaryColor.withValues(alpha: 0.5); return AppColors.primaryColor; }
  Color get _lineColor { if (isFinalStatus) return AppColors.primaryColor; if (isFirst) return AppColors.primaryColor.withValues(alpha: 0.5); return AppColors.primaryColor; }
  Color get _textColor { if (isFirst) return AppColors.primaryColor.withValues(alpha: 0.7); return AppColors.primaryColor; }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 24, child: Column(children: [const SizedBox(height: 2), _AnimatedDot(isActive: isFirst, dotColor: _dotColor), if (!isLast) Expanded(child: Container(width: 2, color: _lineColor))])),
      const SizedBox(width: 10),
      Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textColor)), const SizedBox(height: 4), HtmlWidget(message, textStyle: const TextStyle(fontSize: 13))]))),
    ]));
  }
}

class _AnimatedDot extends StatefulWidget {
  final bool isActive; final Color dotColor;
  const _AnimatedDot({required this.isActive, required this.dotColor});
  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() { super.initState(); if (widget.isActive) { _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true); _animation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); } }

  @override
  void dispose() { if (widget.isActive) _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.dotColor, shape: BoxShape.circle));
    return AnimatedBuilder(animation: _animation, builder: (context, child) => Transform.scale(scale: _animation.value, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.dotColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.dotColor.withValues(alpha: 0.6), blurRadius: 8 * _animation.value, spreadRadius: 2 * _animation.value)]))));
  }
}
