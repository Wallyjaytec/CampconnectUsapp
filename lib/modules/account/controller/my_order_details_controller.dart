import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/modules/account/view/web_pay_view.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/my_order_repository.dart';
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
