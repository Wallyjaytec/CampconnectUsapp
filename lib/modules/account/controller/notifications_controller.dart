import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../core/utils/link_mapper.dart';
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
      final res = await _repo.fetchUnreadNotifications();
      items.assignAll(res.notifications);
      notificationCount.value = items.length;
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
      final res = await _repo.fetchUnreadNotifications();
      items.assignAll(res.notifications);
      notificationCount.value = items.length;
    } catch (_) {
    } finally {
      isRefreshing.value = false;
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
      Get.snackbar(
        'Success'.tr,
        'All notifications marked as read'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } else {
      Get.snackbar(
        'Failed'.tr,
        'Could not mark all as read'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
  }

  Future<void> onTapNotification(NotificationItem item) async {
    final res = await _repo.markSingleAsRead(notificationId: item.id);
    if (res.success) {
      item.isRead = true;
      items.refresh();
      notificationCount.value = items.where((e) => !e.isRead).length;
    }
    Get.to(() => NotificationDetailView(item: item));
  }

  Future<bool> deleteNotification(String id) async {
    final success = await _repo.deleteNotification(id);
    if (success) {
      items.removeWhere((e) => e.id == id);
      notificationCount.value = items.where((e) => !e.isRead).length;
      Get.snackbar(
        'Deleted'.tr,
        'Notification deleted'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    }
    return success;
  }

  // Selection mode methods
  void toggleSelection(NotificationItem item) {
    item.isSelected = !item.isSelected;
    items.refresh();
    selectedCount.value = items.where((e) => e.isSelected).length;
    isSelectionMode.value = selectedCount.value > 0;
  }

  void selectAll() {
    for (var item in items) {
      item.isSelected = true;
    }
    items.refresh();
    selectedCount.value = items.length;
    isSelectionMode.value = true;
  }

  void clearSelection() {
    for (var item in items) {
      item.isSelected = false;
    }
    items.refresh();
    selectedCount.value = 0;
    isSelectionMode.value = false;
  }

  Future<void> deleteSelected() async {
    final selectedIds = items.where((e) => e.isSelected).map((e) => e.id).toList();
    for (var id in selectedIds) {
      await _repo.deleteNotification(id);
    }
    items.removeWhere((e) => e.isSelected);
    clearSelection();
    notificationCount.value = items.where((e) => !e.isRead).length;
    Get.snackbar(
      'Deleted'.tr,
      '${selectedIds.length} notifications deleted'.tr,
      backgroundColor: AppColors.primaryColor,
      snackPosition: SnackPosition.TOP,
      colorText: AppColors.whiteColor,
    );
  }

  Future<void> markSelectedAsRead() async {
    final selectedIds = items.where((e) => e.isSelected).map((e) => e.id).toList();
    for (var id in selectedIds) {
      await _repo.markSingleAsRead(notificationId: id);
    }
    for (var item in items) {
      if (item.isSelected) {
        item.isRead = true;
      }
    }
    items.refresh();
    clearSelection();
    notificationCount.value = items.where((e) => !e.isRead).length;
    Get.snackbar(
      'Success'.tr,
      '${selectedIds.length} notifications marked as read'.tr,
      backgroundColor: AppColors.primaryColor,
      snackPosition: SnackPosition.TOP,
      colorText: AppColors.whiteColor,
    );
  }

  Future<void> markSelectedAsUnread() async {
    final selectedIds = items.where((e) => e.isSelected).map((e) => e.id).toList();
    for (var item in items) {
      if (item.isSelected) {
        item.isRead = false;
      }
    }
    items.refresh();
    clearSelection();
    notificationCount.value = items.where((e) => !e.isRead).length;
    Get.snackbar(
      'Success'.tr,
      '${selectedIds.length} notifications marked as unread'.tr,
      backgroundColor: AppColors.primaryColor,
      snackPosition: SnackPosition.TOP,
      colorText: AppColors.whiteColor,
    );
  }
}
