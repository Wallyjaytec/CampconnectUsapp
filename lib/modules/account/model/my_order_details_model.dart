import 'dart:convert';

class OrderAddress {
  final String name; final String address; final String phone; final String postalCode; final String country; final String state; final String city;
  OrderAddress({required this.name, required this.address, required this.phone, required this.postalCode, required this.country, required this.state, required this.city});
  factory OrderAddress.fromJson(Map<String, dynamic>? json) { final j = json ?? {}; return OrderAddress(name: j['name']?.toString() ?? '', address: j['address']?.toString() ?? '', phone: j['phone']?.toString() ?? '', postalCode: j['postal_code']?.toString() ?? '', country: j['country']?.toString() ?? '', state: j['state']?.toString() ?? '', city: j['city']?.toString() ?? ''); }
}

class ReturnStatus { final String status; final String klass; final String label; ReturnStatus({required this.status, required this.klass, required this.label}); factory ReturnStatus.fromJson(Map<String, dynamic>? json) { final j = json ?? {}; return ReturnStatus(status: (j['status'] ?? j['return_status'])?.toString() ?? '', klass: j['class']?.toString() ?? '', label: j['label']?.toString() ?? ''); } }
class TrackingItem { final String message; final String date; TrackingItem({required this.message, required this.date}); factory TrackingItem.fromJson(Map<String, dynamic> j) => TrackingItem(message: j['message']?.toString() ?? '', date: j['date']?.toString() ?? ''); }
class ShopInfo { final String shopName; final String shopLogo; final String shopSlug; final String shopId; ShopInfo({required this.shopName, required this.shopLogo, required this.shopSlug, required this.shopId}); factory ShopInfo.fromJson(Map<String, dynamic>? json) { final j = json ?? {}; return ShopInfo(shopName: j['shop_name']?.toString() ?? '', shopLogo: j['shop_logo']?.toString() ?? '', shopSlug: j['shop_slug']?.toString() ?? '', shopId: j['shop_id']?.toString() ?? ''); } }
class PickupPointInfo { final int id; final String name; final String phone; final String location; final String zoneName; PickupPointInfo({required this.id, required this.name, required this.phone, required this.location, required this.zoneName}); factory PickupPointInfo.fromJson(Map<String, dynamic> j) => PickupPointInfo(id: (j['id'] is num) ? j['id'].toInt() : int.tryParse(j['id']?.toString() ?? '') ?? 0, name: j['name']?.toString() ?? '', phone: j['phone']?.toString() ?? '', location: j['location']?.toString() ?? '', zoneName: j['zone_name']?.toString() ?? ''); }

class OrderProductItem {
  final int id; final int productId; final String name; final String permalink; final String? variant;
  final double unitPrice; final int quantity; final double shippingCost; final double tax; final String image;
  final ReturnStatus returnStatus; final int canReturn; final int canCancel; final String? deliveredDate;
  final String deliveryStatus; final List<TrackingItem> trackingList; final ShopInfo shop; final dynamic attachment;
  final String? trackingId; final String? shippingContact; final String? shippingType;
  final String? deliveryMode; final PickupPointInfo? pickupPoint;
  final String? trackingUrl; final String? shippingName;

  OrderProductItem({required this.id, required this.productId, required this.name, required this.permalink, required this.variant, required this.unitPrice, required this.quantity, required this.shippingCost, required this.tax, required this.image, required this.returnStatus, required this.canReturn, required this.canCancel, required this.deliveredDate, required this.deliveryStatus, required this.trackingList, required this.shop, this.attachment, this.trackingId, this.shippingContact, this.shippingType, this.deliveryMode, this.pickupPoint, this.trackingUrl, this.shippingName});

  static double _d(dynamic v) { if (v == null) return 0; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0; return 0; }
  static int _i(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

  factory OrderProductItem.fromJson(Map<String, dynamic> j) => OrderProductItem(
    id: _i(j['id']), productId: _i(j['product_id']), name: j['name']?.toString() ?? '', permalink: j['permalink']?.toString() ?? '',
    variant: j['variant']?.toString(), unitPrice: _d(j['unit_price']), quantity: _i(j['quantity']),
    shippingCost: _d(j['shipping_cost']), tax: _d(j['tax']), image: j['image']?.toString() ?? '',
    returnStatus: ReturnStatus.fromJson(j['return_status'] as Map<String, dynamic>?), canReturn: _i(j['can_return']), canCancel: _i(j['can_cancel']),
    deliveredDate: j['delivered_date']?.toString(), deliveryStatus: j['delivery_status']?.toString() ?? '',
    trackingList: (j['tracking_list'] as List? ?? const []).map((e) => TrackingItem.fromJson(Map<String, dynamic>.from(e))).toList(),
    shop: ShopInfo.fromJson(j['shop'] as Map<String, dynamic>?), attachment: j['attatchment'] ?? j['attachment'],
    trackingId: j['tracking_id']?.toString(), shippingContact: j['shipping_contact']?.toString(), shippingType: j['shipping_type']?.toString(),
    deliveryMode: j['delivery_mode']?.toString(), pickupPoint: j['pickup_point'] != null ? PickupPointInfo.fromJson(Map<String, dynamic>.from(j['pickup_point'])) : null,
    trackingUrl: j['tracking_url']?.toString(), shippingName: j['shipping']?['name']?.toString(),
  );

  double get lineTotal => unitPrice * quantity;

  String get shippingLabel {
    if (deliveryMode == 'pickup') return '';
    if (shippingType == 'driver') return 'Local Driver'.tr;
    if (shippingName != null && shippingName!.isNotEmpty) return shippingName!;
    if (trackingUrl != null) return 'Carrier';
    return 'Pending'.tr;
  }
}

class OrderDetailsData {
  final int id; final String orderCode; final String paymentStatus; final String paymentStatusLabel; final String deliveryStatusLabel;
  final String paymentMethod; final String deliveryStatus; final double subTotal; final double totalTax; final double totalDeliveryCost;
  final double totalDiscount; final double totalPayableAmount; final String orderDate; final OrderAddress billingDetails;
  final OrderAddress shippingDetails; final List<OrderProductItem> products; final int canCancel; final String? note; final int paymentRequired;
  OrderDetailsData({required this.id, required this.orderCode, required this.paymentStatus, required this.paymentStatusLabel, required this.deliveryStatusLabel, required this.paymentMethod, required this.deliveryStatus, required this.subTotal, required this.totalTax, required this.totalDeliveryCost, required this.totalDiscount, required this.totalPayableAmount, required this.orderDate, required this.billingDetails, required this.shippingDetails, required this.products, required this.canCancel, required this.note, required this.paymentRequired});
  static double _d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
  static int _i(dynamic v) => (v is String) ? int.tryParse(v) ?? 0 : (v ?? 0);
  factory OrderDetailsData.fromMap(Map<String, dynamic> j) { final productsData = (j['products']?['data'] as List?) ?? const []; return OrderDetailsData(id: _i(j['id']), orderCode: j['order_code']?.toString() ?? '', paymentStatus: j['payment_status']?.toString() ?? '', paymentStatusLabel: j['payment_status_label']?.toString() ?? '', deliveryStatusLabel: j['delivery_status_label']?.toString() ?? '', paymentMethod: j['payment_method']?.toString() ?? '', deliveryStatus: j['delivery_status']?.toString() ?? '', subTotal: _d(j['sub_total']), totalTax: _d(j['total_tax']), totalDeliveryCost: _d(j['total_delivery_cost']), totalDiscount: _d(j['total_discount']), totalPayableAmount: _d(j['total_payable_amount']), orderDate: j['order_date']?.toString() ?? '', billingDetails: OrderAddress.fromJson(j['billing_details'] as Map<String, dynamic>?), shippingDetails: OrderAddress.fromJson(j['shipping_details'] as Map<String, dynamic>?), products: productsData.map((e) => OrderProductItem.fromJson(Map<String, dynamic>.from(e))).toList(), canCancel: _i(j['can_cancel']), note: j['note']?.toString(), paymentRequired: _i(j['payment_required'])); }
}

class OrderDetailsResponse { final OrderDetailsData data; final bool success; final int status; OrderDetailsResponse({required this.data, required this.success, required this.status}); factory OrderDetailsResponse.fromMap(Map<String, dynamic> map) => OrderDetailsResponse(data: OrderDetailsData.fromMap(Map<String, dynamic>.from(map['data'] ?? {})), success: map['success'] == true, status: (map['status'] is String) ? int.tryParse(map['status']) ?? 0 : (map['status'] ?? 0)); static OrderDetailsResponse fromJsonString(String s) => OrderDetailsResponse.fromMap(json.decode(s) as Map<String, dynamic>); }
