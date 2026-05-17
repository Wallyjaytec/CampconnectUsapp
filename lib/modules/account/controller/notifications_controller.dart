import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../core/utils/link_mapper.dart';
import '../../../data/repositories/notification_repository.dart';
import '../model/notification_model.dart';
import 'notification_detail_view.dart';

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
      items.clear();
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
    try {
      final res = await _repo.markSingleAsRead(notificationId: item.id);

      if (res.unreadNotifications.isNotEmpty) {
        items.assignAll(res.unreadNotifications);
      } else {
        items.removeWhere((e) => e.id == item.id);
      }
      notificationCount.value = items.length;
    } catch (_) {}

    // Navigate to detail view
    Get.to(() => NotificationDetailView(item: item));
  }
}
