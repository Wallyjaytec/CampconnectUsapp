import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../account/model/address_model.dart';
import '../../account/widgets/order_pay_web_view.dart';
import '../../account/controller/customer_dashboard_controller.dart';
import '../model/cart_item_model.dart';
import '../model/payment_method_model.dart';
import '../model/pickup_point_model.dart';
import '../model/shipping_options_model.dart';
import 'cart_controller.dart';

enum DeliveryMode { home, pickup }

enum BillingMode { sameAsShipping, different }

class CheckoutController extends GetxController {
  CheckoutController({
    ApiService? api,
    AddressRepository? addressRepo,
    CheckoutRepository? checkoutRepo,
    WalletRepository? walletRepo,
  }) : _addressRepo = addressRepo ?? AddressRepository(api ?? ApiService()),
       _checkoutRepo = checkoutRepo ?? CheckoutRepository(api ?? ApiService()),
       _walletRepo = walletRepo ?? WalletRepository(api: api ?? ApiService());

  final AddressRepository _addressRepo;
  final CheckoutRepository _checkoutRepo;
  final WalletRepository _walletRepo;

  final RxBool isScreenLoading = false.obs;

  final RxList<CartListItem> items = <CartListItem>[].obs;
  final RxList<Map<String, dynamic>> appliedCoupons = <Map<String, dynamic>>[].obs;

  final Rx<DeliveryMode> deliveryMode = DeliveryMode.home.obs;
  final Rx<BillingMode> billingMode = BillingMode.sameAsShipping.obs;

  final RxList<CustomerAddress> allAddresses = <CustomerAddress>[].obs;
  List<CustomerAddress> get activeAddresses => allAddresses.where((a) {
    final s = a.status.trim().toLowerCase();
    return s == 'active' || s == '1';
  }).toList();
  final RxnInt selectedShippingId = RxnInt();
  final RxnInt selectedBillingId = RxnInt();

  final RxList<PickupPoint> pickupPoints = <PickupPoint>[].obs;

  final RxMap<String, DeliveryMode> productDeliveryMode = <String, DeliveryMode>{}.obs;
  final RxMap<String, int?> productPickupId = <String, int?>{}.obs;

  DeliveryMode getProductDeliveryMode(String uid) {
    return productDeliveryMode[uid] ?? DeliveryMode.home;
  }

  void setProductDeliveryMode(String uid, DeliveryMode mode) {
    productDeliveryMode[uid] = mode;
    if (mode == DeliveryMode.home) productPickupId.remove(uid);
    refresh();
  }

  bool hasPickupForProduct(String uid) {
    if (pickupPoints.isEmpty) return false;
    final item = items.firstWhereOrNull((e) => e.uid == uid);
    if (item == null) return false;
    final productId = item.id;
    final sellerId = int.tryParse(item.seller) ?? 0;
    return pickupPoints.any((pp) => 
      pp.productIds.contains(productId) || 
      (pp.sellerId == sellerId && pp.productIds.isEmpty)
    );
  }

  int? getProductPickupId(String uid) => productPickupId[uid];

  void setProductPickupId(String uid, int? id) {
    productPickupId[uid] = id;
    refresh();
  }

  final RxBool isLoadingOptions = false.obs;
  final RxString optionsError = ''.obs;
  final Map<String, ShippingOptionsForProduct> optionsByUid = {};
  final RxSet<String> notAvailableUids = <String>{}.obs;
  final RxMap<String, int> selectedMethodByUid = <String, int>{}.obs;
  final RxMap<String, double> _taxByUid = <String, double>{}.obs;
  final Map<int, String> _uidByProductId = {};

  final RxList<ActivePaymentMethod> activePaymentMethods = <ActivePaymentMethod>[].obs;
  final RxBool isLoadingPayments = false.obs;
  final RxString paymentError = ''.obs;
  final RxnInt selectedPaymentMethodId = RxnInt();

  final RxBool isLoadingWallet = false.obs;
  final RxString walletError = ''.obs;
  final RxnDouble walletAvailable = RxnDouble();
  final RxBool isWalletPaying = false.obs;

  final noteCtrl = TextEditingController();
  final _fmt = NumberFormat.decimalPattern();
  String get _symbol {
    try { return (Get.find<CurrencyService>().current?.symbol ?? '\$').trim(); }
    catch (_) { return '\$'; }
  }

  String money(num v) => '$_symbol ${_fmt.format(v)}';

  void _showSnackbar(String title, String message) {
    final c = Get.context; if (c == null) return;
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)), Text(message, style: const TextStyle(color: AppColors.whiteColor))])));
  }

  List<String> formattedAddressLines(CustomerAddress a) {
    final lastLine = [if (a.city?.name != null && a.city!.name.isNotEmpty) a.city!.name, if (a.state?.name != null && a.state!.name.isNotEmpty) a.state!.name, if (a.country?.name != null && a.country!.name.isNotEmpty) a.country!.name].join(', ');
    return ['${'Name'.tr}: ${a.name}', if (a.address.isNotEmpty) '${'Address'.tr}: ${a.address}', if (a.phone.isNotEmpty) '${'Phone'.tr}: ${a.phone}', if (a.postalCode.isNotEmpty) '${'Postal Code'.tr}: ${a.postalCode}', if (lastLine.trim().isNotEmpty) lastLine];
  }

  bool get _hasOptionsOrNA => optionsByUid.isNotEmpty || notAvailableUids.isNotEmpty;
  Iterable<CartListItem> get _countedItems => _hasOptionsOrNA ? items.where((e) => !notAvailableUids.contains(e.uid)) : items;
  double get subTotal => _countedItems.fold(0.0, (p, e) => p + e.lineTotal);

  double get shippingFee {
    double sum = 0.0;
    for (final it in _countedItems) {
      if (getProductDeliveryMode(it.uid) == DeliveryMode.pickup) continue;
      final op = optionsByUid[it.uid]; if (op == null) continue;
      if (op.methods.isEmpty) { if (op.defaultOption != null) sum += op.defaultOption!.cost; continue; }
      final sid = selectedMethodByUid[it.uid] ?? op.defaultOption?.id ?? (op.methods.isNotEmpty ? op.methods.first.id : null);
      if (sid == null) continue;
      sum += op.methods.firstWhereOrNull((x) => x.id == sid)?.cost ?? op.defaultOption?.cost ?? 0.0;
    }
    return sum;
  }

  double get taxTotal { double s = 0.0; for (final it in _countedItems) { final t = _taxByUid[it.uid] ?? 0.0; if (t.isFinite) s += t; } return s; }
  double get payableTotal => (subTotal + taxTotal + shippingFee).clamp(0.0, double.infinity);
  int get totalQty => _countedItems.fold(0, (p, e) => p + e.quantity);
  bool get canPayWithWallet => (walletAvailable.value ?? 0.0) >= payableTotal;
  String get walletBalanceText => money(walletAvailable.value ?? 0.0);
  String variantLine(CartListItem it) { final v = (it.variant ?? '').trim(); return v.isEmpty ? '' : v; }

  String addressLabel(CustomerAddress a) {
    final p = <String>[a.name, '• ${a.phone}', if (a.address.isNotEmpty) a.address, if (a.city?.name != null && a.city!.name.isNotEmpty) a.city!.name, if (a.postalCode.isNotEmpty) a.postalCode];
    return p.where((e) => e.trim().isNotEmpty).join(', ');
  }

  CustomerAddress? get selectedShipping => activeAddresses.firstWhereOrNull((a) => a.id == selectedShippingId.value);
  CustomerAddress? get selectedBilling => activeAddresses.firstWhereOrNull((a) => a.id == selectedBillingId.value);
  bool hasOptionsFor(String uid) => optionsByUid[uid]?.methods.isNotEmpty == true;

  ShippingMethod? selectedMethodFor(String uid) {
    final op = optionsByUid[uid]; if (op == null) return null;
    if (op.methods.isEmpty) return op.defaultOption;
    final sid = selectedMethodByUid[uid] ?? op.defaultOption?.id ?? (op.methods.isNotEmpty ? op.methods.first.id : null);
    if (sid == null) return null;
    return op.methods.firstWhereOrNull((x) => x.id == sid) ?? op.defaultOption;
  }

  @override
  void onInit() { super.onInit(); _ingestIncomingItems(); isScreenLoading.value = true; _loadAddresses(); }

  void _ingestIncomingItems() {
    final arg = Get.arguments?['items']; if (arg == null) return;
    if (arg is List<CartListItem>) items.assignAll(arg);
    else if (arg is List<CartApiItem>) items.assignAll(arg.map(_fromApiModel).toList());
    else if (arg is List) { final list = <CartListItem>[]; for (final e in arg) { if (e is CartListItem) list.add(e); else if (e is CartApiItem) list.add(_fromApiModel(e)); else { try { list.add(CartListItem.fromJson(Map<String, dynamic>.from(e as Map))); } catch (_) {} } } if (list.isNotEmpty) items.assignAll(list); }
    _uidByProductId..clear()..addAll({for (final it in items) it.id: it.uid});
    final coupons = Get.arguments?['coupons']; if (coupons is List) appliedCoupons.assignAll(coupons.cast<Map<String, dynamic>>());
  }

  CartListItem _fromApiModel(CartApiItem a) => CartListItem(uid: a.uid, id: a.id, name: a.name, permalink: a.permalink, image: a.image, variant: a.variant, variantCode: a.variantCode, quantity: a.quantity, unitPrice: a.unitPrice.toString(), oldPrice: a.oldPrice.toString(), minItem: a.minItem, maxItem: a.maxItem, attachment: a.attachment, seller: a.seller.toString(), shopName: a.shopName, shopSlug: a.shopSlug, isAvailable: a.isAvailable, isSelected: a.isSelected);

  Future<void> _loadAddresses() async {
    try {
      final list = await _addressRepo.getAllCustomerAddresses(); if (Get.context == null) return;
      allAddresses.assignAll(list);
      final sd = activeAddresses.firstWhereOrNull((a) => a.defaultShipping == 2);
      final bd = activeAddresses.firstWhereOrNull((a) => a.defaultBilling == 2);
      if (sd != null) selectedShippingId.value = sd.id;
      if (bd != null) selectedBillingId.value = bd.id;
      if (selectedShippingId.value == null && activeAddresses.isNotEmpty) selectedShippingId.value = activeAddresses.first.id;
      if (billingMode.value == BillingMode.sameAsShipping) selectedBillingId.value = selectedShippingId.value;
      else { if (selectedBillingId.value == null && activeAddresses.isNotEmpty) selectedBillingId.value = activeAddresses.first.id; }
      await _loadPickupPoints(); await _refreshShippingOptions(); await _refreshActivePaymentMethods(); await _loadWalletSummary();
    } catch (e) { if (Get.context == null) return; _showSnackbar('Address'.tr, 'Failed to load addresses'.tr); } finally { isScreenLoading.value = false; }
  }

  Future<void> _loadPickupPoints() async {
    try {
      final map = await _checkoutRepo.fetchActivePickupPoints(productsJsonString: _productsJsonString());
      if (Get.context == null) return;
      final resp = PickupPointResponse.fromJson(map);
      if (resp.success) pickupPoints.assignAll(resp.data);
    } catch (_) {}
  }

  Future<void> placeOrder() async { await _submitOrder(useWallet: false); }
  Future<void> payWithWallet() async { if (isWalletPaying.value) return; isWalletPaying.value = true; try { await _submitOrder(useWallet: true); } finally { isWalletPaying.value = false; } }

  Future<void> _submitOrder({bool useWallet = false}) async {
    if (_countedItems.isEmpty) { _showSnackbar('Checkout'.tr, 'No items to checkout'.tr); return; }
    if (selectedShipping == null) { _showSnackbar('Address'.tr, 'Please select a shipping address'.tr); return; }
    if (selectedBilling == null) { _showSnackbar('Address'.tr, 'Please select a billing address'.tr); return; }
    for (final it in _countedItems) {
      if (getProductDeliveryMode(it.uid) == DeliveryMode.pickup) {
        final ppId = getProductPickupId(it.uid);
        if (ppId == null || ppId == 0) {
          _showSnackbar('Pickup'.tr, 'Please select a pickup point for all pickup items'.tr);
          return;
        }
      }
    }
    if (useWallet && !canPayWithWallet) { _showSnackbar('Wallet'.tr, 'Insufficient wallet balance'.tr); return; }
    late int wp; int? pid;
    if (useWallet) { wp = 1; pid = 2; }
    else { wp = 2; pid = selectedPaymentMethodId.value; if (pid == null) { _showSnackbar('Payment'.tr, 'Please choose a payment method'.tr); return; } if (!_validateBankFields()) return; }
    final body = <String, dynamic>{'payment_id': pid, 'note': noteCtrl.text.trim(), 'wallet_payment': wp, 'origin': 'app', 'billing_address': (selectedBillingId.value ?? 0).toString(), 'shipping_address': (selectedShippingId.value ?? 0).toString(), 'products': _productsJsonForCheckout(), 'coupon_discounts': jsonEncode(appliedCoupons)};
    if (items.any((it) => getProductDeliveryMode(it.uid) == DeliveryMode.pickup)) {
      int? ppId;
      for (final id in productPickupId.values) {
        if (id != null) { ppId = id; break; }
      }
      if (ppId != null) body['pickup_point'] = ppId.toString();
    }
    if (!useWallet && isBankPaymentSelected) { body['bank_name'] = bankNameCtrl.text.trim(); body['branch_name'] = bankBranchCtrl.text.trim(); body['account_number'] = bankAccountNumberCtrl.text.trim(); body['account_name'] = bankAccountNameCtrl.text.trim(); body['transaction_number'] = bankTransactionIdCtrl.text.trim(); final path = bankReceiptImagePath.value; if (path != null && path.isNotEmpty) body['receipt'] = path; }
    isScreenLoading.value = true;
    try { final resp = await _checkoutRepo.customerCheckoutOrderCreate(body: body); if (Get.context == null) return; await _handleOrderResponse(resp); }
    catch (e) { if (Get.context == null) return; String msg = 'Something went wrong'; if (e is ApiHttpException) { try { final b = jsonDecode(e.body); if (b is Map && b['message'] != null) msg = b['message'].toString(); } catch (_) {} } _showSnackbar('Checkout'.tr, msg); }
    finally { isScreenLoading.value = false; }
  }

  String _productsJsonString() => jsonEncode(items.map((e) => e.toApiModel().toJson()).toList());

  String _productsJsonForCheckout() {
    final payload = <Map<String, dynamic>>[];
    for (final it in _countedItems) {
      final method = selectedMethodFor(it.uid); final tax = _taxByUid[it.uid] ?? 0.0;
      final uidVal = int.tryParse(it.uid) ?? it.uid;
      final unitPrice = double.tryParse(it.unitPrice.toString()) ?? 0.0;
      final oldPrice = double.tryParse(it.oldPrice.toString()) ?? unitPrice;
      final attachmentId = _extractAttachmentFileId(it.attachment);
      final mode = getProductDeliveryMode(it.uid);
      final pickupId = getProductPickupId(it.uid);
      payload.add({
        'uid': uidVal, 'tax': tax, 'product_id': it.id, 'quantity': it.quantity,
        'unitPrice': unitPrice, 'oldPrice': oldPrice, 'variant_code': it.variantCode,
        'variant': it.variant, 'image': it.image,
        'shipping_cost': mode == DeliveryMode.pickup ? 0.0 : (method?.cost ?? 0.0),
        'shipping_rate_id': mode == DeliveryMode.pickup ? 0 : (method?.id ?? 0),
        'attatchment': attachmentId,
        'delivery_mode': mode == DeliveryMode.pickup ? 'pickup' : 'home',
        'pickup_point_id': pickupId ?? 0,
      });
    }
    return jsonEncode(payload);
  }

  Future<void> _refreshShippingOptions() async {
    final ship = selectedShipping; if (ship == null || items.isEmpty) { _clearOptionsState(); return; }
    try {
      isLoadingOptions.value = true; optionsError.value = '';
      final map = await _checkoutRepo.fetchShippingOptions(location: ship.city?.id ?? 0, postCode: ship.postalCode.isNotEmpty ? ship.postalCode : null, shippingType: 'home_delivery', productsJsonString: _productsJsonString());
      if (Get.context == null) return;
      final parsed = ShippingOptionsResponse.fromJson(map); if (parsed.success != true) throw Exception('server returned success=false');
      optionsByUid.clear(); notAvailableUids.clear(); selectedMethodByUid.clear(); _taxByUid.clear();
      for (final nap in parsed.notAvailableProducts) { final uid = nap['uid']?.toString(); if (uid != null && uid.isNotEmpty) notAvailableUids.add(uid); else { final id = (nap['id'] is num) ? (nap['id'] as num).toInt() : int.tryParse('${nap['id']}') ?? -1; final hit = items.firstWhereOrNull((i) => i.id == id); if (hit != null) notAvailableUids.add(hit.uid); } }
      for (final op in parsed.options) { String uid = op.productUid; if (uid.isEmpty || !items.any((i) => i.uid == uid)) { final fUid = _uidByProductId[op.productId]; if (fUid != null) uid = fUid; } if (uid.isEmpty || !items.any((i) => i.uid == uid)) continue; optionsByUid[uid] = op; _taxByUid[uid] = op.tax; final def = op.defaultOption ?? (op.methods.isNotEmpty ? op.methods.first : null); if (def != null) selectedMethodByUid[uid] = def.id; }
    } catch (e) { optionsError.value = 'Failed to get shipping options'.tr; _clearOptionsState(); } finally { isLoadingOptions.value = false; }
  }

  Future<void> _refreshActivePaymentMethods() async {
    try { isLoadingPayments.value = true; paymentError.value = ''; activePaymentMethods.clear(); selectedPaymentMethodId.value = null; final ship = selectedShipping; final map = await _checkoutRepo.fetchActivePaymentMethods(city: (ship?.city?.id ?? 0).toString(), pickupPoint: '', productsJsonString: _productsJsonString()); if (Get.context == null) return; final resp = ActivePaymentMethodsResponse.fromJson(map); if (!resp.success) throw Exception('success=false'); activePaymentMethods.assignAll(resp.data); } catch (e) { paymentError.value = 'Failed to load payment methods'.tr; } finally { isLoadingPayments.value = false; }
  }

  Future<void> _loadWalletSummary() async { try { isLoadingWallet.value = true; walletError.value = ''; final s = await _walletRepo.fetchWalletSummary(); if (Get.context == null) return; walletAvailable.value = s.totalAvailable.toDouble(); } catch (e) { walletError.value = 'Failed to load wallet balance'.tr; walletAvailable.value = null; } finally { isLoadingWallet.value = false; } }

  void _clearOptionsState() { optionsByUid.clear(); notAvailableUids.clear(); selectedMethodByUid.clear(); _taxByUid.clear(); }

  Future<void> setShipping(int? id) async { selectedShippingId.value = id; if (billingMode.value == BillingMode.sameAsShipping) selectedBillingId.value = id; isScreenLoading.value = true; await _refreshShippingOptions(); await _refreshActivePaymentMethods(); await _loadWalletSummary(); isScreenLoading.value = false; }
  void setBilling(int? id) => selectedBillingId.value = id;
  Future<void> setBillingMode(BillingMode mode) async { billingMode.value = mode; if (mode == BillingMode.sameAsShipping) selectedBillingId.value = selectedShippingId.value; else { if (selectedBillingId.value == null && activeAddresses.isNotEmpty) selectedBillingId.value = activeAddresses.first.id; } }
  Future<void> addNewAddress(BuildContext context) async { final r = await Get.toNamed(AppRoutes.addAddressView); if (r == true) { isScreenLoading.value = true; await _loadAddresses(); if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Address added successfully'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating)); } }
  bool get isBankPaymentSelected { final id = selectedPaymentMethodId.value; if (id == null) return false; final m = activePaymentMethods.firstWhereOrNull((e) => e.id == id); if (m == null) return false; return m.name.toLowerCase().contains('bank') || (m.instruction ?? '').toLowerCase().contains('bank'); }

  void selectShippingFor(String uid) {
    final op = optionsByUid[uid]; if (op == null) return;
    final cur = selectedMethodByUid[uid]; final defId = op.defaultOption?.id;
    final methods = op.methods.isEmpty && op.defaultOption != null ? [op.defaultOption!] : op.methods;
    if (methods.isEmpty) return; final ctx = Get.context; if (ctx == null) return;
    showDialog(context: ctx, builder: (dc) => AlertDialog(
      title: Text('Select shipping option'.tr),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: methods.length, itemBuilder: (_, i) {
        final m = methods[i];
        return ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(cur == m.id ? Icons.radio_button_checked : Icons.radio_button_off), title: m.title.trim().isNotEmpty ? Text(m.title) : null, subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (m.cost.isFinite && m.cost >= 0) Text('${'Cost'.tr}: ${formatCurrency(m.cost)}'), if (m.shippingTime.trim().isNotEmpty) Text('${'Time'.tr}: ${m.shippingTime}'), if (defId == m.id) Text('default'.tr, style: const TextStyle(fontWeight: FontWeight.w700))]), onTap: () { selectedMethodByUid[uid] = m.id; Navigator.of(dc).pop(); });
      })),
      actions: [TextButton(onPressed: () => Navigator.of(dc).pop(), child: Text('close'.tr))],
    ));
  }

  void removeItemByUid(String uid) { final r = items.firstWhereOrNull((e) => e.uid == uid); items.removeWhere((e) => e.uid == uid); notAvailableUids.remove(uid); selectedMethodByUid.remove(uid); optionsByUid.remove(uid); _taxByUid.remove(uid); productDeliveryMode.remove(uid); productPickupId.remove(uid); if (r != null) _uidByProductId.remove(r.id); }

  Future<void> _handleOrderResponse(Map<String, dynamic> resp) async {
    final success = resp['success'] == true || resp['status']?.toString().toLowerCase() == 'success';
    if (!success) { _showSnackbar('Checkout'.tr, resp['message']?.toString() ?? resp['error']?.toString() ?? 'Server error'); return; }
    final orderId = _extractOrderId(resp); final responseUrl = _extractRedirectUrl(resp);
    if (responseUrl.isEmpty) { await _afterOrderSuccess(orderId); return; }
    if (Get.isRegistered<CustomerDashboardController>()) Get.find<CustomerDashboardController>().fetchDashboard();
    _showSnackbar('Redirecting'.tr, 'Redirecting to payment page'.tr);
    final result = await Get.to<PaymentPageResult?>(() => OrderPayWebView(initialUrl: responseUrl, successUrlContains: const ['payment/success','payment-success','status=success','payment_status=success','redirect_status=succeeded','succeeded','success=true','paid'], cancelUrlContains: const ['payment/cancel','payment-cancel','status=cancel','status=cancelled','payment_status=cancelled','canceled','cancelled'], failedUrlContains: const ['payment/fail','payment/failed','payment-error','status=failed','status=error','payment_status=failed'], pendingUrlContains: const ['pending','processing','awaiting']));
    if (Get.context == null) return;
    switch (result?.status) { case PaymentPageResultStatus.success: await _afterOrderSuccess(orderId); default: _showSnackbar('Payment'.tr, 'Payment was not completed'.tr); }
  }

  Future<void> _afterOrderSuccess(int? orderId) async { if (orderId == null || orderId <= 0) { _showSnackbar('Orders'.tr, 'Could not find order id'.tr); return; } _clearAfterOrder(); if (Get.isRegistered<CartController>()) Get.find<CartController>().clearAfterOrder(); _loadWalletSummary(); if (Get.isRegistered<CustomerDashboardController>()) Get.find<CustomerDashboardController>().fetchDashboard(); _showSnackbar('Order placed successfully'.tr, 'Thank you'.tr); _goToOrderSummary(orderId); }
  void _goToOrderSummary(int orderId) => Get.offNamed(AppRoutes.orderSummaryView, arguments: orderId);
  String _extractRedirectUrl(Map<String, dynamic> resp) { final u = (resp['redirect_url'] ?? resp['response_url'] ?? '').toString().trim(); return u.isEmpty || u.toLowerCase() == 'none' || u.toLowerCase() == 'null' ? '' : u; }
  int? _extractOrderId(Map<String, dynamic> resp) { final d = resp['order_id']; if (d is int) return d; if (d is String) { final p = int.tryParse(d); if (p != null) return p; } try { final dt = resp['data']; if (dt is Map && dt['order_id'] != null) { final v = dt['order_id']; if (v is int) return v; if (v is String) return int.tryParse(v); } } catch (_) {} return null; }
  void _clearAfterOrder() { noteCtrl.clear(); resetBankForm(); selectedPaymentMethodId.value = null; _clearOptionsState(); productDeliveryMode.clear(); productPickupId.clear(); if (Get.isRegistered<CartController>()) Get.find<CartController>().clearAfterOrder(); }
  Future<void> refreshAll() async { isScreenLoading.value = true; await _loadAddresses(); }

  final TextEditingController bankAccountNameCtrl = TextEditingController();
  final TextEditingController bankAccountNumberCtrl = TextEditingController();
  final TextEditingController bankNameCtrl = TextEditingController();
  final TextEditingController bankBranchCtrl = TextEditingController();
  final TextEditingController bankTransactionIdCtrl = TextEditingController();
  final RxnString bankReceiptImagePath = RxnString();

  bool _validateBankFields() { if (!isBankPaymentSelected) return true; final m = <String>[]; if (bankNameCtrl.text.trim().isEmpty) m.add('Bank name'); if (bankBranchCtrl.text.trim().isEmpty) m.add('Branch name'); if (bankAccountNumberCtrl.text.trim().isEmpty) m.add('Account number'); if (bankAccountNameCtrl.text.trim().isEmpty) m.add('Account name'); if (bankTransactionIdCtrl.text.trim().isEmpty) m.add('Transaction number'); if ((bankReceiptImagePath.value ?? '').isEmpty) m.add('Receipt'); if (m.isNotEmpty) { _showSnackbar('Bank Payment'.tr, '${m.join(', ')} required'); return false; } return true; }
  void resetBankForm() { bankAccountNameCtrl.clear(); bankAccountNumberCtrl.clear(); bankNameCtrl.clear(); bankBranchCtrl.clear(); bankTransactionIdCtrl.clear(); bankReceiptImagePath.value = null; }

  @override
  void onClose() { noteCtrl.dispose(); bankAccountNameCtrl.dispose(); bankAccountNumberCtrl.dispose(); bankNameCtrl.dispose(); bankBranchCtrl.dispose(); bankTransactionIdCtrl.dispose(); super.onClose(); }
}

int? _extractAttachmentFileId(dynamic attachment) {
  if (attachment == null) return null;
  if (attachment is Map) { final v = attachment['file_id']; if (v is int) return v; if (v is String) return int.tryParse(v); }
  if (attachment is String) { final s = attachment.trim(); if (s.isEmpty || s == 'null') return null; try { final d = jsonDecode(s); if (d is Map) { final v = d['file_id']; if (v is int) return v; if (v is String) return int.tryParse(v); } if (d is int) return d; } catch (_) { return int.tryParse(s); } }
  return null;
}
