import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' as html_parser;
import '../../../core/constants/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/my_order_repository.dart';
import '../../../data/repositories/refund_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../model/notification_model.dart';
import '../model/my_order_details_model.dart';
import '../model/refund_request_details_model.dart';

class NotificationDetailView extends StatefulWidget {
  final NotificationItem item;
  final String? notificationId;

  const NotificationDetailView({
    super.key,
    required this.item,
    this.notificationId,
  });

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  late NotificationItem _item;
  bool _isLoading = false;
  String? _error;
  
  // Enhanced data
  OrderDetailsData? _orderData;
  RefundRequestDetailsData? _refundData;
  bool _loadingEnhanced = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (widget.notificationId != null && widget.notificationId!.isNotEmpty) {
      _loadFromApi();
    }
    _loadEnhancedData();
  }

  Future<void> _loadFromApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = NotificationRepository();
      final fetched = await repo.fetchNotificationById(widget.notificationId!);
      if (mounted) {
        setState(() {
          if (fetched != null) {
            _item = fetched;
            _isLoading = false;
            _loadEnhancedData();
          } else {
            _error = 'Notification not found'.tr;
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notification'.tr;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEnhancedData() async {
    final type = _item.type;
    final param = _item.param;
    
    if (type == null || param == null) return;
    
    setState(() => _loadingEnhanced = true);
    
    try {
      if (type == 'order') {
        final repo = OrderRepository();
        final res = await repo.fetchOrderDetails(orderId: param);
        if (mounted) {
          setState(() {
            _orderData = res.data;
            _loadingEnhanced = false;
          });
        }
      } else if (type == 'refund') {
        final repo = RefundRepository();
        final res = await repo.fetchRefundRequestDetails(id: param);
        if (mounted) {
          setState(() {
            _refundData = res.data;
            _loadingEnhanced = false;
          });
        }
      } else {
        setState(() => _loadingEnhanced = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEnhanced = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        title: Text(
          'Notification Details'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFromApi,
            child: Text('Retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final type = _item.type;
    
    if (type == 'order' && _orderData != null) {
      return _buildOrderDetail(isDark);
    } else if (type == 'refund' && _refundData != null) {
      return _buildRefundDetail(isDark);
    } else {
      return _buildSimpleDetail(isDark);
    }
  }

  // ────────────────────────────────────────────
  // ORDER DETAIL
  // ────────────────────────────────────────────
  Widget _buildOrderDetail(bool isDark) {
    final d = _orderData!;
    final product = d.products.isNotEmpty ? d.products.first : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header message
          _buildHeaderMessage(isDark),
          const SizedBox(height: 16),
          
          // Product card
          if (product != null) ...[
            _buildProductCard(isDark, product),
            const SizedBox(height: 12),
          ],
          
          // Status + Info card
          _buildOrderInfoCard(isDark, d),
          const SizedBox(height: 16),
          
          // View full details button
          _buildViewFullButton(
            onTap: () => Get.toNamed(
              AppRoutes.myOrderDetailsView,
              arguments: {'order_id': d.id},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(bool isDark, OrderDetailsData d) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Status'.tr, d.deliveryStatusLabel.tr, valueColor: AppColors.primaryColor),
          const SizedBox(height: 6),
          _infoRow('Total'.tr, formatCurrency(d.totalPayableAmount, applyConversion: true)),
          if (d.paymentMethod.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('Payment'.tr, d.paymentMethod),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // REFUND DETAIL
  // ────────────────────────────────────────────
  Widget _buildRefundDetail(bool isDark) {
    final d = _refundData!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header message
          _buildHeaderMessage(isDark),
          const SizedBox(height: 16),
          
          // Product card
          _buildRefundProductCard(isDark, d),
          const SizedBox(height: 12),
          
          // Status + Info card
          _buildRefundInfoCard(isDark, d),
          const SizedBox(height: 16),
          
          // View full details button
          _buildViewFullButton(
            onTap: () => Get.toNamed(
              AppRoutes.refundRequestDetailsView,
              arguments: d.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundProductCard(bool isDark, RefundRequestDetailsData d) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: AppConfig.assetUrl(d.product.image),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 56, height: 56,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${'Qty'.tr}: ${d.product.quantity} | ${'Price'.tr}: ${formatCurrency(double.tryParse(d.product.price) ?? 0, applyConversion: true)}',
                  style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundInfoCard(bool isDark, RefundRequestDetailsData d) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Return'.tr, d.returnStatus.tr, valueColor: _refundStatusColor(d.returnStatus)),
          const SizedBox(height: 6),
          _infoRow('Payment'.tr, d.paymentStatus.tr, valueColor: _refundStatusColor(d.paymentStatus)),
          const SizedBox(height: 6),
          _infoRow('Reason'.tr, d.refundReason.tr),
          if (d.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('Note'.tr, d.note),
          ],
          if (d.attachments.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('Attachments'.tr, '${d.attachments.length} ${'files'.tr}'),
          ],
        ],
      ),
    );
  }

  Color _refundStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'refunded' || s == 'approved' || s == 'paid') return Colors.green;
    if (s == 'cancelled' || s == 'canceled') return Colors.red;
    if (s == 'pending' || s == 'processing') return Colors.orange;
    return Colors.grey;
  }

  // ────────────────────────────────────────────
  // SIMPLE DETAIL (admin custom notifications)
  // ────────────────────────────────────────────
  Widget _buildSimpleDetail(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_item.title != null && _item.title!.isNotEmpty)
            Text(_item.title!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
          if (_item.title != null && _item.title!.isNotEmpty) const SizedBox(height: 10),
          if (_item.image != null && _item.image!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _item.image!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            ),
          Text(_htmlToPlainText(_item.message), style: TextStyle(fontSize: 16, height: 1.5,
            color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 20),
          Text(_item.time, style: TextStyle(fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600])),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // SHARED WIDGETS
  // ────────────────────────────────────────────
  Widget _buildHeaderMessage(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _htmlToPlainText(_item.message),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _item.time,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(bool isDark, OrderProductItem product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: AppConfig.assetUrl(product.image),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 56, height: 56,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                if ((product.variant ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(product.variant!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${formatCurrency(product.unitPrice, applyConversion: true)} x${product.quantity} = ${formatCurrency(product.lineTotal, applyConversion: true)}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (product.shop.shopName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('${'Sold by'.tr}: ${product.shop.shopName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primaryColor)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? (Get.theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          )),
        ),
      ],
    );
  }

  Widget _buildViewFullButton({required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: const BorderSide(color: AppColors.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('View Full Details'.tr),
      ),
    );
  }

  String _htmlToPlainText(String htmlString) {
    final doc = html_parser.parse(htmlString);
    return doc.body?.text ?? htmlString;
  }
}
