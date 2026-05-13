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

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CustomerBasicInfoController>();
    final basicCtrl = Get.find<CustomerBasicInfoController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          } else if (avatar.isNotEmpty) {
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
                    child: GestureDetector(
                      onTap: () => basicCtrl.sendResetEmailLink(),
                      child: Text("${'Reset Email'.tr} ${'?'}", style: const TextStyle(fontSize: 14, color: AppColors.primaryColor)),
                    ),
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
                    child: GestureDetector(
                      onTap: () => basicCtrl.sendForgotPasswordLink(),
                      child: Text('Forgot Password${' ?'.tr}', style: const TextStyle(fontSize: 14, color: AppColors.primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Phone with country picker
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: PhoneFormField(
                        initialValue: PhoneNumber(isoCode: IsoCode.NG, nsn: ''),
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
                          c.phoneController.text = p.international;
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
