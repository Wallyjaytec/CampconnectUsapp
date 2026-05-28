import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../account/model/my_order_details_model.dart';
import '../controller/guest_order_summary_controller.dart';

class GuestOrderSummaryView extends StatefulWidget {
  final int orderId;

  const GuestOrderSummaryView({super.key, required this.orderId});

  @override
  State<GuestOrderSummaryView> createState() => _GuestOrderSummaryViewState();
}

class _GuestOrderSummaryViewState extends State<GuestOrderSummaryView> {
  late final GuestOrderSummaryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(GuestOrderSummaryController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load(widget.orderId);
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<GuestOrderSummaryController>()) {
      Get.delete<GuestOrderSummaryController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offAllNamed(AppRoutes.bottomNavbarView);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          titleSpacing: 0,
          elevation: 0,
          leading: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () {
                Get.offAllNamed(AppRoutes.bottomNavbarView);
              },
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
              splashRadius: 20,
            ),
          ),
          centerTitle: false,
          title: Text(
            'Guest Order Summary'.tr,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        body: Obx(() {
          if (_controller.isLoading.value && _controller.order.value == null) {
            return _buildLoadingShimmer(context);
          }

          final err = _controller.error.value;
          if (err != null && _controller.order.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(err, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _controller.load(widget.orderId),
                      child: Text('Retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = _controller.order.value;
          if (data == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => _controller.refreshNow(data.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 12,
                left: 12,
                right: 12,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme, data),
                  const SizedBox(height: 10),
                  _buildOrderSummaryCard(theme, data),
                  const SizedBox(height: 10),
                  _buildOrderDetails(theme, data),
                  const SizedBox(height: 10),
                  _buildOrderSummary(theme, data),
                  _buildBottomButtons(theme, data),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, OrderDetailsData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Iconsax.receipt_1_copy,
            size: 36,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank You'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          '${'Order ID'.tr}: ${d.orderCode}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: AppColors.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(ThemeData theme, OrderDetailsData d) {
    const labelStyle = TextStyle(fontSize: 13);
    const valueStyle = TextStyle(fontSize: 13);

    final shipping = d.shippingDetails;
    final address = _fullAddress(shipping);
    final paymentStatusText = d.paymentStatusLabel.isNotEmpty
    ? d.paymentStatusLabel.tr
    : d.paymentStatus.tr;
final orderStatusText = d.deliveryStatusLabel.isNotEmpty
    ? d.deliveryStatusLabel.tr
    : d.deliveryStatus.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _labelValue(
                '${'Order Code'.tr}:',
                d.orderCode,
                labelStyle,
                valueStyle,
              ),
              _labelValue(
                '${'Name'.tr}:',
                shipping.name,
                labelStyle,
                valueStyle,
              ),
              _labelValue(
                '${'Mobile'.tr}:',
                shipping.phone,
                labelStyle,
                valueStyle,
              ),
              _labelValue('${'Address'.tr}:', address, labelStyle, valueStyle),
              _labelValue(
                '${'Postal Code'.tr}:',
                shipping.postalCode,
                labelStyle,
                valueStyle,
              ),
              const SizedBox(width: 24),
              _labelValue(
                '${'Order Date'.tr}:',
                d.orderDate,
                labelStyle,
                valueStyle,
              ),
              _labelValue(
                '${'Order Status'.tr}:',
                orderStatusText,
                labelStyle,
                valueStyle,
              ),
              _labelValue(
                '${'Total Amount'.tr}:',
                formatCurrency(d.totalPayableAmount, applyConversion: true),
                labelStyle,
                valueStyle,
              ),
              _labelValue(
                '${'Payment Status'.tr}:',
                paymentStatusText,
                labelStyle,
                valueStyle,
              ),
              _labelValue(
                '${'Payment Method'.tr}:',
                d.paymentMethod,
                labelStyle,
                valueStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(ThemeData theme, OrderDetailsData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Details'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < d.products.length; i++)
                _buildProductRow(
                  theme,
                  d.products[i],
                  showDivider:
                      d.products.length > 1 && i < d.products.length - 1,
                  context: context,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(
    ThemeData theme,
    OrderProductItem p, {
    bool showDivider = false,
    required BuildContext context,
  }) {
    final textTheme = theme.textTheme;
    final cancelled = _controller.isItemCancelledEffective(p);

    final nameStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      decoration: cancelled ? TextDecoration.lineThrough : null,
      color: cancelled ? Colors.grey : null,
    );

    final infoStyle = textTheme.bodySmall?.copyWith(color: Colors.grey[700]);

    final totalPriceStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: cancelled ? Colors.grey : theme.colorScheme.primary,
      decoration: cancelled ? TextDecoration.lineThrough : null,
    );

    final attachmentLabel = _attachmentLabelFromRaw(p.attachment);
    final attachmentPath = _attachmentPathFromRaw(p.attachment);

    return Container(
      margin: EdgeInsets.only(bottom: showDivider ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 64,
              height: 64,
              child: p.image.isNotEmpty
                  ? CachedNetworkImage(imageUrl: p.image, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
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
                  p.name,
                  style: nameStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                if (p.variant != null && p.variant!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${'Size'.tr} / ${'Variant'.tr}: ${p.variant!}',
                      style: infoStyle,
                    ),
                  ),

                if (p.shop.shopName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text('${'Sold by'.tr}: ', style: infoStyle),
                        Text(
                          p.shop.shopName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${'Quantity'.tr}: ${p.quantity}',
                    style: infoStyle,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${'Unit Price'.tr}: ${formatCurrency(p.unitPrice, applyConversion: true)}',
                    style: infoStyle,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${'Total'.tr}: ${formatCurrency(p.lineTotal, applyConversion: true)}',
                    style: totalPriceStyle,
                  ),
                ),
                if (attachmentLabel != null &&
                    attachmentLabel.isNotEmpty &&
                    attachmentPath != null &&
                    attachmentPath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: InkWell(
                      onTap: () => _openAttachment(context, attachmentPath),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.document_copy,
                            size: 14,
                            color: infoStyle?.color ?? Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'View attachment'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (cancelled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Cancelled'.tr,
                      style: infoStyle?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme, OrderDetailsData d) {
    final textTheme = theme.textTheme;

    final subtotal = d.subTotal;
    final shipping = d.totalDeliveryCost;
    final tax = d.totalTax;
    final payableTotal = d.totalPayableAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryRow(
                'Subtotal'.tr,
                formatCurrency(subtotal, applyConversion: true),
                textTheme,
              ),
              _buildSummaryRow(
                'Shipping Cost'.tr,
                formatCurrency(shipping, applyConversion: true),
                textTheme,
              ),
              _buildSummaryRow(
                'Tax'.tr,
                formatCurrency(tax, applyConversion: true),
                textTheme,
              ),
              const Divider(height: 16),
              _buildSummaryRow(
                'Payable Total'.tr,
                formatCurrency(payableTotal, applyConversion: true),
                textTheme,
                isBold: true,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    TextTheme textTheme, {
    bool isBold = false,
  }) {
    final style = isBold
        ? textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
        : textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _labelValue(
    String label,
    String? value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _fullAddress(OrderAddress a) {
    final parts = <String>[
      a.address,
      a.city,
      a.state,
      a.country,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? '' : parts.join(', ');
  }

  Widget _buildBottomButtons(ThemeData theme, OrderDetailsData d) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          Get.offAllNamed(AppRoutes.bottomNavbarView);
        },
        child: Text('Shop More'.tr),
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

void _openAttachment(BuildContext context, String? path) {
  if (path == null || path.isEmpty) return;

  Get.toNamed(
    AppRoutes.fullScreenImageView,
    arguments: {
      'images': [path],
      'index': 0,
      'id': null,
      'heroPrefix': 'guestOrderAttachment',
    },
  );
}

String? _attachmentLabelFromRaw(dynamic raw) {
  if (raw == null) return null;

  if (raw is Map) {
    final name =
        (raw['original_name'] ?? raw['file_original_name'] ?? raw['file_name'])
            ?.toString();

    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final id = raw['file_id']?.toString();
    if (id != null && id.isNotEmpty) return 'Attachment #$id';

    return 'Attachment';
  }

  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;

    try {
      final decoded = jsonDecode(s);
      return _attachmentLabelFromRaw(decoded);
    } catch (_) {
      return 'Attachment';
    }
  }

  if (raw is int) return 'Attachment #$raw';

  return 'Attachment';
}

String? _attachmentPathFromRaw(dynamic raw) {
  if (raw == null) return null;

  if (raw is Map) {
    final p = raw['path']?.toString();
    if (p != null && p.isNotEmpty) {
      return AppConfig.assetUrl(p);
    }

    final name = raw['file_name']?.toString();
    if (name != null &&
        (name.startsWith('http://') || name.startsWith('https://'))) {
      return name;
    }
    return null;
  }

  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;

    try {
      final decoded = jsonDecode(s);
      return _attachmentPathFromRaw(decoded);
    } catch (_) {
      return AppConfig.assetUrl(s);
    }
  }

  return null;
}
