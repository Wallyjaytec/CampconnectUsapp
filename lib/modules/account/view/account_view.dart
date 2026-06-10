import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:campconnectus_marketplace/core/services/login_service.dart';
import 'package:campconnectus_marketplace/modules/account/view/settings_view.dart';
import 'package:campconnectus_marketplace/modules/account/view/support_view.dart';
import 'package:campconnectus_marketplace/shared/widgets/cart_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/notification_icon_widget.dart';
import 'package:campconnectus_marketplace/shared/widgets/search_icon_widget.dart';

import '../../../core/config/app_config.dart';
import '../../../core/controllers/currency_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/customer_basic_info_controller.dart';
import '../controller/customer_dashboard_controller.dart';

class AccountView extends StatelessWidget {
  final bool showBackButton;
  const AccountView({super.key, this.showBackButton = true});

  void _showLoginPrompt({String? redirectTo}) {
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
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.loginView, arguments: {'redirect': redirectTo ?? AppRoutes.bottomNavbarView});
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Login'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseAccountDialog() {
    final confirmCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final isCodeSent = false.obs;
    final maskedEmail = ''.obs;
    final isLoading = false.obs;
    final isTextValid = false.obs;
    final isCodeValid = false.obs;

    confirmCtrl.addListener(() {
      isTextValid.value = confirmCtrl.text == 'DELETE MY CCU ACCOUNT';
    });

    codeCtrl.addListener(() {
      isCodeValid.value = codeCtrl.text.trim().length == 6;
    });

    Get.dialog(
      Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkProductCardColor : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Iconsax.warning_2, color: AppColors.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text('Close Account'.tr),
              ],
            ),
            content: Obx(() {
              if (isCodeSent.value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'A verification code has been sent to'.tr} ${maskedEmail.value}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit code'.tr,
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ${'Warning'.tr}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone. All your data will be permanently deleted.'.tr,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${'Type'.tr} "DELETE MY CCU ACCOUNT" ${'to confirm'.tr}:',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type here...'.tr,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              );
            }),
            actions: [
              TextButton(
                onPressed: () {
                  confirmCtrl.dispose();
                  codeCtrl.dispose();
                  Get.back();
                },
                child: Text('Cancel'.tr),
              ),
              Obx(() {
                final valid = isCodeSent.value ? isCodeValid.value && !isLoading.value : isTextValid.value && !isLoading.value;
                return ElevatedButton(
                  onPressed: !valid
                      ? null
                      : () async {
                          if (isLoading.value) return;
                          isLoading.value = true;

                          if (!isCodeSent.value) {
                            try {
                              final api = ApiService();
                              final resp = await api.postJson(AppConfig.sendCloseAccountCodeUrl());
                              if (resp['success'] == true) {
                                isCodeSent.value = true;
                                maskedEmail.value = resp['email']?.toString() ?? '';
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(resp['message']?.toString() ?? 'Failed'.tr),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (_) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Something went wrong'.tr),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } finally {
                              isLoading.value = false;
                            }
                          } else {
                            if (codeCtrl.text.trim().isEmpty || codeCtrl.text.trim().length < 6) {
                              isLoading.value = false;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Please enter the verification code'.tr),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            try {
                              final api = ApiService();
                              final resp = await api.postJson(AppConfig.closeAccountUrl(), body: {
                                'code': codeCtrl.text.trim(),
                              });
                              if (resp['success'] == true) {
                                confirmCtrl.dispose();
                                codeCtrl.dispose();
                                Get.back();
                                final authCtrl = Get.find<AuthController>();
                                await authCtrl.logout();
                                Get.offAllNamed(AppRoutes.loginView);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Account closed permanently'.tr),
                                    backgroundColor: AppColors.primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text((resp['message']?.toString() ?? 'Invalid code').tr),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (_) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Something went wrong'.tr),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } finally {
                              isLoading.value = false;
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading.value
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : Text(isCodeSent.value ? 'Delete My Account'.tr : 'Send Code'.tr),
                );
              }),
            ],
          );
        },
      ),
      barrierDismissible: false,
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
                      icon: const Icon(Iconsax.edit_2, size: 18, color: Colors.white),
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
                onRefresh: () async { await infoCtrl.fetchBasicInfo(); await dashCtrl.fetchDashboard(); currencyCtrl.refreshSelected(); },
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Obx(() => Row(children: [
                      Expanded(child: _statCard("${"Total".tr}\n${"Orders".tr}", '${dashCtrl.totalOrder.value}', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Pending".tr}\n${"Orders".tr}", '${dashCtrl.totalPendingOrder.value}', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Success".tr}\n${"Orders".tr}", '${dashCtrl.totalSuccessOrder.value}', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Cancelled".tr}\n${"Orders".tr}", '${dashCtrl.totalCancelledOrder.value}', context)),
                    ]))),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Obx(() { String money(num v) => currencyCtrl.format(v, applyConversion: true);
                      return Row(children: [
                        Expanded(child: _statCard("${"Total".tr}\n${"Purchase".tr}", money(dashCtrl.totalPurchaseAmount.value), context)),
                        const SizedBox(width: 6),
                        Expanded(child: _statCard("${"Purchase".tr} ${"in".tr}\n${dashCtrl.currentMonth.value.isEmpty ? '—' : dashCtrl.currentMonth.value}", money(dashCtrl.currentMonthPurchase.value), context)),
                        const SizedBox(width: 6),
                        Expanded(child: _statCard("${'Last'.tr} ${'Month'.tr}\n${'Purchase'.tr}", money(dashCtrl.lastMonthPurchase.value), context)),
                        const SizedBox(width: 6),
                        Expanded(child: _statCard("${"Wallet".tr}\n${"Balance".tr}", money(dashCtrl.walletBalance.value), context)),
                      ]);
                    })),
                    const SizedBox(height: 30),
                    _menuItem(Iconsax.shopping_bag, "My Orders".tr, () => Get.toNamed(AppRoutes.myOrderListView)),
                    _menuItem(Iconsax.location, "My Addresses".tr, () => Get.toNamed(AppRoutes.myAddressView)),
                    _menuItem(Iconsax.card, "My Wallet".tr, () => Get.toNamed(AppRoutes.myWalletView)),
                    _menuItem(Iconsax.star, "Ratings & Reviews".tr, () => Get.toNamed(AppRoutes.pendingReviewsView)),
                    _menuItem(Iconsax.ticket_discount, "Coupons".tr, () => Get.toNamed(AppRoutes.couponsView)),
                    _menuItem(Iconsax.shop_add, "Follow Sellers".tr, () => Get.toNamed(AppRoutes.followSellerView)),
                    _menuItem(Iconsax.danger, "Report a Seller".tr, () => Get.toNamed(AppRoutes.reportSellerView)),
                    _menuItem(Iconsax.undo, "Refund Requests".tr, () => Get.toNamed(AppRoutes.refundRequestListView)),
                    _menuItem(Iconsax.setting, "Settings".tr, () => Get.toNamed(AppRoutes.settingsView)),
                    _menuItem(Iconsax.headphone, "Customer Support".tr, () => Get.toNamed(AppRoutes.supportView)),
                    _menuItem(Iconsax.message_add, "Contact Us".tr, () => Get.toNamed(AppRoutes.contactUsView)),
                    _menuItem(Iconsax.lamp_on, "Request Feature".tr, () => Get.toNamed(AppRoutes.requestFeatureView)),
                    _menuItem(Iconsax.message_question, "Privacy Policy".tr, () => Get.toNamed(AppRoutes.privacyPolicyView)),
                    _menuItem(Iconsax.info_circle, "Terms and Conditions".tr, () => Get.toNamed(AppRoutes.termsConditionsView)),
                    _menuItem(Iconsax.profile_delete, "Close Account".tr, () => _showCloseAccountDialog()),
                    _menuItem(Iconsax.logout, "Logout".tr, () async { await authCtrl.logout(); infoCtrl.avatarUrl.value = ''; infoCtrl.name.value = ''; infoCtrl.email.value = ''; infoCtrl.phone.value = ''; dashCtrl.clear(); }),
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
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
                      Expanded(child: _statCard("${"Total".tr}\n${"Orders".tr}", '0', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Pending".tr}\n${"Orders".tr}", '0', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Success".tr}\n${"Orders".tr}", '0', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Cancelled".tr}\n${"Orders".tr}", '0', context)),
                    ])),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
                      Expanded(child: _statCard("${"Total".tr}\n${"Purchase".tr}", '₦0.00', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Purchase".tr}\n—", '₦0.00', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${'Last'.tr}\n${'Purchase'.tr}", '₦0.00', context)),
                      const SizedBox(width: 6),
                      Expanded(child: _statCard("${"Wallet".tr}\n${"Balance".tr}", '₦0.00', context)),
                    ])),
                    const SizedBox(height: 30),
                    _menuItem(Iconsax.shopping_bag, "My Orders".tr, () => _showLoginPrompt(redirectTo: AppRoutes.myOrderListView)),
                    _menuItem(Iconsax.location, "My Addresses".tr, () => _showLoginPrompt(redirectTo: AppRoutes.myAddressView)),
                    _menuItem(Iconsax.card, "My Wallet".tr, () => _showLoginPrompt(redirectTo: AppRoutes.myWalletView)),
                    _menuItem(Iconsax.star, "Ratings & Reviews".tr, () => _showLoginPrompt(redirectTo: AppRoutes.pendingReviewsView)),
                    _menuItem(Iconsax.ticket_discount, "Coupons".tr, () => _showLoginPrompt(redirectTo: AppRoutes.couponsView)),
                    _menuItem(Iconsax.shop_add, "Follow Sellers".tr, () => _showLoginPrompt(redirectTo: AppRoutes.followSellerView)),
                    _menuItem(Iconsax.danger, "Report a Seller".tr, () => _showLoginPrompt(redirectTo: AppRoutes.reportSellerView)),
                    _menuItem(Iconsax.undo, "Refund Requests".tr, () => _showLoginPrompt(redirectTo: AppRoutes.refundRequestListView)),
                    _menuItem(Iconsax.setting, "Settings".tr, () => _showLoginPrompt(redirectTo: AppRoutes.settingsView)),
                    _menuItem(Iconsax.headphone, "Customer Support".tr, () => _showLoginPrompt(redirectTo: AppRoutes.supportView)),
                    _menuItem(Iconsax.message_add, "Contact Us".tr, () => Get.toNamed(AppRoutes.contactUsView)),
                    _menuItem(Iconsax.lamp_on, "Request Feature".tr, () => Get.toNamed(AppRoutes.requestFeatureView)),
                    _menuItem(Iconsax.message_question, "Privacy Policy".tr, () => Get.toNamed(AppRoutes.privacyPolicyView)),
                    _menuItem(Iconsax.info_circle, "Terms and Conditions".tr, () => Get.toNamed(AppRoutes.termsConditionsView)),
                    _menuItem(Iconsax.user_add, "Register".tr, () => Get.toNamed(AppRoutes.signupView)),
                    _menuItem(Iconsax.login, "Login".tr, () => Get.toNamed(AppRoutes.loginView)),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
      ),
    );
  }

  Widget _statCard(String title, String valueText, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 90, padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(valueText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
        const SizedBox(height: 4),
        Text(title, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis)),
      ]),
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
    final hasNet = url.isNotEmpty && url != '/';
    return CircleAvatar(
      radius: 40, backgroundColor: Colors.white,
      child: hasNet
          ? ClipOval(child: CachedNetworkImage(imageUrl: url, width: 80, height: 80, fit: BoxFit.cover, errorWidget: (_, __, ___) => Image.asset("assets/icons/profile.png", width: 80, height: 80, fit: BoxFit.cover)))
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
