import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../controller/seller_bottom_navbar_controller.dart';

class SellerBottomNavbar extends StatelessWidget {
  const SellerBottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerBottomNavbarController());

    return Obx(
      () => Scaffold(
        body: controller.screens[controller.currentIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) {
            controller.currentIndex.value = index;
          },
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.home_1_copy),
              label: 'Home'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.shopping_bag_copy),
              label: 'Products'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Iconsax.message_copy),
              label: 'Reviews'.tr,
            ),
          ],
        ),
      ),
    );
  }
}
