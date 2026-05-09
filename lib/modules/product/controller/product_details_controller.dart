import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartly_e_commerce/modules/product/controller/related_products_controller.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/product_details_repository.dart';
import '../../../data/repositories/product_reviews_repository.dart';
import '../model/product_details_model.dart';
import '../model/product_model.dart';
import '../model/review_model.dart';
import '../view/all_reviews_view.dart';
import '../widgets/add_to_cart_sheet.dart';
import 'add_to_cart_controller.dart';

enum ReviewSort { recent, ratingHigh, ratingLow }

enum QuickSection { overview, reviews, details, recommendations }

class ProductDetailsController extends GetxController {
  ProductDetailsController(this._detailsRepo)
    : _reviewsRepo = ProductReviewsRepository(ApiService());

  final ProductDetailsRepository _detailsRepo;
  final ProductReviewsRepository _reviewsRepo;

  late final String permalink;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rxn<ProductDetailsModel> product = Rxn<ProductDetailsModel>();

  final RxInt galleryIndex = 0.obs;
  final RxBool showQuickBar = false.obs;
  final Rx<QuickSection> activeSection = QuickSection.overview.obs;

  final RxMap<String, String> selected = <String, String>{}.obs;

  final RxBool isLoadingRecent = false.obs;
  final RxList<ProductReview> recentReviews = <ProductReview>[].obs;

  final RxBool isLoadingAll = false.obs;
  final RxList<ProductReview> allReviews = <ProductReview>[].obs;
  final Rx<ReviewSort> reviewSort = ReviewSort.recent.obs;

  int _allPage = 1;
  int _allLastPage = 1;
  final RxInt reviewsTotal = 0.obs;

  static const int idxGallery = 0;
  static const int idxOverview = 1;
  static const int idxQuickConnect = 2;
  static const int idxReviews = 3;
  static const int idxSeller = 4;
  static const int idxDetails = 5;
  static const int idxRecommendations = 6;

  bool _isSheetOpen = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    permalink =
        (args is Map && (args['permalink'] != null || args['slug'] != null))
        ? (args['permalink'] ?? args['slug']).toString()
        : '';
    if (permalink.isEmpty) {
      error.value = 'Invalid product permalink.';
    } else {
      load();
    }
  }

  bool get hasVariationsProduct {
    final p = product.value;
    if (p == null) return false;
    final groupsWithChoice = p.attributes.where((g) => g.options.length > 1);
    return groupsWithChoice.isNotEmpty;
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      final res = await _detailsRepo.fetchByPermalink(permalink);
      product.value = res;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<RelatedProductsController>()) {
          Get.find<RelatedProductsController>().loadFor(res.id);
        }
      });
      await loadRecentReviews();
    } catch (e) {
      error.value = 'Something went wrong';
      product.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecentReviews() async {
    final p = product.value;
    if (p == null) return;
    if (isLoadingRecent.value) return;
    try {
      isLoadingRecent.value = true;
      final page = await _reviewsRepo.fetch(productId: p.id, page: 1, perPage: 5, sorting: 'DESC');
      recentReviews.assignAll(page.items);
      reviewsTotal.value = page.total;
    } catch (e) {
      recentReviews.clear();
    } finally {
      isLoadingRecent.value = false;
    }
  }

  Future<void> loadAllReviews({bool reset = false}) async {
    final p = product.value;
    if (p == null) return;
    if (isLoadingAll.value) return;
    if (reset) { _allPage = 1; _allLastPage = 1; allReviews.clear(); }
    if (_allPage > _allLastPage) return;
    try {
      isLoadingAll.value = true;
      final page = await _reviewsRepo.fetch(productId: p.id, page: _allPage, perPage: 10, sorting: reviewSort.value == ReviewSort.ratingLow ? 'ASC' : 'DESC');
      if (reset) allReviews.clear();
      allReviews.addAll(page.items);
      reviewsTotal.value = page.total;
      _allLastPage = page.lastPage;
      _allPage = page.currentPage + 1;
    } catch (_) {} finally {
      isLoadingAll.value = false;
    }
  }

  void openAllReviews() async {
    await loadAllReviews(reset: allReviews.isEmpty);
    Get.to(const AllReviewsView());
  }

  void setReviewSort(ReviewSort v) async {
    reviewSort.value = v;
    await loadAllReviews(reset: true);
  }

  String get totalReviewsText => formatCount(reviewsTotal.value);

  List<ProductReview> get reviewsByCurrentSort {
    final list = [...allReviews];
    if (reviewSort.value == ReviewSort.ratingHigh) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (reviewSort.value == ReviewSort.ratingLow) {
      list.sort((a, b) => a.rating.compareTo(b.rating));
    } else {
      list.sort((a, b) {
        final at = a.time?.millisecondsSinceEpoch ?? 0;
        final bt = b.time?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    }
    return list;
  }

  bool get canLoadMoreAll => !isLoadingAll.value && _allPage <= _allLastPage;
  void onPageChanged(int i) => galleryIndex.value = i;

  void selectAttr(String groupName, String optionId) {
    selected[groupName] = optionId;
    update();
  }

  bool get allRequiredSelected {
    final p = product.value;
    if (p == null) return false;
    final reqGroups = p.attributes.where((g) => g.required).toList();
    if (reqGroups.isEmpty) return selected.isNotEmpty;
    for (final g in reqGroups) if ((selected[g.name] ?? '').isEmpty) return false;
    return true;
  }

  bool isSelected(String groupName, String optionId) => selected[groupName] == optionId;

  double get effectivePrice {
    final p = product.value;
    if (p == null) return 0.0;
    if (p.selectedVariant?.price != null) return p.selectedVariant!.price!;
    if (allRequiredSelected) {
      for (final g in p.attributes) {
        final pick = selected[g.name];
        if (pick == null) continue;
        final opt = g.options.firstWhereOrNull((o) => o.id == pick);
        if (opt?.price != null) return opt!.price!;
      }
    }
    return p.price;
  }

  double? get effectiveOldPrice {
    final p = product.value;
    if (p == null) return null;
    if (p.selectedVariant?.oldPrice != null && p.selectedVariant!.oldPrice! > effectivePrice) return p.selectedVariant!.oldPrice!;
    if (allRequiredSelected) {
      for (final g in p.attributes) {
        final pick = selected[g.name];
        if (pick == null) continue;
        final opt = g.options.firstWhereOrNull((o) => o.id == pick);
        if (opt?.oldPrice != null && opt!.oldPrice! > effectivePrice) return opt.oldPrice!;
      }
    }
    return (p.oldPrice != null && p.oldPrice! > effectivePrice) ? p.oldPrice : null;
  }

  bool get shouldShowRange {
    final p = product.value;
    if (p == null) return false;
    final hasRange = (p.priceRangeMin != null && p.priceRangeMax != null && p.priceRangeMax! > p.priceRangeMin!);
    return p.hasVariant && hasRange && !allRequiredSelected;
  }

  String get rangeText {
    final p = product.value;
    if (p == null) return '';
    final min = p.priceRangeMin ?? p.price;
    final max = p.priceRangeMax ?? p.price;
    return '${formatCurrency(min, applyConversion: true)} – ${formatCurrency(max, applyConversion: true)}';
  }

  Future<void> shareProduct(BuildContext context) async {
    final p = product.value;
    if (p == null) return;
    final priceText = formatCurrency(effectivePrice, applyConversion: true);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
    await SharePlus.instance.share(ShareParams(text: '${p.name} — $priceText\n${p.url}', subject: p.name, sharePositionOrigin: origin));
  }

  void addToCompare() {
    final p = product.value;
    if (p == null) return;
    Get.snackbar('Compare', '${p.name} added to compare list', snackPosition: SnackPosition.TOP, backgroundColor: AppColors.primaryColor, colorText: AppColors.whiteColor);
  }

  void openAllReviewsScreen() => openAllReviews();

  void openAddToCartSheet() {
    if (_isSheetOpen) return;
    _isSheetOpen = true;

    final p = product.value;
    if (p == null) {
      _isSheetOpen = false;
      return;
    }

    final safeName = (p.name).toString();
    final safePrice = p.price;
    final safeRating = p.rating;
    final safeQty = p.quantity;
    final String img = (p.galleryImages.isNotEmpty) ? (p.galleryImages.first.imageUrl) : '';

    final groups = p.attributes.map((g) {
      final backendKey = (g.id).toString().trim();
      return VariationGroup(name: g.name, backendKey: backendKey, required: g.required,
        options: g.options.map((o) {
          final bool isColorGroup = g.name.toLowerCase().contains('color') || g.id == 'color';
          final String? hex = isColorGroup ? (o.hex?.isNotEmpty == true ? o.hex : (o.valueHex?.isNotEmpty == true ? o.valueHex : (o.value?.isNotEmpty == true ? o.value : null))) : null;
          final String? img = isColorGroup && (o.image?.isNotEmpty == true) ? AppConfig.assetUrl(o.image) : null;
          return VariationOption(id: o.id, label: o.label, hex: hex, imageUrl: img, price: o.price, oldPrice: o.oldPrice);
        }).toList(),
      );
    }).toList();

    final tag = 'add-to-cart-${p.id}-${DateTime.now().millisecondsSinceEpoch}';

    final cartUi = CartUiProduct(id: p.id, title: safeName, imageUrl: img, price: safePrice, rating: safeRating);

    Get.put(AddToCartController(cartUi, details: p, stock: safeQty, groups: groups), tag: tag);

    Get.bottomSheet(
      AddToCartSheet(controllerTag: tag, p: p),
      isScrollControlled: true,
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      enableDrag: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    ).whenComplete(() => _isSheetOpen = false);
  }

  @override
  void onClose() {
    if (Get.isRegistered<RelatedProductsController>()) Get.find<RelatedProductsController>().onClose();
    super.onClose();
  }
}
