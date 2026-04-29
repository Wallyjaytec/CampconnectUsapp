import 'dart:convert';

import 'package:kartly_e_commerce/modules/product/model/product_model.dart';

import '../../../core/config/app_config.dart';

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String _str(dynamic v) => v?.toString() ?? '';

class CartListItem {
  final String uid;
  final int id;
  final String name;
  final String permalink;
  final String image;
  final String? variant;
  final String? variantCode;
  final int quantity;
  final String unitPrice;
  final String? oldPrice;
  final int minItem;
  final int maxItem;

  final Map<String, dynamic>? attachment;

  final String seller;
  final String shopName;
  final String shopSlug;
  final int? isAvailable;
  final bool? isSelected;

  CartListItem({
    required this.uid,
    required this.id,
    required this.name,
    required this.permalink,
    required this.image,
    required this.variant,
    required this.variantCode,
    required this.quantity,
    required this.unitPrice,
    required this.oldPrice,
    required this.minItem,
    required this.maxItem,
    required this.attachment,
    required this.seller,
    required this.shopName,
    required this.shopSlug,
    this.isAvailable,
    this.isSelected,
  });

  String get imageUrl => AppConfig.assetUrl(image);

  double get unitPriceNum => double.tryParse(unitPrice) ?? 0.0;
  double get oldPriceNum => double.tryParse(oldPrice ?? '') ?? unitPriceNum;

  double get lineTotal => unitPriceNum * quantity;

  CartListItem copyWith({
    String? uid,
    int? id,
    String? name,
    String? permalink,
    String? image,
    String? variant,
    String? variantCode,
    int? quantity,
    String? unitPrice,
    String? oldPrice,
    int? minItem,
    int? maxItem,
    Map<String, dynamic>? attachment,
    String? seller,
    String? shopName,
    String? shopSlug,
    int? isAvailable,
    bool? isSelected,
  }) {
    return CartListItem(
      uid: uid ?? this.uid,
      id: id ?? this.id,
      name: name ?? this.name,
      permalink: permalink ?? this.permalink,
      image: image ?? this.image,
      variant: variant ?? this.variant,
      variantCode: variantCode ?? this.variantCode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      oldPrice: oldPrice ?? this.oldPrice,
      minItem: minItem ?? this.minItem,
      maxItem: maxItem ?? this.maxItem,
      attachment: attachment ?? this.attachment,
      seller: seller ?? this.seller,
      shopName: shopName ?? this.shopName,
      shopSlug: shopSlug ?? this.shopSlug,
      isAvailable: isAvailable ?? this.isAvailable,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory CartListItem.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? attachment;
    final rawAtt = j['attachment'];

    if (rawAtt is Map<String, dynamic>) {
      attachment = rawAtt;
    } else if (rawAtt is String) {
      final txt = rawAtt.trim();
      if (txt.isNotEmpty && txt.toLowerCase() != 'null') {
        try {
          final decoded = jsonDecode(txt);
          if (decoded is Map<String, dynamic>) {
            attachment = decoded;
          }
        } catch (_) {
          attachment = null;
        }
      }
    }

    return CartListItem(
      uid: _str(j['uid']),
      id: _parseInt(j['id']) ?? 0,
      name: _str(j['name']),
      permalink: _str(j['permalink']),
      image: _str(j['image']),
      variant: j['variant']?.toString(),
      variantCode: j['variant_code']?.toString(),
      quantity: _parseInt(j['quantity']) ?? 0,
      unitPrice: _str(j['unitPrice']),
      oldPrice: j['oldPrice']?.toString(),
      minItem: _parseInt(j['min_item']) ?? 1,
      maxItem: _parseInt(j['max_item']) ?? 0,
      attachment: attachment,
      seller: _str(j['seller']),
      shopName: _str(j['shop_name']),
      shopSlug: _str(j['shop_slug']),
      isAvailable: _parseInt(j['is_available']),
      isSelected: _parseBool(j['is_selected']),
    );
  }

  Map<String, dynamic> toApiItem() {
    return {
      "id": id,
      "uid": uid,
      "name": name,
      "permalink": permalink,
      "image": image,
      "variant": variant,
      "variant_code": variantCode,
      "quantity": quantity,
      "unitPrice": unitPriceNum,
      "oldPrice": oldPriceNum,
      "min_item": minItem,
      "max_item": maxItem,
      "attachment": attachment,
      "seller": int.tryParse(seller) ?? 0,
      "shop_name": shopName,
      "shop_slug": shopSlug,
      if (isAvailable != null) "is_available": isAvailable,
      if (isSelected != null) "is_selected": isSelected,
    };
  }

  CartApiItem toApiModel() {
    return CartApiItem(
      uid: uid,
      id: id,
      name: name,
      permalink: permalink,
      image: image,
      variant: variant,
      variantCode: variantCode,
      quantity: quantity,
      unitPrice: unitPriceNum,
      oldPrice: oldPriceNum,
      minItem: minItem,
      maxItem: maxItem,
      attachment: attachment,
      seller: int.tryParse(seller) ?? 0,
      shopName: shopName,
      shopSlug: shopSlug,
      isAvailable: isAvailable,
      isSelected: isSelected,
    );
  }
}

class CartListResponse {
  final List<CartListItem> items;
  final bool success;
  final int status;
  CartListResponse({
    required this.items,
    required this.success,
    required this.status,
  });

  factory CartListResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as List?) ?? const [];
    return CartListResponse(
      items: data
          .map((e) => CartListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      success: j['success'] == true,
      status: (j['status'] as num?)?.toInt() ?? 0,
    );
  }
}

class CartApiItem {
  final String uid;
  final int id;
  final String name;
  final String permalink;
  final String image;
  final String? variant;
  final String? variantCode;
  final int quantity;
  final num unitPrice;
  final num oldPrice;
  final int minItem;
  final int maxItem;
  final Map<String, dynamic>? attachment;
  final int seller;
  final String shopName;
  final String shopSlug;
  final int? isAvailable;
  final bool? isSelected;

  CartApiItem({
    required this.uid,
    required this.id,
    required this.name,
    required this.permalink,
    required this.image,
    required this.variant,
    required this.variantCode,
    required this.quantity,
    required this.unitPrice,
    required this.oldPrice,
    required this.minItem,
    required this.maxItem,
    required this.attachment,
    required this.seller,
    required this.shopName,
    required this.shopSlug,
    this.isAvailable,
    this.isSelected,
  });

  String toFormFieldString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "name": name,
    "permalink": permalink,
    "image": image,
    "variant": variant,
    "variant_code": variantCode,
    "quantity": quantity,
    "unitPrice": unitPrice,
    "oldPrice": oldPrice,
    "min_item": minItem,
    "max_item": maxItem,
    "attachment": attachment,
    "seller": seller,
    "shop_name": shopName,
    "shop_slug": shopSlug,
    if (isAvailable != null) "is_available": isAvailable,
    if (isSelected != null) "is_selected": isSelected,
  };

  static CartApiItem fromUi({
    required ProductModel product,
    required int quantity,
    required num unitPrice,
    num? oldPrice,
    String uid = '',
    String? variant,
    String? variantCode,
    int minItem = 1,
    int maxItem = 9999,
    int? seller,
    String? shopName,
    String? shopSlug,
  }) {
    return CartApiItem(
      uid: uid.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : uid,
      id: product.id,
      name: product.title,
      permalink: product.slug,
      image: product.image,
      variant: variant,
      variantCode: variantCode,
      quantity: quantity,
      unitPrice: unitPrice,
      oldPrice: oldPrice ?? unitPrice,
      minItem: minItem,
      maxItem: maxItem,
      attachment: null,
      seller: (seller ?? 0),
      shopName: shopName ?? '',
      shopSlug: shopSlug ?? '',
    );
  }
}

class ApplyCouponResponse {
  final bool success;
  final String? message;
  final num? discount;
  final String? couponCode;
  final int? couponId;
  final bool freeShipping;

  ApplyCouponResponse({
    required this.success,
    this.message,
    this.discount,
    this.couponCode,
    this.couponId,
    required this.freeShipping,
  });

  factory ApplyCouponResponse.fromJson(Map<String, dynamic> j) {
    bool b(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == '1' || s == 'true';
    }

    int? i(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    num? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    return ApplyCouponResponse(
      success: j['success'] == true,
      message: j['message']?.toString(),
      discount: n(j['discount']),
      couponCode: j['coupon_code']?.toString(),
      couponId: i(j['coupon_id']),
      freeShipping: b(j['free_shipping']),
    );
  }
}
