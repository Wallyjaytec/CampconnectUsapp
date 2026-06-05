import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/routes/app_routes.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../data/repositories/guest_checkout_repository.dart';
import '../../../data/repositories/site_settings_properties_repository.dart';
import '../../account/model/address_model.dart';
import '../../account/widgets/order_pay_web_view.dart';
import '../model/cart_item_model.dart';
import '../model/payment_method_model.dart';
import '../model/pickup_point_model.dart';
import '../model/shipping_options_model.dart';
import 'cart_controller.dart';

enum GuestDeliveryMode { home, pickup }

enum GuestBillingMode { sameAsShipping, different }

class GuestCheckoutController extends GetxController {
  GuestCheckoutController({
    ApiService? api,
    AddressRepository? addressRepo,
    CheckoutRepository? checkoutRepo,
    GuestCheckoutRepository? guestRepo,
    SiteSettingsPropertiesRepository? settingsRepo,
  }) : api = api ?? ApiService(),
       _addressRepo = addressRepo ?? AddressRepository(api ?? ApiService()),
       _checkoutRepo = checkoutRepo ?? CheckoutRepository(api ?? ApiService()),
       _guestRepo =
           guestRepo ?? GuestCheckoutRepository(api: api ?? ApiService()),
       _settingsRepo =
           settingsRepo ??
           SiteSettingsPropertiesRepository(api ?? ApiService());

  final ApiService api;
  final AddressRepository _addressRepo;
  final CheckoutRepository _checkoutRepo;
  final GuestCheckoutRepository _guestRepo;
  final SiteSettingsPropertiesRepository _settingsRepo;

  final RxBool isScreenLoading = false.obs;

  final RxList<CartListItem> items = <CartListItem>[].obs;

  final Rx<GuestDeliveryMode> deliveryMode = GuestDeliveryMode.home.obs;
  final Rx<GuestBillingMode> billingMode = GuestBillingMode.sameAsShipping.obs;

  final TextEditingController shipNameC = TextEditingController();
  final TextEditingController shipEmailC = TextEditingController();
  final TextEditingController shipPhoneC = TextEditingController();
  final TextEditingController shipAddressC = TextEditingController();
  final TextEditingController shipPostalC = TextEditingController();
  final TextEditingController shipCountryC = TextEditingController();
  final TextEditingController shipStateC = TextEditingController();
  final TextEditingController shipCityC = TextEditingController();

  final Rx<CountryModel?> shipSelectedCountry = Rx<CountryModel?>(null);
  final Rx<StateModel?> shipSelectedState = Rx<StateModel?>(null);
  final Rx<CityModel?> shipSelectedCity = Rx<CityModel?>(null);

  final TextEditingController pickupNameC = TextEditingController();
  final TextEditingController pickupEmailC = TextEditingController();

  final TextEditingController billNameC = TextEditingController();
  final TextEditingController billEmailC = TextEditingController();
  final TextEditingController billPhoneC = TextEditingController();
  final TextEditingController billAddressC = TextEditingController();
  final TextEditingController billPostalC = TextEditingController();
  final TextEditingController billCountryC = TextEditingController();
  final TextEditingController billStateC = TextEditingController();
  final TextEditingController billCityC = TextEditingController();

  final Rx<CountryModel?> billSelectedCountry = Rx<CountryModel?>(null);
  final Rx<StateModel?> billSelectedState = Rx<StateModel?>(null);
  final Rx<CityModel?> billSelectedCity = Rx<CityModel?>(null);

  final createAccount = false.obs;

  final TextEditingController passwordController = TextEditingController();
  final RxBool passwordObscure = true.obs;
  final RxString passwordError = ''.obs;

  final TextEditingController confirmPasswordController =
      TextEditingController();
  final RxBool confirmPasswordObscure = true.obs;
  final RxString confirmPasswordError = ''.obs;

  IconData get eyeOpenIcon => Iconsax.eye_copy;
  IconData get eyeClosedIcon => Iconsax.eye_slash_copy;

  void togglePasswordVisibility() {
    passwordObscure.value = !passwordObscure.value;
  }

  void toggleConfirmPasswordVisibility() {
    confirmPasswordObscure.value = !confirmPasswordObscure.value;
  }

  bool validatePasswords() {
    passwordError.value = '';
    confirmPasswordError.value = '';

    if (!createAccount.value) return true;

    if (passwordController.text.length < 6) {
      passwordError.value = 'Password must be at least 6 characters'.tr;
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      confirmPasswordError.value = 'Passwords do not match'.tr;
      return false;
    }
    return true;
  }

  bool _isOn(dynamic v) => v == 1 || v == '1' || v == true;
  bool _isRequired(dynamic v) => v == 1 || v == '1';

  final RxBool enableNameField = true.obs;
  final RxBool requiredNameField = true.obs;

  final RxBool enableEmailField = true.obs;
  final RxBool requiredEmailField = false.obs;

  final RxBool enablePhoneField = true.obs;
  final RxBool requiredPhoneField = false.obs;

  final RxBool enableAddressField = true.obs;
  final RxBool requiredAddressField = false.obs;

  final RxBool enablePostCodeField = true.obs;
  final RxBool requiredPostCodeField = false.obs;

  final RxBool enableCountryStateCityField = true.obs;

  final RxBool enableBillingAddressSection = true.obs;
  final RxBool useShippingAsBillingDefault = false.obs;

  final RxBool enableCreateAccountOption = true.obs;
  final RxBool enablePickupPointInCheckout = true.obs;
  final RxBool enableGuestPersonalInfoSection = true.obs;
  final RxBool enableOrderNoteField = true.obs;

  List<CountryModel> _cachedCountries = [];

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

  final TextEditingController bankAccountNameCtrl = TextEditingController();
  final TextEditingController bankAccountNumberCtrl = TextEditingController();
  final TextEditingController bankNameCtrl = TextEditingController();
  final TextEditingController bankBranchCtrl = TextEditingController();
  final TextEditingController bankTransactionIdCtrl = TextEditingController();
  final RxnString bankReceiptImagePath = RxnString();

  final noteCtrl = TextEditingController();

  String money(num v, {bool applyConversion = true}) {
    if (Get.isRegistered<CurrencyService>()) {
      return Get.find<CurrencyService>().format(
        v,
        applyConversion: applyConversion,
      );
    }
    return '\$${v.toStringAsFixed(2)}';
  }

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

  String variantLine(CartListItem it) {
    final v = (it.variant ?? '').trim();
    return v.isEmpty ? '' : v;
  }

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

  String get shippingSummaryText {
    if (deliveryMode.value == GuestDeliveryMode.home) {
      final parts = <String>[
        shipNameC.text.trim(),
        shipPhoneC.text.trim(),
        shipAddressC.text.trim(),
        shipCityC.text.trim(),
        shipPostalC.text.trim(),
      ].where((e) => e.isNotEmpty).join(', ');
      return parts;
    } else {
      final pp = pickupPoints.firstWhereOrNull(
        (e) => e.id == selectedPickupId.value,
      );
      return pp == null
          ? '${'Pickup'.tr} (${'no point selected'.tr})'
          : '${'Pickup'.tr}: ${pp.name}';
    }
  }

  String? get chosenPaymentTitle {
    final id = selectedPaymentMethodId.value;
    if (id == null) return null;
    return activePaymentMethods.firstWhereOrNull((p) => p.id == id)?.name;
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

  @override
  void onInit() {
    super.onInit();
    _ingestIncomingItems();
    isScreenLoading.value = true;
    _loadInitial();
  }

  void _ingestIncomingItems() {
    final arg = Get.arguments?['items'];
    if (arg == null) return;

    if (arg is List<CartListItem>) {
      items.assignAll(arg);
    } else if (arg is List<CartApiItem>) {
      items.assignAll(arg.map(_fromApiModel).toList());
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

  Future<void> _loadInitial() async {
    try {
      await _loadCheckoutSettings();
      await _loadPickupPoints();
      await _refreshShippingOptions();
      await _refreshActivePaymentMethods();
    } finally {
      isScreenLoading.value = false;
    }
  }

  Future<void> _loadCheckoutSettings() async {
    try {
      final s = await _settingsRepo.fetchSiteSettingsMap();

      if (Get.context == null) return;

      enableNameField.value = _isOn(s['enable_name_in_checkout']);
      requiredNameField.value = _isRequired(s['name_required_in_checkout']);

      enableEmailField.value = _isOn(s['enable_email_in_checkout']);
      requiredEmailField.value = _isRequired(s['email_required_in_checkout']);

      enablePhoneField.value = _isOn(s['enable_phone_in_checkout']);
      requiredPhoneField.value = _isRequired(s['phone_required_in_checkout']);

      enableAddressField.value = _isOn(s['enable_address_in_checkout']);
      requiredAddressField.value = _isRequired(
        s['address_required_in_checkout'],
      );

      enablePostCodeField.value = _isOn(s['enable_post_code_in_checkout']);
      requiredPostCodeField.value = _isRequired(
        s['post_code_required_in_checkout'],
      );

      enableCountryStateCityField.value = _isOn(
        s['enable_country_state_city_in_checkout'],
      );

      enableBillingAddressSection.value = _isOn(s['enable_billing_address']);
      useShippingAsBillingDefault.value = _isOn(
        s['use_shipping_address_as_billing_address'],
      );

      enableCreateAccountOption.value = _isOn(
        s['create_account_in_guest_checkout'],
      );

      enablePickupPointInCheckout.value =
          _isOn(s['enable_pickup_point_in_checkout']) &&
          _isOn(s['is_active_pickuppoint']);

      final rawPersonal = s['enable_personal_info_guest_checkout'];
      enableGuestPersonalInfoSection.value =
          rawPersonal == 1 ||
          rawPersonal == '1' ||
          rawPersonal == 2 ||
          rawPersonal == '2';

      enableOrderNoteField.value = _isOn(s['enable_order_note_in_checkout']);

      if (!enablePickupPointInCheckout.value &&
          deliveryMode.value == GuestDeliveryMode.pickup) {
        deliveryMode.value = GuestDeliveryMode.home;
      }

      if (useShippingAsBillingDefault.value) {
        billingMode.value = GuestBillingMode.sameAsShipping;
      }
    } catch (_) {}
  }

  Future<void> _loadPickupPoints() async {
    try {
      final map = await _checkoutRepo.fetchActivePickupPoints();

      if (Get.context == null) return;

      final resp = PickupPointResponse.fromJson(map);
      if (resp.success) {
        pickupPoints.assignAll(resp.data);
        if (deliveryMode.value == GuestDeliveryMode.pickup &&
            selectedPickupId.value == null &&
            pickupPoints.isNotEmpty) {
          selectedPickupId.value = pickupPoints.first.id;
        }
      }
    } catch (_) {}
  }

  Future<List<CountryModel>> loadCountries() async {
    if (_cachedCountries.isNotEmpty) return _cachedCountries;
    try {
      final list = await _addressRepo.getCountries();

      if (Get.context == null) return [];

      _cachedCountries = list;
      return list;
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Error'.tr, 'Failed to load countries'.tr);
      }
      rethrow;
    }
  }

  Future<List<StateModel>> loadShippingStates() async {
    final co = shipSelectedCountry.value;
    if (co == null) return [];
    try {
      final result = await _addressRepo.getStates(countryId: co.id);

      if (Get.context == null) return [];

      return result;
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Error'.tr, 'Failed to load states'.tr);
      }
      rethrow;
    }
  }

  Future<List<CityModel>> loadShippingCities() async {
    final st = shipSelectedState.value;
    if (st == null) return [];
    try {
      final result = await _addressRepo.getCities(stateId: st.id);

      if (Get.context == null) return [];

      return result;
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Error'.tr, 'Failed to load cities'.tr);
      }
      rethrow;
    }
  }

  Future<List<StateModel>> loadBillingStates() async {
    final co = billSelectedCountry.value;
    if (co == null) return [];
    try {
      final result = await _addressRepo.getStates(countryId: co.id);

      if (Get.context == null) return [];

      return result;
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Error'.tr, 'Failed to load states'.tr);
      }
      rethrow;
    }
  }

  Future<List<CityModel>> loadBillingCities() async {
    final st = billSelectedState.value;
    if (st == null) return [];
    try {
      final result = await _addressRepo.getCities(stateId: st.id);

      if (Get.context == null) return [];

      return result;
    } catch (e) {
      if (Get.context != null) {
        _showSnackbar('Error'.tr, 'Failed to load cities'.tr);
      }
      rethrow;
    }
  }

  void onSelectShipCountry(CountryModel c) {
    shipSelectedCountry.value = c;
    shipCountryC.text = c.name;
    shipSelectedState.value = null;
    shipStateC.clear();
    shipSelectedCity.value = null;
    shipCityC.clear();
  }

  void onSelectShipState(StateModel s) {
    shipSelectedState.value = s;
    shipStateC.text = s.name;
    shipSelectedCity.value = null;
    shipCityC.clear();
  }

  void onSelectShipCity(CityModel c) {
    shipSelectedCity.value = c;
    shipCityC.text = c.name;
    _onShippingLocationChanged();
    refreshAll();
  }

  void onSelectBillCountry(CountryModel c) {
    billSelectedCountry.value = c;
    billCountryC.text = c.name;
    billSelectedState.value = null;
    billStateC.clear();
    billSelectedCity.value = null;
    billCityC.clear();
  }

  void onSelectBillState(StateModel s) {
    billSelectedState.value = s;
    billStateC.text = s.name;
    billSelectedCity.value = null;
    billCityC.clear();
  }

  void onSelectBillCity(CityModel c) {
    billSelectedCity.value = c;
    billCityC.text = c.name;
  }

  void onShippingPostalChanged(String _) {
    _onShippingLocationChanged();
  }

  Future<void> _onShippingLocationChanged() async {
    if (deliveryMode.value != GuestDeliveryMode.home) return;
    if (shipSelectedCity.value == null ||
        shipPostalC.text.trim().isEmpty ||
        items.isEmpty) {
      _clearOptionsState();
      await _refreshActivePaymentMethods();
      return;
    }
    isScreenLoading.value = true;
    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    isScreenLoading.value = false;
  }

  String _productsJsonForOptions() {
    final payload = <Map<String, dynamic>>[];

    for (final it in _countedItems) {
      final map = it.toApiModel().toJson();

      final uid = it.uid;
      final tax = _taxByUid[uid] ?? 0.0;
      final method = selectedMethodFor(uid);
      final shippingCost = method?.cost ?? 0.0;

      map['tax'] = tax;
      map['shipping_cost'] = shippingCost;

      payload.add(map);
    }

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

    if (deliveryMode.value == GuestDeliveryMode.home) {
      final city = shipSelectedCity.value;
      if (city == null || items.isEmpty) {
        _clearOptionsState();
        return;
      }
      location = city.id;
      final pc = shipPostalC.text.trim();
      postCode = pc.isEmpty ? null : pc;
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
      shippingType = 'pickup_delivery';
    }

    try {
      isLoadingOptions.value = true;
      optionsError.value = '';

      final map = await _checkoutRepo.fetchShippingOptions(
        location: location,
        postCode: postCode,
        shippingType: shippingType,
        productsJsonString: _productsJsonForOptions(),
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

      if (deliveryMode.value == GuestDeliveryMode.home) {
        cityStr = (shipSelectedCity.value?.id ?? 0).toString();
        pickupStr = '';
      } else {
        cityStr = '';
        pickupStr = (selectedPickupId.value ?? 0).toString();
      }

      final map = await _checkoutRepo.fetchActivePaymentMethods(
        city: cityStr,
        pickupPoint: pickupStr,
        productsJsonString: _productsJsonForOptions(),
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

  void _clearOptionsState() {
    optionsByUid.clear();
    notAvailableUids.clear();
    selectedMethodByUid.clear();
    _taxByUid.clear();
  }

  Future<void> setDeliveryMode(GuestDeliveryMode m) async {
    if (deliveryMode.value == m) return;

    if (m == GuestDeliveryMode.pickup && !enablePickupPointInCheckout.value) {
      _showSnackbar('Pickup'.tr, 'Pickup point is not available'.tr);
      return;
    }

    deliveryMode.value = m;
    isScreenLoading.value = true;

    if (m == GuestDeliveryMode.pickup) {
      if (pickupPoints.isEmpty) {
        await _loadPickupPoints();
      }
      if (selectedPickupId.value == null && pickupPoints.isNotEmpty) {
        selectedPickupId.value = pickupPoints.first.id;
      }
    }

    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    isScreenLoading.value = false;
  }

  Future<void> setPickupPoint(int? id) async {
    selectedPickupId.value = id;
    isScreenLoading.value = true;
    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    isScreenLoading.value = false;
  }

  void togglePickupBillingMode() {
    billingMode.value = billingMode.value == GuestBillingMode.different
        ? GuestBillingMode.sameAsShipping
        : GuestBillingMode.different;
  }

  void selectShippingFor(String uid) {
    final op = optionsByUid[uid];
    if (op == null) return;

    final context = Get.context;
    if (context == null) return;

    final current = selectedMethodByUid[uid];
    final defaultId = op.defaultOption?.id;

    final methods = op.methods.isEmpty && op.defaultOption != null
        ? [op.defaultOption!]
        : op.methods;

    if (methods.isEmpty) return;

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
                    if (hasCost) Text('${'Cost'.tr}: ${money(m.cost)}'),
                    if (hasTime) Text('${'Time'.tr}: ${m.shippingTime}'),
                    if (hasFrom) Text('${'from'.tr}: ${m.shippingFrom}'),
                    if (hasBy) Text('${'By'.tr}: ${m.by}'),
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

  void resetBankForm() {
    bankAccountNameCtrl.clear();
    bankAccountNumberCtrl.clear();
    bankNameCtrl.clear();
    bankBranchCtrl.clear();
    bankTransactionIdCtrl.clear();
    bankReceiptImagePath.value = null;
  }

  Future<void> refreshAll() async {
    isScreenLoading.value = true;
    await _loadCheckoutSettings();
    await _loadPickupPoints();
    await _refreshShippingOptions();
    await _refreshActivePaymentMethods();
    isScreenLoading.value = false;
  }

  void setSelectedPayment(int? id) {
    selectedPaymentMethodId.value = id;
    if (!isBankPaymentSelected) {
      resetBankForm();
    }
  }

  bool _isEmpty(TextEditingController c) => c.text.trim().isEmpty;

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
        '${missing.join(', ')} ${missing.length == 1 ? 'is' : 'are'} ${'required for bank payment'.tr}.',
      );
      return false;
    }
    return true;
  }

  Map<String, dynamic> _buildAddressMap({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String postalCode,
    required CountryModel? country,
    required StateModel? state,
    required CityModel? city,
  }) {
    return {
      'address': address,
      'name': name,
      'email': email,
      'phone': phone,
      'postal_code': postalCode,
      'country_id': country?.id,
      'state_id': state?.id,
      'city_id': city?.id,
    };
  }

  bool _validateHomeShipping() {
    final missing = <String>[];

    if (enableNameField.value &&
        requiredNameField.value &&
        _isEmpty(shipNameC)) {
      missing.add('Name');
    }
    if (enableEmailField.value &&
        requiredEmailField.value &&
        _isEmpty(shipEmailC)) {
      missing.add('Email');
    }
    if (enablePhoneField.value &&
        requiredPhoneField.value &&
        _isEmpty(shipPhoneC)) {
      missing.add('Phone');
    }
    if (enableAddressField.value &&
        requiredAddressField.value &&
        _isEmpty(shipAddressC)) {
      missing.add('Address');
    }
    if (enablePostCodeField.value &&
        requiredPostCodeField.value &&
        _isEmpty(shipPostalC)) {
      missing.add('Postal Code');
    }

    if (enableCountryStateCityField.value) {
      if (shipSelectedCountry.value == null) missing.add('Country');
      if (shipSelectedState.value == null) missing.add('State');
      if (shipSelectedCity.value == null) missing.add('City');
    }

    if (missing.isNotEmpty) {
      _showSnackbar(
        'Missing info'.tr,
        '${missing.join(', ')} '
        '${missing.length == 1 ? 'is' : 'are'} ${'required for shipping'.tr}.',
      );
      return false;
    }
    return true;
  }

  bool _validatePickupPersonal() {
    if (!enableGuestPersonalInfoSection.value) return true;

    final missing = <String>[];

    if (enableNameField.value &&
        requiredNameField.value &&
        _isEmpty(pickupNameC)) {
      missing.add('Name');
    }
    if (enableEmailField.value &&
        requiredEmailField.value &&
        _isEmpty(pickupEmailC)) {
      missing.add('Email');
    }

    if (missing.isNotEmpty) {
      _showSnackbar(
        'Missing info'.tr,
        '${missing.join(', ')} ${missing.length == 1 ? 'is' : 'are'} ${'required'.tr}.',
      );
      return false;
    }
    return true;
  }

  bool _validateBillingIfNeeded() {
    if (!enableBillingAddressSection.value) return true;
    if (billingMode.value != GuestBillingMode.different) return true;

    final missing = <String>[];

    if (enableNameField.value &&
        requiredNameField.value &&
        _isEmpty(billNameC)) {
      missing.add('Name');
    }
    if (enableEmailField.value &&
        requiredEmailField.value &&
        _isEmpty(billEmailC)) {
      missing.add('Email');
    }
    if (enablePhoneField.value &&
        requiredPhoneField.value &&
        _isEmpty(billPhoneC)) {
      missing.add('Phone');
    }
    if (enableAddressField.value &&
        requiredAddressField.value &&
        _isEmpty(billAddressC)) {
      missing.add('Address');
    }
    if (enablePostCodeField.value &&
        requiredPostCodeField.value &&
        _isEmpty(billPostalC)) {
      missing.add('Postal Code');
    }

    if (enableCountryStateCityField.value) {
      if (billSelectedCountry.value == null) missing.add('Country');
      if (billSelectedState.value == null) missing.add('State');
      if (billSelectedCity.value == null) missing.add('City');
    }

    if (missing.isNotEmpty) {
      _showSnackbar(
        'Billing information'.tr,
        '${missing.join(', ')} '
        '${missing.length == 1 ? 'is' : 'are'} ${'required for billing'.tr}.',
      );
      return false;
    }
    return true;
  }

  Future<void> placeOrder() async {
    if (_countedItems.isEmpty) {
      _showSnackbar('Checkout'.tr, 'No items to checkout'.tr);
      return;
    }

    final isHome = deliveryMode.value == GuestDeliveryMode.home;

    if (isHome) {
      if (!_validateHomeShipping()) return;
    } else {
      if (!_validatePickupPersonal()) return;
      if (selectedPickupId.value == null) {
        _showSnackbar('Pickup'.tr, 'Please select a pickup point'.tr);
        return;
      }
    }

    if (!_validateBillingIfNeeded()) return;

    if (selectedPaymentMethodId.value == null) {
      _showSnackbar('Payment'.tr, 'Please choose a payment method'.tr);
      return;
    }

    if (!validatePasswords()) return;

    if (!_validateBankFields()) return;

    final isBank = isBankPaymentSelected;

    final customerName = isHome
        ? shipNameC.text.trim()
        : pickupNameC.text.trim();
    final customerEmail = isHome
        ? shipEmailC.text.trim()
        : pickupEmailC.text.trim();

    Map<String, dynamic>? shippingAddress;
    if (isHome) {
      shippingAddress = _buildAddressMap(
        name: shipNameC.text.trim(),
        email: shipEmailC.text.trim(),
        phone: shipPhoneC.text.trim(),
        address: shipAddressC.text.trim(),
        postalCode: shipPostalC.text.trim(),
        country: shipSelectedCountry.value,
        state: shipSelectedState.value,
        city: shipSelectedCity.value,
      );
    }

    late final Map<String, dynamic> billingAddress;
    if (enableBillingAddressSection.value &&
        billingMode.value == GuestBillingMode.different) {
      billingAddress = _buildAddressMap(
        name: billNameC.text.trim(),
        email: billEmailC.text.trim(),
        phone: billPhoneC.text.trim(),
        address: billAddressC.text.trim(),
        postalCode: billPostalC.text.trim(),
        country: billSelectedCountry.value,
        state: billSelectedState.value,
        city: billSelectedCity.value,
      );
    } else {
      if (isHome && shippingAddress != null) {
        billingAddress = Map<String, dynamic>.from(shippingAddress);
      } else {
        billingAddress = {
          'address': '',
          'name': pickupNameC.text.trim(),
          'email': pickupEmailC.text.trim(),
          'phone': '',
          'postal_code': '',
          'country_id': null,
          'state_id': null,
          'city_id': null,
        };
      }
    }

    final paymentId = selectedPaymentMethodId.value!;
    final note = noteCtrl.text.trim();
    const walletPayment = 2;

    isScreenLoading.value = true;

    try {
      final body = <String, dynamic>{
        'payment_id': paymentId,
        'note': note,
        'wallet_payment': walletPayment,
        'origin': 'app',
        'customer_name': customerName,
        'customer_email': customerEmail,
        'billing_address': jsonEncode(billingAddress),
        'products': _productsJsonForCheckout(),
      };

      if (isHome) {
        body['shipping_address'] = jsonEncode(shippingAddress ?? {});
      } else {
        body['pickup_point'] = selectedPickupId.value;
      }

      if (createAccount.value && enableCreateAccountOption.value) {
        body['create_new_account'] = '1';
        body['password'] = passwordController.text;
        body['password_confirmation'] = confirmPasswordController.text;
      }

      if (isBank) {
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

      final resp = await _guestRepo.guestCheckout(body: body);

      if (Get.context == null) return;

      await _handleGuestOrderResponse(resp, isHome: isHome);
    } catch (e) {
      if (Get.context == null) return;
      _showSnackbar('Checkout'.tr, 'Failed to place order'.tr);
    } finally {
      isScreenLoading.value = false;
    }
  }

  Future<void> _handleGuestOrderResponse(
    Map<String, dynamic> resp, {
    required bool isHome,
  }) async {
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
      await _afterGuestOrderSuccess(orderId);
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
        await _afterGuestOrderSuccess(orderId);
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

  void _goToOrderSummary(int orderId) {
    if (orderId <= 0) return;
    Get.offNamed(AppRoutes.guestOrderSummaryView, arguments: orderId);
  }

  Future<void> _afterGuestOrderSuccess(int orderId) async {
    if (orderId <= 0) {
      _showSnackbar('Order'.tr, 'Could not find order id'.tr);
      return;
    }

    _clearAllFormsAndState();

    if (Get.isRegistered<CartController>()) {
      final cart = Get.find<CartController>();
      await cart.clearAfterOrder();
    }

    _showSnackbar(
      '${'Order placed successfully'.tr} (${'Guest User'.tr})',
      'Thank you'.tr,
    );

    _goToOrderSummary(orderId);
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

  int _extractOrderId(Map<String, dynamic> resp) {
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
        if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {}

    return 0;
  }

  void _clearAllFormsAndState() {
    shipNameC.clear();
    shipEmailC.clear();
    shipPhoneC.clear();
    shipAddressC.clear();
    shipPostalC.clear();
    shipCountryC.clear();
    shipStateC.clear();
    shipCityC.clear();
    shipSelectedCountry.value = null;
    shipSelectedState.value = null;
    shipSelectedCity.value = null;

    pickupNameC.clear();
    pickupEmailC.clear();

    billNameC.clear();
    billEmailC.clear();
    billPhoneC.clear();
    billAddressC.clear();
    billPostalC.clear();
    billCountryC.clear();
    billStateC.clear();
    billCityC.clear();
    billSelectedCountry.value = null;
    billSelectedState.value = null;
    billSelectedCity.value = null;

    noteCtrl.clear();

    resetBankForm();

    passwordController.clear();
    confirmPasswordController.clear();
    passwordError.value = '';
    confirmPasswordError.value = '';
    createAccount.value = false;

    deliveryMode.value = GuestDeliveryMode.home;
    billingMode.value = useShippingAsBillingDefault.value
        ? GuestBillingMode.sameAsShipping
        : GuestBillingMode.different;

    _clearOptionsState();
    selectedPaymentMethodId.value = null;
  }

  @override
  void onClose() {
    shipNameC.dispose();
    shipEmailC.dispose();
    shipPhoneC.dispose();
    shipAddressC.dispose();
    shipPostalC.dispose();
    shipCountryC.dispose();
    shipStateC.dispose();
    shipCityC.dispose();
    pickupNameC.dispose();
    pickupEmailC.dispose();
    billNameC.dispose();
    billEmailC.dispose();
    billPhoneC.dispose();
    billAddressC.dispose();
    billPostalC.dispose();
    billCountryC.dispose();
    billStateC.dispose();
    billCityC.dispose();
    noteCtrl.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
