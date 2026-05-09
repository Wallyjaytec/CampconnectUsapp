import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../product/model/product_details_model.dart';
import '../controller/add_to_cart_controller.dart';

class AddToCartSheet extends GetView<AddToCartController> {
  const AddToCartSheet({
    super.key,
    required this.controllerTag,
    required this.p,
  });

  final String controllerTag;
  final ProductDetailsModel p;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = controller;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double maxSheetHeight = screenHeight * 0.85;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  _HeaderBlock(p: p, c: c),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Obx(
                        () => Text(
                          '${c.displayStock} ${'In Stock'.tr}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (c.hasVariations)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: c.variationGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _VariationGroupView(
                        group: c.variationGroups[i],
                        controllerTag: controllerTag,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Text(
                          'Quantity'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        _QtyBtn(icon: Iconsax.minus_copy, onTap: c.dec),
                        const SizedBox(width: 10),
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Obx(() => Text('${c.qty.value}')),
                        ),
                        const SizedBox(width: 10),
                        _QtyBtn(icon: Iconsax.add_copy, onTap: c.inc),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Text(
                          'Total Price'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Obx(
                          () => Text(
                            formatCurrency(
                              c.totalEffective,
                              applyConversion: true,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if ((p.attachmentTitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _AttachmentPickerSection(
                      title: p.attachmentTitle!,
                      controllerTag: controllerTag,
                    ),
                  ],

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // FIXED: Buttons with loading state
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Obx(() => ElevatedButton(
                        onPressed: c.isAdding.value ? null : c.buyNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightBlueColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: c.isAdding.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Buy Now'.tr),
                      )),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Obx(() => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: c.isAdding.value ? null : c.addToCartAndClose,
                        child: c.isAdding.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Add To Cart'.tr),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({required this.p, required this.c});
  final ProductDetailsModel p;
  final AddToCartController c;

  @override
  Widget build(BuildContext context) {
    final String name = (p.name).toString();
    final double rating = p.rating;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Obx(() {
            final img = c.currentImageUrl.value;
            return CachedNetworkImage(
              imageUrl: img,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox(
                width: 64,
                height: 64,
                child: Icon(Iconsax.gallery_remove_copy),
              ),
            );
          }),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                final double? minPrice = (p.priceRangeMin is num)
                    ? (p.priceRangeMin as num).toDouble()
                    : null;
                final double? maxPrice = (p.priceRangeMax is num)
                    ? (p.priceRangeMax as num).toDouble()
                    : null;
                final double? minOld = (p.priceRangeMinOld is num)
                    ? (p.priceRangeMinOld as num).toDouble()
                    : null;
                final double? maxOld = (p.priceRangeMaxOld is num)
                    ? (p.priceRangeMaxOld as num).toDouble()
                    : null;
                final bool showRange =
                    c.shouldShowRange &&
                    minPrice != null &&
                    maxPrice != null &&
                    maxPrice > minPrice;

                final price = c.effectivePrice;
                final old = c.effectiveOldPrice;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showRange) ...[
                      if (minOld != null && maxOld != null)
                        Text(
                          '${formatCurrency(minPrice, applyConversion: true)} – ${formatCurrency(maxPrice, applyConversion: true)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                            height: 1.2,
                          ),
                        ),
                      Text(
                        '${formatCurrency(minOld, applyConversion: true)} – ${formatCurrency(maxOld, applyConversion: true)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          decoration: TextDecoration.lineThrough,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Text(
                          formatCurrency(price, applyConversion: true),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (old != null)
                          Text(
                            formatCurrency(old, applyConversion: true),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.primaryColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _VariationGroupView extends GetView<AddToCartController> {
  const _VariationGroupView({required this.group, required this.controllerTag});
  final VariationGroup group;
  final String controllerTag;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    final title = group.name;
    final opts = group.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (group.required)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opts.map((o) {
              final selected = controller.isSelected(group.name, o.id);
              return _RoundChoice(
                label: o.label,
                imageUrl: o.imageUrl,
                hex: o.hex,
                selected: selected,
                onTap: () => controller.selectVariation(group.name, o.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RoundChoice extends StatelessWidget {
  const _RoundChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageUrl,
    this.hex,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? hex;

  static const double _rectChipWidth = 70;
  static const double _rectChipHeight = 36;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImg = (imageUrl ?? '').trim().isNotEmpty;
    final validHex =
        hex != null &&
        RegExp(r'^[#]?[0-9a-fA-F]{6}$').hasMatch(hex!.replaceAll('#', ''));

    final onlyLabel = !hasImg && !validHex;

    if (onlyLabel) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: _rectChipWidth,
          height: _rectChipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? AppColors.primaryColor.withValues(alpha: 0.08)
                : isDark
                ? AppColors.darkBackgroundColor
                : AppColors.primaryColor.withValues(alpha: 0.04),
            border: Border.all(
              color: selected
                  ? AppColors.primaryColor
                  : const Color(0xFFD1D5DB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.primaryColor
                        : isDark
                        ? AppColors.whiteColor
                        : AppColors.blackColor,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
              ],
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: hasImg
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        AppConfig.assetUrl(imageUrl!),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: hasImg
                  ? null
                  : (validHex ? _hexToColor(hex!) : const Color(0xFFE5E7EB)),
              border: Border.all(
                color: selected
                    ? AppColors.primaryColor
                    : const Color(0xFFD1D5DB),
                width: selected ? 2 : 1,
              ),
            ),
          ),
          if (selected)
            const Positioned(
              right: -2,
              bottom: -2,
              child: Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Color _hexToColor(String v) {
    final s = v.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }
}

class _AttachmentPickerSection extends GetView<AddToCartController> {
  const _AttachmentPickerSection({
    required this.title,
    required this.controllerTag,
  });

  final String title;
  final String controllerTag;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Obx(() {
          final c = controller;
          final uploading = c.isUploadingAttachment.value;
          final hasFile = c.attachmentFileId.value != null;
          final fileName = c.attachmentFileName.value;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardColor
                  : AppColors.lightCardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    uploading
                        ? 'Uploading'.tr
                        : (hasFile ? fileName : 'No file chosen'.tr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: uploading
                      ? null
                      : () => c.pickAndUploadAttachment(),
                  child: Text(
                    hasFile ? 'Change'.tr : 'Choose file'.tr,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
