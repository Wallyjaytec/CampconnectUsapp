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

  // Selection mode
  final isSelectionMode = false.obs;
  final selectedCount = 0.obs;

  void _showSnackbar(String message, {Color? backgroundColor}) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor ?? AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

  // Show per-notification bottom sheet
  void showNotificationOptions(NotificationItem item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(item.message.length > 50 ? '${item.message.substring(0, 50)}...' : item.message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.done, color: Colors.green),
              title: Text('Mark as read'.tr),
              onTap: () {
                Get.back();
                markSingleAsRead(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_unread, color: AppColors.primaryColor),
              title: Text('Mark as unread'.tr),
              onTap: () {
                Get.back();
                markSingleAsUnread(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete this notification'.tr, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                deleteSingle(item);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel'.tr, style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: false,
    );
  }

  // Top menu options
  void showTopMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.checklist, color: AppColors.primaryColor),
              title: Text('Select'.tr),
              onTap: () {
                Get.back();
                enterSelectionMode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: Colors.green),
              title: Text('Mark all as read'.tr),
              onTap: () {
                Get.back();
                markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_unread, color: AppColors.primaryColor),
              title: Text('Mark all as unread'.tr),
              onTap: () {
                Get.back();
                markAllAsUnread();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: Text('Delete all'.tr, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                deleteAll();
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel'.tr, style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: false,
    );
  }

  void enterSelectionMode() {
    for (var item in items) {
      item.isSelected = false;
    }
    isSelectionMode.value = true;
    selectedCount.value = 0;
  }

  void exitSelectionMode() {
    for (var item in items) {
      item.isSelected = false;
    }
    items.refresh();
    isSelectionMode.value = false;
    selectedCount.value = 0;
  }

  void toggleSelection(NotificationItem item) {
    item.isSelected = !item.isSelected;
    selectedCount.value = items.where((e) => e.isSelected).length;
    if (selectedCount.value == 0) {
      isSelectionMode.value = false;
    }
  }

  void selectAll() {
    for (var item in items) {
      item.isSelected = true;
    }
    selectedCount.value = items.length;
  }

  Future<void> markSingleAsRead(NotificationItem item) async {
    final res = await _repo.markSingleAsRead(notificationId: item.id);
    if (res.success) {
      item.isRead = true;
      items.refresh();
      notificationCount.value = items.where((e) => !e.isRead).length;
      _showSnackbar('Marked as read'.tr);
    }
  }

  Future<void> markSingleAsUnread(NotificationItem item) async {
    item.isRead = false;
    items.refresh();
    notificationCount.value = items.where((e) => !e.isRead).length;
    _showSnackbar('Marked as unread'.tr);
  }

  Future<void> deleteSingle(NotificationItem item) async {
    final success = await _repo.deleteNotification(item.id);
    if (success) {
      items.removeWhere((e) => e.id == item.id);
      items.refresh();
      notificationCount.value = items.where((e) => !e.isRead).length;
      _showSnackbar('Notification deleted'.tr);
    }
  }

  Future<void> markAllAsRead() async {
    final ok = await _repo.markAllAsRead();
    if (ok) {
      for (var item in items) {
        item.isRead = true;
      }
      items.refresh();
      notificationCount.value = 0;
      _showSnackbar('All marked as read'.tr);
    }
  }

  Future<void> markAllAsUnread() async {
    for (var item in items) {
      item.isRead = false;
    }
    items.refresh();
    notificationCount.value = items.length;
    _showSnackbar('All marked as unread'.tr);
  }

  Future<void> deleteAll() async {
    for (var item in items.toList()) {
      await _repo.deleteNotification(item.id);
    }
    items.clear();
    items.refresh();
    notificationCount.value = 0;
    _showSnackbar('All notifications deleted'.tr);
  }

  Future<void> deleteSelected() async {
    final selectedItems = items.where((e) => e.isSelected).toList();
    for (var item in selectedItems) {
      await _repo.deleteNotification(item.id);
    }
    items.removeWhere((e) => e.isSelected);
    items.refresh();
    exitSelectionMode();
    notificationCount.value = items.where((e) => !e.isRead).length;
    _showSnackbar('${selectedItems.length} deleted'.tr);
  }

  Future<void> markSelectedAsRead() async {
    for (var item in items) {
      if (item.isSelected) {
        await _repo.markSingleAsRead(notificationId: item.id);
        item.isRead = true;
      }
    }
    items.refresh();
    exitSelectionMode();
    notificationCount.value = items.where((e) => !e.isRead).length;
    _showSnackbar('Marked as read'.tr);
  }

  Future<void> markSelectedAsUnread() async {
    for (var item in items) {
      if (item.isSelected) {
        item.isRead = false;
      }
    }
    items.refresh();
    exitSelectionMode();
    notificationCount.value = items.where((e) => !e.isRead).length;
    _showSnackbar('Marked as unread'.tr);
  }
}
