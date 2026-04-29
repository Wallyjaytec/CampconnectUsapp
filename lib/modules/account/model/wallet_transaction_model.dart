class WalletSummary {
  final num totalPending;
  final num totalAvailable;

  WalletSummary({required this.totalPending, required this.totalAvailable});

  factory WalletSummary.fromJson(Map<String, dynamic> j) {
    return WalletSummary(
      totalPending: (j['total_pending'] ?? 0),
      totalAvailable: (j['total_available'] ?? 0),
    );
  }
}

class WalletTransaction {
  final int id;
  final double rechargeAmount;
  final String date;
  final String status;
  final String type;
  final String paymentMethod;

  WalletTransaction({
    required this.id,
    required this.rechargeAmount,
    required this.date,
    required this.status,
    required this.type,
    required this.paymentMethod,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) {
    return WalletTransaction(
      id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
      rechargeAmount: j['recharge_amount'] is double
          ? j['recharge_amount']
          : double.tryParse(j['recharge_amount']?.toString() ?? '') ?? 0,
      date: j['date']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      type: j['type']?.toString() ?? '',
      paymentMethod: j['payment_method']?.toString() ?? '',
    );
  }
}

class WalletPageLinks {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  WalletPageLinks({this.first, this.last, this.prev, this.next});

  factory WalletPageLinks.fromJson(Map<String, dynamic> j) => WalletPageLinks(
    first: j['first']?.toString(),
    last: j['last']?.toString(),
    prev: j['prev']?.toString(),
    next: j['next']?.toString(),
  );
}

class WalletPageMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;

  WalletPageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
  });

  factory WalletPageMeta.fromJson(Map<String, dynamic> j) => WalletPageMeta(
    currentPage: j['current_page'] ?? 1,
    lastPage: j['last_page'] ?? 1,
    perPage: j['per_page'] is int
        ? j['per_page']
        : int.tryParse(j['per_page']?.toString() ?? '0') ?? 0,
    total: j['total'] ?? 0,
    from: j['from'] ?? 0,
    to: j['to'] ?? 0,
  );
}

class WalletTransactionPage {
  final List<WalletTransaction> data;
  final WalletPageLinks? links;
  final WalletPageMeta? meta;
  final bool success;
  final int status;

  WalletTransactionPage({
    required this.data,
    this.links,
    this.meta,
    required this.success,
    required this.status,
  });

  factory WalletTransactionPage.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List<dynamic>? ?? [])
        .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return WalletTransactionPage(
      data: list,
      links: j['links'] != null
          ? WalletPageLinks.fromJson(j['links'] as Map<String, dynamic>)
          : null,
      meta: j['meta'] != null
          ? WalletPageMeta.fromJson(j['meta'] as Map<String, dynamic>)
          : null,
      success:
          (j['success'] == true ||
          j['success']?.toString().toLowerCase() == 'true'),
      status: j['status'] is int
          ? j['status']
          : int.tryParse(j['status']?.toString() ?? '0') ?? 0,
    );
  }
}
