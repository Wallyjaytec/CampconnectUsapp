import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/utils/currency_formatters.dart';
import 'package:kartly_e_commerce/shared/utils/dialog_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/my_order_details_controller.dart';
import '../controller/return_controller.dart';

class ReturnDialog extends StatelessWidget {
  const ReturnDialog({
    super.key,
    required this.orderId,
    required this.packageId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
  });

  final int orderId;
  final int packageId;
  final String productName;
  final String productImage;
  final double unitPrice;
  final int quantity;

  ReturnController _getController(String tag) {
    if (Get.isRegistered<ReturnController>(tag: tag)) {
      return Get.find<ReturnController>(tag: tag);
    }
    return Get.put(ReturnController(orderId: orderId, packageId: packageId), tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    final tag = 'return-$orderId-$packageId';
    final rc = _getController(tag);

    Widget productHeader() {
      final total = unitPrice * quantity;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: productImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 44, height: 44, color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(unitPrice, applyConversion: true), style: const TextStyle(height: 1)),
                Text('${'Qty'.tr}: $quantity'),
                Text('${'Total'.tr}: ${formatCurrency(total, applyConversion: true)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ],
          ),
        ],
      );
    }

    Widget shimmerBar({double width = 140, double height = 14}) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
        period: const Duration(milliseconds: 1000),
        child: Container(width: width, height: height,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6))),
      );
    }

    Widget reasonDropdown() {
      rc.ensureReasonsLoaded();
      return Obx(() {
        final loading = rc.reasonsLoading.value;
        final items = rc.reasons;
        final dropdownItems = items.map((r) => DropdownMenuItem<int>(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis))).toList();
        final shimmerHint = Row(mainAxisSize: MainAxisSize.min, children: [shimmerBar(width: 120, height: 14)]);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Refund Reason'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Colors.red)),
          ]),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: loading ? null : rc.selectedReasonId.value,
            items: loading ? const [] : dropdownItems,
            onChanged: loading ? null : (v) => rc.selectedReasonId.value = v,
            isExpanded: true,
            icon: const Icon(Iconsax.arrow_down_1_copy, size: 18),
            borderRadius: BorderRadius.circular(8),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: loading ? shimmerHint : Text('Select a reason'.tr),
            disabledHint: shimmerHint,
          ),
        ]);
      });
    }

    Widget commentField() {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Write a comment'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          maxLines: 4,
          onChanged: (v) => rc.comment.value = v,
          decoration: InputDecoration(
            hintText: 'Type here'.tr,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardColor : AppColors.lightCardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ]);
    }

    Widget imagesPicker() {
      return Obx(() {
        final files = rc.images;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 10),
          Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.center, children: [
            ...List.generate(files.length, (i) {
              return Stack(clipBehavior: Clip.none, children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(files[i].path), width: 70, height: 70, fit: BoxFit.cover)),
                Positioned(right: -8, top: -8, child: IconButton(onPressed: () => rc.removeImageAt(i), icon: const Icon(Iconsax.close_circle_copy, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints())),
              ]);
            }),
          ]),
          const SizedBox(height: 10),
          Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(onTap: rc.pickFromGallery, child: const CircleAvatar(radius: 24, backgroundColor: AppColors.primaryColor, child: Icon(Iconsax.gallery_copy, size: 24, color: Colors.white))),
            GestureDetector(onTap: rc.pickFromCamera, child: const CircleAvatar(radius: 24, backgroundColor: AppColors.primaryColor, child: Icon(Iconsax.camera_copy, size: 24, color: Colors.white))),
          ]),
        ]);
      });
    }

    Widget submitBar() {
      return Obx(() => SizedBox(
        width: double.infinity, height: 44,
        child: ElevatedButton(
          onPressed: rc.submitting.value ? null : () async {
            final ok = await rc.submit();
            if (ok) {
              safeBack();
              ScaffoldMessenger.of(Get.context!).showSnackBar(
                SnackBar(content: Text('Return product submitted'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2)),
              );
              try {
                final odc = Get.find<OrderDetailsController>();
                await odc.refreshNow(orderId);
              } catch (_) {}
            } else {
              ScaffoldMessenger.of(Get.context!).showSnackBar(
                SnackBar(content: Text('Could not submit'.tr), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2)),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: rc.submitting.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : Text('Submit'.tr),
        ),
      ));
    }

    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkProductCardColor : AppColors.lightBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Return product'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => safeBack(), icon: const Icon(Iconsax.close_circle_copy)),
            ]),
            const SizedBox(height: 8),
            productHeader(),
            const SizedBox(height: 16),
            reasonDropdown(),
            const SizedBox(height: 8),
            commentField(),
            const SizedBox(height: 8),
            imagesPicker(),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: submitBar()),
          ]),
        ),
      ),
    );
  }
}
