import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class LinkMapper {
  static bool navigateByNotification({
    required String? type,
    required String link,
    int? param,
  }) {
    final path = Uri.parse(link).path.trim();
    final t = (type ?? '').toLowerCase();

    if (t == 'order') {
      final id = param ?? _extractOrderIdFromPath(path);
      if (id != null && id > 0) {
        Get.toNamed(
          AppRoutes.myOrderDetailsView,
          arguments: {'order_id': id, 'from_notification': true},
        );
        return true;
      }
      Get.snackbar('Order'.tr, '	Invalid order id from server'.tr);
      return false;
    }

    if (t == 'wallet') {
      Get.toNamed(AppRoutes.myWalletView);
      return true;
    }

    final m = RegExp(r'^/dashboard/order-details/(\d+)$').firstMatch(path);
    if (m != null) {
      final id = int.tryParse(m.group(1) ?? '');
      if (id != null && id > 0) {
        Get.toNamed(AppRoutes.myOrderDetailsView, arguments: id);
        return true;
      }
    }

    try {
      Get.toNamed(path);
      return true;
    } catch (_) {
      Get.snackbar(
        'Navigation'.tr,
        '${'Unable to open'.tr}: $path',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
      );
      return false;
    }
  }

  static int? _extractOrderIdFromPath(String path) {
    final m = RegExp(r'^/dashboard/order-details/(\d+)$').firstMatch(path);
    return m != null ? int.tryParse(m.group(1) ?? '') : null;
  }
}
