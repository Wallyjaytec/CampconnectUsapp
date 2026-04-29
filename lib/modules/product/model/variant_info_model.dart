class VariantInfoModel {
  final bool success;
  final String? old;
  final String? newVariant;
  final double basePrice;
  final double? oldPrice;
  final int quantity;

  VariantInfoModel({
    required this.success,
    required this.basePrice,
    required this.quantity,
    this.old,
    this.newVariant,
    this.oldPrice,
  });

  factory VariantInfoModel.fromJson(Map<String, dynamic> j) {
    double toD(v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    int toI(v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    return VariantInfoModel(
      success: (j['success'] == true) || (j['success']?.toString() == 'true'),
      old: j['old']?.toString(),
      newVariant: j['new_variant']?.toString(),
      basePrice: toD(j['base_price']),
      oldPrice: j['oldPrice'] != null ? toD(j['oldPrice']) : null,
      quantity: toI(j['quantity']),
    );
  }
}
