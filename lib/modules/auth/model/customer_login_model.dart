class CustomerLoginUser {
  final String? image;
  final String name;
  final String email;
  final int id;
  final String uid;
  final String phoneWithCode;
  final String phoneCode;
  final String phone;
  final String? verifiedAt;

  const CustomerLoginUser({
    required this.image,
    required this.name,
    required this.email,
    required this.id,
    required this.uid,
    required this.phoneWithCode,
    required this.phoneCode,
    required this.phone,
    required this.verifiedAt,
  });

  factory CustomerLoginUser.fromJson(Map<String, dynamic> json) {
    return CustomerLoginUser(
      image: json['image']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      id: _toInt(json['id']),
      uid: json['uid']?.toString() ?? '',
      phoneWithCode: json['phone_with_code']?.toString() ?? '',
      phoneCode: json['phone_code']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      verifiedAt: json['verified_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'image': image,
    'name': name,
    'email': email,
    'id': id,
    'uid': uid,
    'phone_with_code': phoneWithCode,
    'phone_code': phoneCode,
    'phone': phone,
    'verified_at': verifiedAt,
  };

  static int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

class CustomerDashboardContent {
  final int totalOrder;
  final int totalSuccessfullOrder;
  final int totalPendingOrder;
  final int totalCancelledOrder;
  final num totalPurchaseAmount;
  final String? lastPurchaseDate;
  final num lastPurchaseAmount;
  final String currentMonth;
  final num currentMonthPurchase;
  final String lastMonth;
  final num lastMonthPurchase;
  final int totalWishlistedProduct;
  final int totalSupportTickets;
  final num walletBalance;

  const CustomerDashboardContent({
    required this.totalOrder,
    required this.totalSuccessfullOrder,
    required this.totalPendingOrder,
    required this.totalCancelledOrder,
    required this.totalPurchaseAmount,
    required this.lastPurchaseDate,
    required this.lastPurchaseAmount,
    required this.currentMonth,
    required this.currentMonthPurchase,
    required this.lastMonth,
    required this.lastMonthPurchase,
    required this.totalWishlistedProduct,
    required this.totalSupportTickets,
    required this.walletBalance,
  });

  factory CustomerDashboardContent.fromJson(Map<String, dynamic> j) {
    return CustomerDashboardContent(
      totalOrder: _i(j['total_order']),
      totalSuccessfullOrder: _i(j['total_successfull_order']),
      totalPendingOrder: _i(j['total_pending_order']),
      totalCancelledOrder: _i(j['total_cancelled_order']),
      totalPurchaseAmount: _n(j['total_purchase_amount']),
      lastPurchaseDate: j['last_purchase_date']?.toString(),
      lastPurchaseAmount: _n(j['last_purchase_amount']),
      currentMonth: j['current_month']?.toString() ?? '',
      currentMonthPurchase: _n(j['current_month_purchase']),
      lastMonth: j['last_month']?.toString() ?? '',
      lastMonthPurchase: _n(j['last_month_purchase']),
      totalWishlistedProduct: _i(j['total_wishlisted_product']),
      totalSupportTickets: _i(j['total_support_tickets']),
      walletBalance: _n(j['wallet_balance']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_order': totalOrder,
    'total_successfull_order': totalSuccessfullOrder,
    'total_pending_order': totalPendingOrder,
    'total_cancelled_order': totalCancelledOrder,
    'total_purchase_amount': totalPurchaseAmount,
    'last_purchase_date': lastPurchaseDate,
    'last_purchase_amount': lastPurchaseAmount,
    'current_month': currentMonth,
    'current_month_purchase': currentMonthPurchase,
    'last_month': lastMonth,
    'last_month_purchase': lastMonthPurchase,
    'total_wishlisted_product': totalWishlistedProduct,
    'total_support_tickets': totalSupportTickets,
    'wallet_balance': walletBalance,
  };

  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
  static num _n(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '0') ?? 0;
}
