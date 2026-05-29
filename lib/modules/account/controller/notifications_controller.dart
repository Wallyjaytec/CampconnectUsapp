import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/controllers/theme_controller.dart';
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

  @override
  void onReady() {
    super.onReady();
    if (_loginService.isLoggedIn()) {
      isLoading.value = true;
      refreshList().then((_) {
        isLoading.value = false;
        checkPushNotification();
      });
    }
  }

  void checkPushNotification() {
    final box = GetStorage();
    final pushId = box.read<String>('push_notification_id') ?? '';
    if (pushId.isNotEmpty) {
      final message = box.read<String>('push_notif_message') ?? '';
      final title = box.read<String>('push_notif_title') ?? '';
      final image = box.read<String>('push_notif_image') ?? '';
      
      box.remove('push_notification_id');
      box.remove('push_notif_message');
      box.remove('push_notif_title');
      box.remove('push_notif_image');
      
      final item = NotificationItem(
        id: pushId,
        message: message,
        link: '',
        time: 'Just now',
        title: title.isNotEmpty ? title : null,
        image: image.isNotEmpty ? image : null,
      );
      
      Get.to(() => NotificationDetailView(item: item));
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
      updateCount();
    } catch (e) {
      errorText.value = 'Something went wrong'.tr;
      items.clear();
      notificationCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() async {
    if (!_loginService.isLoggedIn()) return;

    isRefreshing.value = true;
    try {
      final res = await _repo.fetchAllNotifications();
      final newItems = res.notifications;
      for (var newItem in newItems) {
        final existing = items.firstWhereOrNull((e) => e.id == newItem.id);
        if (existing != null) {
          newItem.isRead = existing.isRead;
        }
      }
      items.assignAll(newItems);
      updateCount();
    } catch (_) {
    } finally {
      isRefreshing.value = false;
    }
  }

  void updateCount() {
    notificationCount.value = items.where((e) => !e.isRead).length;
  }

  Future<void> onTapNotification(NotificationItem item) async {
    await Get.to(() => NotificationDetailView(item: item));
    _repo.markSingleAsRead(notificationId: item.id).then((res) {
      if (res.success) {
        item.isRead = true;
        items.refresh();
        updateCount();
      }
    });
    item.isRead = true;
    items.refresh();
    updateCount();
  }

  void showNotificationOptions(NotificationItem item) {
    Get.bottomSheet(
      GetBuilder<ThemeController>(
        builder: (ctrl) {
          final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(
                  item.message.length > 50 ? '${item.message.substring(0, 50)}...' : item.message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
                ListTile(
                  leading: const Icon(Icons.done_all, color: Colors.green),
                  title: Text('Mark as read'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  onTap: () {
                    Get.back();
                    markSingleAsRead(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mark_chat_unread, color: AppColors.primaryColor),
                  title: Text('Mark as unread'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
          );
        },
      ),
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
    );
  }

  void showTopMenu() {
    Get.bottomSheet(
      GetBuilder<ThemeController>(
        builder: (ctrl) {
          final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.checklist, color: AppColors.primaryColor),
                  title: Text('Select'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  onTap: () {
                    Get.back();
                    enterSelectionMode();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.done_all, color: Colors.green),
                  title: Text('Mark all as read'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  onTap: () {
                    Get.back();
                    markAllAsRead();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mark_chat_unread, color: AppColors.primaryColor),
                  title: Text('Mark all as unread'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
          );
        },
      ),
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
    );
  }

  void enterSelectionMode() {
    for (var item in items) {
      item.isSelected = false;
    }
    items.refresh();
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
    items.refresh();
    selectedCount.value = items.where((e) => e.isSelected).length;
    if (selectedCount.value == 0) {
      isSelectionMode.value = false;
    }
  }

  void selectAll() {
    final allSelected = items.every((e) => e.isSelected);
    for (var item in items) {
      item.isSelected = !allSelected;
    }
    items.refresh();
    selectedCount.value = items.where((e) => e.isSelected).length;
  }

  void markSingleAsRead(NotificationItem item) {
    item.isRead = true;
    items.refresh();
    updateCount();
    _repo.markSingleAsRead(notificationId: item.id);
    _showSnackbar('Marked as read'.tr);
  }

  void markSingleAsUnread(NotificationItem item) {
    item.isRead = false;
    items.refresh();
    updateCount();
    _repo.markSingleAsUnread(notificationId: item.id);
    _showSnackbar('Marked as unread'.tr);
  }

  void deleteSingle(NotificationItem item) {
    items.removeWhere((e) => e.id == item.id);
    items.refresh();
    updateCount();
    _repo.deleteNotification(item.id);
    _showSnackbar('Notification deleted'.tr);
  }

  void markAllAsRead() {
    for (var item in items) {
      item.isRead = true;
    }
    items.refresh();
    updateCount();
    _repo.markAllAsRead();
    _showSnackbar('All marked as read'.tr);
  }

  void markAllAsUnread() {
    for (var item in items) {
      item.isRead = false;
      _repo.markSingleAsUnread(notificationId: item.id);
    }
    items.refresh();
    updateCount();
    _showSnackbar('All marked as unread'.tr);
  }

  void deleteAll() {
    final count = items.length;
    final ids = items.map((e) => e.id).toList();
    items.clear();
    items.refresh();
    updateCount();
    for (var id in ids) {
      _repo.deleteNotification(id);
    }
    _showSnackbar('$count notifications deleted'.tr);
  }

  void deleteSelected() {
    final selectedItems = items.where((e) => e.isSelected).toList();
    final count = selectedItems.length;
    for (var item in selectedItems) {
      _repo.deleteNotification(item.id);
    }
    items.removeWhere((e) => e.isSelected);
    items.refresh();
    exitSelectionMode();
    updateCount();
    _showSnackbar('$count deleted'.tr);
  }

  void markSelectedAsRead() {
    for (var item in items) {
      if (item.isSelected) {
        item.isRead = true;
        _repo.markSingleAsRead(notificationId: item.id);
      }
    }
    items.refresh();
    exitSelectionMode();
    updateCount();
    _showSnackbar('Marked as read'.tr);
  }

  void markSelectedAsUnread() {
    for (var item in items) {
      if (item.isSelected) {
        item.isRead = false;
        _repo.markSingleAsUnread(notificationId: item.id);
      }
    }
    items.refresh();
    exitSelectionMode();
    updateCount();
    _showSnackbar('Marked as unread'.tr);
  }
}
