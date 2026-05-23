import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/modules/account/view/web_pay_view.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../data/repositories/my_order_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../product/model/payment_method_model.dart';
import '../model/my_order_details_model.dart';

class OrderDetailsController extends GetxController {
  OrderDetailsController({OrderRepository? repository})
    : _repo = repository ?? OrderRepository();

  final OrderRepository _repo;

  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final Rxn<OrderDetailsData> order = Rxn<OrderDetailsData>();

  final RxSet<int> expandedPackages = <int>{}.obs;
  bool isExpanded(int index) => expandedPackages.contains(index);
  void toggleExpanded(int index) {
    if (expandedPackages.contains(index)) {
      expandedPackages.remove(index);
    } else {
      expandedPackages.add(index);
    }
    expandedPackages.refresh();
  }

  final RxBool optimisticOrderCancelled = false.obs;
  final RxSet<int> optimisticCancelledItemIds = <int>{}.obs;

  final RxBool paying = false.obs;
  final RxBool isLoadingPayments = false.obs;
  final RxList<ActivePaymentMethod> paymentMethods = <ActivePaymentMethod>[].obs;
  final RxnInt selectedPaymentId = RxnInt();

  Future<void> load(int orderId) async {
    await _fetch(orderId, showSpinner: true);
  }

  Future<void> refreshNow(int orderId) async {
    await _fetch(orderId, showSpinner: false);
  }

  Future<void> _fetch(int orderId, {required bool showSpinner}) async {
    if (showSpinner) isLoading.value = true;
    error.value = null;
    try {
      final res = await _repo.fetchOrderDetails(orderId: orderId);
      final fresh = res.data;
      order.value = fresh;

      final stillCancelledOptimistic = <int>{};
      for (final id in optimisticCancelledItemIds) {
        final p = fresh.products.firstWhereOrNull((e) => e.id == id);
        if (p != null && _serverSaysItemCancelled(p)) {
          stillCancelledOptimistic.add(id);
        }
      }
      optimisticCancelledItemIds
        ..clear()
        ..addAll(stillCancelledOptimistic);
      optimisticCancelledItemIds.refresh();

      final allCancelledByServer =
          fresh.products.isNotEmpty &&
          fresh.products.every((p) => _serverSaysItemCancelled(p));
      if (!allCancelledByServer) {
        optimisticOrderCancelled.value = false;
      }
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      if (showSpinner) isLoading.value = false;
    }
  }

  Future<void> cancelWholeOrder() async {
    final d = order.value;
    if (d == null) return;

    try {
      final ok = await _repo.cancelOrder(orderId: d.id);
      if (ok) {
        optimisticOrderCancelled.value = true;
        Get.snackbar(
          'Cancelled'.tr,
          'Order has been cancelled'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );

        await _fetch(d.id, showSpinner: false);

        if (!_serverSaysOrderCancelledCompletely()) {
          await Future.delayed(const Duration(seconds: 2));
          await _fetch(d.id, showSpinner: false);
        }
      } else {
        Get.snackbar(
          'Failed'.tr,
          'Order cancel failed'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
  }

  Future<void> cancelItem(int itemId) async {
    final d = order.value;
    if (d == null) return;

    try {
      final ok = await _repo.cancelOrder(orderId: d.id, itemId: itemId);
      if (ok) {
        optimisticCancelledItemIds.add(itemId);
        optimisticCancelledItemIds.refresh();
        Get.snackbar(
          'Cancelled'.tr,
          'This item has been cancelled'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );

        await _fetch(d.id, showSpinner: false);

        if (!_serverSaysItemCancelledById(itemId)) {
          await Future.delayed(const Duration(seconds: 2));
          await _fetch(d.id, showSpinner: false);
        }
      } else {
        Get.snackbar(
          'Failed'.tr,
          'Item cancel failed'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
  }

  Future<void> payNow(BuildContext context) async {
    final d = order.value;
    if (d == null) return;
    if (paying.value) return;

    paying.value = true;
    try {
      final link = await _repo.generateOrderPaymentLink(orderId: d.id);
      if (link == null || link.isEmpty) {
        Get.snackbar(
          'Payment'.tr,
          'Could not generate payment link'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
        paying.value = false;
        return;
      }

      final ok = await Get.to<bool>(
        () => WebPayView(
          initialUrl: link,
          headers: const {},
          successUrlContains: null,
          cancelUrlContains: null,
          failedUrlContains: null,
          timeout: const Duration(seconds: 200),
        ),
      );

      if (ok == null) {
        final result = await Get.to<bool>(
          () => WebPayView(
            initialUrl: link,
            headers: const {},
            successUrlContains: null,
            cancelUrlContains: null,
            failedUrlContains: null,
            timeout: const Duration(seconds: 200),
          ),
        );
        await refreshNow(d.id);
        if (result == true) {
          Get.snackbar(
            'Payment'.tr,
            'Payment successful'.tr,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        } else {
          Get.snackbar(
            'Payment'.tr,
            'Payment not completed'.tr,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        }
      } else {
        await refreshNow(d.id);
        if (ok == true) {
          Get.snackbar(
            'Payment'.tr,
            'Payment successful'.tr,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        } else {
          Get.snackbar(
            'Payment'.tr,
            'Payment not completed'.tr,
            backgroundColor: AppColors.primaryColor,
            snackPosition: SnackPosition.TOP,
            colorText: AppColors.whiteColor,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Payment Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      paying.value = false;
    }
  }

  Future<void> showPayOptions(BuildContext context) async {
    final d = order.value;
    if (d == null || paying.value) return;

    // Load payment methods
    isLoadingPayments.value = true;
    try {
      final checkoutRepo = CheckoutRepository(ApiService());
      final shipping = d.shippingDetails;
      final cityId = shipping.city.isNotEmpty ? shipping.city : '0';
      final map = await checkoutRepo.fetchActivePaymentMethods(
        city: cityId,
        pickupPoint: '',
        productsJsonString: '[]',
      );
      final resp = ActivePaymentMethodsResponse.fromJson(map);
      if (resp.success) {
        paymentMethods.assignAll(resp.data);
      }
    } catch (_) {}
    isLoadingPayments.value = false;

    // Check wallet balance
    double walletBalance = 0;
    try {
      final walletRepo = WalletRepository(api: ApiService());
      final summary = await walletRepo.fetchWalletSummary();
      walletBalance = summary.totalAvailable.toDouble();
    } catch (_) {}

    final canWallet = walletBalance >= d.totalPayableAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pay for Order'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 4),
              Text('${'Total'.tr}: ${formatCurrency(d.totalPayableAmount, applyConversion: true)}', style: const TextStyle(fontSize: 14, color: AppColors.primaryColor)),
              const SizedBox(height: 16),
              // Wallet option
              if (canWallet) ...[
                ListTile(
                  leading: const Icon(Iconsax.wallet_3_copy, color: AppColors.primaryColor),
                  title: Text('Pay with Wallet'.tr),
                  subtitle: Text('Balance: ${formatCurrency(walletBalance, applyConversion: true)}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _payWithWallet(context);
                  },
                ),
                const Divider(),
              ],
              // Payment method dropdown
              if (paymentMethods.isNotEmpty) ...[
                Text('${'Payment method'.tr}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton2<int>(
                    buttonStyleData: ButtonStyleData(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    isExpanded: true,
                    items: paymentMethods.map((m) => DropdownMenuItem<int>(
                      value: m.id,
                      child: Text(m.name, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    value: selectedPaymentId.value,
                    hint: Text('Select Payment method'.tr, style: const TextStyle(fontSize: 13)),
                    onChanged: (v) => selectedPaymentId.value = v,
                    iconStyleData: const IconStyleData(icon: Icon(Iconsax.arrow_down_1_copy), iconSize: 18),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 300,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: selectedPaymentId.value == null ? null : () {
                      Navigator.pop(ctx);
                      payNow(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Pay Now'.tr),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payWithWallet(BuildContext context) async {
    final d = order.value;
    if (d == null) return;
    if (paying.value) return;

    paying.value = true;
    try {
      final walletRepo = WalletRepository(api: ApiService());
      // Use checkout to pay with wallet
      final checkoutRepo = CheckoutRepository(ApiService());
      final body = <String, dynamic>{
        'payment_id': '2',
        'note': '',
        'wallet_payment': '1',
        'origin': 'app',
        'billing_address': '0',
        'products': '[]',
        'order_id': d.id,
      };

      final resp = await checkoutRepo.customerCheckoutOrderCreate(body: body);
      final success = resp['success'] == true;
      
      if (success) {
        await refreshNow(d.id);
        Get.snackbar(
          'Payment'.tr,
          'Payment successful'.tr,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      } else {
        final msg = resp['message']?.toString() ?? 'Payment failed'.tr;
        Get.snackbar(
          'Payment'.tr,
          msg,
          backgroundColor: AppColors.primaryColor,
          snackPosition: SnackPosition.TOP,
          colorText: AppColors.whiteColor,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Payment Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      paying.value = false;
    }
  }

  bool isItemCancelledEffective(OrderProductItem p) {
    if (_serverSaysItemCancelled(p)) return true;
    return optimisticOrderCancelled.value ||
        optimisticCancelledItemIds.contains(p.id);
  }

  bool _serverSaysItemCancelled(OrderProductItem p) {
    final s = p.deliveryStatus.trim().toLowerCase();
    const cancelCodes = {'0', '-1', '4', 'cancel', 'cancelled', 'canceled'};
    return cancelCodes.contains(s);
  }

  bool _serverSaysItemCancelledById(int itemId) {
    final d = order.value;
    if (d == null) return false;
    final p = d.products.firstWhereOrNull((e) => e.id == itemId);
    if (p == null) return false;
    return _serverSaysItemCancelled(p);
  }

  bool _serverSaysOrderCancelledCompletely() {
    final d = order.value;
    if (d == null || d.products.isEmpty) return false;
    return d.products.every((p) => _serverSaysItemCancelled(p));
  }
}
