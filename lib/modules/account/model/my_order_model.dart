import 'dart:convert';

class OrderItem {
  final int id;
  final String orderCode;
  final double totalPayableAmount;
  final int totalProducts;
  final String orderDate;

  OrderItem({
    required this.id,
    required this.orderCode,
    required this.totalPayableAmount,
    required this.totalProducts,
    required this.orderDate,
  });

  static double _parseAmount(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ??
          double.tryParse(num.tryParse(v)?.toString() ?? '') ??
          0.0;
    }
    return 0.0;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] ?? 0),
      orderCode: json['order_code']?.toString() ?? '',
      totalPayableAmount: _parseAmount(json['total_payable_amount']),
      totalProducts: json['total_products'] is String
          ? int.tryParse(json['total_products']) ?? 0
          : (json['total_products'] ?? 0),
      orderDate: json['order_date']?.toString() ?? '',
    );
  }
}

class PaginationLink {
  final String? url;
  final String label;
  final bool active;

  PaginationLink({this.url, required this.label, required this.active});

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: json['url']?.toString(),
      label: json['label']?.toString() ?? '',
      active: json['active'] == true,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;
  final List<PaginationLink> links;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    required this.links,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final linksJson = (json['links'] as List?) ?? const [];
    return PaginationMeta(
      currentPage: (json['current_page'] ?? 1) is String
          ? int.tryParse(json['current_page']) ?? 1
          : (json['current_page'] ?? 1),
      lastPage: (json['last_page'] ?? 1) is String
          ? int.tryParse(json['last_page']) ?? 1
          : (json['last_page'] ?? 1),
      perPage: (json['per_page'] ?? 0) is String
          ? int.tryParse(json['per_page']) ?? 0
          : (json['per_page'] ?? 0),
      total: (json['total'] ?? 0) is String
          ? int.tryParse(json['total']) ?? 0
          : (json['total'] ?? 0),
      from: (json['from'] ?? 0) is String
          ? int.tryParse(json['from']) ?? 0
          : (json['from'] ?? 0),
      to: (json['to'] ?? 0) is String
          ? int.tryParse(json['to']) ?? 0
          : (json['to'] ?? 0),
      links: linksJson.map((e) => PaginationLink.fromJson(e)).toList(),
    );
  }
}

class OrderListResponse {
  final List<OrderItem> data;
  final PaginationMeta? meta;
  final bool success;
  final int status;

  OrderListResponse({
    required this.data,
    required this.meta,
    required this.success,
    required this.status,
  });

  factory OrderListResponse.fromMap(Map<String, dynamic> map) {
    final list = (map['data'] as List?) ?? const [];
    return OrderListResponse(
      data: list.map((e) => OrderItem.fromJson(e)).toList(),
      meta: map['meta'] != null ? PaginationMeta.fromJson(map['meta']) : null,
      success: map['success'] == true,
      status: (map['status'] ?? 0) is String
          ? int.tryParse(map['status']) ?? 0
          : (map['status'] ?? 0),
    );
  }

  static OrderListResponse fromJsonString(String jsonStr) {
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return OrderListResponse.fromMap(map);
  }
}
