import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/routes/app_routes.dart';

class BackIconWidget extends StatelessWidget {
  const BackIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: () {
          final nav = Navigator.of(context);

          if (nav.canPop()) {
            nav.pop();
            return;
          }

          final canPopGet = Get.key.currentState?.canPop() ?? false;
          if (canPopGet) {
            Get.back();
            return;
          }

          Get.offAllNamed(AppRoutes.bottomNavbarView);
        },
        icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
        splashRadius: 20,
      ),
    );
  }
}
