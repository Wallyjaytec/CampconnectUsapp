import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kartly_e_commerce/modules/account/view/web_pay_view.dart';
import 'package:kartly_e_commerce/shared/utils/dialog_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/login_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../auth/widget/custom_text_field.dart';
import '../controller/wallet_recharge_controller.dart';
import '../model/wallet_payment_methods_model.dart';

class RechargeWalletView extends StatelessWidget {
  RechargeWalletView({super.key});

  final WalletRechargeController c = Get.put(
    WalletRechargeController(repo: WalletRepository(api: ApiService())),
  );

  final tabs = [
    Tab(height: 38, text: 'Online'.tr),
    Tab(height: 38, text: 'Offline'.tr),
  ];

  @override
  Widget build(BuildContext context) {
    String code = 'USD';
    int currencyId = 1;
    if (Get.isRegistered<CurrencyService>()) {
      final svc = Get.find<CurrencyService>();
      final cur = svc.current;
      if (cur != null) {
        code = (cur.code.isNotEmpty ? cur.code : 'USD').toUpperCase();
        currencyId = cur.id;
      }
    }
    if (c.currencyId.value != currencyId) {
      c.setCurrency(currencyId);
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false, leadingWidth: 44, leading: const BackIconWidget(),
          centerTitle: false, titleSpacing: 0,
          title: Text('Wallet Recharge'.tr, style: const TextStyle(fontSize: 18)),
          bottom: TabBar(
            padding: EdgeInsets.zero, indicatorColor: AppColors.whiteColor,
            labelColor: AppColors.whiteColor, labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelColor: AppColors.greyColor, unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: tabs, onTap: c.setTab,
          ),
        ),
        body: Obx(() {
          if (c.isLoadingMethods.value && c.methods.value == null) return const _RechargeShimmer();
          if (c.methodsError.isNotEmpty) return _Err(msg: c.methodsError.value, onRetry: c.loadMethods);
          final methods = c.methods.value!;
          return TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _OnlineTab(methods: methods.onlineMethods, currencyCode: code),
              _OfflineTab(methods: methods.offlineMethods, currencyCode: code),
            ],
          );
        }),
      ),
    );
  }
}

class _OnlineTab extends StatelessWidget {
  const _OnlineTab({required this.methods, required this.currencyCode});
  final List<WalletOnlineMethod> methods;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final validMethods = methods.where((e) => e.id > 0 && e.name.trim().isNotEmpty).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (validMethods.isEmpty) return Center(child: Text('No online methods available'.tr));
    return ListView.separated(
      padding: const EdgeInsets.all(10), itemCount: validMethods.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = validMethods[i];
        return Container(
          decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            hoverColor: AppColors.transparentColor, contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: _LogoBox(url: m.logo),
            title: const SizedBox.shrink(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                const Icon(Iconsax.arrow_right_3_copy, color: AppColors.greyColor, size: 18),
              ],
            ),
            onTap: () => _openOnlineAmountSheet(m, currencyCode),
          ),
        );
      },
    );
  }

  void _openOnlineAmountSheet(WalletOnlineMethod method, String currencyCode) {
    final ctrl = Get.find<WalletRechargeController>();
    ctrl.pickOnlineMethod(method.id); ctrl.setOnlineAmount('');
    Get.bottomSheet(
      Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom), child: SafeArea(top: false, child: _OnlineAmountSheet(method: method, currencyCode: currencyCode))),
      isScrollControlled: true, backgroundColor: Get.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    );
  }
}

class _OnlineAmountSheet extends StatelessWidget {
  const _OnlineAmountSheet({required this.method, required this.currencyCode});
  final WalletOnlineMethod method;
  final String currencyCode;
  String _pretty(num v) => formatCurrency(v, applyConversion: false);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WalletRechargeController>();
    return Obx(() {
      final min = c.minAmount.value; final max = c.maxAmount.value; final isLoaded = c.isLimitsLoaded.value;
      String helper = '';
      if (isLoaded) { final parts = <String>[]; if (min != null) parts.add('min ${_pretty(min)}'); if (max != null) parts.add('max ${_pretty(max)}'); if (parts.isNotEmpty) helper = 'Limits: ${parts.join(', ')} ($currencyCode)'; } else { helper = 'Fetching limits...'; }
      final err = c.onlineFieldErrors['recharge_amount'];
      return Wrap(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [_LogoBox(url: method.logo), const SizedBox(width: 8), Expanded(child: Text('${'Pay with'.tr} ${method.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), IconButton(onPressed: () => safeBack(), icon: const Icon(Icons.close))]),
          const SizedBox(height: 12),
          CustomTextField(hint: '${'Enter amount'.tr} ($currencyCode)', icon: Iconsax.coin_1_copy, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: c.setOnlineAmount),
          if (err != null) ...[const SizedBox(height: 4), Text(err, style: const TextStyle(color: Colors.red, fontSize: 12))] else if (helper.isNotEmpty) ...[const SizedBox(height: 4), Text(helper, style: const TextStyle(color: Colors.black54, fontSize: 12))],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46, child: ElevatedButton.icon(
            onPressed: c.isGeneratingLink.value ? null : () async {
              final url = await c.generateOnlineLink(); if (url == null) return;
              if (kIsWeb) { final ok = await launchUrlString(url, mode: LaunchMode.externalApplication); return; }
              final login = LoginService(); final headers = <String, String>{}; final token = login.token;
              if (token != null && token.isNotEmpty) headers['Authorization'] = '${login.tokenType} $token';
              final result = await Get.to<bool>(() => WebPayView(initialUrl: url, headers: headers));
              if (result == true) { if (Get.isBottomSheetOpen == true) safeBack(); }
            },
            icon: c.isGeneratingLink.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Iconsax.send_2_copy),
            label: Text('Generate and Pay'.tr),
          )),
          const SizedBox(height: 10),
        ])),
      ]);
    });
  }
}

class _OfflineTab extends StatelessWidget {
  const _OfflineTab({required this.methods, required this.currencyCode});
  final List<WalletOfflineMethod> methods;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WalletRechargeController>();
    return ListView(padding: const EdgeInsets.all(12), children: [
      _OfflineMethodPicker(methods: methods), const SizedBox(height: 10),
      _OfflineMethodDetails(methods: methods), const SizedBox(height: 10),
      _LabeledField(child: CustomTextField(hint: '${'Enter amount'.tr} ($currencyCode)', icon: Iconsax.coin_1_copy, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: ctrl.setAmount)), const SizedBox(height: 10),
      Obx(() { final err = ctrl.fieldErrors['transaction_id']; return _LabeledField(errorText: err, child: CustomTextField(hint: 'Transaction ID'.tr, icon: Iconsax.hashtag_1_copy, onChanged: ctrl.setTxnId)); }), const SizedBox(height: 10),
      Obx(() { final file = ctrl.transactionProof.value; return _LabeledField(child: Row(children: [ElevatedButton.icon(onPressed: () async { final allowed = await PermissionService.I.canUseMediaOrExplain(); if (!allowed) return; final picker = ImagePicker(); final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85); if (x != null) ctrl.setProof(File(x.path)); }, icon: const Icon(Iconsax.image_copy), label: Text('Choose Image'.tr)), const SizedBox(width: 10), Expanded(child: Text(file == null ? 'No file chosen'.tr : file.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis))])); }), const SizedBox(height: 20),
      Obx(() {
        final raw = ctrl.rechargeAmount.value.trim(); final parsed = double.tryParse(raw); final hasValidNumber = parsed != null;
        final hasTxn = ctrl.transactionId.value.trim().isNotEmpty; final hasMethod = ctrl.selectedOfflineMethodId.value > 0;
        final hasFile = ctrl.transactionProof.value != null;
        final canSubmit = hasValidNumber && hasTxn && hasMethod && hasFile && !ctrl.isSubmitting.value;
        return SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: canSubmit ? () async { final ok = await ctrl.submitOffline(); if (ok) { ctrl.setAmount(''); ctrl.setTxnId(''); ctrl.setProof(null); } } : null, icon: ctrl.isSubmitting.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const SizedBox(), label: Text('Submit'.tr)));
      }),
    ]);
  }
}

class _OfflineMethodPicker extends StatelessWidget {
  const _OfflineMethodPicker({required this.methods});
  final List<WalletOfflineMethod> methods;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Get.find<WalletRechargeController>();
    if (methods.isEmpty) return Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('No offline methods available'.tr)));
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Obx(() {
        final selected = c.selectedOfflineMethodId.value;
        return RadioGroup<int>(groupValue: selected, onChanged: (v) { if (v != null) c.pickOfflineMethod(v); }, child: Column(children: methods.map((m) {
          final active = (m.id == selected);
          return GestureDetector(onTap: () => c.pickOfflineMethod(m.id), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
            Transform.scale(scale: 0.80, child: Radio<int>(value: m.id)), const SizedBox(width: 6),
            _LogoBox(url: m.logo), const SizedBox(width: 10),
            Expanded(child: Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            if (active) const Icon(Icons.check_circle, size: 18, color: AppColors.primaryColor),
          ])));
        }).toList()));
      }),
    );
  }
}

class _OfflineMethodDetails extends StatelessWidget {
  const _OfflineMethodDetails({required this.methods});
  final List<WalletOfflineMethod> methods;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Get.find<WalletRechargeController>();
    return Obx(() {
      final id = c.selectedOfflineMethodId.value;
      final m = methods.firstWhereOrNull((e) => e.id == id);
      if (m == null) return const SizedBox.shrink();

      final hasInstruction = (m.instructionHtml ?? '').trim().isNotEmpty;
      final hasBankName = (m.bankName ?? '').trim().isNotEmpty;
      final hasAccName = (m.accountName ?? '').trim().isNotEmpty;
      final hasAccNo = (m.accountNumber ?? '').trim().isNotEmpty;
      final hasRouting = (m.routingNumber ?? '').trim().isNotEmpty;
      final hasSwift = (m.swiftCode ?? '').trim().isNotEmpty;
      final hasBankAddr = (m.bankAddress ?? '').trim().isNotEmpty;
      final hasPhone = (m.phoneNumber ?? '').trim().isNotEmpty;
      final hasEmail = (m.email ?? '').trim().isNotEmpty;
      final hasSort = (m.sortCode ?? '').trim().isNotEmpty;
      final any = hasInstruction || hasBankName || hasAccName || hasAccNo || hasRouting || hasSwift || hasBankAddr || hasPhone || hasEmail || hasSort;
      if (!any) return const SizedBox.shrink();

      return Container(
        decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hasInstruction) ...[
            Row(children: [
              const Icon(Iconsax.info_circle, size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              Text('Instruction'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Scrollbar(
                thumbVisibility: true, trackVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 8),
                  child: HtmlWidget(
                    (m.instructionHtml ?? '').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&'),
                    textStyle: const TextStyle(fontSize: 14, height: 1.8),
                  ),
                ),
              ),
            ),
          ],
          if (hasBankName || hasAccName || hasAccNo || hasRouting || hasSwift || hasBankAddr || hasPhone || hasEmail || hasSort) ...[
            const SizedBox(height: 10), const Divider(), const SizedBox(height: 6),
            Row(children: [
              const Icon(Iconsax.bank, size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              Text('Bank Details'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
            if (hasBankName) _KV('Bank Name'.tr, m.bankName!),
            if (hasAccName) _KV('Account Name'.tr, m.accountName!),
            if (hasAccNo) _KV('Account Number'.tr, m.accountNumber!),
            if (hasRouting) _KV('Routing Number'.tr, m.routingNumber!),
            if (hasSwift) _KV('SWIFT/BIC Code'.tr, m.swiftCode!),
            if (hasBankAddr) _KV('Bank Address'.tr, m.bankAddress!),
            if (hasPhone) _KV('Phone'.tr, m.phoneNumber!),
            if (hasEmail) _KV('Email'.tr, m.email!),
            if (hasSort) _KV('Sort Code'.tr, m.sortCode!),
          ],
        ]),
      );
    });
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('$k: ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: v));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$k copied'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 1)));
          },
          child: const Icon(Iconsax.copy_copy, size: 16, color: AppColors.primaryColor),
        ),
      ]),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final resolved = AppConfig.assetUrl(url);
    final hasImage = resolved.isNotEmpty;
    return Container(
      width: 100, height: 36, clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(10),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: resolved, fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 300),
              placeholderFadeInDuration: const Duration(milliseconds: 0),
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const Center(child: Icon(Iconsax.card_pos_copy, size: 18)),
            )
          : const Center(child: Icon(Iconsax.card_pos_copy, size: 18)),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.child, this.errorText});
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [child, if (errorText != null) ...[const SizedBox(height: 4), Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12))]]);
}

class _Err extends StatelessWidget {
  const _Err({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Iconsax.info_circle, size: 38), const SizedBox(height: 10), Text('Failed to load methods'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(msg, textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text('Retry'.tr))])));
}

class _RechargeShimmer extends StatelessWidget {
  const _RechargeShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12;
    final highlight = Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26;
    return ListView.separated(padding: const EdgeInsets.all(12), itemBuilder: (_, __) => Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: Container(height: 88, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12)))), separatorBuilder: (_, __) => const SizedBox(height: 10), itemCount: 6);
  }
}
