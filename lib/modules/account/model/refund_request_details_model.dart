import 'package:flutter/material.dart';

@immutable
class RefundRequestDetailsResponse {
  final RefundRequestDetailsData data;
  final bool success;
  final int status;

  const RefundRequestDetailsResponse({
    required this.data,
    required this.success,
    required this.status,
  });

  factory RefundRequestDetailsResponse.fromJson(Map<String, dynamic> json) {
    return RefundRequestDetailsResponse(
      data: RefundRequestDetailsData.fromJson(json['data'] ?? const {}),
      success: json['success'] == true || json['success']?.toString() == 'true',
      status: json['status'] is int
          ? json['status']
          : int.tryParse('${json['status']}') ?? 200,
    );
  }
}

@immutable
class RefundRequestDetailsData {
  final int id;
  final String refundDate;
  final String totalAmount;
  final String refundedAmount;
  final String refundCode;
  final String currentReturnStatus;
  final String currentPaymentStatus;
  final String returnStatus;
  final String paymentStatus;
  final OrderSummary order;
  final ProductDetails product;
  final List<RefundTrackingItem> tracking;
  final List<String> attachments;
  final String note;
  final String refundReason;

  const RefundRequestDetailsData({
    required this.id,
    required this.refundDate,
    required this.totalAmount,
    required this.refundedAmount,
    required this.refundCode,
    required this.currentReturnStatus,
    required this.currentPaymentStatus,
    required this.returnStatus,
    required this.paymentStatus,
    required this.order,
    required this.product,
    required this.tracking,
    required this.attachments,
    required this.note,
    required this.refundReason,
  });

  factory RefundRequestDetailsData.fromJson(Map<String, dynamic> j) {
    final tlist = ((j['tracking_list']?['data']) as List? ?? [])
        .map((e) => RefundTrackingItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final atts = (j['attachments'] as List? ?? [])
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return RefundRequestDetailsData(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      refundDate: j['refund_date']?.toString() ?? '',
      totalAmount: j['total_amount']?.toString() ?? '0',
      refundedAmount: j['refunded_amount']?.toString() ?? '0',
      refundCode: j['refund_code']?.toString() ?? '',
      currentReturnStatus: j['current_return_status']?.toString() ?? '',
      currentPaymentStatus: j['current_payment_status']?.toString() ?? '',
      returnStatus: j['return_status']?.toString() ?? '',
      paymentStatus: j['payment_status']?.toString() ?? '',
      order: OrderSummary.fromJson(j['order_details'] ?? const {}),
      product: ProductDetails.fromJson(j['product_details'] ?? const {}),
      tracking: tlist,
      attachments: atts,
      note: j['note']?.toString() ?? '',
      refundReason: j['refund_reason']?.toString() ?? '',
    );
  }
}

@immutable
class OrderSummary {
  final int id;
  final String orderDate;
  final String subtotal;
  final String discount;
  final String shippingCost;
  final String tax;
  final String orderAmount;
  final String orderCode;
  final String paidBy;

  const OrderSummary({
    required this.id,
    required this.orderDate,
    required this.subtotal,
    required this.discount,
    required this.shippingCost,
    required this.tax,
    required this.orderAmount,
    required this.orderCode,
    required this.paidBy,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
    id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
    orderDate: j['order_date']?.toString() ?? '',
    subtotal: j['subtotal']?.toString() ?? '0',
    discount: j['discount']?.toString() ?? '0',
    shippingCost: j['shipping_cost']?.toString() ?? '0',
    tax: j['tax']?.toString() ?? '0',
    orderAmount: j['order_amount']?.toString() ?? '0',
    orderCode: j['order_code']?.toString() ?? '',
    paidBy: j['paid_by']?.toString() ?? '',
  );
}

@immutable
class ProductDetails {
  final String name;
  final String permalink;
  final String image;
  final String quantity;
  final String price;

  const ProductDetails({
    required this.name,
    required this.permalink,
    required this.image,
    required this.quantity,
    required this.price,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> j) => ProductDetails(
    name: j['name']?.toString() ?? '',
    permalink: j['permalink']?.toString() ?? '',
    image: j['image']?.toString() ?? '',
    quantity: j['quantity']?.toString() ?? '0',
    price: j['price']?.toString() ?? '0',
  );
}

class RefundTrackingItem {
  final int id;
  final String message;
  final String date;

  const RefundTrackingItem({
    required this.id,
    required this.message,
    required this.date,
  });

  factory RefundTrackingItem.fromJson(Map<String, dynamic> j) {
    return RefundTrackingItem(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      message: j['message']?.toString() ?? '',
      date: j['created_at']?.toString() ?? '',
    );
  }
}
