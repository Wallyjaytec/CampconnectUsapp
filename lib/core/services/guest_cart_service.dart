import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../../modules/product/model/cart_item_model.dart';

class GuestCartService {
  static const String _kGuestCartItems = 'guest_cart_items';

  final GetStorage _storage = GetStorage();

  List<CartApiItem> _readRaw() {
    final raw = _storage.read(_kGuestCartItems);
    if (raw is String && raw.isNotEmpty) {
      try {
        final list =
            (jsonDecode(raw) as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const <Map<String, dynamic>>[];
        return list.map((m) => _fromJsonCartApiItem(m)).toList();
      } catch (_) {
        return <CartApiItem>[];
      }
    }
    return <CartApiItem>[];
  }

  void _writeRaw(List<CartApiItem> items) {
    final data = items.map((e) => e.toJson()).toList();
    _storage.write(_kGuestCartItems, jsonEncode(data));
  }

  void clear() => _storage.remove(_kGuestCartItems);

  List<CartListItem> getListItems() {
    final raw = _readRaw();
    return raw.map(_toListItem).toList();
  }

  String addOrMerge(CartApiItem incoming) {
    final items = _readRaw();

    final idx = items.indexWhere(
      (e) =>
          e.id == incoming.id &&
          (e.variantCode ?? '') == (incoming.variantCode ?? ''),
    );

    if (idx >= 0) {
      final base = items[idx];
      final maxStock = base.maxItem > 0 ? base.maxItem : 999999;
      final mergedQty = (base.quantity + incoming.quantity).clamp(1, maxStock);

      final merged = CartApiItem(
        uid: base.uid,
        id: base.id,
        name: base.name,
        permalink: base.permalink,
        image: base.image,
        variant: base.variant ?? incoming.variant,
        variantCode: base.variantCode ?? incoming.variantCode,
        quantity: mergedQty,
        unitPrice: incoming.unitPrice,
        oldPrice: incoming.oldPrice,
        minItem: base.minItem,
        maxItem: base.maxItem,
        attachment: base.attachment,
        seller: base.seller,
        shopName: base.shopName,
        shopSlug: base.shopSlug,
        isAvailable: 1,
        isSelected: true,
      );

      items[idx] = merged;
      _writeRaw(items);
      return merged.uid;
    } else {
      final uid = (incoming.uid.isEmpty)
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : incoming.uid;

      final line = CartApiItem(
        uid: uid,
        id: incoming.id,
        name: incoming.name,
        permalink: incoming.permalink,
        image: incoming.image,
        variant: incoming.variant,
        variantCode: incoming.variantCode,
        quantity: incoming.quantity,
        unitPrice: incoming.unitPrice,
        oldPrice: incoming.oldPrice,
        minItem: incoming.minItem,
        maxItem: incoming.maxItem,
        attachment: incoming.attachment,
        seller: incoming.seller,
        shopName: incoming.shopName,
        shopSlug: incoming.shopSlug,
        isAvailable: 1,
        isSelected: true,
      );

      items.insert(0, line);
      _writeRaw(items);
      return uid;
    }
  }

  void updateQty(String uid, int qty) {
    final items = _readRaw();
    final i = items.indexWhere((e) => e.uid == uid);
    if (i < 0) return;
    final maxStock = items[i].maxItem > 0 ? items[i].maxItem : 999999;
    final nextQty = qty.clamp(1, maxStock);
    items[i] = CartApiItem(
      uid: items[i].uid,
      id: items[i].id,
      name: items[i].name,
      permalink: items[i].permalink,
      image: items[i].image,
      variant: items[i].variant,
      variantCode: items[i].variantCode,
      quantity: nextQty,
      unitPrice: items[i].unitPrice,
      oldPrice: items[i].oldPrice,
      minItem: items[i].minItem,
      maxItem: items[i].maxItem,
      attachment: items[i].attachment,
      seller: items[i].seller,
      shopName: items[i].shopName,
      shopSlug: items[i].shopSlug,
      isAvailable: items[i].isAvailable,
      isSelected: items[i].isSelected,
    );
    _writeRaw(items);
  }

  void removeByUid(String uid) {
    final items = _readRaw();
    items.removeWhere((e) => e.uid == uid);
    _writeRaw(items);
  }

  CartListItem _toListItem(CartApiItem a) {
    return CartListItem(
      uid: a.uid,
      id: a.id,
      name: a.name,
      permalink: a.permalink,
      image: a.image,
      variant: a.variant,
      variantCode: a.variantCode,
      quantity: a.quantity,
      unitPrice: a.unitPrice.toString(),
      oldPrice: a.oldPrice.toString(),
      minItem: a.minItem,
      maxItem: a.maxItem,
      attachment: a.attachment,
      seller: a.seller.toString(),
      shopName: a.shopName,
      shopSlug: a.shopSlug,
      isAvailable: a.isAvailable ?? 1,
      isSelected: a.isSelected ?? true,
    );
  }

  CartApiItem _fromJsonCartApiItem(Map<String, dynamic> j) {
    num n(dynamic v) {
      if (v is num) return v;
      return num.tryParse(v?.toString() ?? '0') ?? 0;
    }

    int i(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    bool? b(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
      return null;
    }

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

    return CartApiItem(
      uid: (j['uid'] ?? '').toString(),
      id: i(j['id']),
      name: (j['name'] ?? '').toString(),
      permalink: (j['permalink'] ?? '').toString(),
      image: (j['image'] ?? '').toString(),
      variant: j['variant']?.toString(),
      variantCode: j['variant_code']?.toString(),
      quantity: i(j['quantity']),
      unitPrice: n(j['unitPrice']),
      oldPrice: n(j['oldPrice']),
      minItem: i(j['min_item']),
      maxItem: i(j['max_item']),
      attachment: attachment,
      seller: i(j['seller']),
      shopName: (j['shop_name'] ?? '').toString(),
      shopSlug: (j['shop_slug'] ?? '').toString(),
      isAvailable: j['is_available'] == null ? null : i(j['is_available']),
      isSelected: b(j['is_selected']),
    );
  }
}
