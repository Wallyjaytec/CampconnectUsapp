import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/modules/account/widgets/custom_text_form_field.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../controller/contact_controller.dart';

class ContactUsView extends StatelessWidget {
  const ContactUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ContactController(repository: ContactRepository()),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Contact Us'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Text(
                "We love to connect with you Let us know how we can help".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: controller.nameController,
                hint: 'Name'.tr,
                keyboardType: TextInputType.name,
                icon: Iconsax.user_copy,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: controller.emailController,
                hint: 'Email'.tr,
                keyboardType: TextInputType.emailAddress,
                icon: Iconsax.sms_copy,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: controller.subjectController,
                hint: 'Subject'.tr,
                keyboardType: TextInputType.text,
                icon: Iconsax.message_copy,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write a Message'.tr,
                  hintStyle: const TextStyle(
                    color: AppColors.greyColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCardColor
                      : AppColors.lightCardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submitContactForm,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          )
                        : Text('Submit'.tr),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
