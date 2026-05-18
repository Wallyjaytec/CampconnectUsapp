import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../controller/customer_basic_info_controller.dart';
import '../widgets/custom_text_form_field.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late CustomerBasicInfoController c;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _refreshData() async {
    await c.fetchBasicInfo();
    
    if (c.phone.value.isNotEmpty) {
      String fullPhone = c.phone.value;
      
      // Extract country code (starts with + followed by digits)
      final match = RegExp(r'^\+(\d+)').firstMatch(fullPhone);
      if (match != null) {
        String code = '+' + match.group(1)!;
        String number = fullPhone.substring(code.length);
        
        // Update both controller values
        c.phoneCode.value = code;
        c.phoneController.text = number;
      } else {
        // If no country code found, just show the number
        c.phoneController.text = fullPhone;
      }
    }
    
    setState(() {});
  }

  Future<void> _initController() async {
    try {
      c = Get.find<CustomerBasicInfoController>();
    } catch (e) {
      Get.put(CustomerBasicInfoController());
      c = Get.find<CustomerBasicInfoController>();
    }
    
    await Future.delayed(Duration(milliseconds: 500));
    await _refreshData();
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final basicCtrl = c;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = Get.arguments;
      if (arguments is String && arguments.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(arguments), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating),
        );
      }
    });

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Edit Profile'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
        ),
        body: Obx(() {
          final loading = c.isLoading.value;
          final picked = c.pickedImagePath.value;
          final avatar = c.avatarUrl.value;

          ImageProvider avatarProvider;
          if (picked.isNotEmpty && File(picked).existsSync()) {
            avatarProvider = FileImage(File(picked));
          } else if (avatar.isNotEmpty && avatar != '/') {
            avatarProvider = CachedNetworkImageProvider(avatar);
          } else {
            avatarProvider = const AssetImage("assets/icons/profile.png");
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 50, backgroundImage: avatarProvider),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryColor,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Iconsax.gallery_copy, size: 16, color: Colors.white),
                          onPressed: loading ? null : c.pickFromGallery,
                        ),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryColor,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Iconsax.camera_copy, size: 16, color: Colors.white),
                          onPressed: loading ? null : c.pickFromCamera,
                        ),
                      ),
                      Obx(() {
                        final hasImage = (c.avatarUrl.value.isNotEmpty && c.avatarUrl.value != '/') || c.pickedImagePath.value.isNotEmpty;
                        if (!hasImage) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: loading ? null : c.removeProfilePicture,
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFFFF8C00),
                              child: Icon(Iconsax.trash_copy, size: 16, color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  CustomTextFormField(
                    controller: c.nameController,
                    hint: 'Full Name'.tr,
                    icon: Iconsax.user_copy,
                  ),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: TextEditingController(text: c.email.value),
                    readOnly: true,
                    icon: Iconsax.sms_copy,
                    hint: 'Email'.tr,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => GestureDetector(
                      onTap: basicCtrl.isSendingResetLink.value ? null : () => basicCtrl.sendResetEmailLink(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (basicCtrl.isSendingResetLink.value)
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            Text("Reset Email ?", style: const TextStyle(fontSize: 14, color: AppColors.primaryColor)),
                        ],
                      ),
                    )),
                  ),
                  const SizedBox(height: 4),
                  CustomTextFormField(
                    maxLines: 1, minLines: 1,
                    hint: 'Password'.tr,
                    icon: Iconsax.lock_1_copy,
                    readOnly: true,
                    controller: TextEditingController(text: '********'),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => GestureDetector(
                      onTap: basicCtrl.isSendingForgotLink.value ? null : () => basicCtrl.sendForgotPasswordLink(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (basicCtrl.isSendingForgotLink.value)
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            Text('Reset Password ?', style: const TextStyle(fontSize: 14, color: AppColors.primaryColor)),
                        ],
                      ),
                    )),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: PhoneFormField(
                        key: ValueKey(c.phoneController.text),
                        initialValue: _getInitialPhone(c.phoneCode.value, c.phoneController.text),
                        countrySelectorNavigator: const CountrySelectorNavigator.page(),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                          hintText: 'Phone number'.tr,
                          contentPadding: EdgeInsets.zero,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.2),
                        onChanged: (p) {
                          c.phoneCode.value = '+${p.countryCode}';
                          c.phoneController.text = p.nsn;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: ElevatedButton(
                      onPressed: loading ? null : c.saveBasicInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                          : Text('Save Changes'.tr, style: const TextStyle(color: Colors.white)),
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

PhoneNumber _getInitialPhone(String code, String number) {
  if (number.isEmpty) return PhoneNumber(isoCode: IsoCode.NG, nsn: '');
  try {
    final cleanCode = code.replaceAll('+', '');
    for (final iso in IsoCode.values) {
      try {
        if (PhoneNumber(isoCode: iso, nsn: '').countryCode == cleanCode) {
          return PhoneNumber(isoCode: iso, nsn: number);
        }
      } catch (_) {}
    }
    return PhoneNumber(isoCode: IsoCode.NG, nsn: number);
  } catch (_) {
    return PhoneNumber(isoCode: IsoCode.NG, nsn: number);
  }
}
