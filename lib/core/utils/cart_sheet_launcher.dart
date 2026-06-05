import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:campconnectus_marketplace/data/repositories/product_details_repository.dart';
import 'package:campconnectus_marketplace/modules/product/controller/add_to_cart_controller.dart';
import 'package:campconnectus_marketplace/modules/product/model/product_details_model.dart';

import '../../modules/product/model/product_model.dart';
import '../../modules/product/widgets/add_to_cart_sheet.dart';

class CartSheetLauncher {
  CartSheetLauncher._();

  static Future<void> openByPermalink(String permalink) async {
    if (permalink.trim().isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'Invalid product link'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    final repo = ProductDetailsRepository(ApiService());

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    ProductDetailsModel? p;
    try {
      p = await repo.fetchByPermalink(permalink);
    } catch (_) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar(
        'Error'.tr,
        'Failed to load product details'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
      );
      return;
    } finally {
      if (Get.isDialogOpen == true) Get.back();
    }

    final safeName = (p.name).toString();
    final safePrice = p.price;
    final safeRating = p.rating;
    final safeQty = p.quantity;

    final String img = (p.galleryImages.isNotEmpty)
        ? (p.galleryImages.first.imageUrl)
        : '';

    final groups = p.attributes.map((g) {
      final backendKey = (g.id).toString().trim();
      return VariationGroup(
        name: g.name,
        backendKey: backendKey,
        required: g.required,
        options: g.options.map((o) {
          final bool isColorGroup =
              g.name.toLowerCase().contains('color') || g.id == 'color';

          final String? hex = isColorGroup
              ? (o.hex?.isNotEmpty == true)
                    ? o.hex
                    : (o.valueHex?.isNotEmpty == true)
                    ? o.valueHex
                    : (o.value?.isNotEmpty == true)
                    ? o.value
                    : null
              : null;

          final String? optImg = isColorGroup && (o.image?.isNotEmpty == true)
              ? AppConfig.assetUrl(o.image)
              : null;

          return VariationOption(
            id: o.id,
            label: o.label,
            hex: hex,
            imageUrl: optImg,
            price: o.price,
            oldPrice: o.oldPrice,
          );
        }).toList(),
      );
    }).toList();

    final tag = 'add-to-cart-${p.id}';
    if (Get.isRegistered<AddToCartController>(tag: tag)) {
      Get.delete<AddToCartController>(tag: tag, force: true);
    }

    final cartUi = CartUiProduct(
      id: p.id,
      title: safeName,
      imageUrl: img,
      price: safePrice,
      rating: safeRating,
    );

    Get.put(
      AddToCartController(cartUi, details: p, stock: safeQty, groups: groups),
      tag: tag,
    );

    Get.bottomSheet(
      AddToCartSheet(controllerTag: tag, p: p),
      isScrollControlled: true,
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}
