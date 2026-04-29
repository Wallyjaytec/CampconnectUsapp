import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class SearchIconWidget extends StatelessWidget {
  const SearchIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.searchView),
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(
            Iconsax.search_normal_1_copy,
            size: 20,
            color: AppColors.whiteColor,
          ),
        ),
      ),
    );
  }
}
