class RefundRequest {
  final int id;
  final String refundCode;
  final String orderId;
  final String paymentStatusLabel;
  final String returnStatusLabel;
  final String totalRefundAmount;
  final String returnDate;

  const RefundRequest({
    required this.id,
    required this.refundCode,
    required this.orderId,
    required this.paymentStatusLabel,
    required this.returnStatusLabel,
    required this.totalRefundAmount,
    required this.returnDate,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    refundCode: json['refund_code']?.toString() ?? '',
    orderId: json['order_id']?.toString() ?? '',
    paymentStatusLabel: json['payment_status_label']?.toString() ?? '',
    returnStatusLabel: json['return_status_label']?.toString() ?? '',
    totalRefundAmount: json['total_refund_amount']?.toString() ?? '0',
    returnDate: json['return_date']?.toString() ?? '',
  );
}

class RefundRequestResponse {
  final List<RefundRequest> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool success;
  final int status;

  const RefundRequestResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.success,
    required this.status,
  });

  factory RefundRequestResponse.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map?) ?? const {};
    final list = (json['data'] as List? ?? [])
        .map((e) => RefundRequest.fromJson(e as Map<String, dynamic>))
        .toList();

    return RefundRequestResponse(
      data: list,
      currentPage: meta['current_page'] is int
          ? meta['current_page']
          : int.tryParse('${meta['current_page']}') ?? 1,
      lastPage: meta['last_page'] is int
          ? meta['last_page']
          : int.tryParse('${meta['last_page']}') ?? 1,
      perPage: meta['per_page'] is int
          ? meta['per_page']
          : int.tryParse('${meta['per_page']}') ?? 10,
      total: meta['total'] is int
          ? meta['total']
          : int.tryParse('${meta['total']}') ?? 0,
      success: json['success'] == true || json['success']?.toString() == 'true',
      status: json['status'] is int
          ? json['status']
          : int.tryParse('${json['status']}') ?? 200,
    );
  }
}
