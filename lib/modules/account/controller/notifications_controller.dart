import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../data/repositories/notification_repository.dart';
import '../model/notification_model.dart';
import '../view/notification_detail_view.dart';

class NotificationController extends GetxController {
  NotificationController({NotificationRepository? repo})
    : _repo = repo ?? NotificationRepository();

  final NotificationRepository _repo;
  final _loginService = LoginService();

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorText = RxnString();

  final items = <NotificationItem>[].obs;
  final notificationCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (_loginService.isLoggedIn()) {
      load();
    }
  }

  Future<void> load() async {
    if (!_loginService.isLoggedIn()) {
      items.clear();
      notificationCount.value = 0;
      errorText.value = null;
      return;
    }

    if (isLoading.value) return;
    isLoading.value = true;
    errorText.value = null;

    try {
      final res = await _repo.fetchAllNotifications();
      items.assignAll(res.notifications);
      notificationCount.value = items.where((e) => !e.isRead).length;
    } catch (e) {
      errorText.value = 'Something went wrong'.tr;
      items.clear();
      notificationCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() async {
    if (!_loginService.isLoggedIn()) {
      items.clear();
      notificationCount.value = 0;
      return;
    }

    isRefreshing.value = true;
    try {
      final res = await _repo.fetchAllNotifications();
      items.assignAll(res.notifications);
      notificationCount.value = items.where((e) => !e.isRead).length;
    } catch (_) {
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> onTapNotification(NotificationItem item) async {
    await Get.to(() => NotificationDetailView(item: item));
    final res = await _repo.markSingleAsRead(notificationId: item.id);
    if (res.success) {
      item.isRead = true;
      items.refresh();
      notificationCount.value = items.where((e) => !e.isRead).length;
    }
  }
}
