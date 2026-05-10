import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import 'package:kartly_e_commerce/core/services/login_service.dart';
import 'package:kartly_e_commerce/modules/account/view/settings_view.dart';
import 'package:kartly_e_commerce/shared/widgets/cart_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/notification_icon_widget.dart';
import 'package:kartly_e_commerce/shared/widgets/search_icon_widget.dart';
import 'package:kartly_e_commerce/shared/utils/dialog_utils.dart';

import '../../../core/controllers/currency_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/customer_basic_info_controller.dart';
import '../controller/customer_dashboard_controller.dart';

class AccountView extends StatelessWidget {
  final bool showBackButton;
  const AccountView({super.key, this.showBackButton = true});

  void _showLoginPrompt() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/wishlist_guest.png', width: 100, height: 100),
            const SizedBox(height: 16),
            Text('Please sign in to access this feature'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: () { safeBack(); Get.offAllNamed(AppRoutes.loginView); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Login'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final infoCtrl = Get.put(CustomerBasicInfoController(), permanent: false);
    final dashCtrl = Get.put(CustomerDashboardController(), permanent: false);
    final currencyCtrl = Get.find<CurrencyController>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, titleSpacing: 10, centerTitle: false,
          title: Text('Account'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [SearchIconWidget(), CartIconWidget(), NotificationIconWidget()],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Obx(
              () => Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: const BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AvatarCircle(url: infoCtrl.avatarUrl.value),
                    const SizedBox(width: 10),
                    Expanded(child: _HeaderTexts(isLoggedIn: LoginService().isLoggedIn(), name: infoCtrl.name.value, email: infoCtrl.email.value, phone: infoCtrl.phone.value)),
                    IconButton(
                      icon: const Icon(Iconsax.edit_copy, size: 18, color: Colors.white),
                      onPressed: () {
                        if (!LoginService().isLoggedIn()) { Get.toNamed(AppRoutes.loginView, arguments: {'redirect': AppRoutes.editProfileView}); return; }
                        Get.toNamed(AppRoutes.editProfileView);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: LoginService().isLoggedIn()
            ? RefreshIndicator(
                onRefresh: () async { await infoCtrl.fetchBasicInfo(); dashCtrl.loadFromStorage(); currencyCtrl.refreshSelected(); },
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Obx(() => Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _statCard("${"Total".tr}\n${"Orders".tr}", '${dashCtrl.totalOrder.value}', context),
                      _statCard("${"Pending".tr}\n${"Orders".tr}", '${dashCtrl.totalPendingOrder.value}', context),
                      _statCard("${"Success".tr}\n${"Orders".tr}", '${dashCtrl.totalSuccessOrder.value}', context),
                    ]))),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Obx(() { String money(num v) => currencyCtrl.format(v, applyConversion: true);
                      return Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _statCard("${"Total".tr}\n${"Purchase".tr}", money(dashCtrl.totalPurchaseAmount.value), context),
                        _statCard("${"Purchase".tr} ${"in".tr}\n${dashCtrl.currentMonth.value.isEmpty ? '—' : dashCtrl.currentMonth.value}", money(dashCtrl.currentMonthPurchase.value), context),
                        _statCard("${'Last'.tr} ${'Month'.tr}\n${'Purchase'.tr}", money(dashCtrl.lastMonthPurchase.value), context),
                      ]);
                    })),
                    const SizedBox(height: 30),
                    _menuItem(Iconsax.shopping_bag_copy, "My Orders".tr, () => Get.toNamed(AppRoutes.myOrderListView)),
                    _menuItem(Iconsax.location_copy, "My Addresses".tr, () => Get.toNamed(AppRoutes.myAddressView)),
                    _menuItem(Iconsax.card_copy, "My Wallet".tr, () => Get.toNamed(AppRoutes.myWalletView)),
                    _menuItem(Iconsax.undo_copy, "Refund Requests".tr, () => Get.toNamed(AppRoutes.refundRequestListView)),
                    _menuItem(Iconsax.settings_copy, "Settings".tr, () => Get.to(const SettingsView())),
                    _menuItem(Iconsax.message_add_1_copy, "Contact Us".tr, () => Get.toNamed(AppRoutes.contactUsView)),
                    _menuItem(Iconsax.message_question_copy, "Privacy Policy".tr, () => Get.toNamed(AppRoutes.privacyPolicyView)),
                    _menuItem(Iconsax.information_copy, "Terms and Conditions".tr, () => Get.toNamed(AppRoutes.termsConditionsView)),
                    _menuItem(Iconsax.logout_1_copy, "Logout".tr, () async { await authCtrl.logout(); infoCtrl.avatarUrl.value = ''; infoCtrl.name.value = ''; infoCtrl.email.value = ''; infoCtrl.phone.value = ''; dashCtrl.clear(); }),
                    const SizedBox(height: 20),
                  ]),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {},
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _statCard("${"Total".tr}\n${"Orders".tr}", '0', context),
                      _statCard("${"Pending".tr}\n${"Orders".tr}", '0', context),
                      _statCard("${"Success".tr}\n${"Orders".tr}", '0', context),
                    ])),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _statCard("${"Total".tr}\n${"Purchase".tr}", '₦0.00', context),
                      _statCard("${"Purchase".tr}\n—", '₦0.00', context),
                      _statCard("${'Last'.tr}\n${'Purchase'.tr}", '₦0.00', context),
                    ])),
                    const SizedBox(height: 30),
                    _menuItem(Iconsax.shopping_bag_copy, "My Orders".tr, _showLoginPrompt),
                    _menuItem(Iconsax.location_copy, "My Addresses".tr, _showLoginPrompt),
                    _menuItem(Iconsax.card_copy, "My Wallet".tr, _showLoginPrompt),
                    _menuItem(Iconsax.undo_copy, "Refund Requests".tr, _showLoginPrompt),
                    _menuItem(Iconsax.settings_copy, "Settings".tr, _showLoginPrompt),
                    _menuItem(Iconsax.message_add_1_copy, "Contact Us".tr, () => Get.toNamed(AppRoutes.contactUsView)),
                    _menuItem(Iconsax.message_question_copy, "Privacy Policy".tr, () => Get.toNamed(AppRoutes.privacyPolicyView)),
                    _menuItem(Iconsax.information_copy, "Terms and Conditions".tr, () => Get.toNamed(AppRoutes.termsConditionsView)),
                    _menuItem(Iconsax.user_add_copy, "Register".tr, () => Get.offAllNamed(AppRoutes.signupView)),
                    _menuItem(Iconsax.login_1_copy, "Login".tr, () => Get.offAllNamed(AppRoutes.loginView)),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
      ),
    );
  }

  Widget _statCard(String title, String valueText, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: 90, padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(valueText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
          Text(title, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 12, right: 12), dense: true, visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      leading: Icon(icon, color: AppColors.primaryColor, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Iconsax.arrow_right_3_copy, size: 18),
      onTap: onTap,
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    final hasNet = url.isNotEmpty;
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      backgroundImage: hasNet
          ? CachedNetworkImageProvider(url)
          : null,
      onBackgroundImageError: (_, __) {},
      child: hasNet
          ? null
          : Image.asset("assets/icons/profile.png", width: 80, height: 80, fit: BoxFit.cover),
    );
  }
}

class _HeaderTexts extends StatelessWidget {
  const _HeaderTexts({required this.isLoggedIn, required this.name, required this.email, required this.phone});
  final bool isLoggedIn;
  final String name;
  final String email;
  final String phone;
  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Guest User'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text('Please login to manage your account'.tr, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name.isNotEmpty ? name : '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
      Text(email.isNotEmpty ? email : '—', style: const TextStyle(fontSize: 14, color: Colors.white70), overflow: TextOverflow.ellipsis),
      Text(phone.isNotEmpty ? phone : '—', style: const TextStyle(fontSize: 14, color: Colors.white70), overflow: TextOverflow.ellipsis),
    ]);
  }
}
