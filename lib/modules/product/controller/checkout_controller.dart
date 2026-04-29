import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/routes/app_routes.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../account/model/address_model.dart';
import '../../account/widgets/order_pay_web_view.dart';
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

  final Rx<DeliveryMode> deliveryMode = DeliveryMode.home.obs;
  bool get isPickupSelected => deliveryMode.value == DeliveryMode.pickup;
  final Rx<BillingMode> billingMode = BillingMode.sameAsShipping.obs;

  final RxList<CustomerAddress> allAddresses = <CustomerAddress>[].obs;
  List<CustomerAddress> get activeAddresses => allAddresses.where((a) {
    final s = a.status.trim().toLowerCase();
    return s == 'active' || s == '1';
  }).toList();
  final RxnInt selectedShippingId = RxnInt();
  final RxnInt selectedBillingId = RxnInt();

  final RxList<PickupPoint> pickupPoints = <PickupPoint>[].obs;
  final RxnInt selectedPickupId = RxnInt();

  final RxBool isLoadingOptions = false.obs;
  final RxString optionsError = ''.obs;

  final Map<String, ShippingOptionsForProduct> optionsByUid = {};
  final RxSet<String> notAvailableUids = <String>{}.obs;
  final RxMap<String, int> selectedMethodByUid = <String, int>{}.obs;

  final RxMap<String, double> _taxByUid = <String, double>{}.obs;

  final Map<int, String> _uidByProductId = {};

  final RxList<ActivePaymentMethod> activePaymentMethods =
      <ActivePaymentMethod>[].obs;
  final RxBool isLoadingPayments = false.obs;
  final RxString paymentError = ''.obs;
  final RxnInt selectedPaymentMethodId = RxnInt();
  final RxBool isPaymentDropdownOpen = false.obs;

  final RxBool isLoadingWallet = false.obs;
  final RxString walletError = ''.obs;
  final RxnDouble walletAvailable = RxnDouble();
  final RxBool isWalletPaying = false.obs;

  final noteCtrl = TextEditingController();
  final _fmt = NumberFormat.decimalPattern();
  String get _symbol {
    try {
      final svc = Get.find<CurrencyService>();
      return (svc.current?.symbol ?? '\$').trim();
    } catch (_) {
      return '\$';
    }
  }

  String money(num v) => '$_symbol ${_fmt.format(v)}';

  void _showSnackbar(String title, String message) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
              ),
            ),
            Text(message, style: const TextStyle(color: AppColors.whiteColor)),
          ],
        ),
      ),
    );
  }

  List<String> formattedAddressLines(CustomerAddress a) {
    final lastLine = [
      if (a.city?.name != null && a.city!.name.isNotEmpty) a.city!.name,
      if (a.state?.name != null && a.state!.name.isNotEmpty) a.state!.name,
      if (a.country?.name != null && a.country!.name.isNotEmpty)
        a.country!.name,
    ].join(', ');

    return [
      'Name: ${a.name}',
      if (a.address.isNotEmpty) 'Address: ${a.address}',
      if (a.phone.isNotEmpty) 'Phone: ${a.phone}',
      if (a.postalCode.isNotEmpty) 'Postal Code: ${a.postalCode}',
      if (lastLine.trim().isNotEmpty) lastLine,
    ];
  }

  bool get _hasOptionsOrNA =>
      optionsByUid.isNotEmpty || notAvailableUids.isNotEmpty;

  Iterable<CartListItem> get _countedItems => _hasOptionsOrNA
      ? items.where((e) => !notAvailableUids.contains(e.uid))
      : items;

  double get subTotal => _countedItems.fold(0.0, (p, e) => p + e.lineTotal);

  double get shippingFee {
    double sum = 0.0;
    for (final it in _countedItems) {
      final uid = it.uid;
      final op = optionsByUid[uid];
      if (op == null) continue;

      if (op.methods.isEmpty) {
        final def = op.defaultOption;
        if (def != null) sum += def.cost;
        continue;
      }

      final selectedId =
          selectedMethodByUid[uid] ??
          op.defaultOption?.id ??
          (op.methods.isNotEmpty ? op.methods.first.id : null);

      if (selectedId == null) continue;

      final m = op.methods.firstWhereOrNull((x) => x.id == selectedId);
      if (m == null) {
        final def = op.defaultOption;
        if (def != null) sum += def.cost;
        continue;
      }
      sum += m.cost;
    }
    return sum;
  }

  double get taxTotal {
    double sum = 0.0;
    for (final it in _countedItems) {
      final t = _taxByUid[it.uid] ?? 0.0;
      if (t.isFinite) sum += t;
    }
    return sum;
  }

  double get payableTotal =>
      (subTotal + taxTotal + shippingFee).clamp(0.0, double.infinity);

  int get totalQty => _countedItems.fold(0, (p, e) => p + e.quantity);

  bool get canPayWithWallet => (walletAvailable.value ?? 0.0) >= payableTotal;

  String get walletBalanceText => money(walletAvailable.value ?? 0.0);

  String variantLine(CartListItem it) {
    final v = (it.variant ?? '').trim();
    return v.isEmpty ? '' : v;
  }

  String addressLabel(CustomerAddress a) {
    final parts = <String>[
      a.name,
      '• ${a.phone}',
      if (a.address.isNotEmpty) a.address,
      if (a.city?.name != null && a.city!.name.isNotEmpty) a.city!.name,
      if (a.postalCode.isNotEmpty) a.postalCode,
    ];
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }

  String? get destinationLabel {
    final s = selectedShipping;
    if (s == null) return null;
    final parts = <String?>[s.city?.name, s.state?.name, s.country?.name]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  CustomerAddress? get selectedShipping =>
      activeAddresses.firstWhereOrNull((a) => a.id == selectedShippingId.value);
  CustomerAddress? get selectedBilling =>
      activeAddresses.firstWhereOrNull((a) => a.id == selectedBillingId.value);

  bool hasOptionsFor(String uid) =>
      optionsByUid[uid]?.methods.isNotEmpty == true;

  ShippingMethod? selectedMethodFor(String uid) {
    final op = optionsByUid[uid];
    if (op == null) return null;
    if (op.methods.isEmpty) return op.defaultOption;

    final selectedId =
        selectedMethodByUid[uid] ??
        op.defaultOption?.id ??
        (op.methods.isNotEmpty ? op.methods.first.id : null);

    if (selectedId == null) return null;
    return op.methods.firstWhereOrNull((x) => x.id == selectedId) ??
        op.defaultOption;
  }

  @override
  void onInit() {
    super.onInit();
    _ingestIncomingItems();
    isScreenLoading.value = true;
    _loadAddresses();
  }

  void _ingestIncomingItems() {
    final arg = Get.arguments?['items'];
    if (arg == null) return;

    if (arg is List<CartListItem>) {
      items.assignAll(arg);
    } else if (arg is List<CartApiItem>) {
      final converted = arg.map(_fromApiModel).toList();
      items.assignAll(converted);
    } else if (arg is List) {
      final list = <CartListItem>[];
      for (final e in arg) {
        if (e is CartListItem) {
          list.add(e);
        } else if (e is CartApiItem) {
          list.add(_fromApiModel(e));
        } else {
          try {
            list.add(
              CartListItem.fromJson(Map<String, dynamic>.from(e as Map)),
            );
          } catch (_) {}
        }
      }
      if (list.isNotEmpty) items.assignAll(list);
    }

    _uidByProductId
      ..clear()
      ..addAll({for (final it in items) it.id: it.uid});
  }

  CartListItem _fromApiModel(CartApiItem a) {
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
      isAvailable: a.isAvailable,
      isSelected: a.isSelected,
    );
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await _addressRepo.getAllCustomerAddresses();

      if (Get.context == null) return;

      allAddresses.assignAll(list);

      final shippingDefault = activeAddresses.firstWhereOrNull(
        (a) => a.defaultShipping == 2,
      );
      final billingDefault = activeAddresses.firstWhereOrNull(
        (a) => a.defaultBilling == 2,
      );

      if (shippingDefault != null) {
        selectedShippingId.value = shippingDefault.id;
      }
      if (billingDefault != null) selectedBillingId.value = billingDefault.id;

      if (selectedShippingId.value == null && activeAddresses.isNotEmpty) {
        selectedShippingId.value = activeAddresses.first.id;
      }

      if (billingMode.value == BillingMode.sameAsShipping) {
        selectedBillingId.value = selectedShippingId.value;
      } else {
        if (selectedBillingId.value == null && activeAddresses.isNotEmpty) {
          selectedBillingId.value = activeAddresses.first.id;
        }
      }

      await _loadPickupPoints();
      await _refreshShippingOptions();
      await _refreshActivePaymentMethods();
      await _loadWalletSummary();
    } catch (e) {
      if (Get.context == null) return;
      _showSnackbar('Address'.tr, 'Failed to load addresses'.tr);
    } finally {
      isScreenLoading.value = false;
    }
  }

  Future<void> _loadPickupPoints() async {
    try {
      final map = await _checkoutRepo.fetchActivePickupPoints();

      if (Get.context == null) return;

      final resp = PickupPointResponse.fromJson(map);
      if (resp.success) {
        pickupPoints.assignAll(resp.data);
        if (deliveryMode.value == DeliveryMode.pickup &&
            selectedPickupId.value == null &&
            pickupPoints.isNotEmpty) {
          selectedPickupId.value = pickupPoints.first.id;
        }
      }
    } catch (_) {}
  }

  Future<void> placeOrder() async {
    await _submitOrder(useWallet: false);
  }

  Future<void> payWithWallet() async {
    if (isWalletPaying.value) return;

    isWalletPaying.value = true;
    try {
      await _submitOrder(useWallet: true);
    } finally {
      isWalletPaying.value = false;
    }
  }

  Future<void> _submitOrder({bool useWallet = false}) async {
    if (_countedItems.isEmpty) {
      _showSnackbar('Checkout'.tr, 'No items to checkout'.tr);
      return;
    }

    final isHome = deliveryMode.value == DeliveryMode.home;

    if (isHome && selectedShipping == null) {
      _showSnackbar('Address'.tr, 'Please select a shipping address'.tr);
      return;
    }
    if (selectedBilling == null) {
      _showSnackbar('Address'.tr, 'Please select a billing address'.tr);
      return;
    }

    if (useWallet && !canPayWithWallet) {
      _showSnackbar('Wallet'.tr, 'Insufficient wallet balance'.tr);
      return;
    }

    late int walletPayment;
    int? paymentId;

    if (useWallet) {
      walletPayment = 1;
      paymentId = 2;
    } else {
      walletPayment = 2;
      paymentId = selectedPaymentMethodId.value;

      if (paymentId == null) {
        _showSnackbar('Payment'.tr, 'Please choose a payment method'.tr);
        return;
      }

      if (!_validateBankFields()) return;
    }

    final note = noteCtrl.text.trim();

    final body = <String, dynamic>{
      'payment_id': paymentId,
      'note': note,
      'wallet_payment': walletPayment,
      'origin': 'app',
      'billing_address': (selectedBillingId.value ?? 0).toString(),
      'products': _productsJsonForCheckout(),
    };

    if (isHome) {
      body['shipping_address'] = (selectedShippingId.value ?? 0).toString();
    } else {
      body['pickup_point'] = (selectedPickupId.value ?? 0).toString();
    }

    if (!useWallet && isBankPaymentSelected) {
      body['bank_name'] = bankNameCtrl.text.trim();
      body['branch_name'] = bankBranchCtrl.text.trim();
      body['account_number'] = bankAccountNumberCtrl.text.trim();
      body['account_name'] = bankAccountNameCtrl.text.trim();
      body['transaction_number'] = bankTransactionIdCtrl.text.trim();

      final path = bankReceiptImagePath.value;
      if (path != null && path.isNotEmpty) {
        body['receipt'] = path;
      }
    }

    isScreenLoading.value = true;
    try {
      final resp = await _checkoutRepo.customerCheckoutOrderCreate(body: body);

      if (Get.context == null) return;

      await _handleOrderResponse(resp);
    } catch (e) {
      if (Get.context == null) return;
      _showSnackbar('Checkout'.tr, 'Failed to place order'.tr);
    } finally {
      isScreenLoading.value = false;
    }
  }

  String _productsJsonString() {
    final payload = items.map((e) => e.toApiModel().toJson()).toList();
    return jsonEncode(payload);
  }

  String _productsJsonForCheckout() {
    final payload = <Map<String, dynamic>>[];

    for (final it in _countedItems) {
      final method = selectedMethodFor(it.uid);
      final tax = _taxByUid[it.uid] ?? 0.0;

      final uidRaw = it.uid;
      final uidVal = int.tryParse(uidRaw) ?? uidRaw;

      final unitPrice = double.tryParse(it.unitPrice.toString()) ?? 0.0;
      final oldPrice = double.tryParse(it.oldPrice.toString()) ?? unitPrice;

      final attachmentId = _extractAttachmentFileId(it.attachment);

      final map = <String, dynamic>{
        'uid': uidVal,
        'tax': tax,
        'product_id': it.id,
        'quantity': it.quantity,
        'unitPrice': unitPrice,
        'oldPrice': oldPrice,
        'variant_code': it.variantCode,
        'variant': it.variant,
        'image': it.image,
        'shipping_cost': method?.cost ?? 0.0,
        'shipping_rate_id': method?.id ?? 0,
        'attatchment': attachmentId,
      };

      payload.add(map);
    }

    return jsonEncode(payload);
  }

  Future<void> _refreshShippingOptions() async {
    int location = 0;
    String? postCode;
    String shippingType;

    if (deliveryMode.value == DeliveryMode.home) {
      final ship = selectedShipping;
      if (ship == null || items.isEmpty) {
        _clearOptionsState();
        return;
      }
      location = ship.city?.id ?? 0;
      postCode = ship.postalCode.isNotEmpty ? ship.postalCode : null;
      shippingType = 'home_delivery';
    } else {
      if (selectedPickupId.value == null) {
        _clearOptionsState();
        return;
      }
      final pp = pickupPoints.firstWhereOrNull(
        (e) => e.id == selectedPickupId.value,
      );
      if (pp == null) {
        _clearOptionsState();
        return;
      }
      location = pp.zoneId;
      postCode = null;
      shippingType = "pickup_delivery";
    }

    try {
      isLoadingOptions.value = true;
      optionsError.value = '';

      final map = await _checkoutRepo.fetchShippingOptions(
        location: location,
        postCode: postCode,
        shippingType: shippingType,
        productsJsonString: _productsJsonString(),
      );

      if (Get.context == null) return;

      final parsed = ShippingOptionsResponse.fromJson(map);
      if (parsed.success != true) {
        throw Exception('server returned success=false');
      }

      optionsByUid.clear();
      notAvailableUids.clear();
      selectedMethodByUid.clear();
      _taxByUid.clear();

      for (final nap in parsed.notAvailableProducts) {
        final uid = nap['uid']?.toString();
        if (uid != null && uid.isNotEmpty) {
          notAvailableUids.add(uid);
        } else {
          final id = (nap['id'] is num)
              ? (nap['id'] as num).toInt()
              : int.tryParse('${nap['id']}') ?? -1;
          final hit = items.firstWhereOrNull((i) => i.id == id);
          if (hit != null) notAvailableUids.add(hit.uid);
        }
      }

      for (final op in parsed.options) {
        String uid = op.productUid;
        if (uid.isEmpty || !items.any((i) => i.uid == uid)) {
          final fallbackUid = _uidByProductId[op.productId];
          if (fallbackUid != null) uid = fallbackUid;
        }
        if (uid.isEmpty || !items.any((i) => i.uid == uid)) continue;

        optionsByUid[uid] = op;
        _taxByUid[uid] = op.tax;

        final def =
            op.defaultOption ??
            (op.methods.isNotEmpty ? op.methods.first : null);
        if (def != null) selectedMethodByUid[uid] = def.id;
      }
    } catch (e) {
      optionsError.value = 'Failed to get shipping options';
      _clearOptionsState();
    } finally {
      isLoadingOptions.value = false;
    }
  }

  Future<void> _refreshActivePaymentMethods() async {
    try {
      isLoadingPayments.value = true;
      paymentError.value = '';
      activePaymentMethods.clear();
      selectedPaymentMethodId.value = null;

      final String cityStr;
      final String pickupStr;

      if (deliveryMode.value == DeliveryMode.home) {
        final ship = selectedShipping;
        cityStr = (ship?.city?.id ?? 0).toString();
        pickupStr = '';
      } else {
        cityStr = '';
        pickupStr = (selectedPickupId.value ?? 0).toString();
      }

      final map = await _checkoutRepo.fetchActivePaymentMethods(
        city: cityStr,
        pickupPoint: pickupStr,
        productsJsonString: _productsJsonString(),
      );

      if (Get.context == null) return;

      final resp = ActivePaymentMethodsResponse.fromJson(map);
      if (!resp.success) {
        throw Exception('success=false');
      }
      activePaymentMethods.assignAll(resp.data);
    } catch (e) {
      paymentError.value = 'Failed to load payment methods';
    } finally {
      isLoadingPayments.value = false;
    }
  }

  Future<void> _loadWalletSummary() async {
    try {
      isLoadingWallet.value = true;
      walletError.value = '';
      final summary = await _walletRepo.fetchWalletSummary();

      if (Get.context == null) return;

      walletAvailable.value = summary.totalAvailable.toDouble();
    } catch (e) {
      walletError.value = 'Failed to load wallet balance';
      walletAvailable.value = null;
    } finally {
      isLoadingWallet.value = false;
    }
  }

  void _clearOptionsState() {
    optionsByUid.clear();
    notAvailableUids.clear();
    selectedMethodByUid.clear();
    _taxByUid.clear();
  }

  Future<void> setShipping(int? id) async {
    selectedShippingId.value = id;
    if (billingMode.value == BillingMode.sameAsShipping) {
      selectedBillingId.value = id;
    }
    isScreenLoading.value = true;
    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    await _loadWalletSummary();
    isScreenLoading.value = false;
  }

  void setBilling(int? id) => selectedBillingId.value = id;

  Future<void> setBillingMode(BillingMode mode) async {
    billingMode.value = mode;
    if (mode == BillingMode.sameAsShipping) {
      selectedBillingId.value = selectedShippingId.value;
    } else {
      if (selectedBillingId.value == null && activeAddresses.isNotEmpty) {
        selectedBillingId.value = activeAddresses.first.id;
      }
    }
  }

  Future<void> addNewAddress(BuildContext context) async {
    final result = await Get.toNamed(AppRoutes.addAddressView);

    if (result == true) {
      isScreenLoading.value = true;
      await _loadAddresses();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Address added successfully'.tr),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> setDeliveryMode(DeliveryMode m) async {
    if (deliveryMode.value == m) return;
    deliveryMode.value = m;

    isScreenLoading.value = true;

    if (m == DeliveryMode.pickup) {
      if (pickupPoints.isEmpty) {
        await _loadPickupPoints();
      }
      if (selectedPickupId.value == null && pickupPoints.isNotEmpty) {
        selectedPickupId.value = pickupPoints.first.id;
      }
    }

    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    await _loadWalletSummary();
    isScreenLoading.value = false;
  }

  Future<void> setPickupPoint(int? id) async {
    selectedPickupId.value = id;
    isScreenLoading.value = true;
    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    await _loadWalletSummary();
    isScreenLoading.value = false;
  }

  bool get isBankPaymentSelected {
    final id = selectedPaymentMethodId.value;
    if (id == null) return false;
    final m = activePaymentMethods.firstWhereOrNull((e) => e.id == id);
    if (m == null) return false;

    final name = m.name.toLowerCase();
    final instr = (m.instruction ?? '').toLowerCase();

    return name.contains('bank') || instr.contains('bank');
  }

  void selectShippingFor(String uid) {
    final op = optionsByUid[uid];
    if (op == null) return;

    final current = selectedMethodByUid[uid];
    final defaultId = op.defaultOption?.id;
    final dest = destinationLabel;

    final methods = op.methods.isEmpty && op.defaultOption != null
        ? [op.defaultOption!]
        : op.methods;

    if (methods.isEmpty) return;

    final context = Get.context;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select shipping option'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: methods.length,
            itemBuilder: (_, i) {
              final m = methods[i];
              final on = (current == m.id);
              final isDefault = (defaultId == m.id);

              final hasTitle = (m.title.trim().isNotEmpty);
              final hasCost = (m.cost.isFinite && m.cost >= 0);
              final hasTime = (m.shippingTime.trim().isNotEmpty);
              final hasFrom = ((m.shippingFrom ?? '').trim().isNotEmpty);
              final hasBy = ((m.by ?? '').trim().isNotEmpty);

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  on ? Icons.radio_button_checked : Icons.radio_button_off,
                ),
                title: hasTitle ? Text(m.title) : null,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCost)
                      Text('${'Cost'.tr}: ${formatCurrency(m.cost)}'),
                    if (hasTime) Text('${'Time'.tr}: ${m.shippingTime}'),
                    if (hasFrom && (dest != null && dest.isNotEmpty))
                      Text('${'from'.tr}: ${m.shippingFrom} → $dest'),
                    if (hasFrom && (dest == null || dest.isEmpty))
                      Text('${'from'.tr}: ${m.shippingFrom}'),
                    if (!hasFrom && (dest != null && dest.isNotEmpty))
                      Text('${'to'.tr}: $dest'),
                    if (hasBy) Text('By: ${m.by}'),
                    if (isDefault)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'default'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  selectedMethodByUid[uid] = m.id;
                  Navigator.of(dialogContext).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  void removeItemByUid(String uid) {
    final removed = items.firstWhereOrNull((e) => e.uid == uid);
    items.removeWhere((e) => e.uid == uid);
    notAvailableUids.remove(uid);
    selectedMethodByUid.remove(uid);
    optionsByUid.remove(uid);
    _taxByUid.remove(uid);

    if (removed != null) {
      _uidByProductId.remove(removed.id);
    }
  }

  Future<void> _handleOrderResponse(Map<String, dynamic> resp) async {
    final success =
        resp['success'] == true ||
        resp['status']?.toString().toLowerCase() == 'success';

    final msg =
        resp['message']?.toString() ??
        resp['error']?.toString() ??
        (success ? 'Order placed successfully'.tr : 'Something went wrong'.tr);

    if (!success) {
      _showSnackbar('Checkout'.tr, msg);
      return;
    }

    final orderId = _extractOrderId(resp);
    final responseUrl = _extractRedirectUrl(resp);

    if (responseUrl.isEmpty) {
      await _afterOrderSuccess(orderId);
      return;
    }

    _showSnackbar('Redirecting'.tr, 'Redirecting to payment page'.tr);

    final result = await Get.to<PaymentPageResult?>(
      () => OrderPayWebView(
        initialUrl: responseUrl,
        successUrlContains: const [
          'payment/success',
          'payment-success',
          'status=success',
          'payment_status=success',
          'redirect_status=succeeded',
          'succeeded',
          'success=true',
          'paid',
        ],
        cancelUrlContains: const [
          'payment/cancel',
          'payment-cancel',
          'status=cancel',
          'status=cancelled',
          'payment_status=cancelled',
          'canceled',
          'cancelled',
        ],
        failedUrlContains: const [
          'payment/fail',
          'payment/failed',
          'payment-error',
          'status=failed',
          'status=error',
          'payment_status=failed',
        ],
        pendingUrlContains: const ['pending', 'processing', 'awaiting'],
      ),
    );

    if (Get.context == null) return;

    switch (result?.status) {
      case PaymentPageResultStatus.success:
        await _afterOrderSuccess(orderId);
        return;

      case PaymentPageResultStatus.cancelled:
        _showSnackbar(
          'Payment'.tr,
          result?.message ?? 'Payment was cancelled'.tr,
        );
        return;

      case PaymentPageResultStatus.failed:
        _showSnackbar('Payment'.tr, result?.message ?? 'Payment failed'.tr);
        return;

      case PaymentPageResultStatus.timeout:
        _showSnackbar(
          'Payment'.tr,
          result?.message ?? 'Payment page timed out. Please try again.'.tr,
        );
        return;

      case PaymentPageResultStatus.error:
        _showSnackbar(
          'Payment'.tr,
          result?.message ??
              'Could not open payment page. Please try again.'.tr,
        );
        return;

      case null:
        _showSnackbar('Payment'.tr, 'Payment was not completed'.tr);
        return;
    }
  }

  Future<void> _afterOrderSuccess(int? orderId) async {
    if (orderId == null || orderId <= 0) {
      _showSnackbar('Orders'.tr, 'Could not find order id'.tr);
      return;
    }

    _clearAfterOrder();

    if (Get.isRegistered<CartController>()) {
      final cart = Get.find<CartController>();
      cart.clearAfterOrder();
    }

    _loadWalletSummary();

    _showSnackbar('Order placed successfully'.tr, 'Thank you'.tr);

    _goToOrderSummary(orderId);
  }

  void _goToOrderSummary(int orderId) {
    Get.offNamed(AppRoutes.orderSummaryView, arguments: orderId);
  }

  String _extractRedirectUrl(Map<String, dynamic> resp) {
    final newKey = resp['redirect_url'];
    final oldKey = resp['response_url'];

    final url = (newKey ?? oldKey ?? '').toString().trim();

    if (url.isEmpty) return '';
    final lower = url.toLowerCase();

    if (lower == 'none' || lower == 'null') return '';

    return url;
  }

  int? _extractOrderId(Map<String, dynamic> resp) {
    final direct = resp['order_id'];
    if (direct is int) return direct;
    if (direct is String) {
      final parsed = int.tryParse(direct);
      if (parsed != null) return parsed;
    }

    try {
      final data = resp['data'];
      if (data is Map && data['order_id'] != null) {
        final v = data['order_id'];
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
      }
    } catch (_) {}

    return null;
  }

  void _clearAfterOrder() {
    noteCtrl.clear();
    resetBankForm();
    selectedPaymentMethodId.value = null;
    _clearOptionsState();

    if (Get.isRegistered<CartController>()) {
      final cart = Get.find<CartController>();
      cart.clearAfterOrder();
    }
  }

  Future<void> refreshAll() async {
    isScreenLoading.value = true;
    await _loadAddresses();
  }

  final TextEditingController bankAccountNameCtrl = TextEditingController();
  final TextEditingController bankAccountNumberCtrl = TextEditingController();
  final TextEditingController bankNameCtrl = TextEditingController();
  final TextEditingController bankBranchCtrl = TextEditingController();
  final TextEditingController bankTransactionIdCtrl = TextEditingController();
  final RxnString bankReceiptImagePath = RxnString();

  bool _validateBankFields() {
    if (!isBankPaymentSelected) return true;

    final missing = <String>[];

    if (bankNameCtrl.text.trim().isEmpty) missing.add('Bank name');
    if (bankBranchCtrl.text.trim().isEmpty) missing.add('Branch name');
    if (bankAccountNumberCtrl.text.trim().isEmpty) {
      missing.add('Account number');
    }
    if (bankAccountNameCtrl.text.trim().isEmpty) missing.add('Account name');
    if (bankTransactionIdCtrl.text.trim().isEmpty) {
      missing.add('Transaction number');
    }
    if ((bankReceiptImagePath.value ?? '').isEmpty) missing.add('Receipt');

    if (missing.isNotEmpty) {
      _showSnackbar(
        'Bank Payment'.tr,
        '${missing.join(', ')} '
        '${missing.length == 1 ? 'is' : 'are'} ${'required for bank payment'.tr}.',
      );
      return false;
    }
    return true;
  }

  void resetBankForm() {
    bankAccountNameCtrl.clear();
    bankAccountNumberCtrl.clear();
    bankNameCtrl.clear();
    bankBranchCtrl.clear();
    bankTransactionIdCtrl.clear();
    bankReceiptImagePath.value = null;
  }

  @override
  void onClose() {
    noteCtrl.dispose();
    bankAccountNameCtrl.dispose();
    bankAccountNumberCtrl.dispose();
    bankNameCtrl.dispose();
    bankBranchCtrl.dispose();
    bankTransactionIdCtrl.dispose();
    super.onClose();
  }
}

int? _extractAttachmentFileId(dynamic attachment) {
  if (attachment == null) return null;

  if (attachment is Map) {
    final v = attachment['file_id'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
  }

  if (attachment is String) {
    final s = attachment.trim();
    if (s.isEmpty || s == 'null') return null;

    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        final v = decoded['file_id'];
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
      }
      if (decoded is int) return decoded;
    } catch (_) {
      return int.tryParse(s);
    }
  }

  return null;
}
