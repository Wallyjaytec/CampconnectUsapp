class CouponModel {
  final int id;
  final String code;
  final String description;
  final String discountType; // 'percentage' or 'flat'
  final double discountAmount;
  final double? minSpend;
  final double? maxSpend;
  final bool allowFreeShipping;
  final String? expiryDate;
  final bool isActive;
  final String? applicableOn; // 'All Products', 'Shoes Category', etc.

  CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountAmount,
    this.minSpend,
    this.maxSpend,
    required this.allowFreeShipping,
    this.expiryDate,
    required this.isActive,
    this.applicableOn,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountAmount: (json['discount_amount'] is String)
          ? double.tryParse(json['discount_amount']) ?? 0.0
          : (json['discount_amount'] ?? 0.0).toDouble(),
      minSpend: json['min_spend'] != null
          ? double.tryParse(json['min_spend'].toString()) ?? 0.0
          : null,
      maxSpend: json['max_spend'] != null
          ? double.tryParse(json['max_spend'].toString()) ?? 0.0
          : null,
      allowFreeShipping: json['allow_free_shipping'] == true || json['allow_free_shipping']?.toString() == '1',
      expiryDate: json['expiry_date']?.toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      applicableOn: json['applicable_on']?.toString(),
    );
  }

  String get discountText {
    if (discountType == 'percentage') {
      return '${discountAmount.toStringAsFixed(0)}% off';
    }
    return '₦${discountAmount.toStringAsFixed(0)} off';
  }

  bool get isExpired {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    final expiry = DateTime.tryParse(expiryDate!);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }
}
