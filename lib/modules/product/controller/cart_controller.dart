import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/guest_cart_service.dart';
import '../../../core/services/login_service.dart';
import '../../../core/services/widget_data_service.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../product/model/cart_item_model.dart';

enum CouponPillKind { none, success, error, info }

class CartController extends GetxController {
  CartController(this._repo);
  final CartRepository _repo;

  final CurrencyService _currency = Get.find<CurrencyService>();

  final RxList<CartListItem> items = <CartListItem>[].obs;
  final RxSet<int> selectedIds = <int>{}.obs;

  final isSummaryOpen = false.obs;
  PersistentBottomSheetController? bottomSheetController;

  int get totalItemsCount => items.fold<int>(0, (sum, e) => sum + e.quantity);
  int get lineCount => items.length;

  String money(num v, {bool applyConversion = true}) {
    try {
      return _currency.format(v, applyConversion: applyConversion);
    } catch (_) {
      final fmt = NumberFormat.decimalPattern();
      return '\$ ${fmt.format(v)}';
    }
  }

  final isLoading = false.obs;
  final error = ''.obs;

  final TextEditingController couponCtrl = TextEditingController();
  final RxBool isApplyingCoupon = false.obs;
  final RxString couponPillText = ''.obs;
  final Rx<CouponPillKind> couponPillKind = CouponPillKind.none.obs;
  final RxnString appliedCouponCode = RxnString();
  final RxnInt appliedCouponId = RxnInt();
  final RxDouble _couponDiscount = 0.0.obs;
  final RxString lastCouponError = ''.obs;
  final Set<String> _usedCoupons = <String>{};

  bool get _isLoggedIn => LoginService().isLoggedIn();
  final GuestCartService _guest = GuestCartService();

  List<Map<String, dynamic>> get appliedCoupons {
    if (appliedCouponCode.value == null) return [];
    return [
      {
        'id': appliedCouponId.value ?? 0,
        'coupon_code': appliedCouponCode.value,
        'discount': _couponDiscount.value,
      }
    ];
  }

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  @override
  void onClose() {
    couponCtrl.dispose();
    super.onClose();
  }

  Future<void> loadCart() async {
    try {
      isLoading.value = true;
      error.value = '';

      if (_isLoggedIn) {
        final res = await _repo.fetchCartItems();
        items.assignAll(res.items);
        await _validateAllAndMark();
        if (selectedIds.isEmpty) {
          final selectable = items
              .where((e) => (e.isAvailable ?? 1) != 2)
              .map((e) => e.id);
          selectedIds
            ..clear()
            ..addAll(selectable);
        }
      } else {
        final local = _guest.getListItems();
        items.assignAll(local);
        selectedIds
          ..clear()
          ..addAll(
            items.where((e) => (e.isAvailable ?? 1) != 2).map((e) => e.id),
          );
      }
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      items.clear();
      selectedIds.clear();
    } finally {
      isLoading.value = false;
      _syncWidget();
    }
  }

  Future<void> refreshFromServer({String? prioritizeUid}) async {
    try {
      if (_isLoggedIn) {
        final res = await _repo.fetchCartItems();
        items.assignAll(res.items);
      } else {
        final local = _guest.getListItems();
        items.assignAll(local);
      }
    } catch (_) {}
    
    if (prioritizeUid != null && prioritizeUid.isNotEmpty) {
      final i = items.indexWhere((e) => e.uid == prioritizeUid);
      if (i > 0) {
        final picked = items.removeAt(i);
        items.insert(0, picked);
      }
    }
  }

  Future<void> _validateAllAndMark() async {
    if (!_isLoggedIn) {
      return;
    }
    if (items.isEmpty) {
      selectedIds.clear();
      return;
    }

    try {
      final payload = items.map((e) => e.toApiModel()).toList();
      final resp = await _repo.validateCartItems(payload);

      final list =
          (resp['items'] ??
                  resp['data'] ??
                  resp['validated'] ??
                  resp['cart'] ??
                  [])
              as List?;

      if (list == null || list.isEmpty) {
        selectedIds
          ..clear()
          ..addAll(
            items.where((e) => (e.isAvailable ?? 1) != 2).map((e) => e.id),
          );
        return;
      }

      String keyOf(Map m) {
        final u = m['uid']?.toString();
        if (u != null && u.isNotEmpty) return 'u:$u';
        final id = m['id']?.toString() ?? '';
        final vc = m['variant_code']?.toString() ?? '';
        return 'k:${id}_$vc';
      }

      final Map<String, Map<String, dynamic>> server = {};
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          server[keyOf(raw)] = raw;
        }
      }

      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        final key = 'u:${it.uid}';
        final altKey = 'k:${it.id}_${it.variantCode ?? ''}';
        final sv = server[key] ?? server[altKey];
        if (sv == null) continue;
        final ia = _asInt(sv['is_available']);
        items[i] = it.copyWith(isAvailable: ia);
      }

      final Set<int> newSelected = {};
      for (final it in items) {
        final key = 'u:${it.uid}';
        final altKey = 'k:${it.id}_${it.variantCode ?? ''}';
        final sv = server[key] ?? server[altKey];
        final isSel = _asBool(sv?['is_selected']);
        final isAvail = (it.isAvailable ?? 1) != 2;
        if (isSel == true && isAvail) newSelected.add(it.id);
      }

      selectedIds
        ..clear()
        ..addAll(newSelected);
    } catch (e) {
      selectedIds
        ..clear()
        ..addAll(
          items.where((e) => (e.isAvailable ?? 1) != 2).map((e) => e.id),
        );
    }
  }

  Future<void> _validateOneAndMark(int idx) async {
    if (!_isLoggedIn) return;
    if (idx < 0 || idx >= items.length) return;
    final it = items[idx];

    try {
      final resp = await _repo.validateCartItems([it.toApiModel()]);
      final list = (resp['items'] ?? resp['data'] ?? []) as List?;
      if (list == null || list.isEmpty) return;

      final m = list.first as Map<String, dynamic>;
      final ia = _asInt(m['is_available']);
      final sel = _asBool(m['is_selected']);

      items[idx] = items[idx].copyWith(isAvailable: ia);

      if (sel == true && (ia ?? 1) != 2) {
        selectedIds.add(it.id);
      } else {
        selectedIds.remove(it.id);
      }
    } catch (_) {}
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  void inc(int idx) async {
    final it = items[idx];
    if ((it.isAvailable ?? 1) == 2) return;

    if (it.quantity >= it.maxItem) return;
    final next = it.copyWith(quantity: it.quantity + 1);
    items[idx] = next;

    try {
      if (_isLoggedIn) {
        await _repo.updateCartItem(next.toApiModel());
        await _validateOneAndMark(idx);
      } else {
        _guest.updateQty(it.uid, next.quantity);
      }
    } catch (_) {
      items[idx] = it;
      Get.snackbar(
        'Cart'.tr,
        'Failed to update quantity'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
    _syncWidget();
  }

  void dec(int idx) async {
    final it = items[idx];
    if ((it.isAvailable ?? 1) == 2) return;

    if (it.quantity <= 1) return;
    final next = it.copyWith(quantity: it.quantity - 1);
    items[idx] = next;

    try {
      if (_isLoggedIn) {
        await _repo.updateCartItem(next.toApiModel());
        await _validateOneAndMark(idx);
      } else {
        _guest.updateQty(it.uid, next.quantity);
      }
    } catch (_) {
      items[idx] = it;
      Get.snackbar(
        'Cart'.tr,
        'Failed to update quantity'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
    _syncWidget();
  }

  void removeAt(int idx) async {
    final it = items[idx];
    items.removeAt(idx);
    selectedIds.remove(it.id);

    try {
      if (_isLoggedIn) {
        await _repo.removeCartItem(it.uid);
      } else {
        _guest.removeByUid(it.uid);
      }
    } catch (_) {
      await loadCart();
      Get.snackbar(
        'Cart'.tr,
        'Failed to remove item'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
    _syncWidget();
  }

  bool isSelectedId(int productId) => selectedIds.contains(productId);

  Future<void> toggleItemSelection(int productId) async {
    final it = items.firstWhereOrNull((e) => e.id == productId);
    if (it == null) return;

    if ((it.isAvailable ?? 1) == 2) return;

    if (selectedIds.contains(productId)) {
      selectedIds.remove(productId);
    } else {
      selectedIds.add(productId);
    }
  }

  bool get allSelected {
    final availableIds = items
        .where((e) => (e.isAvailable ?? 1) != 2)
        .map((e) => e.id)
        .toSet();
    if (availableIds.isEmpty) return false;
    return selectedIds.length == availableIds.length &&
        selectedIds.containsAll(availableIds);
  }

  Future<void> toggleSelectAll(bool value) async {
    if (value) {
      final okIds = items
          .where((e) => (e.isAvailable ?? 1) != 2)
          .map((e) => e.id);
      selectedIds
        ..clear()
        ..addAll(okIds);
    } else {
      selectedIds.clear();
    }
  }

  int get selectedCount => selectedIds.length;

  int get selectedQtyTotal => items
      .where((e) => selectedIds.contains(e.id))
      .fold(0, (p, e) => p + e.quantity);

  double get subTotal => items.fold(0.0, (p, e) => p + e.lineTotal);

  double get selectedSubTotal => items
      .where((e) => selectedIds.contains(e.id))
      .fold(0.0, (p, e) => p + e.lineTotal);

  double get discount => _couponDiscount.value;

  double get grandTotal =>
      (selectedSubTotal - discount).clamp(0.0, double.infinity);

  String variantLine(CartListItem it) {
    final v = (it.variant ?? '').trim();
    if (v.isEmpty) return '';

    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

    final parts = v
        .split('/')
        .map((seg) {
          final idx = seg.indexOf(':');
          if (idx == -1) return cap(seg.trim());
          final key = seg.substring(0, idx).trim();
          final val = seg.substring(idx + 1).trim();
          return '${cap(key)}: $val';
        })
        .join(' / ');

    return parts;
  }

  List<CartListItem> get selectedCartItems =>
      items.where((e) => selectedIds.contains(e.id)).toList();

  bool get canCheckout => selectedIds.isNotEmpty;

  Future<void> goToCheckout() async {
    if (!canCheckout) {
      Get.snackbar(
        'Checkout'.tr,
        'Please select at least one item'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }
    Get.toNamed(
      AppRoutes.checkoutView,
      arguments: {'items': selectedCartItems},
    );
  }

  void openSummary() => isSummaryOpen.value = true;
  void closeSummary() => isSummaryOpen.value = false;
  void toggleSummary() => isSummaryOpen.value ? closeSummary() : openSummary();

  Future<void> applyCoupon({int customerId = 0}) async {
    final code = couponCtrl.text.trim();
    if (code.isEmpty) {
      couponPillText.value = 'Enter coupon code'.tr;
      couponPillKind.value = CouponPillKind.info;
      return;
    }

    if (appliedCouponCode.value != null && appliedCouponCode.value == code) {
      couponPillText.value = 'Already applied'.tr;
      couponPillKind.value = CouponPillKind.info;
      return;
    }
    if (_usedCoupons.contains(code)) {
      couponPillText.value = 'Already applied'.tr;
      couponPillKind.value = CouponPillKind.info;
      return;
    }

    final list =
        (selectedIds.isNotEmpty
                ? items.where((e) => selectedIds.contains(e.id))
                : items)
            .map((e) => e.toApiModel())
            .toList();

    if (list.isEmpty) {
      couponPillText.value = 'No items to apply'.tr;
      couponPillKind.value = CouponPillKind.info;
      return;
    }

    try {
      isApplyingCoupon.value = true;
      lastCouponError.value = '';

      final resp = await _repo.applyCoupon(
        couponCode: code,
        customerId: customerId,
        products: list,
      );

      if (resp.success) {
        _couponDiscount.value = (resp.discount ?? 0).toDouble();
        appliedCouponCode.value = resp.couponCode ?? '';
        appliedCouponId.value = resp.couponId;
        couponPillText.value = 'Applied'.tr;
        couponPillKind.value = CouponPillKind.success;
        _usedCoupons.add(code);
      } else {
        final msg = resp.message ?? 'Coupon apply failed'.tr;
        lastCouponError.value = msg;
        _couponDiscount.value = 0.0;
        appliedCouponCode.value = null;
        appliedCouponId.value = null;
        couponPillText.value = msg.tr;
        couponPillKind.value = CouponPillKind.error;
      }
    } catch (e) {
      isApplyingCoupon.value = false;
      lastCouponError.value = 'Something went wrong'.tr;
      _couponDiscount.value = 0;
      appliedCouponCode.value = null;
      appliedCouponId.value = null;

      couponPillText.value = 'Something went wrong'.tr;
      couponPillKind.value = CouponPillKind.error;

      return;
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  Future<void> clearAfterOrder() async {
    try {
      if (_isLoggedIn) {
        final current = List<CartListItem>.from(items);

        for (final it in current) {
          try {
            await _repo.removeCartItem(it.uid);
          } catch (_) {}
        }
      } else {
        _guest.clear();
      }
    } finally {
      await loadCart();
    }
  }

  void clearCoupon() {
    _couponDiscount.value = 0.0;
    appliedCouponCode.value = null;
    appliedCouponId.value = null;
    couponPillText.value = '';
    couponPillKind.value = CouponPillKind.none;
  }

  void _syncWidget() {
    final count = totalItemsCount;
    final String itemsText;
    if (count == 0) {
      itemsText = '0 items in cart'.tr;
    } else if (count == 1) {
      itemsText = '1 item in cart'.tr;
    } else {
      itemsText = '$count ${'items in cart'.tr}';
    }
    WidgetDataService.updateWidgetData(
      cartItems: totalItemsCount,
      cartTotal: money(grandTotal),
      cartItemsText: itemsText,
      currencySymbol: _currency.current?.symbol ?? '₦',
    );
  }
}
