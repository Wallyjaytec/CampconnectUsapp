import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/data/repositories/compare_repository.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/cart_sheet_launcher.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../search/model/search_model.dart' as search;
import '../controller/compare_controller.dart';
import '../model/compare_model.dart';

class CompareView extends StatelessWidget {
  const CompareView({super.key});

  static const double _wLabel = 100;
  static const double _hSearch = 56;
  static const double _hImage = 200;
  static const double _hRow = 46;
  static const double _hBtn = 56;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final controller = Get.isRegistered<CompareController>()
        ? Get.find<CompareController>()
        : Get.put(CompareController(CompareRepository(ApiService()), ApiService()), permanent: true);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, centerTitle: false, titleSpacing: 10,
          title: Text('Compare Products'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
        ),
        body: Obx(() {
          if (controller.isLoadingTable.value) return const _CompareTableShimmer();
          if (controller.compareList.isEmpty) return emptyPicker(controller: controller);

          final labels = <String>['Search', 'Image', 'Title', 'Brand', 'Category', 'Price', 'Rating', 'Summary', 'Availability', 'Warranty', 'Authentic', 'Refund', 'Cash on Delivery', 'Add To Cart'];

          double rowHeightFor(String label) {
            if (label == 'Search') return _hSearch;
            if (label == 'Image') return _hImage;
            if (label == 'Summary') return _hRow * 2;
            if (label == 'Add To Cart') return _hBtn;
            return _hRow;
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _wLabel,
                    decoration: BoxDecoration(color: isDark ? AppColors.darkBackgroundColor : AppColors.lightBackgroundColor, border: Border(right: BorderSide(color: Colors.grey.shade300))),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final label in labels) _labelCell(label.tr, height: rowHeightFor(label), showDivider: true),
                      ]),
                    ),
                  ),
                  for (int i = 0; i < controller.compareList.length; i++)
                    Container(
                      width: 220,
                      decoration: BoxDecoration(color: isDark ? AppColors.darkBackgroundColor : AppColors.lightBackgroundColor, border: Border(right: BorderSide(color: Colors.grey.shade300))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final label in labels)
                          (label == 'Search')
                              ? _SearchInputCell(height: _hSearch, columnIndex: i, onChanged: (q) => controller.querySuggestions(i, q), onSubmitted: (q) => controller.querySuggestions(i, q), onPick: (id) => controller.replaceAt(i, id))
                              : _valueCell(label: label, product: controller.compareList[i], height: rowHeightFor(label), ctrl: controller, columnIndex: i),
                      ]),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget emptyPicker({required CompareController controller}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/icons/compare_product.png', width: 100, height: 100),
            const SizedBox(height: 24),
            Text('Compare Products'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Add products to compare their features, prices, and specifications side by side. Tap the compare icon on any product to get started.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            _PickerInput(
              hint: 'Search product to compare'.tr,
              onChanged: (q) => controller.querySuggestions(0, q),
              suggestionsBuilder: () => controller.suggestions[0] ?? const [],
              loading: () => controller.isSuggestLoading[0] == true,
              onPick: (p) => controller.selectSuggestionFor(0, p),
              pickedIdListenable: controller.pickedId0,
              onClearPicked: () => controller.clearPick(0),
            ),
            const SizedBox(height: 10),
            _PickerInput(
              hint: 'Search product to compare'.tr,
              onChanged: (q) => controller.querySuggestions(1, q),
              suggestionsBuilder: () => controller.suggestions[1] ?? const [],
              loading: () => controller.isSuggestLoading[1] == true,
              onPick: (p) => controller.selectSuggestionFor(1, p),
              pickedIdListenable: controller.pickedId1,
              onClearPicked: () => controller.clearPick(1),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48, width: double.infinity,
              child: Obx(() {
                final enabled = controller.pickedId0.value != null && controller.pickedId1.value != null && controller.pickedId0.value != controller.pickedId1.value;
                return ElevatedButton.icon(
                  onPressed: enabled ? controller.comparePicked : null,
                  icon: const Icon(Iconsax.arrow_swap_horizontal_copy, size: 18),
                  label: Text('Compare'.tr),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelCell(String text, {required double height, bool showDivider = false}) {
    return Column(children: [
      Container(height: height, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      if (showDivider) Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
    ]);
  }

  Widget _valueCell({required String label, required CompareItemModel product, required double height, required CompareController ctrl, required int columnIndex}) {
    Widget child;
    switch (label) {
      case 'Image':
        child = Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: AppConfig.assetUrl(product.thumbnailImage), width: double.infinity, height: _hImage - 16, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Iconsax.gallery_remove_copy))));
        break;
      case 'Title': child = Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis); break;
      case 'Brand': child = Text(product.brand ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis); break;
      case 'Category': child = Text(product.category?.toString().isEmpty == true ? '-' : product.category!, maxLines: 2, overflow: TextOverflow.ellipsis); break;
      case 'Price':
        final hasDiscount = (product.price != product.basePrice);
        child = Row(children: [Text(formatCurrency(product.price, applyConversion: true)), const SizedBox(width: 6), if (hasDiscount) Text(formatCurrency(product.basePrice, applyConversion: true), style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey))]);
        break;
      case 'Rating': child = Row(children: [const Icon(Icons.star, size: 16, color: Colors.amber), const SizedBox(width: 6), Text(product.avgRating.toString())]); break;
      case 'Summary': final text = _htmlToPlain(product.summary); child = Text(text.isEmpty ? '-' : text, maxLines: 3, overflow: TextOverflow.ellipsis); break;
      case 'Availability': child = Text(product.quantity > 0 ? '${'In Stock'.tr} (${product.quantity})' : 'Stock out'.tr); break;
      case 'Warranty': child = Text(product.hasWarranty ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis); break;
      case 'Authentic': child = Text(product.isAuthentic ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis); break;
      case 'Refund': child = Text(product.isRefundable ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis); break;
      case 'Cash on Delivery': child = Text(product.isActiveCod ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis); break;
      case 'Add To Cart':
        child = Row(children: [
          Expanded(child: SizedBox(height: _hBtn - 16, child: ElevatedButton(onPressed: () async { await CartSheetLauncher.openByPermalink(product.slug); }, child: Text('Add To Cart'.tr)))),
          const SizedBox(width: 8),
          SizedBox(height: _hBtn - 16, width: 44, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.zero, minimumSize: const Size(44, _hBtn - 16), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))).merge(const ButtonStyle(alignment: Alignment.center)), onPressed: () => ctrl.removeFromCompareByIndex(columnIndex), child: const Icon(Iconsax.trash_copy, size: 18, color: Colors.white))),
        ]);
        break;
      default: child = const SizedBox();
    }
    return Column(children: [
      Container(height: height, padding: const EdgeInsets.symmetric(horizontal: 10), alignment: Alignment.centerLeft, child: child),
      Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
    ]);
  }
}

class _SearchInputCell extends StatefulWidget {
  final double height; final int columnIndex;
  final void Function(String)? onChanged; final void Function(String)? onSubmitted; final void Function(int productId)? onPick;
  const _SearchInputCell({required this.height, required this.columnIndex, this.onChanged, this.onSubmitted, this.onPick});
  @override State<_SearchInputCell> createState() => _SearchInputCellState();
}

class _SearchInputCellState extends State<_SearchInputCell> {
  final _controller = TextEditingController(); final _focus = FocusNode(); bool _showClear = false;
  @override void initState() { super.initState(); _focus.addListener(_updateSuffix); _controller.addListener(_updateSuffix); }
  void _updateSuffix() { final shouldShow = _focus.hasFocus || _controller.text.isNotEmpty; if (shouldShow != _showClear) setState(() => _showClear = shouldShow); }
  @override void dispose() { _controller.dispose(); _focus.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark; final ctrl = Get.find<CompareController>(); final col = widget.columnIndex;
    return Column(children: [
      SizedBox(height: widget.height, child: Padding(padding: const EdgeInsets.all(8.0), child: TextFormField(
        controller: _controller, focusNode: _focus, cursorColor: AppColors.primaryColor, keyboardType: TextInputType.text, style: const TextStyle(fontSize: 14), textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true, filled: true, fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          hintText: 'Search product to compare'.tr, hintStyle: const TextStyle(fontSize: 14, color: AppColors.greyColor, fontWeight: FontWeight.normal),
          prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18), prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: _showClear ? InkWell(onTap: () { _controller.clear(); ctrl.suggestions[col] = const []; ctrl.suggestions.refresh(); _focus.requestFocus(); }, child: const Icon(Iconsax.close_circle_copy, size: 16)) : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40), contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        textInputAction: TextInputAction.search, onChanged: widget.onChanged, onFieldSubmitted: widget.onSubmitted,
      ))),
      Obx(() {
        final loading = ctrl.isSuggestLoading[col] == true; final List<search.ProductModel> list = (ctrl.suggestions[col] ?? const []);
        if (!_focus.hasFocus && list.isEmpty && !loading) return Divider(height: 1, thickness: 1, color: Colors.grey.shade300);
        return Column(children: [
          if (loading) const _ShimmerSuggestions(),
          if (!loading && list.isNotEmpty)
            Container(constraints: const BoxConstraints(maxHeight: 220), margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.whiteColor, borderRadius: BorderRadius.circular(8)),
              child: ListView.separated(shrinkWrap: true, itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(),
                itemBuilder: (_, idx) {
                  final s = list[idx];
                  return ListTile(dense: true, leading: (s.thumbnailImage.isEmpty) ? const Icon(Icons.image_not_supported_outlined, size: 20) : ClipRRect(borderRadius: BorderRadius.circular(4), child: CachedNetworkImage(imageUrl: AppConfig.assetUrl(s.thumbnailImage), width: 32, height: 32, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Iconsax.gallery_remove_copy, size: 20))),
                    title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    onTap: () { if (s.id <= 0) return; widget.onPick?.call(s.id); _controller.clear(); _focus.unfocus(); });
                })),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        ]);
      }),
    ]);
  }
}

class _PickerInput extends StatefulWidget {
  final String hint; final void Function(String) onChanged; final List Function() suggestionsBuilder; final bool Function() loading; final void Function(search.ProductModel product) onPick; final RxnInt pickedIdListenable; final VoidCallback onClearPicked;
  const _PickerInput({required this.hint, required this.onChanged, required this.suggestionsBuilder, required this.loading, required this.onPick, required this.pickedIdListenable, required this.onClearPicked});
  @override State<_PickerInput> createState() => _PickerInputState();
}

class _PickerInputState extends State<_PickerInput> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final picked = widget.pickedIdListenable.value; final bool isLoading = widget.loading(); final List<search.ProductModel> sugg = (widget.suggestionsBuilder()).cast<search.ProductModel>();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _controller, onChanged: widget.onChanged, textInputAction: TextInputAction.search, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          decoration: InputDecoration(isDense: true, hintText: widget.hint, hintStyle: const TextStyle(color: AppColors.greyColor, fontWeight: FontWeight.normal, fontSize: 14),
            prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18),
            suffixIcon: picked != null ? IconButton(icon: const Icon(Iconsax.close_circle_copy, size: 18), onPressed: () { widget.onClearPicked(); _controller.clear(); }) : null,
            filled: true, fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        if (isLoading) const _ShimmerSuggestions(),
        if (!isLoading && sugg.isNotEmpty && picked == null)
          Container(margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.whiteColor, borderRadius: BorderRadius.circular(8)), constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(shrinkWrap: true, itemCount: sugg.length, itemBuilder: (_, i) {
              final p = sugg[i];
              return ListTile(dense: true, leading: (p.thumbnailImage.isEmpty) ? const Icon(Icons.image_outlined, size: 20) : ClipRRect(borderRadius: BorderRadius.circular(4), child: CachedNetworkImage(imageUrl: AppConfig.assetUrl(p.thumbnailImage), width: 32, height: 32, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Iconsax.gallery_remove_copy, size: 20))),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () { widget.onPick(p); _controller.text = p.name; FocusScope.of(context).unfocus(); });
            })),
      ]);
    });
  }
}

class _ShimmerSuggestions extends StatelessWidget {
  const _ShimmerSuggestions();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(baseColor: isDark ? AppColors.darkCardColor : AppColors.greyColor, highlightColor: isDark ? AppColors.greyColor : AppColors.whiteColor,
      child: Column(children: List.generate(4, (i) => i).map((_) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10), Expanded(child: Container(height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
      ]))).toList()));
  }
}

class _CompareTableShimmer extends StatelessWidget {
  const _CompareTableShimmer();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(baseColor: isDark ? AppColors.darkCardColor : AppColors.greyColor, highlightColor: isDark ? AppColors.greyColor : AppColors.whiteColor,
      child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: 12, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10), Expanded(child: Container(height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
      ]))));
  }
}

String _htmlToPlain(String? html) {
  if (html == null || html.isEmpty) return '-';
  final noTags = html.replaceAll(RegExp(r'<[^>]*>'), '');
  return noTags.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&#39;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>').trim();
}a
