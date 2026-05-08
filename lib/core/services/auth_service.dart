import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../../shared/utils/dialog_utils.dart';

class AuthService extends GetxService {
  final RxBool _loggedIn = false.obs;
  final RxBool _dialogBusy = false.obs;

  bool get isLoggedIn => _loggedIn.value;

  void setLoggedIn(bool v) => _loggedIn.value = v;

  Future<bool> ensureLoggedIn() async {
    if (isLoggedIn) return true;

    if (_dialogBusy.value) return false;
    _dialogBusy.value = true;

    final ok = await Get.dialog<bool>(_LoginDialog(), barrierDismissible: false);
    
    _dialogBusy.value = false;

    if (ok == true) {
      Get.toNamed(AppRoutes.loginView);
      return false;
    }
    return false;
  }
}

class _LoginDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Login required'.tr),
      content: Text('You need to login to use wishlist'.tr),
      actions: [
        TextButton(
          onPressed: () => safeBack(result: false),
          child: Text('Cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => safeBack(result: true),
          child: Text('Login'.tr),
        ),
      ],
    );
  }
}
