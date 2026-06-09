import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../controller/checkout_controller.dart';
import '../widgets/address_selector.dart';
import '../widgets/bank_payment_dialog.dart';
import '../widgets/pickup_point_selector.dart';

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listKey = GlobalKey<RefreshIndicatorState>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          elevation: 0,
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
          title: Text('Checkout'.tr, style: const TextStyle(fontSize: 18)),
        ),

        body: Obx(() {
          Get.find<CurrencyService>().currentRx.value;

          final loadingScreen = controller.isScreenLoading.value;

          if (loadingScreen) {
            return const _CheckoutFullShimmer();
          }

          final active = controller.activeAddresses;

          final sorted = [...controller.items];
          sorted.sort((a, b) {
            final aNA = controller.notAvailableUids.contains(a.uid) ? 0 : 1;
            final bNA = controller.notAvailableUids.contains(b.uid) ? 0 : 1;
            return aNA.compareTo(bNA);
          });

          return RefreshIndicator(
            key: listKey,
            onRefresh: controller.refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Delivery'.tr),
                      const SizedBox(height: 8),
                      _ModeRadio(
                        label: 'Home Delivery'.tr,
                        selected:
                            controller.deliveryMode.value == DeliveryMode.home,
                        onTap: () =>
                            controller.setDeliveryMode(DeliveryMode.home),
                      ),
                      const SizedBox(height: 6),
                      _ModeRadio(
                        label: 'Collect from Store'.tr,
                        selected:
                            controller.deliveryMode.value ==
                            DeliveryMode.pickup,
                        onTap: () =>
                            controller.setDeliveryMode(DeliveryMode.pickup),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (controller.deliveryMode.value == DeliveryMode.home) ...[
                  AddressSelector(
                    title: 'Shipping Details'.tr,
                    addresses: active,
                    selectedId: controller.selectedShippingId.value,
                    onChanged: controller.setShipping,
                    onAddAddress: () async {
                      await controller.addNewAddress(context);
                    },
                    formatLines: controller.formattedAddressLines,
                  ),
                  const SizedBox(height: 12),
                ],

                if (controller.deliveryMode.value == DeliveryMode.pickup) ...[
                  _SectionCard(
                    child: PickupPointSelector(
                      title:
                          '${'Collect From Store'.tr} (${'Pickup Point'.tr})',
                      points: controller.pickupPoints,
                      selectedId: controller.selectedPickupId.value,
                      onChanged: controller.setPickupPoint,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Billing Details'.tr),
                      const SizedBox(height: 8),
                      Obx(() {
                        final mode = controller.billingMode.value;
                        final isPickup = controller.isPickupSelected;

                        return Column(
                          children: [
                            if (!isPickup) ...[
                              _BillingModeTile(
                                title: 'Same as shipping address'.tr,
                                selected: mode == BillingMode.sameAsShipping,
                                onTap: () => controller.setBillingMode(
                                  BillingMode.sameAsShipping,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            _BillingModeTile(
                              title: isPickup
                                  ? 'Billing Address'.tr
                                  : 'Use a different billing address'.tr,
                              selected: isPickup
                                  ? true
                                  : mode == BillingMode.different,
                              onTap: () => controller.setBillingMode(
                                BillingMode.different,
                              ),
                            ),
                          ],
                        );
                      }),
                      Obx(() {
                        final isPickup = controller.isPickupSelected;
                        final mode = controller.billingMode.value;

                        if (!isPickup && mode == BillingMode.sameAsShipping) {
                          return const SizedBox(height: 8);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: AddressSelector(
                            title: 'Select Billing Address'.tr,
                            addresses: active,
                            selectedId: controller.selectedBillingId.value,
                            onChanged: controller.setBilling,
                            onAddAddress: () async {
                              await controller.addNewAddress(context);
                            },
                            formatLines: controller.formattedAddressLines,
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('${'Products'.tr} (${sorted.length})'),
                      const SizedBox(height: 8),
                      ...List.generate(sorted.length, (i) {
                        final it = sorted[i];
                        final uid = it.uid;
                        final isNA = controller.notAvailableUids.contains(uid);

                        final selected = controller.selectedMethodFor(uid);
                        final selectedCost = selected?.cost;
                        final selectedTitle = selected?.title;
                        final selectedTime = selected?.shippingTime;

                        final attachmentLabel = _attachmentLabelFromRaw(
                          it.attachment,
                        );
                        final attachmentPath = _attachmentPathFromRaw(
                          it.attachment,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CheckoutProductTile(
                                  title: it.name,
                                  imageUrl: it.imageUrl,
                                  variantLine: controller.variantLine(it),
                                  storeName: it.shopName,
                                  unitPriceText: formatCurrency(
                                    it.unitPriceNum,
                                  ),
                                  lineTotalText: formatCurrency(it.lineTotal),
                                  quantity: it.quantity,
                                  isDark: isDark,
                                  attachmentLabel: attachmentLabel,
                                  attachmentPath: attachmentPath,
                                ),
                                const SizedBox(height: 6),

                                if (isNA)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkCardColor
                                          : AppColors.lightCardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white12
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Shipping not available for selected address'
                                                .tr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.redColor,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              controller.removeItemByUid(uid),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: Text(
                                              'Remove'.tr,
                                              style: const TextStyle(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (controller.hasOptionsFor(uid))
                                  InkWell(
                                    onTap: () =>
                                        controller.selectShippingFor(uid),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCardColor
                                            : AppColors.lightCardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.local_shipping_outlined,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              (selectedTitle != null)
                                                  ? '${'Shipping'.tr}: $selectedTitle • ${selectedTime ?? ''}'
                                                  : 'Select shipping option'.tr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            (selectedCost != null)
                                                ? formatCurrency(selectedCost)
                                                : '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Iconsax.arrow_down_1_copy,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (i != sorted.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 8,
                                ),
                                child: Divider(
                                  height: 0,
                                  thickness: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('${'Note'.tr} (${'Optional'.tr})'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.noteCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any instruction for delivery'.tr,
                          isDense: true,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0B1220)
                              : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: Obx(() {
                    final loading = controller.isLoadingPayments.value;
                    final error = controller.paymentError.value;
                    final methods = controller.activePaymentMethods;
                    final selectedId = controller.selectedPaymentMethodId.value;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Payment method'.tr),
                        const SizedBox(height: 8),
                        AbsorbPointer(
                          absorbing: loading,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<int>(
                              buttonStyleData: ButtonStyleData(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardColor
                                      : AppColors.lightCardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                              ),
                              isExpanded: true,
                              items: methods.map((m) {
                                final rawLogoUrl = (m.logo ?? '').trim();
                                final normalizedLogo = AppConfig.assetUrl(
                                  rawLogoUrl,
                                );
                                final hasLogo = rawLogoUrl.isNotEmpty;
                                final instruction = (m.instruction ?? '')
                                    .trim();
                                final hasInstruction = instruction.isNotEmpty;
                                final isBank =
                                    m.name.trim().toLowerCase() == 'bank';

                                return DropdownMenuItem<int>(
  value: m.id,
  child: Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 8.0,
    ),
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Icon(
          (selectedId == m.id)
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
          size: 18,
          color: (selectedId == m.id)
              ? AppColors.primaryColor
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (hasLogo)
                    _NetLogoBox(
                      url: normalizedLogo,
                    ),
                  if (hasLogo)
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (m.name).trim().tr,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasInstruction) ...[
                const SizedBox(height: 2),
                if (isBank)
                  SizedBox(
                    height: 20,
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      child: HtmlWidget(
                        instruction.tr,
                        textStyle:
                            const TextStyle(
                              fontSize: 11,
                              color: AppColors
                                  .greyColor,
                              fontWeight:
                                  FontWeight
                                      .normal,
                            ),
                      ),
                    ),
                  )
                else
                  Text(
                    instruction.tr,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.normal,
                      color:
                          AppColors.greyColor,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  ),
);
                              }).toList(),
                              value: selectedId,
                              hint: Text(
                                'Select Payment method'.tr,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onChanged: (v) {
                                controller.selectedPaymentMethodId.value = v;
                                final m = controller.activePaymentMethods
                                    .firstWhereOrNull((e) => e.id == v);
                                if (m != null &&
                                    m.name.trim().toLowerCase() == 'bank') {
                                  controller.resetBankForm();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (dialogContext) =>
                                        BankPaymentDialog(
                                          controller: controller,
                                        ),
                                  );
                                }
                              },
                              iconStyleData: const IconStyleData(
                                icon: Icon(Iconsax.arrow_down_1_copy),
                                iconSize: 18,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 400,
                                elevation: 2,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkProductCardColor
                                      : AppColors.lightBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 65,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        if (loading) ...[
                          const SizedBox(height: 8),
                          Text('Loading payment methods'.tr),
                        ],
                        if (!loading && error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.isLoadingWallet.value) {
                    return const SizedBox.shrink();
                  }
                  if (controller.walletError.value.isNotEmpty) {
                    return const SizedBox.shrink();
                  }
                  if (controller.walletAvailable.value == null) {
                    return const SizedBox.shrink();
                  }
                  final canPay = controller.canPayWithWallet;
                  if (!canPay) {
                    return const SizedBox.shrink();
                  }
                  return _SectionCard(
                    child: Column(
                      children: [
                        Text(
                          'OR'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'Wallet Balance'.tr} ${controller.walletBalanceText}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: Obx(() {
                            final isLoading = controller.isWalletPaying.value;
                            return ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => controller.payWithWallet(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.whiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Text('Pay with Wallet'.tr),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }),
                SizedBox(height: controller.canPayWithWallet ? 12 : 0),
                _SectionCard(
                  child: Column(
                    children: [
                      _RowLine(
                        'Subtotal'.tr,
                        formatCurrency(controller.subTotal),
                      ),
                      _RowLine('Tax'.tr, formatCurrency(controller.taxTotal)),
                      _RowLine(
                        'Shipping Cost'.tr,
                        formatCurrency(controller.shippingFee),
                      ),
                      const Divider(height: 16, thickness: 2),
                      _RowLine(
                        'Payable Total'.tr,
                        formatCurrency(controller.payableTotal),
                        bold: true,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        bottomNavigationBar: Obx(() {
          final isLoading = controller.isScreenLoading.value;
          if (isLoading) return const _BottomBarShimmer();
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SafeArea(
            top: false,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardColor
                    : AppColors.lightCardColor,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${'Pay'.tr}: ${formatCurrency(controller.payableTotal)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      child: Text(
                        'Place Order'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NetLogoBox extends StatelessWidget {
  const _NetLogoBox({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        height: 30,
        imageUrl: url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorWidget: (context, url, error) => const SizedBox(),
      ),
    );
  }
}

class _ModeRadio extends StatelessWidget {
  const _ModeRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected ? AppColors.primaryColor : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BillingModeTile extends StatelessWidget {
  const _BillingModeTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected ? AppColors.primaryColor : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final ts = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Text(label, style: ts),
          const Spacer(),
          Text(value, style: ts),
        ],
      ),
    );
  }
}

class _CheckoutProductTile extends StatelessWidget {
  const _CheckoutProductTile({
    required this.title,
    required this.imageUrl,
    required this.variantLine,
    required this.storeName,
    required this.unitPriceText,
    required this.lineTotalText,
    required this.quantity,
    required this.isDark,
    this.attachmentLabel,
    this.attachmentPath,
  });

  final String title;
  final String imageUrl;
  final String variantLine;
  final String storeName;
  final String unitPriceText;
  final String lineTotalText;
  final int quantity;
  final bool isDark;
  final String? attachmentLabel;
  final String? attachmentPath;

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _isNetwork
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 56,
                  height: 68,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 56,
                    height: 68,
                    alignment: Alignment.center,
                    color: Colors.black12,
                    child: const Icon(Iconsax.gallery_remove_copy, size: 20),
                  ),
                )
              : Image.asset(imageUrl, width: 56, height: 68, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Text(
                    unitPriceText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '  |  ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    lineTotalText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              if (variantLine.isNotEmpty)
                Text(
                  variantLine,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                        children: <TextSpan>[
                          TextSpan(text: '${'Sold By'.tr}: '),
                          TextSpan(
                            text: storeName.isEmpty ? '—' : storeName,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${'Qty'.tr}: $quantity',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (attachmentLabel != null &&
                  attachmentPath != null &&
                  attachmentPath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: InkWell(
                    onTap: () => _openAttachment(context, attachmentPath),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.document_copy,
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attachmentLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutFullShimmer extends StatelessWidget {
  const _CheckoutFullShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB);
    final highlight = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF3F4F6);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              _shimmerCard(base, highlight, child: _block(base, titleW: 100)),
              const SizedBox(height: 12),
              _shimmerCard(base, highlight, child: _block(base)),
              const SizedBox(height: 12),
              _shimmerCard(base, highlight, child: _block(base)),
              const SizedBox(height: 12),
              _shimmerCard(base, highlight, child: _products(base)),
              const SizedBox(height: 12),
              _shimmerCard(base, highlight, child: _note(base)),
              const SizedBox(height: 12),
              _shimmerCard(base, highlight, child: _summary(base)),
            ],
          ),
        ),
        const _BottomBarShimmer(),
      ],
    );
  }

  static Widget _block(Color base, {double titleW = 120}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line(base, w: titleW, h: 16),
      const SizedBox(height: 12),
      _line(base, w: double.infinity, h: 42, r: 10),
      const SizedBox(height: 8),
      _line(base, w: double.infinity, h: 42, r: 10),
    ],
  );

  static Widget _products(Color base) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line(base, w: 140, h: 16),
      const SizedBox(height: 12),
      _productRow(base),
      const SizedBox(height: 12),
      _productRow(base),
      const SizedBox(height: 12),
      _productRow(base),
    ],
  );

  static Widget _note(Color base) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line(base, w: 140, h: 16),
      const SizedBox(height: 12),
      _line(base, w: double.infinity, h: 72, r: 10),
    ],
  );

  static Widget _summary(Color base) => Column(
    children: [
      _row(base),
      const SizedBox(height: 8),
      _row(base),
      const Divider(height: 16, thickness: 2),
      _row(base),
    ],
  );

  static Widget _shimmerCard(Color base, Color hl, {required Widget child}) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hl,
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  static Widget _line(
    Color base, {
    double w = 100,
    double h = 12,
    double r = 6,
  }) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }

  static Widget _row(Color base) {
    return Row(
      children: [
        _line(base, w: 120, h: 12),
        const Spacer(),
        _line(base, w: 80, h: 12),
      ],
    );
  }

  static Widget _productRow(Color base) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(base, w: 160, h: 12),
              const SizedBox(height: 8),
              Row(
                children: [
                  _line(base, w: 60, h: 10),
                  const SizedBox(width: 8),
                  _line(base, w: 80, h: 10),
                ],
              ),
              const SizedBox(height: 8),
              _line(base, w: 120, h: 10),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _line(base, w: double.infinity, h: 10)),
                  const SizedBox(width: 10),
                  _line(base, w: 40, h: 10),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomBarShimmer extends StatelessWidget {
  const _BottomBarShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB);
    final hl = isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : Colors.white,
        ),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: hl,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openAttachment(BuildContext context, String? path) {
  if (path == null || path.isEmpty) return;

  Get.toNamed(
    AppRoutes.fullScreenImageView,
    arguments: {
      'images': [path],
      'index': 0,
      'id': null,
      'heroPrefix': 'checkoutAttachment',
    },
  );
}

String? _attachmentLabelFromRaw(dynamic raw) {
  if (raw == null) return null;

  if (raw is Map) {
    final name = raw['file_name']?.toString();
    final id = raw['file_id']?.toString();
    if (name != null && name.isNotEmpty) return name;
    if (id != null && id.isNotEmpty) return 'Attachment #$id';
    return 'Attachment';
  }

  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;
    try {
      final decoded = jsonDecode(s);
      return _attachmentLabelFromRaw(decoded);
    } catch (_) {
      return s;
    }
  }

  if (raw is int) return 'Attachment #$raw';
  return raw.toString();
}

String? _attachmentPathFromRaw(dynamic raw) {
  if (raw == null) return null;

  if (raw is Map) {
    final p = raw['path']?.toString();
    if (p != null && p.isNotEmpty) return p;
    final name = raw['file_name']?.toString();
    if (name != null &&
        (name.startsWith('http://') || name.startsWith('https://'))) {
      return name;
    }
    return null;
  }

  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;
    try {
      final decoded = jsonDecode(s);
      return _attachmentPathFromRaw(decoded);
    } catch (_) {
      if (s.startsWith('http://') || s.startsWith('https://')) return s;
      return null;
    }
  }

  return null;
}
