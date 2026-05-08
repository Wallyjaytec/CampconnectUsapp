import 'package:flutter/material.dart';
import 'package:get/get.dart';

void safeBack<T>({T? result}) {
  if (Get.isDialogOpen ?? false) {
    Get.back<T>(result: result);
    return;
  }
  if (Get.overlayContext != null) {
    try {
      Navigator.of(Get.overlayContext!).pop();
      return;
    } catch (_) {}
  }
  try {
    if (Navigator.of(Get.context!).canPop()) {
      Get.back<T>(result: result);
    }
  } catch (_) {}
}
