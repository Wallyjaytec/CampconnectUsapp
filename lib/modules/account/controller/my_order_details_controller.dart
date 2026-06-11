import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/modules/account/view/web_pay_view.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/login_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/my_order_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
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
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text('Order has been cancelled'.tr),
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await _fetch(d.id, showSpinner: false);

        if (!_serverSaysOrderCancelledCompletely()) {
          await Future.delayed(const Duration(seconds: 2));
          await _fetch(d.id, showSpinner: false);
        }
      } else {
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text('Order cancel failed'.tr),
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('Something went wrong'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text('This item has been cancelled'.tr),
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await _fetch(d.id, showSpinner: false);

        if (!_serverSaysItemCancelledById(itemId)) {
          await Future.delayed(const Duration(seconds: 2));
          await _fetch(d.id, showSpinner: false);
        }
      } else {
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text('Item cancel failed'.tr),
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('Something went wrong'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> payWithGateway(BuildContext context) async {
    final d = order.value;
    if (d == null) return;
    if (paying.value) return;

    paying.value = true;
    try {
      final link = await _repo.generateOrderPaymentLink(orderId: d.id);
      if (link == null || link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate payment link'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
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

      if (ok == true) {
        await refreshNow(d.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (ok == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment was cancelled'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong'.tr),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      paying.value = false;
    }
  }

  Future<void> showPayOptions(BuildContext context) async {
    final d = order.value;
    if (d == null || paying.value) return;

    paying.value = true;

    double walletBalance = 0;
    bool canWallet = false;
    try {
      final walletRepo = WalletRepository(api: ApiService());
      final summary = await walletRepo.fetchWalletSummary();
      walletBalance = summary.totalAvailable.toDouble();
      canWallet = walletBalance >= d.totalPayableAmount;
    } catch (_) {}

    paying.value = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pay for Order'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${'Total'.tr}: ${formatCurrency(d.totalPayableAmount, applyConversion: true)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryColor)),
            const SizedBox(height: 16),
            if (canWallet) ...[
              ListTile(
                leading: Icon(Iconsax.wallet_3_copy, color: AppColors.primaryColor),
                title: Text('Pay with Wallet'.tr),
                subtitle: Text('Balance'.tr}: ${formatCurrency(walletBalance, applyConversion: true)}'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: AppColors.primaryColor.withValues(alpha: 0.05),
                onTap: () {
                  Navigator.pop(ctx);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _payWithWallet(context);
                  });
                },
              ),
              const SizedBox(height: 8),
              Center(child: Text('— OR —'.tr, style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 8),
            ],
            ListTile(
              leading: Icon(Iconsax.card_copy, color: AppColors.primaryColor),
              title: Text('Pay with Payment Gateway'.tr),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: AppColors.primaryColor.withValues(alpha: 0.05),
              onTap: () {
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 100), () {
                  payWithGateway(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payWithWallet(BuildContext context) async {
    final d = order.value;
    if (d == null || paying.value) return;

    paying.value = true;
    try {
      final token = LoginService().token;
      final uri = Uri.parse(AppConfig.payOrderWithWalletUrl());
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {'order_id': d.id.toString()},
      );

      final resp = jsonDecode(response.body);
      final success = resp['success'] == true;
      
      if (success) {
        await refreshNow(d.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful'.tr),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final msg = resp['message']?.toString() ?? 'Payment failed'.tr;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong'.tr),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
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
