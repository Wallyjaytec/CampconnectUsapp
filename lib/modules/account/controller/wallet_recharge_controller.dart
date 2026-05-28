import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/repositories/site_settings_properties_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../model/wallet_payment_methods_model.dart';

class WalletRechargeController extends GetxController {
  final WalletRepository repo;
  WalletRechargeController({required this.repo});

  final RxBool isLoadingMethods = false.obs;
  final RxString methodsError = ''.obs;
  final Rx<WalletPaymentMethods?> methods = Rx<WalletPaymentMethods?>(null);

  final RxInt currentTabIndex = 0.obs;

  final RxInt selectedOfflineMethodId = RxInt(0);
  final RxString rechargeAmount = ''.obs;
  final RxString transactionId = ''.obs;
  final RxInt currencyId = RxInt(1);
  final Rx<File?> transactionProof = Rx<File?>(null);

  final RxBool isSubmitting = false.obs;
  final RxMap<String, String?> fieldErrors = <String, String?>{}.obs;

  final RxnDouble minAmount = RxnDouble(null);
  final RxnDouble maxAmount = RxnDouble(null);
  final RxBool isLimitsLoaded = false.obs;

  final RxInt selectedOnlineMethodId = 0.obs;
  final RxString onlineAmount = ''.obs;
  final RxBool isGeneratingLink = false.obs;
  final RxMap<String, String?> onlineFieldErrors = <String, String?>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadMethods();
    _loadLimitsFromSiteSettings();
  }

  double _toDisplayCurrency(double baseValue) {
    try {
      if (Get.isRegistered<CurrencyService>()) {
        final svc = Get.find<CurrencyService>();
        final cur = svc.current;
        if (cur != null && cur.conversionRate > 0) {
          return baseValue * cur.conversionRate;
        }
      }
    } catch (_) {}
    return baseValue;
  }

  Future<void> loadMethods() async {
    isLoadingMethods.value = true;
    methodsError.value = '';
    methods.value = null;
    selectedOnlineMethodId.value = 0;
    selectedOfflineMethodId.value = 0;

    try {
      final res = await repo.fetchPaymentMethods();

      final cleanOnline = res.onlineMethods.where((e) => e.id > 0 && e.name.trim().isNotEmpty).toList();
      final cleanOffline = res.offlineMethods.where((e) => e.id > 0 && e.name.trim().isNotEmpty).toList();

      methods.value = WalletPaymentMethods(onlineMethods: cleanOnline, offlineMethods: cleanOffline);

      if (cleanOffline.isNotEmpty) { selectedOfflineMethodId.value = cleanOffline.first.id; } 
      else { selectedOfflineMethodId.value = 0; }

      if (cleanOnline.isNotEmpty) { selectedOnlineMethodId.value = cleanOnline.first.id; } 
      else { selectedOnlineMethodId.value = 0; }
    } catch (e) {
      methods.value = WalletPaymentMethods(onlineMethods: [], offlineMethods: []);
      selectedOnlineMethodId.value = 0;
      selectedOfflineMethodId.value = 0;
      methodsError.value = e.toString();
    } finally {
      isLoadingMethods.value = false;
    }
  }

  void setTab(int index) => currentTabIndex.value = index;
  void pickOfflineMethod(int id) => selectedOfflineMethodId.value = id;
  void setAmount(String v) => rechargeAmount.value = v;
  void setTxnId(String v) => transactionId.value = v;
  void setCurrency(int v) => currencyId.value = v;
  void setProof(File? f) => transactionProof.value = f;
  void pickOnlineMethod(int id) => selectedOnlineMethodId.value = id;
  void setOnlineAmount(String v) => onlineAmount.value = v;

  Future<bool> submitOffline() async {
    fieldErrors.clear();

    final amountRaw = rechargeAmount.value.trim();
    final amountNum = double.tryParse(amountRaw);
    if (amountNum == null) {
      fieldErrors['recharge_amount'] = 'Enter a valid number'.tr;
      _showSnack('Validation'.tr, 'Enter a valid number'.tr);
      return false;
    }
    if (minAmount.value != null && amountNum < (minAmount.value!)) {
      fieldErrors['recharge_amount'] = '${'Minimum'.tr} ${_toDisplayCurrency(minAmount.value!).toStringAsFixed(2)} ${'in selected currency'.tr}.';
    }
    if (maxAmount.value != null && amountNum > (maxAmount.value!)) {
      fieldErrors['recharge_amount'] = '${'Maximum'.tr} ${_toDisplayCurrency(maxAmount.value!).toStringAsFixed(2)} ${'in selected currency'.tr}.';
    }
    if (transactionId.value.trim().isEmpty) {
      fieldErrors['transaction_id'] = 'Transaction id is required'.tr;
      _showSnack('Validation'.tr, 'Transaction id is required'.tr);
      return false;
    }
    if (selectedOfflineMethodId.value <= 0) {
      fieldErrors['payment_method'] = 'Select a payment method'.tr;
      _showSnack('Validation'.tr, 'Select a payment method'.tr);
      return false;
    }

    isSubmitting.value = true;
    try {
      final res = await repo.submitOfflineRecharge(rechargeType: 2, rechargeAmount: amountRaw, transactionId: transactionId.value.trim(), paymentMethodId: selectedOfflineMethodId.value, currencyId: currencyId.value, transactionImageFile: transactionProof.value);
      final ok = (res['success'] == true) || (res['success']?.toString().toLowerCase() == 'true');
      if (ok) { _showSnack('Success'.tr, 'Recharge submitted successfully'.tr, success: true); }
      return ok;
    } on ApiValidationError catch (ve) {
      fieldErrors.addAll(ve.fieldErrors.map((k, v) => MapEntry(k, (v.isNotEmpty ? v.first : null))));
      final serverMsg = (ve.message.isNotEmpty) ? ve.message : (ve.fieldErrors['recharge_amount']?.first ?? ve.fieldErrors.values.firstWhere((l) => l.isNotEmpty, orElse: () => ['']).first);
      if (serverMsg.isNotEmpty) _showSnack('Validation'.tr, serverMsg);
      return false;
    } catch (e) {
      _showSnack('Error'.tr, _extractServerMessage(e));
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> generateOnlineLink() async {
    onlineFieldErrors.clear();
    final amountRaw = onlineAmount.value.trim();
    final amountNum = double.tryParse(amountRaw);
    if (amountNum == null) { onlineFieldErrors['recharge_amount'] = 'Enter a valid number'.tr; _showSnack('Validation'.tr, 'Enter a valid number'.tr); return null; }
    if (minAmount.value != null && amountNum < (minAmount.value!)) { onlineFieldErrors['recharge_amount'] = '${'Minimum'.tr} ${_toDisplayCurrency(minAmount.value!).toStringAsFixed(2)} ${'in selected currency'.tr}.'; }
    if (maxAmount.value != null && amountNum > (maxAmount.value!)) { onlineFieldErrors['recharge_amount'] = '${'Maximum'.tr} ${_toDisplayCurrency(maxAmount.value!).toStringAsFixed(2)} ${'in selected currency'.tr}.'; }
    if (selectedOnlineMethodId.value <= 0) { onlineFieldErrors['payment_method'] = 'Select a payment method'.tr; _showSnack('Validation'.tr, 'Select a payment method'.tr); return null; }

    isGeneratingLink.value = true;
    try {
      final rawUrl = await repo.generateOnlineRechargeLink(rechargeType: 1, rechargeAmount: amountRaw, paymentMethodId: selectedOnlineMethodId.value, currencyId: currencyId.value.toInt());
      if (rawUrl.isNotEmpty) { _showSnack('Success'.tr, 'Payment link generated'.tr, success: true); return rawUrl; } 
      else { _showSnack('Error'.tr, 'Missing url in response'.tr); return null; }
    } on ApiValidationError catch (ve) {
      onlineFieldErrors.addAll(ve.fieldErrors.map((k, v) => MapEntry(k, (v.isNotEmpty ? v.first : null))));
      final serverMsg = (ve.message.isNotEmpty) ? ve.message : (ve.fieldErrors['recharge_amount']?.first ?? ve.fieldErrors.values.firstWhere((l) => l.isNotEmpty, orElse: () => ['']).first);
      if (serverMsg.isNotEmpty) _showSnack('Validation'.tr, serverMsg);
      return null;
    } catch (e) { _showSnack('Error'.tr, _extractServerMessage(e)); return null; } 
    finally { isGeneratingLink.value = false; }
  }

  String? _firstFieldErrorMsg(dynamic errors) {
    if (errors is Map) { for (final v in errors.values) { if (v is List && v.isNotEmpty && v.first is String && (v.first as String).trim().isNotEmpty) return (v.first as String).trim(); if (v is String && v.trim().isNotEmpty) return v.trim(); } }
    return null;
  }

  String _extractServerMessage(dynamic err) {
    String msg;
    if (err is ApiValidationError) { 
      msg = err.message.isNotEmpty ? err.message : (_firstFieldErrorMsg(err.fieldErrors) ?? 'Validation error'.tr); 
    } else {
      final raw = err.toString();
      try { 
        final decoded = json.decode(raw); 
        if (decoded is Map) { 
          final m = decoded['message']; 
          if (m is String && m.trim().isNotEmpty) {
            msg = m.trim();
          } else {
            final f = _firstFieldErrorMsg(decoded['errors']); 
            msg = f ?? raw;
          }
        } else {
          msg = raw;
        }
      } catch (_) {
        final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw); 
        msg = (match != null && match.groupCount >= 1) ? match.group(1)!.trim() : raw;
      }
    }
    
    msg = msg
        .replaceAll('The minimum recharge amount must be at least', 'The minimum recharge amount must be at least'.tr)
        .replaceAll('The maximum recharge amount must be at most', 'The maximum recharge amount must be at most'.tr);
    
    return _unescapeUnicode(msg);
  }

  String _unescapeUnicode(String s) {
    try { final wrapped = '"${s.replaceAll(r'\"', r'\\\"').replaceAll('"', r'\"')}"'; final decoded = json.decode(wrapped); if (decoded is String) return decoded; } catch (_) {}
    return s.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (m) { final code = int.parse(m.group(1)!, radix: 16); return String.fromCharCode(code); });
  }

  void _showSnack(String title, String message, {bool success = false}) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: success ? AppColors.primaryColor : AppColors.redColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadLimitsFromSiteSettings() async {
    if (isLimitsLoaded.value) return;
    try {
      final settingsRepo = SiteSettingsPropertiesRepository(ApiService());
      final settings = await settingsRepo.fetchSiteSettingsMap();
      double? toDouble(dynamic v) { if (v == null) return null; if (v is num) return v.toDouble(); return double.tryParse(v.toString()); }
      minAmount.value = toDouble(settings['minimum_recharge_amount']);
      maxAmount.value = toDouble(settings['maximum_recharge_amount']);
      isLimitsLoaded.value = true;
    } catch (_) { isLimitsLoaded.value = true; }
  }
}
