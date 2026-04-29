class ShippingMethod {
  final int id;
  final String title;
  final double cost;
  final String shippingTime;
  final String? shippingFrom;
  final String? by;

  ShippingMethod({
    required this.id,
    required this.title,
    required this.cost,
    required this.shippingTime,
    this.shippingFrom,
    this.by,
  });

  factory ShippingMethod.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ShippingMethod(
      id: (j['id'] is num)
          ? (j['id'] as num).toInt()
          : int.tryParse('${j['id']}') ?? 0,
      title: j['title']?.toString() ?? '',
      cost: toDouble(j['shipping_cost']),
      shippingTime: j['shipping_time']?.toString() ?? '',
      shippingFrom: j['shipping_from']?.toString(),
      by: j['by']?.toString(),
    );
  }
}

class _ProductMini {
  final int id;
  final String uid;
  _ProductMini({required this.id, required this.uid});
  factory _ProductMini.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] is num)
        ? (j['id'] as num).toInt()
        : int.tryParse('${j['id']}') ?? 0;
    final uid = j['uid']?.toString() ?? '';
    return _ProductMini(id: id, uid: uid);
  }
}

class ShippingOptionsForProduct {
  final String productUid;
  final int productId;
  final List<ShippingMethod> methods;
  final ShippingMethod? defaultOption;
  final double tax;

  ShippingOptionsForProduct({
    required this.productUid,
    required this.productId,
    required this.methods,
    required this.defaultOption,
    required this.tax,
  });

  factory ShippingOptionsForProduct.fromJson(Map<String, dynamic> j) {
    final prod = _ProductMini.fromJson(
      (j['product'] ?? {}) as Map<String, dynamic>,
    );
    final optBlock = (j['options'] ?? {}) as Map<String, dynamic>;
    final data = (optBlock['data'] as List?) ?? const [];
    final methods = data
        .map((e) => ShippingMethod.fromJson(e as Map<String, dynamic>))
        .toList();

    ShippingMethod? def;
    if (j['default_option'] != null) {
      def = ShippingMethod.fromJson(
        j['default_option'] as Map<String, dynamic>,
      );
    }

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ShippingOptionsForProduct(
      productUid: prod.uid,
      productId: prod.id,
      methods: methods,
      defaultOption: def,
      tax: toDouble(j['tax']),
    );
  }
}

class ShippingOptionsResponse {
  final bool success;
  final bool shippingAvailable;
  final List<ShippingOptionsForProduct> options;
  final List<Map<String, dynamic>> notAvailableProducts;

  ShippingOptionsResponse({
    required this.success,
    required this.shippingAvailable,
    required this.options,
    required this.notAvailableProducts,
  });

  factory ShippingOptionsResponse.fromJson(Map<String, dynamic> j) {
    final opts = (j['options'] as List?) ?? const [];
    final na = (j['not_available_products'] as List?) ?? const [];

    return ShippingOptionsResponse(
      success: j['success'] == true,
      shippingAvailable: (j['shipping_available'] == true),
      options: opts
          .map(
            (e) =>
                ShippingOptionsForProduct.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      notAvailableProducts: na
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
