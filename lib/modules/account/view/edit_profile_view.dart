import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
                  // Phone with country code
                  Row(
                    children: [
                      // Country code dropdown
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Obx(() => DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: c.phoneCode.value,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
                            items: const [
                              DropdownMenuItem(value: '+234', child: Text('🇳🇬 +234', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: '+233', child: Text('🇬🇭 +233', style: TextStyle(fontSize: 14))),
                            ],
                            onChanged: (v) {
                              if (v != null) c.phoneCode.value = v;
                            },
                          ),
                        )),
                      ),
                      const SizedBox(width: 10),
                      // Phone number field
                      Expanded(
                        child: CustomTextFormField(
                          controller: c.phoneController,
                          hint: 'Phone number'.tr,
                          icon: Iconsax.call_copy,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
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
