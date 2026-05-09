import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/guest_cart_service.dart';
import '../../../core/services/login_service.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_attachment_repository.dart';
import '../../../data/repositories/product_variant_repository.dart';
import '../../product/model/product_details_model.dart';
import '../model/cart_item_model.dart';
import '../model/product_model.dart';
import 'cart_controller.dart';

class _ShopPick {
  final int id;
  final String name;
  final String slug;
  const _ShopPick({required this.id, required this.name, required this.slug});
}

_ShopPick _pickShop(ProductDetailsModel d) {
  final shop = d.shopInfo;

  return _ShopPick(id: shop.id, name: shop.name, slug: shop.slug);
}

class VariationOption {
  final String id;
  final String? imageUrl;
  final String label;
  final String? hex;
  final double? price;
  final double? oldPrice;
  VariationOption({
    required this.id,
    this.imageUrl,
    required this.label,
    this.hex,
    this.price,
    this.oldPrice,
  });
}

class VariationGroup {
  final String name;
  final String backendKey;
  final List<VariationOption> options;
  final bool required;
  VariationGroup({
    required this.name,
    required this.backendKey,
    required this.options,
    this.required = true,
  });
}

class AddToCartController extends GetxController {
  AddToCartController(
    this.cart, {
    required this.details,
    this.stock = 99,
    List<VariationGroup>? groups,
    ProductVariantRepository? variantRepo,
    CartRepository? cartRepository,
    OrderAttachmentRepository? attachmentRepo,
  }) : variationGroups = groups ?? const [],
       _repo = variantRepo ?? ProductVariantRepository(ApiService()),
       _cartRepo = cartRepository ?? Get.find<CartRepository>(),
                 attachmentRepo =
         attachmentRepo ?? OrderAttachmentRepository(ApiService()) {
  _applyDefaultSelections();
  currentImageUrl.value = _fallbackImage();
}

@override
void onInit() {
  super.onInit();
  _primeVariantPrice();
}

Map<String, dynamic>? orderAttachment;
  
  final CartUiProduct cart;
  final ProductDetailsModel details;
  final int stock;
  final List<VariationGroup> variationGroups;
  final ProductVariantRepository _repo;
  final CartRepository _cartRepo;
  final OrderAttachmentRepository attachmentRepo;

  final RxnInt attachmentFileId = RxnInt();
  final RxString attachmentFileName = ''.obs;
  final RxBool isUploadingAttachment = false.obs;

  final RxString attachmentJson = ''.obs;
  final RxString attachmentPath = ''.obs;

  final RxInt qty = 1.obs;
  final RxMap<String, String> selected = <String, String>{}.obs;

  final RxnDouble _serverPrice = RxnDouble();
  final RxnDouble _serverOldPrice = RxnDouble();
  final RxInt _serverStock = 0.obs;

  final RxString currentImageUrl = ''.obs;
  bool _addingToCart = false;

  bool get shouldShowRange {
    final min = details.priceRangeMin;
    final max = details.priceRangeMax;
    return min != null && max != null;
  }

  double get effectivePrice {
    if (_serverPrice.value != null) return _serverPrice.value!;
    for (final g in variationGroups) {
      final pick = selected[g.name];
      if (pick == null) continue;
      final opt = g.options.firstWhereOrNull((o) => o.id == pick);
      if (opt?.price != null) return opt!.price!;
    }
    final v = details.selectedVariant?.price;
    if (v != null) return v;
    return details.price;
  }

  double? get effectiveOldPrice {
    if (_serverOldPrice.value != null &&
        _serverOldPrice.value! > effectivePrice) {
      return _serverOldPrice.value!;
    }
    for (final g in variationGroups) {
      final pick = selected[g.name];
      if (pick == null) continue;
      final opt = g.options.firstWhereOrNull((o) => o.id == pick);
      if (opt?.oldPrice != null && opt!.oldPrice! > effectivePrice) {
        return opt.oldPrice!;
      }
    }
    final ov = details.selectedVariant?.oldPrice;
    if (ov != null && ov > effectivePrice) return ov;
    if (details.oldPrice != null && details.oldPrice! > effectivePrice) {
      return details.oldPrice;
    }
    return null;
  }

  double get totalEffective => effectivePrice * qty.value;

  bool get isAttachmentRequired =>
      (details.attachmentTitle ?? '').trim().isNotEmpty;

  bool get hasAttachment => attachmentFileId.value != null;

  void inc() {
    final maxStock = _serverStock.value > 0 ? _serverStock.value : stock;
    if (qty.value < maxStock) {
      qty.value++;
      qty.refresh();
    }
  }

  void dec() {
    if (qty.value > 1) {
      qty.value--;
      qty.refresh();
    }
  }

  void selectVariation(String groupName, String optionId) async {
    final old = selected[groupName];
    if (old == optionId) return;

    selected[groupName] = optionId;
    selected.refresh();

    final g = variationGroups.firstWhereOrNull((x) => x.name == groupName);
    final o = g?.options.firstWhereOrNull((x) => x.id == optionId);
    _setImageIfNonEmpty(o?.imageUrl);

    await _hitVariantInfoApi(groupName);
    if (groupName.trim().toLowerCase() == 'color') {
      await _maybeUpdateColorImages();
    }
    qty.refresh();
  }

  bool isSelected(String groupName, String optionId) =>
      selected[groupName] == optionId;

  bool get hasVariations => variationGroups.isNotEmpty;

  bool get _variationsOk {
    for (final g in variationGroups) {
      if (g.required &&
          (selected[g.name] == null || selected[g.name]!.isEmpty)) {
        return false;
      }
    }
    return true;
  }

  bool get canAddToCart =>
      _variationsOk &&
      (!isAttachmentRequired || attachmentFileId.value != null);

  CartListItem? _findExistingLine(String variantCode) {
    if (!Get.isRegistered<CartController>()) return null;
    final cc = Get.find<CartController>();
    return cc.items.firstWhereOrNull(
      (e) => e.id == details.id && (e.variantCode ?? '') == (variantCode),
    );
  }

  Future<void> pickAndUploadAttachment() async {
    if (!isAttachmentRequired) return;

    try {
      isUploadingAttachment.value = true;

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final fileInfo = result.files.single;
      final path = fileInfo.path;
      if (path == null || path.isEmpty) {
        attachmentFileId.value = null;
        attachmentFileName.value = '';
        orderAttachment = null;
        attachmentJson.value = '';

        Get.snackbar(
          'Attachment'.tr,
          'Selected file has no path'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.redColor,
          colorText: AppColors.whiteColor,
        );
        return;
      }

      final file = File(path);

      final resp = await attachmentRepo.uploadOrderAttachment(file);

      if (!resp.success || resp.fileId == null) {
        attachmentFileId.value = null;
        attachmentFileName.value = '';
        orderAttachment = null;
        attachmentJson.value = '';
        attachmentPath.value = '';

        Get.snackbar(
          'Attachment'.tr,
          'Failed to upload file'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.redColor,
          colorText: AppColors.whiteColor,
        );
        return;
      }

      attachmentFileId.value = resp.fileId;
      attachmentFileName.value = fileInfo.name.isNotEmpty
          ? fileInfo.name
          : (resp.fileName ?? '');
      attachmentPath.value = resp.path ?? '';

      orderAttachment = {
        'file_name': resp.fileName ?? fileInfo.name,
        'file_id': resp.fileId,
        'path': resp.path ?? '',
      };

      attachmentJson.value = jsonEncode({
        'file_name': resp.fileName ?? fileInfo.name,
        'file_id': resp.fileId,
        'path': resp.path ?? '',
      });

      Get.snackbar(
        'Attachment'.tr,
        'File uploaded successfully'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
    } catch (e) {
      attachmentFileId.value = null;
      attachmentFileName.value = '';
      orderAttachment = null;
      attachmentJson.value = '';

      Get.snackbar(
        'Attachment'.tr,
        'Invalid file type'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
      );
    } finally {
      isUploadingAttachment.value = false;
    }
  }

  Future<void> addToCartAndClose() async {
    if (!_variationsOk) {
      final missing = variationGroups.firstWhere(
        (g) =>
            g.required &&
            (selected[g.name] == null || selected[g.name]!.isEmpty),
        orElse: () =>
            VariationGroup(name: 'Option', backendKey: '', options: const []),
      );
      Get.snackbar(
        '${'Select'.tr} ${missing.name}',
        '${'Please choose a'.tr} ${missing.name.toLowerCase()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (isAttachmentRequired && attachmentFileId.value == null) {
      Get.snackbar(
        details.attachmentTitle ?? 'Attachment'.tr,
        'Please upload the required file'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    final maxStock = _serverStock.value > 0 ? _serverStock.value : stock;
    if (maxStock <= 0) {
      Get.snackbar(
        'Out of stock'.tr,
        'This variant is currently unavailable'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (_addingToCart) return;
    _addingToCart = true;

    try {
      final variantText = _buildVariantText();
      final variantCode = _buildVariantCode();
      final unitPrice = effectivePrice;
      final oldPrice = (effectiveOldPrice ?? unitPrice);
      final shop = _pickShop(details);

      final loggedIn = LoginService().isLoggedIn();

      if (loggedIn) {
        final existing = _findExistingLine(variantCode);

        if (existing != null) {
          final mergedQty = (existing.quantity + qty.value).clamp(
            1,
            existing.maxItem,
          );
          final updItem = CartApiItem(
            uid: existing.uid,
            id: details.id,
            name: (details.name).toString(),
            permalink: (details.permalink).toString(),
            image: _bestImage(details),
            variant: variantText.isEmpty ? null : variantText,
            variantCode: variantCode.isEmpty ? null : variantCode,
            quantity: mergedQty,
            unitPrice: unitPrice,
            oldPrice: oldPrice,
            minItem: existing.minItem,
            maxItem: existing.maxItem,
            attachment: orderAttachment,
            seller: shop.id,
            shopName: shop.name,
            shopSlug: shop.slug,
            isAvailable: 1,
            isSelected: true,
          );

          await _cartRepo.updateCartItem(updItem);
        } else {
          final uid = DateTime.now().millisecondsSinceEpoch.toString();
          final newItem = CartApiItem(
            uid: uid,
            id: details.id,
            name: (details.name).toString(),
            permalink: (details.permalink).toString(),
            image: _bestImage(details),
            variant: variantText.isEmpty ? null : variantText,
            variantCode: variantCode.isEmpty ? null : variantCode,
            quantity: qty.value.clamp(1, maxStock),
            unitPrice: unitPrice,
            oldPrice: oldPrice,
            minItem: 1,
            maxItem: maxStock,
            attachment: orderAttachment,
            seller: shop.id,
            shopName: shop.name,
            shopSlug: shop.slug,
            isAvailable: 1,
            isSelected: true,
          );

          await _cartRepo.storeCartItem(newItem);
        }
      } else {
        final payload = CartApiItem(
          uid: '',
          id: details.id,
          name: (details.name).toString(),
          permalink: (details.permalink).toString(),
          image: _bestImage(details),
          variant: variantText.isEmpty ? null : variantText,
          variantCode: variantCode.isEmpty ? null : variantCode,
          quantity: qty.value.clamp(1, maxStock),
          unitPrice: unitPrice,
          oldPrice: oldPrice,
          minItem: 1,
          maxItem: maxStock,
          attachment: orderAttachment,
          seller: shop.id,
          shopName: shop.name,
          shopSlug: shop.slug,
          isAvailable: 1,
          isSelected: true,
        );

        final guest = GuestCartService();
        guest.addOrMerge(payload);
      }

      // Close sheet FIRST
      Navigator.of(Get.context!).pop();

      // Refresh cart AFTER sheet is closed
      Future.delayed(Duration(milliseconds: 500), () {
        if (Get.isRegistered<CartController>()) {
          Get.find<CartController>().refreshFromServer();
        }
      });

      Get.snackbar(
        'Cart'.tr,
        '${'Added'.tr} ${qty.value} ${'items to cart'.tr}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
    } catch (e) {
      Get.snackbar(
        'Cart'.tr,
        'Failed to add to cart'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
      );
    } finally {
      _addingToCart = false;
    }
  }

  Future<void> buyNow() async {
    if (!_variationsOk) {
      final missing = variationGroups.firstWhere(
        (g) =>
            g.required &&
            (selected[g.name] == null || selected[g.name]!.isEmpty),
        orElse: () =>
            VariationGroup(name: 'Option', backendKey: '', options: const []),
      );
      Get.snackbar(
        '${'Select'.tr} ${missing.name}',
        '${'Please choose a'.tr} ${missing.name.toLowerCase()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (isAttachmentRequired && attachmentFileId.value == null) {
      Get.snackbar(
        details.attachmentTitle ?? 'Attachment'.tr,
        'Please upload the required file'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    final maxStock = _serverStock.value > 0 ? _serverStock.value : stock;
    if (maxStock <= 0) {
      Get.snackbar(
        'Out of stock'.tr,
        'This variant is currently unavailable'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
      );
      return;
    }

    if (_addingToCart) return;
    _addingToCart = true;

    try {
      final variantText = _buildVariantText();
      final variantCode = _buildVariantCode();
      final unitPrice = effectivePrice;
      final oldPrice = (effectiveOldPrice ?? unitPrice);
      final shop = _pickShop(details);

      final loggedIn = LoginService().isLoggedIn();

      if (loggedIn) {
        final existing = _findExistingLine(variantCode);

        if (existing != null) {
          final mergedQty = (existing.quantity + qty.value).clamp(
            1,
            existing.maxItem,
          );
          final updItem = CartApiItem(
            uid: existing.uid,
            id: details.id,
            name: (details.name).toString(),
            permalink: (details.permalink).toString(),
            image: _bestImage(details),
            variant: variantText.isEmpty ? null : variantText,
            variantCode: variantCode.isEmpty ? null : variantCode,
            quantity: mergedQty,
            unitPrice: unitPrice,
            oldPrice: oldPrice,
            minItem: existing.minItem,
            maxItem: existing.maxItem,
            attachment: orderAttachment,
            seller: shop.id,
            shopName: shop.name,
            shopSlug: shop.slug,
            isAvailable: 1,
            isSelected: true,
          );

          await _cartRepo.updateCartItem(updItem);
        } else {
          final uid = DateTime.now().millisecondsSinceEpoch.toString();
          final newItem = CartApiItem(
            uid: uid,
            id: details.id,
            name: (details.name).toString(),
            permalink: (details.permalink).toString(),
            image: _bestImage(details),
            variant: variantText.isEmpty ? null : variantText,
            variantCode: variantCode.isEmpty ? null : variantCode,
            quantity: qty.value.clamp(1, maxStock),
            unitPrice: unitPrice,
            oldPrice: oldPrice,
            minItem: 1,
            maxItem: maxStock,
            attachment: orderAttachment,
            seller: shop.id,
            shopName: shop.name,
            shopSlug: shop.slug,
            isAvailable: 1,
            isSelected: true,
          );

          await _cartRepo.storeCartItem(newItem);
        }
      } else {
        final payload = CartApiItem(
          uid: '',
          id: details.id,
          name: (details.name).toString(),
          permalink: (details.permalink).toString(),
          image: _bestImage(details),
          variant: variantText.isEmpty ? null : variantText,
          variantCode: variantCode.isEmpty ? null : variantCode,
          quantity: qty.value.clamp(1, maxStock),
          unitPrice: unitPrice,
          oldPrice: oldPrice,
          minItem: 1,
          maxItem: maxStock,
          attachment: orderAttachment,
          seller: shop.id,
          shopName: shop.name,
          shopSlug: shop.slug,
          isAvailable: 1,
          isSelected: true,
        );

        final guest = GuestCartService();
        guest.addOrMerge(payload);
      }

      // Close sheet first, then navigate
      Navigator.of(Get.context!).pop();
      Future.delayed(Duration(milliseconds: 400), () {
        Get.toNamed(AppRoutes.cartView);
      });
    } catch (e) {
      Get.snackbar(
        'Cart'.tr,
        'Failed to add to cart'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.whiteColor,
      );
    } finally {
      _addingToCart = false;
    }
  }

  void _applyDefaultSelections() {
    if (variationGroups.isNotEmpty) {
      for (final g in variationGroups) {
        if (g.options.isNotEmpty) {
          selected[g.name] = g.options.first.id;
        }
      }
      selected.refresh();
    }
  }

  Map<String, String> _buildSelectionsByBackendKey() {
    final out = <String, String>{};
    for (final g in variationGroups) {
      final picked = selected[g.name];
      if (picked != null && picked.isNotEmpty) {
        if (g.backendKey.isEmpty) {
          continue;
        }
        out[g.backendKey] = picked;
      }
    }
    return out;
  }

  String _buildVariantText() {
    if (variationGroups.isEmpty) return '';
    final parts = <String>[];
    for (final g in variationGroups) {
      final pick = selected[g.name];
      if (pick == null || pick.isEmpty) continue;
      final opt = g.options.firstWhereOrNull((o) => o.id == pick);
      if (opt == null) continue;
      parts.add('${g.name}:${opt.label}');
    }
    return parts.join('/');
  }

  String _buildVariantCode() {
    if (variationGroups.isEmpty) return '';
    final kv = _buildSelectionsByBackendKey();
    if (kv.isEmpty) return '';
    return kv.entries.map((e) => '${e.key}:${e.value}').join('/');
  }

  String _bestImage(ProductDetailsModel d) {
    if (currentImageUrl.value.isNotEmpty) return currentImageUrl.value;
    if (d.galleryImages.isNotEmpty) {
      final s = d.galleryImages.first.imageUrl;
      return AppConfig.assetUrl(s);
    }
    return '';
  }

  Future<void> _primeVariantPrice() async {
    if (variationGroups.isEmpty) return;

    final byKey = _buildSelectionsByBackendKey();
    if (byKey.isEmpty) return;

    String changedBackendKey = 'color';
    if (!byKey.containsKey('color')) {
      changedBackendKey = variationGroups.first.backendKey;
    }

    try {
      final resp = await _repo.fetchVariantInfoByKey(
        productId: details.id,
        selectionsByKey: byKey,
        changedBackendKey: changedBackendKey,
      );

      if (resp.success) {
        _serverPrice.value = resp.basePrice;
        _serverOldPrice.value = resp.oldPrice;
        _serverStock.value = resp.quantity;
        if (_serverStock.value > 0 && qty.value > _serverStock.value) {
          qty.value = _serverStock.value;
        }
      } else {
        _serverPrice.value = null;
        _serverOldPrice.value = null;
        _serverStock.value = 0;
      }
      qty.refresh();
    } catch (e) {
      _serverPrice.value = null;
      _serverOldPrice.value = null;
      _serverStock.value = 0;
      qty.refresh();
    }
  }

  Future<void> _hitVariantInfoApi(String changedGroupLabel) async {
    try {
      final grp = variationGroups.firstWhereOrNull(
        (g) => g.name == changedGroupLabel,
      );
      final changedBackendKey = grp?.backendKey ?? '';
      if (changedBackendKey.isEmpty) {
        _serverPrice.value = null;
        _serverOldPrice.value = null;
        _serverStock.value = 0;
        return;
      }

      final byKey = _buildSelectionsByBackendKey();

      final resp = await _repo.fetchVariantInfoByKey(
        productId: details.id,
        selectionsByKey: byKey,
        changedBackendKey: changedBackendKey,
      );

      if (resp.success) {
        _serverPrice.value = resp.basePrice;
        _serverOldPrice.value = resp.oldPrice;
        _serverStock.value = resp.quantity;

        if (_serverStock.value > 0 && qty.value > _serverStock.value) {
          qty.value = _serverStock.value;
        }
      } else {
        _serverPrice.value = null;
        _serverOldPrice.value = null;
        _serverStock.value = 0;
      }
    } catch (e) {
      _serverPrice.value = null;
      _serverOldPrice.value = null;
      _serverStock.value = 0;
    }
  }

  Future<void> _maybeUpdateColorImages() async {
    try {
      final byKey = _buildSelectionsByBackendKey();
      final resp = await _repo.fetchVariantImagesByKey(
        productId: details.id,
        selectionsByKey: byKey,
      );
      if (resp.success && resp.images.isNotEmpty) {
        final next = (resp.images.first.regular).trim();
        if (next.isNotEmpty) {
          _setImageIfNonEmpty(next);
        }
      }
    } catch (_) {
      final fb = _fallbackImage();
      if (fb.isNotEmpty) currentImageUrl.value = fb;
    }
  }

  bool isValidHex(String? input) {
    if (input == null || input.isEmpty) return false;
    final s = input.replaceAll('#', '');
    final hexRegex = RegExp(r'^[0-9a-fA-F]{6}$');
    return hexRegex.hasMatch(s);
  }

  Color colorFromHex(String hex, {Color fallback = const Color(0xFF999999)}) {
    final s = hex.replaceAll('#', '');
    if (s.length != 6) return fallback;
    return Color(int.parse('FF$s', radix: 16));
  }

  String _fallbackImage() {
    if (details.galleryImages.isNotEmpty) {
      final imgItem = details.galleryImages.firstWhereOrNull(
        (g) => (g.type.toLowerCase() == 'image') && ((g.imageUrl).isNotEmpty),
      );
      if (imgItem != null) {
        return AppConfig.assetUrl(imgItem.imageUrl);
      }
      final vidItem = details.galleryImages.firstWhereOrNull(
        (g) => g.type.toLowerCase() == 'video',
      );
      if (vidItem != null) {
        try {
          final dyn = vidItem as dynamic;
          final thumb = (dyn.thumbnail ?? '').toString();
          if (thumb.isNotEmpty) return AppConfig.assetUrl(thumb);
        } catch (_) {}
      }
    }

    try {
      final dyn = details as dynamic;
      final primary = (dyn.thumbnail ?? dyn.image ?? '').toString();
      if (primary.isNotEmpty) return AppConfig.assetUrl(primary);
    } catch (_) {}

    return '';
  }

  int get stockToShow {
    if (_serverStock.value > 0) return _serverStock.value;

    if (stock > 0) return stock;
    return 0;
  }

  int get displayStock {
    if (_serverStock.value > 0) {
      return _serverStock.value;
    }

    if (stock > 0) {
      return stock;
    }

    return 0;
  }

  bool get isUnlimitedStock => _serverStock.value < 0 || stock < 0;

  void _setImageIfNonEmpty(String? url) {
    final u = (url ?? '').trim();
    if (u.isNotEmpty) {
      currentImageUrl.value = AppConfig.assetUrl(u);
    }
  }
}
